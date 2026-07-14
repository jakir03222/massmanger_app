import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<AppUser> ensureUserDoc(User user, {String? name}) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();

    if (snap.exists) {
      return AppUser.fromMap(user.uid, snap.data()!);
    }

    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      name: name ?? user.displayName,
      photoUrl: user.photoURL,
      messId: null,
      messName: null,
      bio: null,
      createdAt: DateTime.now(),
    );

    await ref.set({
      'email': appUser.email,
      'name': appUser.name,
      'photoUrl': appUser.photoUrl,
      'bio': null,
      'messId': null,
      'messName': null,
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

  Future<void> setMessId(
    String uid,
    String messId, {
    String? messName,
  }) async {
    await _users.doc(uid).set({
      'messId': messId,
      if (messName != null) 'messName': messName,
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
      if (photoUrl != null) 'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }
}
