import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.messId,
    required this.messName,
    this.messLocation,
    this.messCode,
    required this.seatsAvailable,
    this.rentHint,
    required this.body,
    this.likeCount = 0,
    this.commentCount = 0,
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String messId;
  final String messName;
  final String? messLocation;
  final String? messCode;
  final int seatsAvailable;
  final String? rentHint;
  final String body;
  final int likeCount;
  final int commentCount;
  final bool active;
  final DateTime? createdAt;

  factory CommunityPost.fromMap(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) createdAt = raw.toDate();

    return CommunityPost(
      id: id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      messId: data['messId'] as String? ?? '',
      messName: data['messName'] as String? ?? '',
      messLocation: data['messLocation'] as String?,
      messCode: data['messCode'] as String?,
      seatsAvailable: (data['seatsAvailable'] as num?)?.toInt() ?? 0,
      rentHint: data['rentHint'] as String?,
      body: data['body'] as String? ?? '',
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      active: data['active'] as bool? ?? true,
      createdAt: createdAt,
    );
  }
}

class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime? createdAt;

  factory PostComment.fromMap(String id, Map<String, dynamic> data) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) createdAt = raw.toDate();

    return PostComment(
      id: id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}
