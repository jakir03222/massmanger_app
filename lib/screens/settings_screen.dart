import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mess.dart';
import '../services/auth_service.dart';
import '../services/mess_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_app_header.dart';
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
                          const _SettingsTabContent(),
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

  @override
  Widget build(BuildContext context) {
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MemberCard(
                      letter: letter,
                      name: m.name,
                      room: m.room?.isNotEmpty == true ? m.room! : 'রুম —',
                      color: color,
                      textColor: textColor,
                      isAdmin: m.isAdmin,
                    ),
                  );
                }),
              const SizedBox(height: 6),
              _InviteMemberButton(onTap: () => _shareCode(context)),
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
    required this.isAdmin,
  });

  final String letter;
  final String name;
  final String room;
  final Color color;
  final Color textColor;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'অ্যাডমিন',
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
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B5B0), size: 22),
        ],
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
  const _SettingsTabContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'মাসিক বিল',
            subtitle: 'খালা · ভাড়া · বিদ্যুৎ · পানি · ইউটিলিটি',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessBillsScreen()),
              );
            },
          ),
          const _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'নোটিফিকেশন',
          ),
          const _SettingsTile(icon: Icons.lock_outline, title: 'প্রাইভেসি'),
          const _SettingsTile(icon: Icons.help_outline, title: 'সাহায্য'),
          const _SettingsTile(icon: Icons.info_outline, title: 'অ্যাপ সম্পর্কে'),
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
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 22),
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
                        color: AppColors.textDark,
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
