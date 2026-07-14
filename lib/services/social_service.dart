import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/social.dart';
import 'user_service.dart';

class SocialException implements Exception {
  SocialException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SocialService {
  SocialService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    UserService? userService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserService _userService;

  String _followId(String follower, String following) =>
      '${follower}_$following';

  Stream<bool> watchIsFollowing(String followerId, String followingId) {
    return _firestore
        .collection('follows')
        .doc(_followId(followerId, followingId))
        .snapshots()
        .map((s) => s.exists);
  }

  Future<void> follow(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) throw SocialException('আগে লগইন করুন।');
    if (user.uid == targetUid) {
      throw SocialException('নিজেকে ফলো করা যায় না।');
    }
    await _firestore.collection('follows').doc(_followId(user.uid, targetUid)).set({
      'followerId': user.uid,
      'followingId': targetUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollow(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) throw SocialException('আগে লগইন করুন।');
    await _firestore
        .collection('follows')
        .doc(_followId(user.uid, targetUid))
        .delete();
  }

  Stream<bool> watchAreFriends(String a, String b) {
    return _firestore
        .collection('friendships')
        .doc(Friendship.docIdFor(a, b))
        .snapshots()
        .map((s) => s.exists);
  }

  Stream<FriendRequest?> watchPendingRequestBetween(String a, String b) {
    // Listen to both direction docs (not a collection query — safer with rules).
    final idAb = '${a}_$b';
    final idBa = '${b}_$a';
    final refAb = _firestore.collection('friend_requests').doc(idAb);
    final refBa = _firestore.collection('friend_requests').doc(idBa);

    return refAb.snapshots().asyncExpand((snapAb) {
      return refBa.snapshots().map((snapBa) {
        for (final snap in [snapAb, snapBa]) {
          if (!snap.exists || snap.data() == null) continue;
          final req = FriendRequest.fromMap(snap.id, snap.data()!);
          if (req.isPending) return req;
        }
        return null;
      });
    });
  }

  Future<void> sendFriendRequest(String toUid) async {
    final user = _auth.currentUser;
    if (user == null) throw SocialException('আগে লগইন করুন।');
    if (user.uid == toUid) {
      throw SocialException('নিজেকে ফ্রেন্ড রিকোয়েস্ট পাঠানো যায় না।');
    }

    final friendshipId = Friendship.docIdFor(user.uid, toUid);
    final existingFriend =
        await _firestore.collection('friendships').doc(friendshipId).get();
    if (existingFriend.exists) {
      throw SocialException('ইতিমধ্যে ফ্রেন্ড।');
    }

    final me = await _userService.getUser(user.uid);
    final them = await _userService.getUser(toUid);

    final requestId = '${user.uid}_$toUid';
    final reverseId = '${toUid}_${user.uid}';
    final reverse =
        await _firestore.collection('friend_requests').doc(reverseId).get();
    if (reverse.exists && reverse.data()?['status'] == 'pending') {
      // Auto-accept if they already requested us
      await acceptFriendRequest(reverseId);
      return;
    }

    await _firestore.collection('friend_requests').doc(requestId).set({
      'fromUid': user.uid,
      'toUid': toUid,
      'status': 'pending',
      'fromName': me?.name,
      'fromPhotoUrl': me?.photoUrl,
      'toName': them?.name,
      'toPhotoUrl': them?.photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw SocialException('আগে লগইন করুন।');

    final reqRef = _firestore.collection('friend_requests').doc(requestId);
    final snap = await reqRef.get();
    if (!snap.exists || snap.data() == null) {
      throw SocialException('রিকোয়েস্ট পাওয়া যায়নি।');
    }
    final data = snap.data()!;
    if (data['toUid'] != user.uid) {
      throw SocialException('এই রিকোয়েস্ট গ্রহণ করতে পারবেন না।');
    }
    if (data['status'] != 'pending') {
      throw SocialException('রিকোয়েস্ট আর পেন্ডিং নয়।');
    }

    final fromUid = data['fromUid'] as String;
    final friendshipId = Friendship.docIdFor(fromUid, user.uid);

    final batch = _firestore.batch();
    batch.update(reqRef, {'status': 'accepted'});
    batch.set(_firestore.collection('friendships').doc(friendshipId), {
      'uids': [fromUid, user.uid]..sort(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw SocialException('আগে লগইন করুন।');

    final reqRef = _firestore.collection('friend_requests').doc(requestId);
    final snap = await reqRef.get();
    if (!snap.exists || snap.data() == null) {
      throw SocialException('রিকোয়েস্ট পাওয়া যায়নি।');
    }
    if (snap.data()?['toUid'] != user.uid) {
      throw SocialException('এই রিকোয়েস্ট বাতিল করতে পারবেন না।');
    }
    await reqRef.update({'status': 'rejected'});
  }

  Stream<List<FriendRequest>> watchIncomingRequests(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => FriendRequest.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<Friendship>> watchFriendships(String uid) {
    return _firestore
        .collection('friendships')
        .where('uids', arrayContains: uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Friendship.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<List<AppUser>> loadFriends(String uid) async {
    final snap = await _firestore
        .collection('friendships')
        .where('uids', arrayContains: uid)
        .get();
    final friends = <AppUser>[];
    for (final d in snap.docs) {
      final f = Friendship.fromMap(d.id, d.data());
      final other = f.otherUid(uid);
      if (other.isEmpty) continue;
      final user = await _userService.getUser(other);
      if (user != null) friends.add(user);
    }
    friends.sort(
      (a, b) => (a.name ?? a.email).compareTo(b.name ?? b.email),
    );
    return friends;
  }
}
