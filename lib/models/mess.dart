class Mess {
  const Mess({
    required this.id,
    required this.name,
    required this.location,
    required this.code,
    this.createdBy,
  });

  final String id;
  final String name;
  final String location;
  final String code;
  final String? createdBy;

  factory Mess.fromMap(String id, Map<String, dynamic> data) {
    return Mess(
      id: id,
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      code: data['code'] as String? ?? '',
      createdBy: data['createdBy'] as String?,
    );
  }
}

class MessMember {
  const MessMember({
    required this.uid,
    required this.name,
    required this.role,
    this.room,
  });

  final String uid;
  final String name;
  final String role;
  final String? room;

  bool get isAdmin => role == 'admin';

  factory MessMember.fromMap(String uid, Map<String, dynamic> data) {
    return MessMember(
      uid: uid,
      name: data['name'] as String? ?? 'সদস্য',
      role: data['role'] as String? ?? 'member',
      room: data['room'] as String?,
    );
  }
}
