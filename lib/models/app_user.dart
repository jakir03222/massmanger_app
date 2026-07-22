import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.photoUrl,
    this.bio,
    this.messId,
    this.messName,
    this.authProvider,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? bio;
  final String? messId;
  final String? messName;

  /// `google` | `email` — how the account was created / signs in.
  final String? authProvider;
  final DateTime? createdAt;

  bool get hasMess {
    final id = messId?.trim();
    return id != null && id.isNotEmpty;
  }

  bool get isGoogleAuth => authProvider == 'google';

  bool get isEmailAuth => authProvider == 'email';

  String get authProviderBnLabel {
    if (isGoogleAuth) return 'Google';
    if (isEmailAuth) return 'ইমেইল';
    return '—';
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    }

    final rawMessId = data['messId'];
    final messId = rawMessId is String ? rawMessId.trim() : null;
    final rawProvider = data['authProvider'] as String?;
    final authProvider = (rawProvider == 'google' || rawProvider == 'email')
        ? rawProvider
        : null;

    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String?,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      messId: (messId == null || messId.isEmpty) ? null : messId,
      messName: data['messName'] as String?,
      authProvider: authProvider,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'bio': bio,
      'messId': messId,
      'messName': messName,
      'authProvider': authProvider,
      'createdAt': createdAt,
    };
  }

  AppUser copyWith({
    String? name,
    String? photoUrl,
    String? bio,
    String? messId,
    String? messName,
    String? authProvider,
    bool clearMessId = false,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      messId: clearMessId ? null : (messId ?? this.messId),
      messName: clearMessId ? null : (messName ?? this.messName),
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt,
    );
  }
}
