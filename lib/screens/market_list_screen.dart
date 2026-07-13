import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_entry.dart';
import '../services/market_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bn_date_picker.dart';
import '../widgets/mess_session_builder.dart';
import 'add_market_screen.dart';

enum MarketFilter { thisMonth, lastMonth, all }

class MarketListScreen extends StatefulWidget {
  const MarketListScreen({super.key});

  @override
  State<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends State<MarketListScreen> {
  MarketFilter _filter = MarketFilter.thisMonth;
  /// Admin-only: null = সব মেম্বার, else filter by shopperUid.
  String? _memberFilterUid;
  /// Specific day filter (বাংলা ক্যালেন্ডার). null = মাস ফিল্টার ব্যবহার.
  DateTime? _dateFilter;
  final _marketService = MarketService();
  final Set<String> _busyIds = {};

  List<MarketEntry> _filterByMember(List<MarketEntry> items) {
    final uid = _memberFilterUid;
    if (uid == null) return items;
    return items.where((e) => e.shopperUid == uid).toList();
  }

  List<MarketEntry> _filterByDate(List<MarketEntry> items) {
    final d = _dateFilter;
    if (d == null) return items;
    final key = dateKey(d);
    return items.where((e) => e.dateKey == key).toList();
  }

  String? _yearMonthForFilter() {
    if (_dateFilter != null) {
      return yearMonthKey(_dateFilter!);
    }
    final now = DateTime.now();
    switch (_filter) {
      case MarketFilter.thisMonth:
        return yearMonthKey(now);
      case MarketFilter.lastMonth:
        final last = DateTime(now.year, now.month - 1, 1);
        return yearMonthKey(last);
      case MarketFilter.all:
        return null;
    }
  }

  Future<void> _pickDateFilter() async {
    final picked = await showBnDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'বাজার তারিখ ফিল্টার',
    );
    if (picked == null) return;
    setState(() => _dateFilter = picked);
  }

  void _clearDateFilter() {
    setState(() => _dateFilter = null);
  }

