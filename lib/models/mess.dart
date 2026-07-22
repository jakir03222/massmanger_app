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

/// Roles: `super_admin` (mess creator) → `admin` → `member`.
class MessMember {
  const MessMember({
    required this.uid,
    required this.name,
    required this.role,
    this.room,
    this.authProvider,
  });

  final String uid;
  final String name;

  /// `super_admin` | `admin` | `member`
  final String role;
  final String? room;

  /// `google` | `email` — Firebase Auth sign-in method.
  final String? authProvider;

  bool get isSuperAdmin => role == 'super_admin';

  /// Regular admin only (not super admin).
  bool get isRegularAdmin => role == 'admin';

  /// Has admin powers (super admin or admin) — bills, meals, bazaar, etc.
  bool get isAdmin => isSuperAdmin || isRegularAdmin;

  bool get isMemberOnly => !isAdmin;

  String get roleBnLabel {
    if (isSuperAdmin) return 'সুপার অ্যাডমিন';
    if (isRegularAdmin) return 'অ্যাডমিন';
    return 'মেম্বার';
  }

  /// Who [actor] can manage in settings.
  bool canBeManagedBy(MessMember actor) {
    if (uid == actor.uid) return false;
    if (isSuperAdmin) return false;
    if (actor.isSuperAdmin) return true;
    if (actor.isRegularAdmin) return isMemberOnly;
    return false;
  }

  /// Only super admin can promote/demote admin roles.
  bool canChangeRoleOf(MessMember target) {
    if (!isSuperAdmin) return false;
    if (target.isSuperAdmin) return false;
    if (target.uid == uid) return false;
    return true;
  }

  factory MessMember.fromMap(
    String uid,
    Map<String, dynamic> data, {
    String? messCreatedBy,
  }) {
    var role = data['role'] as String? ?? 'member';
    // Legacy: mess creator stored as `admin` → treat as super_admin.
    if (role == 'admin' &&
        messCreatedBy != null &&
        messCreatedBy.isNotEmpty &&
        messCreatedBy == uid) {
      role = 'super_admin';
    }
    if (role != 'super_admin' && role != 'admin' && role != 'member') {
      role = 'member';
    }
    final rawProvider = data['authProvider'] as String?;
    final authProvider = (rawProvider == 'google' || rawProvider == 'email')
        ? rawProvider
        : null;
    return MessMember(
      uid: uid,
      name: data['name'] as String? ?? 'সদস্য',
      role: role,
      room: data['room'] as String?,
      authProvider: authProvider,
    );
  }
}
