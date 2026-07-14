import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final friendSnap =
        await _firestore.collection('friendships').doc(friendshipId).get();
    if (!friendSnap.exists) {
      throw ChatException('শুধু ফ্রেন্ডদের সাথে মেসেজ করতে পারবেন।');
    }

    final convId = Conversation.docIdFor(user.uid, otherUid);
    final ref = _conversations.doc(convId);
    final snap = await ref.get();
    if (!snap.exists) {
      final members = [user.uid, otherUid]..sort();
      try {
        await ref.set({
          'memberIds': members,
          'lastMessage': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (e) {
        // Another client may have created it concurrently.
        if (e.code != 'permission-denied' && e.code != 'already-exists') {
          rethrow;
        }
        final again = await ref.get();
        if (!again.exists) {
          throw ChatException('চ্যাট খোলা যায়নি। আবার চেষ্টা করুন।');
        }
      }
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

    final convRef = _conversations.doc(conversationId);
    final msgRef = convRef.collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(msgRef, {
      'senderId': user.uid,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(convRef, {
      'lastMessage': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
