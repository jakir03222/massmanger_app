import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/bazaar_schedule.dart';
import '../models/mess.dart';
import '../services/bazaar_schedule_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bn_date_picker.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';

class BazaarScheduleScreen extends StatefulWidget {
  const BazaarScheduleScreen({super.key});

  @override
  State<BazaarScheduleScreen> createState() => _BazaarScheduleScreenState();
}

class _BazaarScheduleScreenState extends State<BazaarScheduleScreen> {
  final _service = BazaarScheduleService();
  final Set<String> _busy = {};
  bool _requesting = false;

  Future<void> _approve(String messId, String adminUid, BazaarSchedule s) async {
    setState(() => _busy.add(s.id));
    try {
      await _service.approve(
        messId: messId,
        scheduleId: s.id,
        adminUid: adminUid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'অনুমোদন — এখন সব মেম্বার দেখতে পাবে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(s.id));
    }
  }

  Future<void> _reject(String messId, BazaarSchedule s) async {
    setState(() => _busy.add(s.id));
    try {
      await _service.reject(messId: messId, scheduleId: s.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'প্রত্যাখ্যান — তালিকা থেকে মুছে গেছে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(s.id));
    }
  }

  Future<void> _delete(String messId, BazaarSchedule s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'সময়সূচি মুছবেন?',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${s.memberName} — ${_rangeLabel(s)} মুছে যাবে।',
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
              'মুছুন',
              style: GoogleFonts.notoSansBengali(
                color: const Color(0xFFC62828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.delete(messId: messId, scheduleId: s.id);
  }

  DateTime? _parseDate(String key) {
    final p = key.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  String _rangeLabel(BazaarSchedule s) {
    final start = _parseDate(s.startDateKey);
    final end = _parseDate(s.endDateKey);
    if (start == null) return s.startDateKey;
    final startBn = formatBnDate(start);
    if (end == null || s.isSingleDay) return startBn;
    return '$startBn → ${formatBnDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((m) => m.uid == appUser.uid);
        final me = matched.isNotEmpty ? matched.first : null;
        final isAdmin = me?.isAdmin ?? false;

        return StreamBuilder<List<BazaarSchedule>>(
          stream: _service.watchAll(mess.id),
          builder: (context, snap) {
            final all = snap.data ?? [];
            final pending = all.where((e) => e.isPending).toList();
            final approved = all.where((e) => e.isApproved).toList()
              ..sort((a, b) {
                // Running → Upcoming → Completed
                final order = {
                  BazaarRunStatus.running: 0,
                  BazaarRunStatus.upcoming: 1,
                  BazaarRunStatus.completed: 2,
                };
                final c = (order[a.runStatus()] ?? 9)
                    .compareTo(order[b.runStatus()] ?? 9);
                if (c != 0) return c;
                return a.startDateKey.compareTo(b.startDateKey);
              });
            final myPending = pending
                .where((e) => e.uid == appUser.uid)
                .toList();
            final runningCount =
                approved.where((e) => e.runStatus() == BazaarRunStatus.running).length;
            final upcomingCount =
                approved.where((e) => e.runStatus() == BazaarRunStatus.upcoming).length;
            final completedCount =
                approved.where((e) => e.runStatus() == BazaarRunStatus.completed).length;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
                  children: [
                    MessAppHeader(
                      title: mess.name,
                      subtitle: mess.location,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'বাজার তারিখ / স্ট্যাটাস',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        isAdmin
                            ? 'মেম্বার অনুরোধ অনুমোদন করলে সবাই দেখবে কে কোন দিন বাজার করবে'
                            : 'তারিখ অনুরোধ পাঠান · অনুমোদন হলে সব মেম্বার দেখতে পাবে',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    if (isAdmin && pending.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'বাজার তারিখ অনুরোধ (${pending.length})',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...pending.map(
                        (s) => _PendingCard(
                          schedule: s,
                          dateLabel: _rangeLabel(s),
                          busy: _busy.contains(s.id),
                          onAccept: () =>
                              _approve(mess.id, appUser.uid, s),
                          onReject: () => _reject(mess.id, s),
                        ),
                      ),
                    ],
                    if (!isAdmin && myPending.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'আমার অনুরোধ',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...myPending.map(
                        (s) => _StatusCard(
                          schedule: s,
                          dateLabel: _rangeLabel(s),
                          showDelete: false,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'বাজার স্ট্যাটাস (সব মেম্বার)',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Text(
                        'কে কোন তারিখে বাজার করবে — অনুমোদন এর পর এখানে দেখা যায়',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    if (approved.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatusCountChip(
                                label: 'চলমান',
                                count: runningCount,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusCountChip(
                                label: 'আসন্ন',
                                count: upcomingCount,
                                color: const Color(0xFF1565C0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusCountChip(
                                label: 'সম্পন্ন',
                                count: completedCount,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (approved.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 32,
                        ),
                        child: Text(
                          'এখনো কোনো নির্ধারিত বাজার তারিখ নেই',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansBengali(
                            color: AppColors.textGrey,
                          ),
                        ),
                      )
                    else
                      ...approved.map(
                        (s) => _StatusCard(
                          schedule: s,
                          dateLabel: _rangeLabel(s),
                          showDelete: isAdmin,
                          onDelete: isAdmin
                              ? () => _delete(mess.id, s)
                              : null,
                        ),
                      ),
                  ],
                ),
                Positioned(
                  right: 20,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _requesting || me == null
                        ? null
                        : () => _requestFor(
                              messId: mess.id,
                              me: me,
                              members: members,
                              asAdmin: isAdmin,
                            ),
                    backgroundColor: AppColors.primaryGreen,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      isAdmin ? 'তারিখ নির্ধারণ' : 'তারিখ অনুরোধ',
                      style: GoogleFonts.notoSansBengali(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Future<void> _requestFor({
    required String messId,
    required MessMember me,
    required List<MessMember> members,
    required bool asAdmin,
  }) async {
    MessMember target = me;

    if (asAdmin) {
      final pickedMember = await showModalBottomSheet<MessMember>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (context) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'কার বাজার তারিখ?',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final m = members[index];
                        return ListTile(
                          title: Text(
                            m.name,
                            style: GoogleFonts.notoSansBengali(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, m),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (pickedMember == null) return;
      target = pickedMember;
    }

    if (!mounted) return;
    final minDate = DateTime.now().subtract(const Duration(days: 1));
    final maxDate = DateTime.now().add(const Duration(days: 90));

    final start = await showBnDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'শুরুর তারিখ সিলেক্ট করুন',
    );
    if (start == null || !mounted) return;

    final end = await showBnDatePicker(
      context: context,
      initialDate: start,
      firstDate: start,
      lastDate: maxDate,
      helpText: 'শেষ তারিখ সিলেক্ট করুন',
    );
    if (end == null || !mounted) return;

    setState(() => _requesting = true);
    try {
      await _service.requestSchedule(
        messId: messId,
        uid: target.uid,
        memberName: target.name,
        startDateKey: dateKey(start),
        endDateKey: dateKey(end),
        yearMonth: yearMonthKey(start),
        asAdmin: asAdmin,
      );
      if (!mounted) return;
      final rangeText = dateKey(start) == dateKey(end)
          ? formatBnDate(start)
          : '${formatBnDate(start)} → ${formatBnDate(end)}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asAdmin
                ? '${target.name}: $rangeText নির্ধারিত'
                : 'অনুরোধ ($rangeText) পাঠানো হয়েছে — অনুমোদন হলে সবাই দেখবে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.schedule,
    required this.dateLabel,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final BazaarSchedule schedule;
  final String dateLabel;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schedule.memberName,
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
          ),
          Text(
            dateLabel,
            style: GoogleFonts.notoSansBengali(
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          Text(
            'অনুরোধ: ${formatDateTime(schedule.createdAt)}',
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFC62828)),
                  ),
                  child: Text(
                    'প্রত্যাখ্যান',
                    style: GoogleFonts.notoSansBengali(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'গ্রহণ',
                          style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.schedule,
    required this.dateLabel,
    required this.showDelete,
    this.onDelete,
  });

  final BazaarSchedule schedule;
  final String dateLabel;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.featureGreenBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.memberName,
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  dateLabel,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 6),
                if (schedule.isPending)
                  Text(
                    'স্ট্যাটাস: অপেক্ষমাণ',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: const Color(0xFFF9A825),
                    ),
                  )
                else
                  _RunStatusBadge(status: schedule.runStatus()),
              ],
            ),
          ),
          if (showDelete && onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
            ),
        ],
      ),
    );
  }
}

class _StatusCountChip extends StatelessWidget {
  const _StatusCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.notoSansBengali(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSansBengali(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunStatusBadge extends StatelessWidget {
  const _RunStatusBadge({required this.status});

  final BazaarRunStatus status;

  Color get _color {
    switch (status) {
      case BazaarRunStatus.upcoming:
        return const Color(0xFF1565C0);
      case BazaarRunStatus.running:
        return AppColors.primaryGreen;
      case BazaarRunStatus.completed:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.bnLabel,
        style: GoogleFonts.notoSansBengali(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
