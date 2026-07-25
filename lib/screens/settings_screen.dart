import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/social_links.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/mess.dart';
import '../services/auth_service.dart';
import '../services/mess_service.dart';
import '../services/month_lock_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_palette.dart';
import '../theme/theme_controller.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart' show yearMonthKey;
import '../widgets/month_navigator.dart';
import 'mess_bills_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _tabIndex = 0;
  final _userService = UserService();
  final _messService = MessService();

  static final _avatarColors = [
    AppColors.primaryGreen,
    Color(0xFFFFE0B2),
    Color(0xFFF8BBD0),
    Color(0xFFC8E6C9),
    Color(0xFFFFCC80),
    Color(0xFFBBDEFB),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      final s = AppStrings.of(context);
      return Center(
        child: Text(s.noLogin, style: appFont(context: context)),
      );
    }

    return StreamBuilder(
      stream: _userService.watchUser(uid),
      builder: (context, userSnap) {
        final messId = userSnap.data?.messId;
        if (messId == null || messId.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        return StreamBuilder<Mess?>(
          stream: _messService.watchMess(messId),
          builder: (context, messSnap) {
            final mess = messSnap.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MessAppHeader(title: mess?.name, subtitle: mess?.location),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        _MessInfoCard(mess: mess),
                        const SizedBox(height: 20),
                        _SettingsTabBar(
                          index: _tabIndex,
                          onChanged: (i) => setState(() => _tabIndex = i),
                        ),
                        const SizedBox(height: 16),
                        if (_tabIndex == 0)
                          _MembersTab(
                            messId: messId,
                            messCode: mess?.code ?? '',
                            messService: _messService,
                            avatarColors: _avatarColors,
                          )
                        else
                          _SettingsTabContent(messId: messId),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _LogoutTile(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MessInfoCard extends StatelessWidget {
  const _MessInfoCard({required this.mess});

  final Mess? mess;

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    final s = AppStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.messCodeCopied,
          style: appFont(context: context),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareCode(BuildContext context, String code, String name) async {
    final s = AppStrings.of(context);
    await SharePlus.instance.share(
      ShareParams(text: s.shareMessInvite(name, code)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final name = mess?.name ?? s.loadingEllipsis;
    final location = mess?.location ?? '';
    final code = mess?.code ?? '------';
    final canUseCode = code != '------' && code.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: AppColors.darkGreen),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: appFont(
                              context: context,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.3,
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: AppColors.textGrey,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    location,
                                    style: appFont(
                                      context: context,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textGrey,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                      decoration: BoxDecoration(
                        color: AppColors.featureGreenBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.messCode,
                            style: appFont(
                              context: context,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                code,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreen,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (canUseCode) ...[
                                IconButton(
                                  tooltip: s.copy,
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  onPressed: () => _copyCode(context, code),
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                IconButton(
                                  tooltip: s.share,
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  onPressed: () =>
                                      _shareCode(context, code, name),
                                  icon: Icon(
                                    Icons.share_rounded,
                                    size: 18,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTabBar extends StatelessWidget {
  const _SettingsTabBar({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      children: [
        Row(
          children: [
            _TabItem(
              label: s.members,
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
            _TabItem(
              label: s.settings,
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
        Divider(height: 1, color: AppColors.borderGrey),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                style: appFont(
                  context: context,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.darkGreen : AppColors.textGrey,
                ),
              ),
            ),
            Container(
              height: 3,
              color: selected ? AppColors.primaryGreen : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.messId,
    required this.messCode,
    required this.messService,
    required this.avatarColors,
  });

  final String messId;
  final String messCode;
  final MessService messService;
  final List<Color> avatarColors;

  void _shareCode(BuildContext context) {
    if (messCode.isEmpty) return;
    final s = AppStrings.of(context);
    final text = s.shareMessInviteCode(messCode);
    SharePlus.instance.share(ShareParams(text: text));
    Clipboard.setData(ClipboardData(text: messCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.messCodeSharedCopied,
          style: appFont(context: context),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddMemberDialog(
        messId: messId,
        messService: messService,
      ),
    );
    if (result == true && context.mounted) {
      _toast(context, AppStrings.of(context).memberAdded);
    }
  }

  Future<void> _manageMember(
    BuildContext context,
    MessMember actor,
    MessMember member,
  ) async {
    if (!member.canBeManagedBy(actor) && member.uid != actor.uid) {
      _toast(context, AppStrings.of(context).noPermissionManageMember);
      return;
    }

    final canEditRoom =
        member.uid == actor.uid || member.canBeManagedBy(actor);
    final canChangeRole = actor.canChangeRoleOf(member);
    final canRemove = member.canBeManagedBy(actor);
    final canTransfer =
        actor.isSuperAdmin && member.uid != actor.uid && !member.isSuperAdmin;

    if (!canEditRoom && !canChangeRole && !canRemove && !canTransfer) {
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final s = AppStrings.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                member.name,
                style: appFont(
                  context: context,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                member.roleLabel(bn: s.isBengali),
                style: appFont(
                  context: context,
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              if (canEditRoom)
                ListTile(
                  leading: Icon(Icons.meeting_room_outlined,
                      color: AppColors.primaryGreen),
                  title: Text(s.editRoomNumber,
                      style: appFont(context: context)),
                  onTap: () => Navigator.pop(context, 'room'),
                ),
              if (canChangeRole)
                ListTile(
                  leading: Icon(
                    member.isRegularAdmin
                        ? Icons.person_outline
                        : Icons.admin_panel_settings_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  title: Text(
                    member.isRegularAdmin ? s.removeAsAdmin : s.makeAdmin,
                    style: appFont(context: context),
                  ),
                  subtitle: Text(
                    s.onlySuperAdminCan,
                    style: appFont(
                      context: context,
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'role'),
                ),
              if (canTransfer)
                ListTile(
                  leading: Icon(Icons.swap_horiz_rounded,
                      color: AppColors.darkGreen),
                  title: Text(
                    s.transferSuperAdmin,
                    style: appFont(context: context),
                  ),
                  subtitle: Text(
                    s.transferOwnershipHint,
                    style: appFont(
                      context: context,
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'transfer'),
                ),
              if (canRemove)
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined,
                      color: Color(0xFFC62828)),
                  title: Text(
                    s.removeFromMess,
                    style: appFont(
                      context: context,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == null || !context.mounted) return;
    try {
      switch (action) {
        case 'room':
          await _editRoom(context, member);
        case 'role':
          await _confirmRole(context, member);
        case 'transfer':
          await _confirmTransfer(context, member);
        case 'remove':
          await _confirmRemove(context, member);
      }
    } on MessException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _confirmRole(BuildContext context, MessMember member) async {
    final makeAdmin = !member.isRegularAdmin;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s = AppStrings.of(context);
        return AlertDialog(
          title: Text(
            makeAdmin ? s.makeAdminConfirmTitle : s.removeAdminConfirmTitle,
            style: appFont(context: context, fontWeight: FontWeight.w700),
          ),
          content: Text(
            makeAdmin
                ? s.makeAdminConfirmBody(member.name)
                : s.demoteToMemberBody(member.name),
            style: appFont(context: context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel, style: appFont(context: context)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                makeAdmin ? s.makeAdmin : s.removeRoleAction,
                style: appFont(
                  context: context,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    await messService.setMemberRole(
      messId: messId,
      uid: member.uid,
      makeAdmin: makeAdmin,
    );
    if (context.mounted) {
      final s = AppStrings.of(context);
      _toast(
        context,
        makeAdmin ? s.adminMadeSuccess : s.adminRemovedSuccess,
      );
    }
  }

  Future<void> _confirmTransfer(
    BuildContext context,
    MessMember member,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s = AppStrings.of(context);
        return AlertDialog(
          title: Text(
            s.transferSuperAdminTitle,
            style: appFont(context: context, fontWeight: FontWeight.w700),
          ),
          content: Text(
            s.transferSuperAdminBody(member.name),
            style: appFont(context: context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel, style: appFont(context: context)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                s.transferAction,
                style: appFont(
                  context: context,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC62828),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    await messService.transferSuperAdmin(
      messId: messId,
      newSuperAdminUid: member.uid,
    );
    if (context.mounted) {
      _toast(context, AppStrings.of(context).transferSuccess);
    }
  }

  Future<void> _editRoom(BuildContext context, MessMember member) async {
    final controller = TextEditingController(text: member.room ?? '');
    final room = await showDialog<String>(
      context: context,
      builder: (context) {
        final s = AppStrings.of(context);
        return AlertDialog(
          title: Text(s.roomNumber,
              style: appFont(context: context, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: appFont(context: context),
            decoration: InputDecoration(
              hintText: s.roomHint,
              hintStyle: appFont(context: context),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel, style: appFont(context: context)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(s.save,
                  style: appFont(
                    context: context,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  )),
            ),
          ],
        );
      },
    );
    if (room == null || !context.mounted) return;
    await messService.updateMemberRoom(
      messId: messId,
      uid: member.uid,
      room: room,
    );
    if (context.mounted) {
      _toast(context, AppStrings.of(context).roomUpdated);
    }
  }

  Future<void> _confirmRemove(BuildContext context, MessMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s = AppStrings.of(context);
        return AlertDialog(
          title: Text(s.removeMemberTitle,
              style: appFont(context: context, fontWeight: FontWeight.w700)),
          content: Text(
            s.removeMemberBody(member.name),
            style: appFont(context: context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.no, style: appFont(context: context)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.removeAction,
                  style: appFont(
                    context: context,
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    await messService.removeMember(messId: messId, uid: member.uid);
    if (context.mounted) {
      _toast(context, AppStrings.of(context).memberRemoved);
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: appFont(context: context))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<List<MessMember>>(
      stream: messService.watchMembers(messId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        final members = snap.data ?? [];
        final meList = members.where((m) => m.uid == myUid);
        final me = meList.isNotEmpty ? meList.first : null;
        final uidsKey = members.map((m) => m.uid).join(',');
        final memberProviders = {
          for (final m in members) m.uid: m.authProvider,
        };

        return FutureBuilder<Map<String, String>>(
          key: ValueKey('auth-$uidsKey'),
          future: UserService().getLoginStatusesForUids(
            uids: members.map((m) => m.uid),
            memberProviders: memberProviders,
          ),
          builder: (context, authSnap) {
            final providers = authSnap.data ??
                {
                  for (final m in members)
                    m.uid: UserService.resolveLoginStatus(
                      authProvider: m.authProvider,
                    ),
                };

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.featureGreenBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.group_outlined,
                              size: 32,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppStrings.of(context).noMembersYet,
                            style: appFont(
                              context: context,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.of(context).noMembersHint,
                            textAlign: TextAlign.center,
                            style: appFont(
                              context: context,
                              fontSize: 13,
                              color: AppColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...members.asMap().entries.map((entry) {
                      final i = entry.key;
                      final m = entry.value;
                      final color = avatarColors[i % avatarColors.length];
                      final letter = m.name.isNotEmpty
                          ? String.fromCharCode(m.name.runes.first)
                          : '?';
                      final textColor = color == AppColors.primaryGreen
                          ? Colors.white
                          : AppColors.textDark;
                      final actor = me;
                      final manageable = actor != null &&
                          (m.canBeManagedBy(actor) ||
                              (m.uid == actor.uid && actor.isAdmin));
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MemberCard(
                          letter: letter,
                          name: m.name +
                              (m.uid == myUid
                                  ? ' (${AppStrings.of(context).you})'
                                  : ''),
                          room: m.room?.isNotEmpty == true
                              ? m.room!
                              : AppStrings.of(context).roomEmpty,
                          authProvider: providers[m.uid] ??
                              UserService.resolveLoginStatus(
                                authProvider: m.authProvider,
                              ),
                          color: color,
                          textColor: textColor,
                          member: m,
                          canManage: manageable,
                          onTap: manageable
                              ? () => _manageMember(context, actor, m)
                              : null,
                        ),
                      );
                    }),
                  const SizedBox(height: 6),
                  if (me != null && me.isSuperAdmin) ...[
                    _AddMemberButton(
                      onTap: () => _showAddMemberDialog(context),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _InviteMemberButton(onTap: () => _shareCode(context)),
                  if (me != null && me.isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoBoxBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                me.isSuperAdmin
                                    ? AppStrings.of(context).superAdminManageHint
                                    : AppStrings.of(context).adminManageHint,
                                style: appFont(
                                  context: context,
                                  fontSize: 12,
                                  height: 1.45,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.letter,
    required this.name,
    required this.room,
    required this.color,
    required this.textColor,
    required this.member,
    required this.authProvider,
    this.canManage = false,
    this.onTap,
  });

  final String letter;
  final String name;
  final String room;
  final Color color;
  final Color textColor;
  final MessMember member;
  final String authProvider;
  final bool canManage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badgeColor = member.isSuperAdmin
        ? const Color(0xFF6A1B9A)
        : AppColors.primaryGreen;
    final isGoogle = authProvider == 'google';
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: Text(
                  letter,
                  style: appFont(
                    context: context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: appFont(
                              context: context,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (member.isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              member.roleLabel(bn: AppStrings.of(context).isBengali),
                              style: appFont(
                                context: context,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.card,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room,
                      style: appFont(
                        context: context,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isGoogle
                            ? const Color(0xFFE8F0FE)
                            : AppColors.featureGreenBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGoogle
                                ? Icons.g_mobiledata_rounded
                                : Icons.mail_outline_rounded,
                            size: isGoogle ? 16 : 13,
                            color: isGoogle
                                ? const Color(0xFF4285F4)
                                : AppColors.primaryGreen,
                          ),
                          SizedBox(width: isGoogle ? 0 : 4),
                          Text(
                            isGoogle
                                ? AppStrings.of(context).googleLogin
                                : AppStrings.of(context).emailLoginTitle,
                            style: appFont(
                              context: context,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isGoogle
                                  ? const Color(0xFF4285F4)
                                  : AppColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFFB0B5B0),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMemberButton extends StatelessWidget {
  const _AddMemberButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryGreen,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.of(context).addMember,
                style: appFont(
                  context: context,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.card,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({
    required this.messId,
    required this.messService,
  });

  final String messId;
  final MessService messService;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.messService.createMemberWithEmail(
        messId: widget.messId,
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on MessException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: appFont(context: context)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      title: Text(
        s.addNewMemberTitle,
        style: appFont(context: context, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.addMemberHint,
                style: appFont(
                  context: context,
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.name,
                  labelStyle: appFont(context: context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: appFont(context: context),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.nameRequired;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.email,
                  labelStyle: appFont(context: context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: GoogleFonts.inter(),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return s.emailRequired;
                  if (!value.contains('@')) return s.emailInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                enabled: !_loading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _loading ? null : _submit(),
                decoration: InputDecoration(
                  labelText: s.password,
                  labelStyle: appFont(context: context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _loading
                        ? null
                        : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                style: GoogleFonts.inter(),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return s.passwordMinLengthShort;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text(s.cancel, style: appFont(context: context)),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  s.add,
                  style: appFont(
                    context: context,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

class _InviteMemberButton extends StatelessWidget {
  const _InviteMemberButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.primaryGreen.withValues(alpha: 0.45),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.of(context).shareMessCode,
                  style: appFont(
                    context: context,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          const Radius.circular(14),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SettingsTabContent extends StatelessWidget {
  const _SettingsTabContent({required this.messId});

  final String messId;

  void _showInfo(BuildContext context, String title, String body) {
    final s = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: appFont(context: context, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: appFont(context: context, fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close,
                style: appFont(
                    context: context,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalLink(BuildContext context, String url) async {
    final s = AppStrings.of(context);
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.openLinkFailed, style: appFont(context: context)),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.openLinkFailed, style: appFont(context: context)),
        ),
      );
    }
  }

  Future<void> _showThemePicker(BuildContext context) async {
    final s = AppStrings.of(context);
    final theme = ThemeScope.maybeOf(context);
    if (theme == null) return;

    const customSwatches = <Color>[
      Color(0xFF2E7D32),
      Color(0xFF1976D2),
      Color(0xFF00897B),
      Color(0xFFEF6C00),
      Color(0xFF3949AB),
      Color(0xFFC62828),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFF5D4037),
      Color(0xFF455A64),
      Color(0xFFAD1457),
      Color(0xFF558B2F),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.chooseTheme,
                    style: appFont(
                      context: ctx,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.appThemeTapHint,
                    style: appFont(
                      context: ctx,
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.pickThemeColor,
                    style: appFont(
                      context: ctx,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in customSwatches)
                        GestureDetector(
                          onTap: () async {
                            await theme.setCustomColor(color);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  s.themeApplied,
                                  style: appFont(context: context),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.themeId == AppThemeId.custom &&
                                        theme.customPrimary.toARGB32() ==
                                            color.toARGB32()
                                    ? AppColors.textDark
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: theme.themeId == AppThemeId.custom &&
                                    theme.customPrimary.toARGB32() ==
                                        color.toARGB32()
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      s.darkMode,
                      style: appFont(
                        context: ctx,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: theme.isDark,
                    activeThumbColor: AppColors.primaryGreen,
                    onChanged: (v) async {
                      if (theme.themeId == AppThemeId.custom) {
                        await theme.setCustomDark(v);
                      } else if (v) {
                        await theme.setTheme(AppThemeId.midnight);
                      } else {
                        await theme.setTheme(AppThemeId.forest);
                      }
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            s.themeApplied,
                            style: appFont(context: context),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  for (final palette in AppThemePalette.all) ...[
                    _ThemeOptionTile(
                      palette: palette,
                      selected: theme.themeId == palette.id,
                      title: s.themeName(palette.id.name),
                      onTap: () async {
                        await theme.setTheme(palette.id);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              s.themeApplied,
                              style: appFont(context: context),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _leaveMess(BuildContext context) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.leaveMess,
            style: appFont(context: context, fontWeight: FontWeight.w700)),
        content: Text(
          s.leaveMessConfirmBody,
          style: appFont(context: context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel, style: appFont(context: context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.leaveMess,
                style: appFont(
                    context: context,
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await MessService().leaveMess();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(s.leftMessSuccess, style: appFont(context: context))),
      );
    } on MessException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: appFont(context: context))),
      );
    }
  }

  Future<void> _toggleMonthLock({
    required BuildContext context,
    required bool currentlyLocked,
    required String yearMonth,
    required String monthLabel,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final s = AppStrings.of(context);

    if (!currentlyLocked) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            s.closeMonthTitle,
            style: appFont(context: context, fontWeight: FontWeight.w700),
          ),
          content: Text(
            '$monthLabel\n\n${s.closeMonthConfirm}',
            style: appFont(context: context, height: 1.45, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel, style: appFont(context: context)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.monthRed,
              ),
              child: Text(
                s.closeMonthAction,
                style: appFont(context: context, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }

    try {
      await MonthLockService().setLocked(
        messId: messId,
        yearMonth: yearMonth,
        locked: !currentlyLocked,
        adminUid: uid,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyLocked ? s.monthUnlockedSuccess : s.monthClosedSuccess,
            style: appFont(context: context),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e', style: appFont(context: context)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final locale = LocaleScope.maybeOf(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (locale != null) ...[
            _LanguageSwitcherCard(locale: locale),
            const SizedBox(height: 10),
          ],
          Builder(
            builder: (context) {
              final theme = ThemeScope.maybeOf(context);
              if (theme == null) return const SizedBox.shrink();
              return _SettingsTile(
                icon: Icons.palette_outlined,
                title: s.appTheme,
                subtitle:
                    '${s.themeName(theme.themeId.name)} · ${s.appThemeTapHint}',
                trailing: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.palette.preview,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                ),
                onTap: () => _showThemePicker(context),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: s.monthlyBills,
            subtitle: s.monthlyBillsSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessBillsScreen()),
              );
            },
          ),
          StreamBuilder<List<MessMember>>(
            stream: MessService().watchMembers(messId),
            builder: (context, memberSnap) {
              final members = memberSnap.data ?? [];
              final me = members.where((m) => m.uid == uid);
              final isAdmin = me.isNotEmpty && me.first.isAdmin;
              if (!isAdmin) return const SizedBox.shrink();
              return _MonthClosePanel(
                messId: messId,
                onToggle: ({
                  required bool currentlyLocked,
                  required String yearMonth,
                  required String monthLabel,
                }) =>
                    _toggleMonthLock(
                      context: context,
                      currentlyLocked: currentlyLocked,
                      yearMonth: yearMonth,
                      monthLabel: monthLabel,
                    ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: s.notifications,
            subtitle: s.notificationsSubtitle,
            onTap: () => _showInfo(
              context,
              s.notifications,
              s.notificationsInfoBody,
            ),
          ),
          _SettingsTile(
            icon: Icons.play_circle_outline_rounded,
            title: s.youtubeChannel,
            subtitle: s.youtubeChannelSubtitle,
            onTap: () => _openExternalLink(
              context,
              SocialLinks.youtubeChannel,
            ),
          ),
          _SettingsTile(
            icon: Icons.facebook_rounded,
            title: s.facebookPage,
            subtitle: s.facebookPageSubtitle,
            onTap: () => _openExternalLink(
              context,
              SocialLinks.facebookPage,
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: s.privacy,
            onTap: () => _showInfo(
              context,
              s.privacy,
              s.privacyInfoBody,
            ),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: s.help,
            onTap: () => _showInfo(
              context,
              s.help,
              s.helpInfoBody,
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: s.about,
            subtitle: s.aboutSubtitle,
            onTap: () => _showInfo(
              context,
              s.appTitle,
              s.aboutBody,
            ),
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.exit_to_app_rounded,
            title: s.leaveMess,
            subtitle: s.leaveMessSubtitle,
            danger: true,
            onTap: () => _leaveMess(context),
          ),
        ],
      ),
    );
  }
}

class _MonthClosePanel extends StatefulWidget {
  const _MonthClosePanel({
    required this.messId,
    required this.onToggle,
  });

  final String messId;
  final Future<void> Function({
    required bool currentlyLocked,
    required String yearMonth,
    required String monthLabel,
  }) onToggle;

  @override
  State<_MonthClosePanel> createState() => _MonthClosePanelState();
}

class _MonthClosePanelState extends State<_MonthClosePanel> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ym = yearMonthKey(_month);
    final label = s.monthLabel(_month);

    return StreamBuilder<bool>(
      stream: MonthLockService().watchLocked(widget.messId, ym),
      builder: (context, lockSnap) {
        final locked = lockSnap.data ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: locked ? AppColors.monthRed : AppColors.primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      locked ? s.monthLocked : s.lockMonth,
                      style: appFont(
                        context: context,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                s.monthLockedHint,
                style: appFont(
                  context: context,
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 10),
              MonthNavigator(
                month: _month,
                locked: locked,
                margin: EdgeInsets.zero,
                onChanged: (m) => setState(() {
                  _month = DateTime(m.year, m.month);
                }),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () => widget.onToggle(
                    currentlyLocked: locked,
                    yearMonth: ym,
                    monthLabel: label,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        locked ? AppColors.primaryGreen : AppColors.monthRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    locked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    size: 18,
                  ),
                  label: Text(
                    locked ? s.unlockMonth : s.closeMonthAction,
                    style: appFont(
                      context: context,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) {
              final ds = AppStrings.of(context);
              return AlertDialog(
                title: Text(
                  ds.logout,
                  style: appFont(context: context, fontWeight: FontWeight.w700),
                ),
                content: Text(
                  ds.logoutConfirm,
                  style: appFont(context: context),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(ds.no, style: appFont(context: context)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      ds.yesLogout,
                      style: appFont(
                        context: context,
                        color: const Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          if (confirmed != true) return;

          try {
            await AuthService().signOut();
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppStrings.of(context).logoutFailed,
                  style: appFont(context: context),
                ),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFCDD2)),
            color: const Color(0xFFFFEBEE),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFC62828), size: 22),
              const SizedBox(width: 10),
              Text(
                s.logout,
                style: appFont(
                  context: context,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC62828),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.palette,
    required this.selected,
    required this.title,
    required this.onTap,
  });

  final AppThemePalette palette;
  final bool selected;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Material(
      color: selected
          ? palette.primary.withValues(alpha: 0.12)
          : AppColors.inputBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.primary : AppColors.borderGrey,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: appFont(
                        context: context,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MiniSwatch(
                            color: palette.primary, label: s.themePreviewPrimary),
                        const SizedBox(width: 8),
                        _MiniSwatch(
                            color: palette.textDark, label: s.themePreviewText),
                        const SizedBox(width: 8),
                        _MiniSwatch(
                            color: palette.pageBackground,
                            label: s.themePreviewBg,
                            bordered: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSwatch extends StatelessWidget {
  const _MiniSwatch({
    required this.color,
    required this.label,
    this.bordered = false,
  });

  final Color color;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: bordered
                ? Border.all(color: AppColors.borderGrey)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: appFont(
            context: context,
            fontSize: 10,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}

class _LanguageSwitcherCard extends StatelessWidget {
  const _LanguageSwitcherCard({required this.locale});

  final LocaleController locale;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded,
                  color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.language,
                      style: appFont(
                        context: context,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      s.chooseLanguage,
                      style: appFont(
                        context: context,
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  label: Text(
                    s.languageBn,
                    style: appFont(
                      context: context,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.language, size: 16),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text(
                    s.languageEn,
                    style: appFont(
                      context: context,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.translate, size: 16),
                ),
              ],
              selected: {locale.isBengali},
              onSelectionChanged: (set) async {
                final wantBn = set.first;
                await locale.setBengali(wantBn);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppStrings.of(context).languageChanged,
                      style: appFont(context: context),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primaryGreen;
                  }
                  return AppColors.inputBackground;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppColors.textDark;
                }),
                side: WidgetStatePropertyAll(
                  BorderSide(color: AppColors.borderGrey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? const Color(0xFFC62828) : AppColors.primaryGreen;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: danger ? const Color(0xFFFFCDD2) : AppColors.borderGrey,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: appFont(
                        context: context,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: danger ? accent : AppColors.textDark,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: appFont(
                          context: context,
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textGrey,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
