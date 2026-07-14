import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    this.fromName,
    this.fromPhotoUrl,
    this.toName,
    this.toPhotoUrl,
    this.createdAt,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final String status; // pending | accepted | rejected
  final String? fromName;
  final String? fromPhotoUrl;
  final String? toName;
  final String? toPhotoUrl;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  factory FriendRequest.fromMap(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) createdAt = raw.toDate();

    return FriendRequest(
      id: id,
      fromUid: data['fromUid'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      fromName: data['fromName'] as String?,
      fromPhotoUrl: data['fromPhotoUrl'] as String?,
      toName: data['toName'] as String?,
      toPhotoUrl: data['toPhotoUrl'] as String?,
      createdAt: createdAt,
    );
  }
}

class Friendship {
  const Friendship({
    required this.id,
    required this.uids,
    this.createdAt,
  });

  final String id;
  final List<String> uids;
  final DateTime? createdAt;

  String otherUid(String me) => uids.firstWhere((u) => u != me, orElse: () => '');

  factory Friendship.fromMap(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) createdAt = raw.toDate();
    final uids = (data['uids'] as List?)?.map((e) => '$e').toList() ?? <String>[];

    return Friendship(id: id, uids: uids, createdAt: createdAt);
  }

  static String docIdFor(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.memberIds,
    this.lastMessage,
    this.updatedAt,
  });

  final String id;
  final List<String> memberIds;
  final String? lastMessage;
  final DateTime? updatedAt;

  String otherUid(String me) =>
      memberIds.firstWhere((u) => u != me, orElse: () => '');

  factory Conversation.fromMap(String id, Map<String, dynamic> data) {
    DateTime? updatedAt;
    final raw = data['updatedAt'];
    if (raw is Timestamp) updatedAt = raw.toDate();
    final members =
        (data['memberIds'] as List?)?.map((e) => '$e').toList() ?? <String>[];

    return Conversation(
      id: id,
      memberIds: members,
      lastMessage: data['lastMessage'] as String?,
      updatedAt: updatedAt,
    );
  }

  static String docIdFor(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) createdAt = raw.toDate();

    return ChatMessage(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}
