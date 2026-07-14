import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/community_post.dart';
import 'user_service.dart';

class CommunityException implements Exception {
  CommunityException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CommunityPostService {
  CommunityPostService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    UserService? userService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserService _userService;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('community_posts');

  Stream<List<CommunityPost>> watchFeed({bool activeOnly = true}) {
    Query<Map<String, dynamic>> q =
        _posts.orderBy('createdAt', descending: true).limit(80);
    if (activeOnly) {
      q = _posts
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(80);
    }
    return q.snapshots().map(
          (snap) => snap.docs
              .map((d) => CommunityPost.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<CommunityPost?> watchPost(String postId) {
    return _posts.doc(postId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CommunityPost.fromMap(snap.id, snap.data()!);
    });
  }

  Future<String> createVacancyPost({
    required int seatsAvailable,
    required String body,
    String? rentHint,
    bool includeMessCode = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw CommunityException('আগে লগইন করুন।');

    final profile = await _userService.getUser(user.uid);
    if (profile == null || !profile.hasMess) {
      throw CommunityException('মেস জয়েন করার পর পোস্ট করতে পারবেন।');
    }

    final messSnap =
        await _firestore.collection('messes').doc(profile.messId).get();
    if (!messSnap.exists || messSnap.data() == null) {
      throw CommunityException('মেস পাওয়া যায়নি।');
    }
    final mess = messSnap.data()!;
    final messName = mess['name'] as String? ?? profile.messName ?? 'মেস';
    final messLocation = mess['location'] as String?;
    final messCode = mess['code'] as String?;

    if (seatsAvailable < 1) {
      throw CommunityException('কমপক্ষে ১টি সিট উল্লেখ করুন।');
    }
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw CommunityException('পোস্টের বিবরণ লিখুন।');
    }

    final doc = _posts.doc();
    await doc.set({
      'authorId': user.uid,
      'authorName': profile.name?.trim().isNotEmpty == true
          ? profile.name!.trim()
          : (user.displayName ?? 'সদস্য'),
      'authorPhotoUrl': profile.photoUrl ?? user.photoURL,
      'messId': profile.messId,
      'messName': messName,
      'messLocation': messLocation,
      'messCode': includeMessCode ? messCode : null,
      'seatsAvailable': seatsAvailable,
      'rentHint': rentHint?.trim().isEmpty == true ? null : rentHint?.trim(),
      'body': trimmed,
      'likeCount': 0,
      'commentCount': 0,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Keep denormalized mess name on user
    await _userService.setMessId(
      user.uid,
      profile.messId!,
      messName: messName,
    );

    return doc.id;
  }

  Future<void> closePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw CommunityException('আগে লগইন করুন।');
    final ref = _posts.doc(postId);
    final snap = await ref.get();
    if (!snap.exists) throw CommunityException('পোস্ট পাওয়া যায়নি।');
    if (snap.data()?['authorId'] != user.uid) {
      throw CommunityException('শুধু নিজের পোস্ট বন্ধ করতে পারবেন।');
    }
    await ref.update({'active': false});
  }

  Stream<bool> watchLiked(String postId, String uid) {
    return _posts
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((s) => s.exists);
  }

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw CommunityException('আগে লগইন করুন।');

    final likeRef = _posts.doc(postId).collection('likes').doc(user.uid);
    final postRef = _posts.doc(postId);

    await _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) {
        throw CommunityException('পোস্ট পাওয়া যায়নি।');
      }
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  Stream<List<PostComment>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PostComment.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> addComment(String postId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw CommunityException('আগে লগইন করুন।');
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw CommunityException('কমেন্ট লিখুন।');

    final profile = await _userService.getUser(user.uid);
    final batch = _firestore.batch();
    final commentRef = _posts.doc(postId).collection('comments').doc();
    batch.set(commentRef, {
      'authorId': user.uid,
      'authorName': profile?.name?.trim().isNotEmpty == true
          ? profile!.name!.trim()
          : (user.displayName ?? 'সদস্য'),
      'authorPhotoUrl': profile?.photoUrl ?? user.photoURL,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_posts.doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
  }
}
