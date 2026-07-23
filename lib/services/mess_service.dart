import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../l10n/app_locale.dart';
import '../models/mess.dart';
import 'user_service.dart';

class MessException implements Exception {
  MessException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Admin creates a mess. Other users join with the 6-digit code as members.
class MessService {
  MessService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    UserService? userService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserService _userService;

  String _t(String bn, String en) => AppLocale.pick(bn, en);

  CollectionReference<Map<String, dynamic>> get _messes =>
      _firestore.collection('messes');

  CollectionReference<Map<String, dynamic>> get _messCodes =>
      _firestore.collection('mess_codes');

  String normalizeCode(String code) {
    return code.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<String> _uniqueCode() async {
    final random = Random();
    for (var i = 0; i < 12; i++) {
      final code = List.generate(6, (_) => random.nextInt(10)).join();
      final existing = await _messCodes.doc(code).get();
      if (!existing.exists) return code;
    }
    throw MessException(
      _t('মেস কোড তৈরি করা যায়নি। আবার চেষ্টা করুন।',
          'Could not create a mess code. Please try again.'),
    );
  }

  /// Admin creates mess. [linkUser] false = show code dialog before Home.
  Future<Mess> createMess({
    required String name,
    required String location,
    bool linkUser = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw MessException(_t('আগে লগইন করুন।', 'Please sign in first.'));
    }

    final trimmedName = name.trim();
    final trimmedLocation = location.trim();
    if (trimmedName.isEmpty || trimmedLocation.isEmpty) {
      throw MessException(
        _t('মেসের নাম ও ঠিকানা দিন।', 'Enter the mess name and address.'),
      );
    }

    try {
      await _userService.ensureUserDoc(user);
      final existing = await _userService.getUser(user.uid);
      if (existing != null && existing.hasMess) {
        throw MessException(
          _t('আপনি ইতিমধ্যে একটি মেসে আছেন।', 'You are already in a mess.'),
        );
      }

      final code = await _uniqueCode();
      final doc = _messes.doc();
      final memberName = (existing?.name != null && existing!.name!.trim().isNotEmpty)
          ? existing.name!.trim()
          : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : (user.email ?? trimmedName));

      final batch = _firestore.batch();

      batch.set(doc, {
        'name': trimmedName,
        'location': trimmedLocation,
        'code': code,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(doc.collection('members').doc(user.uid), {
        'name': memberName,
        'role': 'super_admin',
        'room': null,
        'authProvider': UserService.detectAuthProvider(user),
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Reliable join lookup for other users (no collection query needed).
      batch.set(_messCodes.doc(code), {
        'messId': doc.id,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (linkUser) {
        await _userService.setMessId(
          user.uid,
          doc.id,
          messName: trimmedName,
        );
      }

      return Mess(
        id: doc.id,
        name: trimmedName,
        location: trimmedLocation,
        code: code,
        createdBy: user.uid,
      );
    } on MessException {
      rethrow;
    } on FirebaseException catch (e) {
      throw MessException(_mapError(e));
    } catch (e) {
      throw MessException(
        _t('মেস তৈরি ব্যর্থ। আবার চেষ্টা করুন।',
            'Failed to create mess. Please try again.'),
      );
    }
  }

  Future<void> linkCurrentUserToMess(String messId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw MessException(_t('আগে লগইন করুন।', 'Please sign in first.'));
    }
    await _userService.ensureUserDoc(user);
    final mess = await getMess(messId);
    await _userService.setMessId(
      user.uid,
      messId,
      messName: mess?.name,
    );
  }

  static const _secondaryAuthAppName = 'SecondaryAuth';

  Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app(_secondaryAuthAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAuthAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  /// Super admin creates email/password account and joins them to this mess.
  /// Uses a secondary Firebase Auth app so the super admin stays signed in.
  Future<void> createMemberWithEmail({
    required String messId,
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    if (trimmedName.isEmpty) {
      throw MessException(_t('মেম্বারের নাম দিন।', 'Enter the member name.'));
    }
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw MessException(_t('সঠিক ইমেইল দিন।', 'Enter a valid email.'));
    }
    if (password.length < 6) {
      throw MessException(
        _t('পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।',
            'Password must be at least 6 characters.'),
      );
    }

    final actor = await _requireActor(messId);
    if (!actor.isSuperAdmin) {
      throw MessException(
        _t('শুধু সুপার অ্যাডমিন নতুন মেম্বার অ্যাকাউন্ট তৈরি করতে পারে।',
            'Only the super admin can create new member accounts.'),
      );
    }

    final mess = await getMess(messId);
    if (mess == null) {
      throw MessException(_t('মেস পাওয়া যায়নি।', 'Mess not found.'));
    }

    final secondaryApp = await _secondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final secondaryDb = FirebaseFirestore.instanceFor(app: secondaryApp);

    User? createdUser;
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        throw MessException(
          _t('অ্যাকাউন্ট তৈরি ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
              'Failed to create account. Please try again.'),
        );
      }

      await createdUser.updateDisplayName(trimmedName);

      final uid = createdUser.uid;
      final batch = secondaryDb.batch();
      final userRef = secondaryDb.collection('users').doc(uid);
      final memberRef =
          secondaryDb.collection('messes').doc(messId).collection('members').doc(uid);

      batch.set(userRef, {
        'email': trimmedEmail,
        'name': trimmedName,
        'photoUrl': null,
        'bio': null,
        'messId': messId,
        'messName': mess.name,
        'authProvider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(memberRef, {
        'name': trimmedName,
        'role': 'member',
        'room': null,
        'authProvider': 'email',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on MessException {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw MessException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw MessException(_mapError(e));
    } catch (_) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw MessException(
        _t('মেম্বার যোগ করতে ব্যর্থ। আবার চেষ্টা করুন।',
            'Failed to add member. Please try again.'),
      );
    } finally {
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
    }
  }

  /// Member joins an existing mess using the admin's 6-digit code.
  Future<Mess> joinMess({required String code}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw MessException(_t('আগে লগইন করুন।', 'Please sign in first.'));
    }

    final normalized = normalizeCode(code);
    if (normalized.length != 6) {
      throw MessException(
        _t('সঠিক ৬ ডিজিটের মেস কোড দিন।', 'Enter a valid 6-digit mess code.'),
      );
    }

    try {
      await _userService.ensureUserDoc(user);

      final appUser = await _userService.getUser(user.uid);
      if (appUser != null && appUser.hasMess) {
        // Already in this same mess → ok; different mess → block.
        final currentMess = await getMess(appUser.messId!);
        if (currentMess != null && currentMess.code == normalized) {
          return currentMess;
        }
        throw MessException(
          _t('আপনি ইতিমধ্যে অন্য মেসে আছেন। আগে লগআউট/মেস ছাড়ুন।',
              'You are already in another mess. Leave that mess first.'),
        );
      }

      // Prefer mess_codes doc (reliable). No collection scan (security rules block list).
      String? messId;
      final codeSnap = await _messCodes.doc(normalized).get();
      if (codeSnap.exists && codeSnap.data() != null) {
        messId = codeSnap.data()!['messId'] as String?;
      }

      if (messId == null || messId.isEmpty) {
        throw MessException(
          _t('মেস কোড সঠিক নয়। অ্যাডমিনের কোড চেক করুন।',
              'Invalid mess code. Check the admin’s code.'),
        );
      }

      final messRef = _messes.doc(messId);
      final messSnap = await messRef.get();
      if (!messSnap.exists || messSnap.data() == null) {
        throw MessException(_t('মেস পাওয়া যায়নি।', 'Mess not found.'));
      }

      final profile = await _userService.ensureUserDoc(user);
      final memberName = (profile.name != null && profile.name!.trim().isNotEmpty)
          ? profile.name!.trim()
          : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : (user.email ?? _t('সদস্য', 'Member')));

      final memberRef = messRef.collection('members').doc(user.uid);
      final existingMember = await memberRef.get();
      final authProvider = UserService.detectAuthProvider(user);
      if (!existingMember.exists) {
        await memberRef.set({
          'name': memberName,
          'role': 'member',
          'room': null,
          'authProvider': authProvider,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await memberRef.set({
          'name': memberName,
          'authProvider': authProvider,
        }, SetOptions(merge: true));
      }

      final joined = Mess.fromMap(messId, messSnap.data()!);
      await _userService.setMessId(
        user.uid,
        messId,
        messName: joined.name,
      );

      return joined;
    } on MessException {
      rethrow;
    } on FirebaseException catch (e) {
      throw MessException(_mapError(e));
    } catch (_) {
      throw MessException(
        _t('মেসে যোগ দিতে ব্যর্থ। আবার চেষ্টা করুন।',
            'Failed to join mess. Please try again.'),
      );
    }
  }

  Future<Mess?> getMess(String messId) async {
    final snap = await _messes.doc(messId).get();
    if (!snap.exists || snap.data() == null) return null;
    return Mess.fromMap(messId, snap.data()!);
  }

  Stream<Mess?> watchMess(String messId) {
    return _messes.doc(messId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Mess.fromMap(messId, snap.data()!);
    });
  }

  Future<MessMember?> _getMember(String messId, String uid) async {
    final snap = await _messes.doc(messId).collection('members').doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    final mess = await getMess(messId);
    return MessMember.fromMap(
      uid,
      snap.data()!,
      messCreatedBy: mess?.createdBy,
    );
  }

  Future<MessMember> _requireActor(String messId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw MessException(_t('আগে লগইন করুন।', 'Please sign in first.'));
    }
    final me = await _getMember(messId, user.uid);
    if (me == null) {
      throw MessException(
        _t('আপনি এই মেসের মেম্বার নন।', 'You are not a member of this mess.'),
      );
    }
    return me;
  }

  /// Admin updates a member's room number.
  Future<void> updateMemberRoom({
    required String messId,
    required String uid,
    required String? room,
  }) async {
    try {
      final actor = await _requireActor(messId);
      final target = await _getMember(messId, uid);
      if (target == null) {
        throw MessException(_t('মেম্বার পাওয়া যায়নি।', 'Member not found.'));
      }
      if (target.uid != actor.uid && !target.canBeManagedBy(actor)) {
        throw MessException(
          _t('এই মেম্বার ম্যানেজ করার অনুমতি নেই।',
              'You do not have permission to manage this member.'),
        );
      }
      await _messes.doc(messId).collection('members').doc(uid).set(
        {'room': (room == null || room.trim().isEmpty) ? null : room.trim()},
        SetOptions(merge: true),
      );
    } on MessException {
      rethrow;
    } on FirebaseException catch (e) {
      throw MessException(_mapError(e));
    }
  }

  /// Only super admin can promote/demote to admin. Super admin role is locked.
  Future<void> setMemberRole({
    required String messId,
    required String uid,
    required bool makeAdmin,
  }) async {
    try {
      final actor = await _requireActor(messId);
      final target = await _getMember(messId, uid);
      if (target == null) {
        throw MessException(_t('মেম্বার পাওয়া যায়নি।', 'Member not found.'));
      }
      if (!actor.canChangeRoleOf(target)) {
        if (target.isSuperAdmin) {
          throw MessException(
            _t('সুপার অ্যাডমিনের রোল কেউ পরিবর্তন করতে পারবে না।',
                'No one can change the super admin role.'),
          );
        }
        throw MessException(
          _t('শুধু সুপার অ্যাডমিন অন্যকে অ্যাডমিন বানাতে/সরাতে পারে।',
              'Only the super admin can promote or demote admins.'),
        );
      }
      await _messes.doc(messId).collection('members').doc(uid).set(
        {'role': makeAdmin ? 'admin' : 'member'},
        SetOptions(merge: true),
      );
    } on MessException {
      rethrow;
    } on FirebaseException catch (e) {
      throw MessException(_mapError(e));
    }
  }

  /// Super admin can remove anyone except self.
  /// Regular admin can only remove normal members.
  Future<void> removeMember({
    required String messId,
    required String uid,
  }) async {
    final me = _auth.currentUser;
    if (me != null && me.uid == uid) {
      throw MessException(
        _t('নিজেকে রিমুভ করা যাবে না। "মেস ছাড়ুন" ব্যবহার করুন।',
            'You cannot remove yourself. Use “Leave mess” instead.'),
      );
    }
    try {
      final actor = await _requireActor(messId);
      final target = await _getMember(messId, uid);
      if (target == null) {
        throw MessException(_t('মেম্বার পাওয়া যায়নি।', 'Member not found.'));
      }
      if (target.isSuperAdmin) {
        throw MessException(
          _t('সুপার অ্যাডমিনকে রিমুভ করা যায় না।',
              'The super admin cannot be removed.'),
        );
      }
      if (!target.canBeManagedBy(actor)) {
        throw MessException(
          actor.isRegularAdmin
              ? _t(
                  'অ্যাডমিন শুধু সাধারণ মেম্বার রিমুভ করতে পারে। অ্যাডমিনকে সুপার অ্যাডমিন নিয়ন্ত্রণ করে।',
                  'Admins can only remove regular members. Super admin manages other admins.',
                )
              : _t('এই মেম্বার রিমুভ করার অনুমতি নেই।',
                  'You do not have permission to remove this member.'),
        );
      }
      // Atomic: delete member + clear users.messId in one batch.
      final batch = _firestore.batch();
      batch.delete(_messes.doc(messId).collection('members').doc(uid));
      final userRef = _firestore.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final currentMessId = userSnap.data()?['messId'];
      if (currentMessId is String && currentMessId == messId) {
        batch.set(
          userRef,
          {'messId': null, 'messName': null},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } on MessException {
      rethrow;
    } on FirebaseException catch (e) {
      throw MessException(_mapError(e));
    }
  }

  /// Current user leaves the mess.
  Future<void> leaveMess() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw MessException(_t('আগে লগইন করুন।', 'Please sign in first.'));
    }
    final appUser = await _userService.getUser(user.uid);
    final messId = appUser?.messId;
    if (messId == null || messId.isEmpty) {
      throw MessException(_t('আপনি কোনো মেসে নেই।', 'You are not in a mess.'));
    }

    try {
      final members = await watchMembers(messId).first;
      final meList = members.where((m) => m.uid == user.uid);
      if (meList.isEmpty) {
        await _userService.clearMessId(user.uid);
        return;
      }
      final me = meList.first;

      if (me.isSuperAdmin && members.length > 1) {
        throw MessException(
          _t(
            'আপনি সুপার অ্যাডমিন। মেসে অন্য মেম্বার থাকলে ছাড়া যায় না। '
            'আগে মেস হস্তান্তর করুন বা সবাইকে রিমুভ করুন।',
            'You are the super admin. You cannot leave while other members remain. '
            'Transfer the mess first or remove everyone.',
          ),
        );
      }
      if (me.isRegularAdmin && members.length > 1) {
        final otherManagers =
            members.where((m) => m.isAdmin && m.uid != user.uid).length;
        if (otherManagers == 0) {
          throw MessException(
            _t(
              'আপনি একমাত্র অ্যাডমিন। আগে সুপার অ্যাডমিনকে জানান বা অন্যকে অ্যাডমিন বানান।',
              'You are the only admin. Notify the super admin or promote someone else first.',
            ),
          );
        }
      }

      await _messes.doc(messId).collection('members').doc(user.uid).delete();
      await _userService.clearMessId(user.uid);
    } on MessException {
      rethrow;
    } on FirebaseException catch (e) {
      throw MessException(_mapError(e));
    }
  }

  /// Super admin transfers ownership to another member.
  Future<void> transferSuperAdmin({
    required String messId,
    required String newSuperAdminUid,
  }) async {
    try {
      final actor = await _requireActor(messId);
      if (!actor.isSuperAdmin) {
        throw MessException(
          _t('শুধু সুপার অ্যাডমিন হস্তান্তর করতে পারে।',
              'Only the super admin can transfer ownership.'),
        );
      }
      if (newSuperAdminUid == actor.uid) {
        throw MessException(
          _t('নিজের কাছে হস্তান্তর করা যায় না।',
              'You cannot transfer ownership to yourself.'),
        );
      }
      final target = await _getMember(messId, newSuperAdminUid);
      if (target == null) {
        throw MessException(_t('মেম্বার পাওয়া যায়নি।', 'Member not found.'));
      }

      final batch = _firestore.batch();
      final members = _messes.doc(messId).collection('members');
      batch.set(
        members.doc(newSuperAdminUid),
        {'role': 'super_admin'},
        SetOptions(merge: true),
      );
      batch.set(
        members.doc(actor.uid),
        {'role': 'admin'},
        SetOptions(merge: true),
      );
      batch.set(
        _messes.doc(messId),
        {'createdBy': newSuperAdminUid},
        SetOptions(merge: true),
      );
      await batch.commit();
    } on MessException {
      rethrow;
    } on FirebaseException catch (e) {
      throw MessException(_mapError(e));
    }
  }

  Stream<List<MessMember>> watchMembers(String messId) {
    return _messes.doc(messId).collection('members').snapshots().asyncMap(
      (snap) async {
        final mess = await getMess(messId);
        final createdBy = mess?.createdBy;
        final members = snap.docs
            .map(
              (d) => MessMember.fromMap(
                d.id,
                d.data(),
                messCreatedBy: createdBy,
              ),
            )
            .toList();

        // One-time backfill: creator still stored as admin → super_admin.
        for (final m in members) {
          if (createdBy != null &&
              m.uid == createdBy &&
              m.isSuperAdmin) {
            final raw = snap.docs.firstWhere((d) => d.id == m.uid).data();
            if (raw['role'] == 'admin') {
              // ignore: unawaited_futures
              _messes.doc(messId).collection('members').doc(m.uid).set(
                {'role': 'super_admin'},
                SetOptions(merge: true),
              );
            }
          }
        }

        members.sort((a, b) {
          int rank(MessMember m) {
            if (m.isSuperAdmin) return 0;
            if (m.isRegularAdmin) return 1;
            return 2;
          }

          final c = rank(a).compareTo(rank(b));
          if (c != 0) return c;
          return a.name.compareTo(b.name);
        });
        return members;
      },
    );
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return _t('ইমেইল ঠিকানা সঠিক নয়।', 'Invalid email address.');
      case 'email-already-in-use':
        return _t('এই ইমেইলে ইতিমধ্যে অ্যাকাউন্ট আছে।',
            'An account already exists with this email.');
      case 'weak-password':
        return _t('পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।',
            'Password must be at least 6 characters.');
      case 'network-request-failed':
        return _t('ইন্টারনেট সংযোগ নেই। আবার চেষ্টা করুন।',
            'No internet connection. Please try again.');
      case 'too-many-requests':
        return _t('অনেকবার চেষ্টা হয়েছে। একটু পরে আবার চেষ্টা করুন।',
            'Too many attempts. Please try again later.');
      case 'operation-not-allowed':
        return _t('ইমেইল/পাসওয়ার্ড সাইন-আপ চালু নেই।',
            'Email/password sign-up is not enabled.');
      default:
        return e.message ??
            _t('অ্যাকাউন্ট তৈরি ব্যর্থ। আবার চেষ্টা করুন।',
                'Failed to create account. Please try again.');
    }
  }

  String _mapError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return _t('অনুমতি নেই। অ্যাডমিনকে জানান।',
            'Permission denied. Contact an admin.');
      case 'unavailable':
        return _t('ইন্টারনেট সংযোগ নেই।', 'No internet connection.');
      case 'failed-precondition':
        return _t('ডেটাবেস ইনডেক্স লাগতে পারে। একটু পরে আবার চেষ্টা করুন।',
            'A database index may be required. Please try again later.');
      case 'not-found':
        return _t('মেস কোড সঠিক নয়।', 'Invalid mess code.');
      default:
        return e.message ??
            _t('কিছু ভুল হয়েছে। আবার চেষ্টা করুন।',
                'Something went wrong. Please try again.');
    }
  }
}
