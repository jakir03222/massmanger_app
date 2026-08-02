import '../models/mess.dart';

/// Member list helpers — replaces repeated `where((m) => m.uid == …).first`.
extension MessMemberListX on List<MessMember> {
  MessMember? byUid(String uid) {
    for (final m in this) {
      if (m.uid == uid) return m;
    }
    return null;
  }

  bool isAdminUid(String uid) => byUid(uid)?.isAdmin ?? false;

  List<MessMember> visibleFor({
    required String uid,
    required bool isAdmin,
  }) =>
      isAdmin ? this : where((m) => m.uid == uid).toList();
}
