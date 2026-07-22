import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Detects sign-in method from Firebase Auth provider data.
  static String detectAuthProvider(User user) {
    final ids = user.providerData.map((p) => p.providerId).toSet();
    if (ids.contains('google.com')) return 'google';
    if (ids.contains('password')) return 'email';
    // Fallback: Google photo URLs often appear after Google sign-in.
    final photo = user.photoURL ?? '';
    if (photo.contains('googleusercontent.com') ||
        photo.contains('ggpht.com')) {
      return 'google';
    }
    return 'email';
  }

  /// Resolves Firebase login status for display. Always returns `google` or `email`.
  static String resolveLoginStatus({
    String? authProvider,
    String? photoUrl,
    User? liveAuthUser,
  }) {
    if (liveAuthUser != null) {
      return detectAuthProvider(liveAuthUser);
    }
    if (authProvider == 'google' || authProvider == 'email') {
      return authProvider!;
    }
    final photo = photoUrl ?? '';
    if (photo.contains('googleusercontent.com') ||
        photo.contains('ggpht.com')) {
      return 'google';
    }
    return 'email';
  }

  Future<AppUser> ensureUserDoc(User user, {String? name}) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    final authProvider = detectAuthProvider(user);

    if (snap.exists) {
      final data = snap.data()!;
      final patch = <String, dynamic>{};
      if (data['authProvider'] != authProvider) {
        patch['authProvider'] = authProvider;
      }
      // Keep email in sync when available.
      final email = user.email?.trim();
      if (email != null && email.isNotEmpty && data['email'] != email) {
        patch['email'] = email;
      }
      final photo = user.photoURL;
      if (photo != null &&
          photo.isNotEmpty &&
          data['photoUrl'] != photo) {
        patch['photoUrl'] = photo;
      }
      if (patch.isNotEmpty) {
        await ref.set(patch, SetOptions(merge: true));
      }

      // Keep mess member doc in sync with Firebase Auth provider.
      final messId = data['messId'];
      if (messId is String && messId.isNotEmpty) {
        await _firestore
            .collection('messes')
            .doc(messId)
            .collection('members')
            .doc(user.uid)
            .set({'authProvider': authProvider}, SetOptions(merge: true));
      }

      return AppUser.fromMap(
        user.uid,
        patch.isEmpty ? data : {...data, ...patch},
      );
    }

    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      name: name ?? user.displayName,
      photoUrl: user.photoURL,
      messId: null,
      messName: null,
      bio: null,
      authProvider: authProvider,
      createdAt: DateTime.now(),
    );

    await ref.set({
      'email': appUser.email,
      'name': appUser.name,
      'photoUrl': appUser.photoUrl,
      'bio': null,
      'messId': null,
      'messName': null,
      'authProvider': authProvider,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return appUser;
  }

  Future<AppUser?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AppUser.fromMap(uid, snap.data()!);
    });
  }

  /// Firebase login status (`google` / `email`) for every member uid.
  /// Current user uses live Firebase Auth; others use Firestore (synced from Auth).
  Future<Map<String, String>> getLoginStatusesForUids({
    required Iterable<String> uids,
    Map<String, String?> memberProviders = const {},
  }) async {
    final unique = uids.toSet();
    if (unique.isEmpty) return {};

    final live = FirebaseAuth.instance.currentUser;
    if (live != null && unique.contains(live.uid)) {
      // Sync this device's Firebase Auth provider into Firestore.
      try {
        await ensureUserDoc(live);
      } catch (_) {}
    }

    final result = <String, String>{};
    await Future.wait(
      unique.map((uid) async {
        final user = await getUser(uid);
        final liveUser =
            (live != null && live.uid == uid) ? live : null;
        result[uid] = resolveLoginStatus(
          authProvider: user?.authProvider ?? memberProviders[uid],
          photoUrl: user?.photoUrl,
          liveAuthUser: liveUser,
        );
      }),
    );
    return result;
  }

  Future<void> setMessId(
    String uid,
    String messId, {
    String? messName,
  }) async {
    await _users.doc(uid).set({
      'messId': messId,
      'messName': ?messName,
    }, SetOptions(merge: true));
  }

  Future<void> clearMessId(String uid) async {
    await _users.doc(uid).set({
      'messId': null,
      'messName': null,
    }, SetOptions(merge: true));
  }

  /// Clears mess link only if the user still points at [messId].
  Future<void> clearMessIdIfMess(String uid, String messId) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return;
    final current = snap.data()!['messId'];
    if (current is String && current == messId) {
      await clearMessId(uid);
    }
  }

  Future<void> updateName(String uid, String name) async {
    await _users.doc(uid).set({'name': name.trim()}, SetOptions(merge: true));
  }

  Future<void> updateBio(String uid, String bio) async {
    await _users.doc(uid).set({'bio': bio.trim()}, SetOptions(merge: true));
  }

  Future<void> updatePublicProfile({
    required String uid,
    String? name,
    String? bio,
    String? photoUrl,
  }) async {
    await _users.doc(uid).set({
      if (name != null) 'name': name.trim(),
      if (bio != null) 'bio': bio.trim(),
      'photoUrl': ?photoUrl,
    }, SetOptions(merge: true));
  }
}
