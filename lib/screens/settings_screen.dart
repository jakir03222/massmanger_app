import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/mess.dart';
import '../services/auth_service.dart';
import '../services/mess_service.dart';
import '../services/month_lock_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart' show yearMonthKey;
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

  static const _avatarColors = [
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
      return const Center(child: Text('লগইন নেই'));
    }

    return StreamBuilder(
      stream: _userService.watchUser(uid),
      builder: (context, userSnap) {
        final messId = userSnap.data?.messId;
        if (messId == null || messId.isEmpty) {
          return const Center(
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

  @override
  Widget build(BuildContext context) {
    final name = mess?.name ?? 'লোড হচ্ছে...';
    final location = mess?.location ?? '';
    final code = mess?.code ?? '------';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.map_outlined,
                                  size: 14,
                                  color: AppColors.textGrey,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    location,
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'মেস কোড',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreen,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: code == '------'
                                    ? null
                                    : () {
                                        Clipboard.setData(ClipboardData(text: code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'মেস কোড কপি হয়েছে',
                                              style: GoogleFonts.notoSansBengali(),
                                            ),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
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
    return Column(
      children: [
        Row(
          children: [
            _TabItem(
              label: 'মেম্বার',
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
            _TabItem(
              label: 'সেটিংস',
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
        const Divider(height: 1, color: AppColors.borderGrey),
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
                style: GoogleFonts.notoSansBengali(
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
    Clipboard.setData(ClipboardData(text: messCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'মেস কোড $messCode কপি হয়েছে — অন্য ব্যবহারকারীকে দিন',
          style: GoogleFonts.notoSansBengali(),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _manageMember(
    BuildContext context,
    MessMember actor,
    MessMember member,
  ) async {
    if (!member.canBeManagedBy(actor) && member.uid != actor.uid) {
      _toast(context, 'এই মেম্বার ম্যানেজ করার অনুমতি নেই।');
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              member.name,
              style: GoogleFonts.notoSansBengali(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              member.roleBnLabel,
              style: GoogleFonts.notoSansBengali(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            if (canEditRoom)
              ListTile(
                leading: const Icon(Icons.meeting_room_outlined,
                    color: AppColors.primaryGreen),
                title: Text('রুম নম্বর সম্পাদনা',
                    style: GoogleFonts.notoSansBengali()),
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
                  member.isRegularAdmin
                      ? 'অ্যাডমিন থেকে সরান'
                      : 'অ্যাডমিন বানান',
                  style: GoogleFonts.notoSansBengali(),
                ),
                subtitle: Text(
                  'শুধু সুপার অ্যাডমিন করতে পারে',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
                onTap: () => Navigator.pop(context, 'role'),
              ),
            if (canTransfer)
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.darkGreen),
                title: Text(
                  'সুপার অ্যাডমিন হস্তান্তর',
                  style: GoogleFonts.notoSansBengali(),
                ),
                subtitle: Text(
                  'মেসের মালিকানা এঁকে দিবেন',
                  style: GoogleFonts.notoSansBengali(
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
                  'মেস থেকে রিমুভ',
                  style: GoogleFonts.notoSansBengali(
                      color: const Color(0xFFC62828)),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
      builder: (context) => AlertDialog(
        title: Text(
          makeAdmin ? 'অ্যাডমিন বানাবেন?' : 'অ্যাডমিন থেকে সরাবেন?',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        content: Text(
          makeAdmin
              ? '${member.name} কে অ্যাডমিন করা হবে। অ্যাডমিন মেম্বার ম্যানেজ করতে পারবে, কিন্তু সুপার অ্যাডমিনের রোল বদলাতে পারবে না।'
              : '${member.name} কে সাধারণ মেম্বার করা হবে।',
          style: GoogleFonts.notoSansBengali(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              makeAdmin ? 'অ্যাডমিন বানান' : 'সরান',
              style: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await messService.setMemberRole(
      messId: messId,
      uid: member.uid,
      makeAdmin: makeAdmin,
    );
    if (context.mounted) {
      _toast(context, makeAdmin ? 'অ্যাডমিন করা হয়েছে' : 'অ্যাডমিন সরানো হয়েছে');
    }
  }

  Future<void> _confirmTransfer(
    BuildContext context,
    MessMember member,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'সুপার অ্যাডমিন হস্তান্তর?',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${member.name} সুপার অ্যাডমিন হবেন। আপনি অ্যাডমিন হয়ে যাবেন। '
          'এই কাজ পরে আর উল্টানো যায় না সহজে।',
          style: GoogleFonts.notoSansBengali(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'হস্তান্তর করুন',
              style: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await messService.transferSuperAdmin(
      messId: messId,
      newSuperAdminUid: member.uid,
    );
    if (context.mounted) {
      _toast(context, 'সুপার অ্যাডমিন হস্তান্তর হয়েছে');
    }
  }

  Future<void> _editRoom(BuildContext context, MessMember member) async {
    final controller = TextEditingController(text: member.room ?? '');
    final room = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('রুম নম্বর',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.notoSansBengali(),
          decoration: InputDecoration(
            hintText: 'যেমন: A-১',
            hintStyle: GoogleFonts.notoSansBengali(),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('সেভ',
                style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
    if (room == null || !context.mounted) return;
    await messService.updateMemberRoom(
      messId: messId,
      uid: member.uid,
      room: room,
    );
    if (context.mounted) _toast(context, 'রুম হালনাগাদ হয়েছে');
  }

  Future<void> _confirmRemove(BuildContext context, MessMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('মেম্বার রিমুভ?',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700)),
        content: Text(
          '${member.name} কে মেস থেকে রিমুভ করা হবে।',
          style: GoogleFonts.notoSansBengali(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('না', style: GoogleFonts.notoSansBengali()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('রিমুভ',
                style: GoogleFonts.notoSansBengali(
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await messService.removeMember(messId: messId, uid: member.uid);
    if (context.mounted) _toast(context, 'মেম্বার রিমুভ হয়েছে');
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.notoSansBengali())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<List<MessMember>>(
      stream: messService.watchMembers(messId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        final members = snap.data ?? [];
        final meList = members.where((m) => m.uid == myUid);
        final me = meList.isNotEmpty ? meList.first : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'এখনো কোনো মেম্বার নেই',
                    style: GoogleFonts.notoSansBengali(color: AppColors.textGrey),
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
                  final textColor =
                      color == AppColors.primaryGreen ? Colors.white : AppColors.textDark;
                  final actor = me;
                  final manageable = actor != null &&
                      (m.canBeManagedBy(actor) ||
                          (m.uid == actor.uid && actor.isAdmin));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MemberCard(
                      letter: letter,
                      name: m.name + (m.uid == myUid ? ' (আপনি)' : ''),
                      room: m.room?.isNotEmpty == true ? m.room! : 'রুম —',
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
              _InviteMemberButton(onTap: () => _shareCode(context)),
              if (me != null && me.isAdmin)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    me.isSuperAdmin
                        ? 'সুপার অ্যাডমিন: মেম্বারকে অ্যাডমিন বানান · অ্যাডমিন ও মেম্বার নিয়ন্ত্রণ করুন'
                        : 'অ্যাডমিন: শুধু সাধারণ মেম্বার ম্যানেজ করতে পারবেন · সুপার অ্যাডমিনের রোল বদলানো যায় না',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: AppColors.textGrey,
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

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.letter,
    required this.name,
    required this.room,
    required this.color,
    required this.textColor,
    required this.member,
    this.canManage = false,
    this.onTap,
  });

  final String letter;
  final String name;
  final String room;
  final Color color;
  final Color textColor;
  final MessMember member;
  final bool canManage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badgeColor = member.isSuperAdmin
        ? const Color(0xFF6A1B9A)
        : AppColors.primaryGreen;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              style: GoogleFonts.notoSansBengali(
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
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (member.isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          member.roleBnLabel,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  room,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            canManage ? Icons.more_vert_rounded : Icons.chevron_right_rounded,
            color: const Color(0xFFB0B5B0),
            size: 22,
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _InviteMemberButton extends StatelessWidget {
  const _InviteMemberButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primaryGreen.withValues(alpha: 0.45),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add_alt_1_outlined,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'মেম্বার আমন্ত্রণ করুন',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
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
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: GoogleFonts.notoSansBengali(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close,
                style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveMess(BuildContext context) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.leaveMess,
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700)),
        content: Text(
          'আপনি এই মেস থেকে বের হয়ে যাবেন। পরে আবার কোড দিয়ে যোগ দিতে পারবেন।',
          style: GoogleFonts.notoSansBengali(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel, style: GoogleFonts.notoSansBengali()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.leaveMess,
                style: GoogleFonts.notoSansBengali(
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
                Text('মেস ছেড়ে দেওয়া হয়েছে', style: GoogleFonts.notoSansBengali())),
      );
    } on MessException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.notoSansBengali())),
      );
    }
  }

  Future<void> _toggleMonthLock({
    required BuildContext context,
    required bool currentlyLocked,
    required String yearMonth,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final s = AppStrings.of(context);
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
            currentlyLocked ? s.unlockMonth : s.lockMonth,
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e', style: GoogleFonts.notoSansBengali()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final locale = LocaleScope.maybeOf(context);
    final yearMonth = yearMonthKey(DateTime.now());
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (locale != null)
            _SettingsTile(
              icon: Icons.translate_rounded,
              title: s.language,
              subtitle: locale.isBengali ? s.languageBn : s.languageEn,
              onTap: () async {
                await locale.toggle();
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
              return StreamBuilder<bool>(
                stream: MonthLockService().watchLocked(messId, yearMonth),
                builder: (context, lockSnap) {
                  final locked = lockSnap.data ?? false;
                  return _SettingsTile(
                    icon: locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    title: locked ? s.unlockMonth : s.lockMonth,
                    subtitle: locked ? s.monthLocked : s.monthLockedHint,
                    onTap: () => _toggleMonthLock(
                      context: context,
                      currentlyLocked: locked,
                      yearMonth: yearMonth,
                    ),
                  );
                },
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
              'মিল/বাজার অনুমোদন ও বিল যোগ হলে নোটিফিকেশন পাবেন। ডিভাইস পারমিশন চালু রাখুন।',
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: s.privacy,
            onTap: () => _showInfo(
              context,
              s.privacy,
              'আপনার তথ্য শুধুমাত্র আপনার মেসের হিসাব পরিচালনার জন্য ব্যবহৃত হয়। মেসের ডেটা শুধু মেসের মেম্বাররাই দেখতে পারে। আমরা কোনো তথ্য তৃতীয় পক্ষের কাছে বিক্রি করি না।',
            ),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: s.help,
            onTap: () => _showInfo(
              context,
              s.help,
              '• মিল: প্রতিদিন সকাল/বিকাল/রাতের মিল যোগ করুন।\n'
                  '• বাজার: বাজার এন্ট্রি দিন — অ্যাডমিন অনুমোদন করবে।\n'
                  '• রিপোর্ট: মাসিক/দৈনিক হিসাব দেখুন।\n'
                  '• মাসিক বিল: অ্যাডমিন বিল যোগ করে মাস শেষে PDF এক্সপোর্ট করতে পারে।\n'
                  '• মেম্বার যোগ: মেস কোড শেয়ার করুন।',
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: s.about,
            subtitle: 'মেস ম্যানেজার · সংস্করণ ১.০.০',
            onTap: () => _showInfo(
              context,
              s.appTitle,
              'সংস্করণ ১.০.০\n\nমেস/হোস্টেলের মিল, বাজার, বিল ও মাসিক হিসাব সহজে পরিচালনার অ্যাপ। সব মেম্বারের হিসাব এক জায়গায়, স্বচ্ছভাবে।',
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

class _LogoutTile extends StatelessWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'লগআউট',
                style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'আপনি কি লগআউট করতে চান?',
                style: GoogleFonts.notoSansBengali(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('না', style: GoogleFonts.notoSansBengali()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'হ্যাঁ, লগআউট',
                    style: GoogleFonts.notoSansBengali(
                      color: const Color(0xFFC62828),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (confirmed != true) return;

          try {
            await AuthService().signOut();
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'লগআউট ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
                  style: GoogleFonts.notoSansBengali(),
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
                'লগআউট',
                style: GoogleFonts.notoSansBengali(
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? const Color(0xFFC62828) : AppColors.primaryGreen;
    return Material(
      color: Colors.white,
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
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: danger ? accent : AppColors.textDark,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
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
