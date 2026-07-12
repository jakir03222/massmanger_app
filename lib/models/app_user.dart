import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.photoUrl,
    this.messId,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? messId;
  final DateTime? createdAt;

  bool get hasMess {
    final id = messId?.trim();
    return id != null && id.isNotEmpty;
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    }

    final rawMessId = data['messId'];
    final messId = rawMessId is String ? rawMessId.trim() : null;

    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String?,
      photoUrl: data['photoUrl'] as String?,
      messId: (messId == null || messId.isEmpty) ? null : messId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'messId': messId,
      'createdAt': createdAt,
    };
  }

  AppUser copyWith({
    String? name,
    String? photoUrl,
    String? messId,
    bool clearMessId = false,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      messId: clearMessId ? null : (messId ?? this.messId),
      createdAt: createdAt,
    );
  }
}
