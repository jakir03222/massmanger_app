import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    throw MessException('মেস কোড তৈরি করা যায়নি। আবার চেষ্টা করুন।');
  }

  /// Admin creates mess. [linkUser] false = show code dialog before Home.
  Future<Mess> createMess({
    required String name,
    required String location,
    bool linkUser = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw MessException('আগে লগইন করুন।');
    }

    final trimmedName = name.trim();
    final trimmedLocation = location.trim();
    if (trimmedName.isEmpty || trimmedLocation.isEmpty) {
      throw MessException('মেসের নাম ও ঠিকানা দিন।');
    }

    try {
      await _userService.ensureUserDoc(user);
      final existing = await _userService.getUser(user.uid);
      if (existing != null && existing.hasMess) {
        throw MessException('আপনি ইতিমধ্যে একটি মেসে আছেন।');
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
        'role': 'admin',
        'room': null,
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
        await _userService.setMessId(user.uid, doc.id);
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
      throw MessException('মেস তৈরি ব্যর্থ। আবার চেষ্টা করুন।');
    }
  }

  Future<void> linkCurrentUserToMess(String messId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw MessException('আগে লগইন করুন।');
    }
    await _userService.ensureUserDoc(user);
    await _userService.setMessId(user.uid, messId);
  }

  /// Member joins an existing mess using the admin's 6-digit code.
  Future<Mess> joinMess({required String code}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw MessException('আগে লগইন করুন।');
    }

    final normalized = normalizeCode(code);
    if (normalized.length != 6) {
      throw MessException('সঠিক ৬ ডিজিটের মেস কোড দিন।');
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
          'আপনি ইতিমধ্যে অন্য মেসে আছেন। আগে লগআউট/মেস ছাড়ুন।',
        );
      }

      // Prefer mess_codes doc (reliable). Fallback to query for old messes.
      String? messId;
      final codeSnap = await _messCodes.doc(normalized).get();
      if (codeSnap.exists && codeSnap.data() != null) {
        messId = codeSnap.data()!['messId'] as String?;
      }

      if (messId == null || messId.isEmpty) {
        final query =
            await _messes.where('code', isEqualTo: normalized).limit(1).get();
        if (query.docs.isEmpty) {
          throw MessException('মেস কোড সঠিক নয়। অ্যাডমিনের কোড চেক করুন।');
        }
        messId = query.docs.first.id;
        // Backfill lookup for next joins.
        await _messCodes.doc(normalized).set({
          'messId': messId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final messRef = _messes.doc(messId);
      final messSnap = await messRef.get();
      if (!messSnap.exists || messSnap.data() == null) {
        throw MessException('মেস পাওয়া যায়নি।');
      }

      final profile = await _userService.ensureUserDoc(user);
      final memberName = (profile.name != null && profile.name!.trim().isNotEmpty)
          ? profile.name!.trim()
          : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : (user.email ?? 'সদস্য'));

      final memberRef = messRef.collection('members').doc(user.uid);
      final existingMember = await memberRef.get();
      if (!existingMember.exists) {
        await memberRef.set({
          'name': memberName,
          'role': 'member',
          'room': null,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await memberRef.set({'name': memberName}, SetOptions(merge: true));
      }

      await _userService.setMessId(user.uid, messId);

      return Mess.fromMap(messId, messSnap.data()!);
    } on MessException {
      rethrow;
    } on FirebaseException catch (e) {
      throw MessException(_mapError(e));
    } catch (_) {
      throw MessException('মেসে যোগ দিতে ব্যর্থ। আবার চেষ্টা করুন।');
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

  Stream<List<MessMember>> watchMembers(String messId) {
    return _messes.doc(messId).collection('members').snapshots().map((snap) {
      final members = snap.docs
          .map((d) => MessMember.fromMap(d.id, d.data()))
          .toList();
      members.sort((a, b) {
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return a.name.compareTo(b.name);
      });
      return members;
    });
  }

  String _mapError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'অনুমতি নেই। অ্যাডমিনকে জানান।';
      case 'unavailable':
        return 'ইন্টারনেট সংযোগ নেই।';
      case 'failed-precondition':
        return 'ডেটাবেস ইনডেক্স লাগতে পারে। একটু পরে আবার চেষ্টা করুন।';
      case 'not-found':
        return 'মেস কোড সঠিক নয়।';
      default:
        return e.message ?? 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';
    }
  }
}