  Future<void> _openAdd({required bool isAdmin}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddMarketScreen()),
    );
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result
              ? 'বাজার যোগ হয়েছে'
              : 'অনুরোধ পাঠানো হয়েছে — অ্যাডমিন অনুমোদন করলে সবাই দেখতে পাবে',
          style: GoogleFonts.notoSansBengali(),
        ),
      ),
    );
  }

  Future<void> _openEdit(MarketEntry entry) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddMarketScreen(existing: entry)),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('বাজার হালনাগাদ হয়েছে', style: GoogleFonts.notoSansBengali()),
        ),
      );
    }
  }

  Future<void> _approve(String messId, String adminUid, MarketEntry entry) async {
    setState(() => _busyIds.add(entry.id));
    try {
      await _marketService.approveMarket(
        messId: messId,
        marketId: entry.id,
        adminUid: adminUid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'অনুমোদন হয়েছে — এখন সবাই দেখতে পাবে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('অনুমোদন ব্যর্থ', style: GoogleFonts.notoSansBengali()),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(entry.id));
    }
  }

  Future<void> _reject(String messId, String adminUid, MarketEntry entry) async {
    setState(() => _busyIds.add(entry.id));
    try {
      await _marketService.rejectMarket(
        messId: messId,
        marketId: entry.id,
        adminUid: adminUid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'প্রত্যাখ্যান করা হয়েছে — সবাই দেখতে পারবে না',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('প্রত্যাখ্যান ব্যর্থ', style: GoogleFonts.notoSansBengali()),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(entry.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((m) => m.uid == appUser.uid);
        final isAdmin = matched.isNotEmpty && matched.first.isAdmin;

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
              children: [
                Text(
                  'বাজারের তালিকা',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
                Text(
                  mess.name,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 16),
                if (isAdmin)
                  StreamBuilder<List<MarketEntry>>(
                    stream: _marketService.watchPendingMarkets(mess.id),
                    builder: (context, pendingSnap) {
                      final pending =
                          _filterByMember(pendingSnap.data ?? []);
                      if (pending.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'মেম্বার অনুরোধ (${pending.length})',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'অনুমোদন করলে সবাই দেখতে পাবে · প্রত্যাখ্যান করলে যোগ হবে না',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...pending.map(
                            (e) => _PendingRequestCard(
                              entry: e,
                              busy: _busyIds.contains(e.id),
                              onAccept: () =>
                                  _approve(mess.id, appUser.uid, e),
                              onReject: () =>
                                  _reject(mess.id, appUser.uid, e),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  )
                else
                  StreamBuilder<List<MarketEntry>>(
                    stream:
                        _marketService.watchMyRequests(mess.id, appUser.uid),
                    builder: (context, mySnap) {
                      final mine = mySnap.data ?? [];
                      if (mine.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'আমার অনুরোধ',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...mine.map(
                            (e) => _MyRequestCard(
                              entry: e,
                              onTap: e.isPending ? () => _openEdit(e) : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                Row(
                  children: [
                    _chip('এই মাস', MarketFilter.thisMonth),
                    const SizedBox(width: 8),
                    _chip('গত মাস', MarketFilter.lastMonth),
                    const SizedBox(width: 8),
                    _chip('সব', MarketFilter.all),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDateFilter,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _dateFilter != null
                            ? AppColors.primaryGreen
                            : AppColors.borderGrey,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'তারিখ ফিল্টার',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              Text(
                                _dateFilter == null
                                    ? 'সব তারিখ (মাস ফিল্টার)'
                                    : formatBnDate(_dateFilter!),
                                style: GoogleFonts.notoSansBengali(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_dateFilter != null)
                          TextButton(
                            onPressed: _clearDateFilter,
                            child: Text(
                              'মুছুন',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                          )
                        else
                          Text(
                            'সিলেক্ট',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isAdmin && members.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'মেম্বার ফিল্টার',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _memberChip(label: 'সব মেম্বার', uid: null),
                        ...members.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _memberChip(label: m.name, uid: m.uid),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                StreamBuilder<List<MarketEntry>>(
                  stream: _marketService.watchApprovedMarkets(
                    mess.id,
                    yearMonth: _yearMonthForFilter(),
                  ),
                  builder: (context, snap) {
                    final allApproved = snap.data ?? [];
                    var items = isAdmin
                        ? _filterByMember(allApproved)
                        : allApproved
                            .where((e) => e.shopperUid == appUser.uid)
                            .toList();
                    items = _filterByDate(items);
                    final total =
                        items.fold<double>(0, (s, e) => s + e.amount);
                    final dueTotal = items
                        .where((e) => e.isDue)
                        .fold<double>(0, (s, e) => s + e.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.featureGreenBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isAdmin
                                          ? 'অনুমোদিত বাজার (সবাই দেখতে পাবে)'
                                          : 'আমার বাজার (অনুমোদিত)',
                                      style: GoogleFonts.notoSansBengali(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatTaka(total),
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              if (dueTotal > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 16,
                                      color: AppColors.marketOrangeDark,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'এর মধ্যে বাকি',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.marketOrangeDark,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatTaka(dueTotal),
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.marketOrangeDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAdmin
                              ? '${items.length} টি খরচ'
                              : 'শুধু আপনার বাজার · অন্য মেম্বার দেখা যায় না',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          )
                        else if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                isAdmin
                                    ? (_dateFilter != null
                                        ? 'এই তারিখে কোনো বাজার নেই'
                                        : (_memberFilterUid == null
                                            ? 'এখনো কোনো অনুমোদিত বাজার নেই'
                                            : 'এই মেম্বারের কোনো বাজার নেই'))
                                    : (_dateFilter != null
                                        ? 'এই তারিখে আপনার কোনো বাজার নেই'
                                        : 'আপনার কোনো অনুমোদিত বাজার নেই'),
                                style: GoogleFonts.notoSansBengali(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                          )
                        else
                          ...items.map(
                            (e) => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: isAdmin ? () => _openEdit(e) : null,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.borderGrey,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    e.shopperName,
                                                    style: GoogleFonts
                                                        .notoSansBengali(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (e.isDue) const _DueBadge(),
                                              ],
                                            ),
                                            if (e.items.isNotEmpty)
                                              Text(
                                                e.items
                                                    .map(
                                                      (i) =>
                                                          '${i.name} ${i.quantity}',
                                                    )
                                                    .join(', '),
                                                style:
                                                    GoogleFonts.notoSansBengali(
                                                  fontSize: 12,
                                                  color: AppColors.textGrey,
                                                ),
                                              )
                                            else if (e.notes.isNotEmpty)
                                              Text(
                                                e.notes,
                                                style:
                                                    GoogleFonts.notoSansBengali(
                                                  fontSize: 12,
                                                  color: AppColors.textGrey,
                                                ),
                                              ),
                                            Text(
                                              e.dateKey,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textGrey,
                                              ),
                                            ),
                                            _MarketTimes(entry: e),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formatTaka(e.amount),
                                        style: GoogleFonts.notoSansBengali(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.marketAmountBrown,
                                        ),
                                      ),
                                      if (isAdmin) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () => _openAdd(isAdmin: isAdmin),
                backgroundColor: AppColors.primaryGreen,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, MarketFilter value) {
    final selected = _dateFilter == null && _filter == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = value;
        _dateFilter = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _memberChip({required String label, required String? uid}) {
    final selected = _memberFilterUid == uid;
    return GestureDetector(
      onTap: () => setState(() => _memberFilterUid = uid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.darkGreen : AppColors.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.actionOrange),
      ),
      child: Text(
        'বাকি',
        style: GoogleFonts.notoSansBengali(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.marketOrangeDark,
        ),
      ),
    );
  }
}

class _MarketTimes extends StatelessWidget {
  const _MarketTimes({required this.entry});

  final MarketEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'তৈরি: ${formatDateTime(entry.createdAt)}',
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
          if (entry.wasEditedByAdmin)
            Text(
              'সম্পাদনা: ${entry.editedByName}',
              style: GoogleFonts.notoSansBengali(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.entry,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final MarketEntry entry;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.shopperName,
                        style: GoogleFonts.notoSansBengali(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (entry.isDue) const _DueBadge(),
                  ],
                ),
              ),
              Text(
                formatTaka(entry.amount),
                style: GoogleFonts.notoSansBengali(
                  fontWeight: FontWeight.w700,
                  color: AppColors.marketAmountBrown,
                ),
              ),
            ],
          ),
          if (entry.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                entry.items
                    .map((i) => '${i.name} ${i.quantity}')
                    .join(', '),
                style: GoogleFonts.notoSansBengali(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          Text(
            entry.dateKey,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
          ),
          _MarketTimes(entry: entry),
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

class _MyRequestCard extends StatelessWidget {
  const _MyRequestCard({required this.entry, this.onTap});

  final MarketEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pending = entry.isPending;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: pending
                  ? const Color(0xFFFFE082)
                  : const Color(0xFFFFCDD2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.shopperName,
                            style: GoogleFonts.notoSansBengali(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (entry.isDue) const _DueBadge(),
                      ],
                    ),
                    if (entry.items.isNotEmpty)
                      Text(
                        entry.items
                            .map((i) => '${i.name} ${i.quantity}')
                            .join(', '),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    Text(
                      entry.dateKey,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                    _MarketTimes(entry: entry),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatTaka(entry.amount),
                    style: GoogleFonts.notoSansBengali(
                      fontWeight: FontWeight.w700,
                      color: AppColors.marketAmountBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pending
                          ? const Color(0xFFFFF8E1)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.status.bnLabel,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pending
                            ? const Color(0xFFF9A825)
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
