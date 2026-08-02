import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/social.dart';

class ChatException implements Exception {
  ChatException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  Future<String> getOrCreateConversation(String otherUid) async {
    final user = _auth.currentUser;
    if (user == null) throw ChatException('আগে লগইন করুন।');
    if (user.uid == otherUid) {
      throw ChatException('নিজের সাথে চ্যাট করা যায় না।');
    }

    final friendshipId = Friendship.docIdFor(user.uid, otherUid);
    debugPrint('[Chat] getOrCreate me=${user.uid} other=$otherUid');
    final friendSnap =
        await _firestore.collection('friendships').doc(friendshipId).get();
    if (!friendSnap.exists) {
      throw ChatException('শুধু ফ্রেন্ডদের সাথে মেসেজ করতে পারবেন।');
    }

    final convId = Conversation.docIdFor(user.uid, otherUid);
    final ref = _conversations.doc(convId);
    final members = [user.uid, otherUid]..sort();

    try {
      final snap = await ref.get();
      if (snap.exists) {
        debugPrint('[Chat] conversation exists id=$convId');
        return convId;
      }

      debugPrint('[Chat] creating conversation id=$convId members=$members');
      await ref.set({
        'memberIds': members,
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[Chat] conversation created id=$convId');
    } on FirebaseException catch (e) {
      debugPrint('[Chat] getOrCreate FirebaseException ${e.code} ${e.message}');
      // Race: another client created it, or rules denied once then succeeded.
      final again = await ref.get();
      if (again.exists) return convId;
      if (e.code == 'permission-denied') {
        throw ChatException(
          'চ্যাট খোলার অনুমতি নেই। ফ্রেন্ডশিপ চেক করুন বা Firestore rules ডিপ্লয় করুন।',
        );
      }
      throw ChatException('চ্যাট খোলা যায়নি। আবার চেষ্টা করুন।');
    }

    return convId;
  }

  Stream<List<Conversation>> watchInbox(String uid) {
    return _conversations
        .where('memberIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Conversation.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatMessage.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw ChatException('আগে লগইন করুন।');
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ChatException('মেসেজ লিখুন।');
    if (trimmed.length > 4000) {
      throw ChatException('মেসেজ অনেক বড়। ছোট করে লিখুন।');
    }

    debugPrint(
      '[Chat] sendMessage conv=$conversationId '
      'len=${trimmed.length} from=${user.uid}',
    );

    final convRef = _conversations.doc(conversationId);
    final msgRef = convRef.collection('messages').doc();

    try {
      final convSnap = await convRef.get();
      if (!convSnap.exists) {
        // Recover: rebuild members from sorted conversation id.
        final other = conversationId
            .split('_')
            .where((p) => p != user.uid)
            .join('_');
        if (other.isEmpty || other == user.uid) {
          throw ChatException('চ্যাট এখনো তৈরি হয়নি। আবার খুলে চেষ্টা করুন।');
        }
        await getOrCreateConversation(other);
      }

      final batch = _firestore.batch();
      batch.set(msgRef, {
        'senderId': user.uid,
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        convRef,
        {
          'lastMessage': trimmed,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      debugPrint('[Chat] sendMessage OK id=${msgRef.id}');
    } on ChatException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('[Chat] sendMessage FAIL ${e.code} ${e.message}');
      if (e.code == 'permission-denied') {
        throw ChatException(
          'মেসেজ পাঠানোর অনুমতি নেই। ফ্রেন্ড কিনা চেক করুন।',
        );
      }
      throw ChatException('মেসেজ পাঠানো যায়নি। আবার চেষ্টা করুন।');
    }
  }
}
