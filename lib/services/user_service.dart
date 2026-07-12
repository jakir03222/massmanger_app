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
      createdAt: DateTime.now(),
    );

    await ref.set({
      'email': appUser.email,
      'name': appUser.name,
      'photoUrl': appUser.photoUrl,
      'messId': null,
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

  Future<void> setMessId(String uid, String messId) async {
    await _users.doc(uid).set({'messId': messId}, SetOptions(merge: true));
  }
}
