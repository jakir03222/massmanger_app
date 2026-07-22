import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_entry.dart';
import '../models/meal_entry.dart';
import '../models/mess.dart';
import '../models/monthly_settlement.dart';
import '../config/feature_flags.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../services/monthly_report_pdf_service.dart';
import '../services/monthly_settlement_service.dart';
import '../services/pdf_download_service.dart';
import '../theme/app_colors.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';
import 'community/community_hub_screen.dart';
import 'market_hub_screen.dart';
import 'meal_screen.dart';
import 'mess_bills_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  Widget _tabForIndex(int index) {
    if (FeatureFlags.communityEnabled) {
      return switch (index) {
        0 => const _HomeTab(),
        1 => const MealScreen(),
        2 => const MarketHubScreen(),
        3 => const CommunityHubScreen(embedded: true),
        4 => const ReportScreen(),
        5 => const SettingsScreen(),
        _ => const _HomeTab(),
      };
    }
    return switch (index) {
      0 => const _HomeTab(),
      1 => const MealScreen(),
      2 => const MarketHubScreen(),
      3 => const ReportScreen(),
      4 => const SettingsScreen(),
      _ => const _HomeTab(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: _tabForIndex(_navIndex),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _mealService = MealService();
  final _marketService = MarketService();
  final _settlementService = MonthlySettlementService();
  final _pdfService = MonthlyReportPdfService();
  final _pdfDownload = PdfDownloadService();

  bool _exporting = false;
  int _refreshTick = 0;
  late final DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  String get _monthLabel {
    const months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    return '${months[_month.month - 1]} ${_month.year}';
  }

  String _fmtMeals(double n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

  Future<void> _exportMonthPdf({
    required Mess mess,
    required List<MessMember> members,
  }) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final report = await _settlementService.buildReport(
        mess: mess,
        members: members,
        month: _month,
      );
      final bytes = await _pdfService.generate(report);
      if (!mounted) return;
      final result = await _pdfDownload.saveAndOpen(
        bytes: bytes,
        filename: 'mess-hisab-${yearMonthKey(_month)}.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.savedToDownloads
                ? 'PDF ডাউনলোড ফোল্ডারে সেভ হয়েছে'
                : 'PDF সেভ হয়েছে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF তৈরি ব্যর্থ — আবার চেষ্টা করুন',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final today = dateKey(DateTime.now());
        final month = yearMonthKey(_month);
        final matched = members.where((e) => e.uid == appUser.uid);
        final isAdmin = matched.isNotEmpty && matched.first.isAdmin;
        final displayName = matched.isNotEmpty
            ? matched.first.name
            : (appUser.name ?? appUser.email);

        return StreamBuilder<List<MealEntry>>(
          stream: _mealService.watchDayMeals(mess.id, today),
          builder: (context, mealSnap) {
            final todayMeals =
                (mealSnap.data ?? []).where((e) => e.isApproved).toList();
            final todayMealTotal =
                todayMeals.fold<double>(0, (s, e) => s + e.mealCount);

            return StreamBuilder<List<MarketEntry>>(
              stream: _marketService.watchMarkets(mess.id, yearMonth: month),
              builder: (context, marketSnap) {
                final markets = marketSnap.data ?? [];
                final monthSpendAll =
                    markets.fold<double>(0, (s, e) => s + e.amount);
                final todaySpend = markets
                    .where((e) => e.dateKey == today)
                    .fold<double>(0, (s, e) => s + e.amount);
                final dueSpend = markets
                    .where((e) => e.isDue)
                    .fold<double>(0, (s, e) => s + e.amount);
                final myMarketTotal = markets
                    .where((e) => e.shopperUid == appUser.uid)
                    .fold<double>(0, (s, e) => s + e.amount);
                final todayMealRate = todayMealTotal == 0
                    ? 0.0
                    : todaySpend / todayMealTotal;
                final recentList = markets.take(3).toList();

                return StreamBuilder<MonthlySettlementReport>(
                  key: ValueKey('home-report-$_refreshTick'),
                  stream: _settlementService.watchReport(
                    mess: mess,
                    members: members,
                    month: _month,
                  ),
                  builder: (context, reportSnap) {
                    final report = reportSnap.data;
                    final loadingReport = reportSnap.connectionState ==
                            ConnectionState.waiting &&
                        report == null;

                    return RefreshIndicator(
                      color: AppColors.primaryGreen,
                      onRefresh: () async {
                        setState(() => _refreshTick++);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 450),
                        );
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          MessAppHeader(
                            title: mess.name,
                            subtitle: mess.location,
                          ),
                          const SizedBox(height: 14),
                          _WelcomeBanner(
                            name: displayName,
                            monthLabel: _monthLabel,
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: 14),
                            _TodayRateCard(
                              rate: todayMealRate,
                              meals: todayMealTotal,
                              spend: todaySpend,
                              fmtMeals: _fmtMeals,
                            ),
                          ],
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              isAdmin
                                  ? 'সার্বিক কাউন্ট ($_monthLabel)'
                                  : 'আমার কাউন্ট ($_monthLabel)',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (loadingReport)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _OverallGrid(
                                isAdmin: isAdmin,
                                members: members.length,
                                monthMeals: report?.totalConsumeMeal ?? 0,
                                monthSpend: isAdmin
                                    ? (report?.totalDeposit ?? monthSpendAll)
                                    : myMarketTotal,
                                mealRate: report?.mealRate ?? 0,
                                fixedBills: report?.totalCookCost ?? 0,
                                dueSpend: dueSpend,
                                todayMeals: todayMealTotal,
                                todaySpend: todaySpend,
                                fmtMeals: _fmtMeals,
                              ),
                            ),
                          if (isAdmin) ...[
                            const SizedBox(height: 18),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'মাস শেষ — সব মেম্বারের হিসাব',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Smart PDF — প্রতি মেম্বারের মিল, বাজার, বিল ভাগ ও পাবে/দিবে',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _exporting
                                          ? null
                                          : () => _exportMonthPdf(
                                                mess: mess,
                                                members: members,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: _exporting
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.picture_as_pdf_outlined,
                                            ),
                                      label: Text(
                                        'Smart মাসিক হিসাব PDF',
                                        style: GoogleFonts.notoSansBengali(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MessBillsScreen(),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.darkGreen,
                                      side: const BorderSide(
                                        color: AppColors.primaryGreen,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'বিল',
                                      style: GoogleFonts.notoSansBengali(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (report != null) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'সব মেম্বারের হিসাব (সংক্ষেপ)',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...report.members.map(
                                (row) => _MemberBalanceCard(row: row),
                              ),
                            ],
                          ] else ...[
                            const SizedBox(height: 16),
                            if (report != null)
                              _MyMonthCard(
                                report: report,
                                uid: appUser.uid,
                                fmtMeals: _fmtMeals,
                              ),
                          ],
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'সাম্প্রতিক বাজার',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (recentList.isEmpty)
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: AppColors.borderGrey),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: AppColors.featureOrangeBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: AppColors.featureOrangeIcon,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'এই মাসে এখনো কোনো বাজার এন্ট্রি নেই',
                                      style: GoogleFonts.notoSansBengali(
                                        color: AppColors.textGrey,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...recentList.map(
                              (entry) => Container(
                                margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: AppColors.borderGrey),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${entry.shopperName} · ${formatTaka(entry.amount)}',
                                        style: GoogleFonts.notoSansBengali(
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      entry.dateKey,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!isAdmin && recentList.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                              child: Text(
                                'এই মাসে আপনার মোট বাজার: ${formatTaka(myMarketTotal)}',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
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
          },
        );
      },
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.name, required this.monthLabel});

  final String name;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bannerGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'স্বাগতম, $name',
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatBnDate(DateTime.now())}  ·  $monthLabel',
            style: GoogleFonts.notoSansBengali(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRateCard extends StatelessWidget {
  const _TodayRateCard({
    required this.rate,
    required this.meals,
    required this.spend,
    required this.fmtMeals,
  });

  final double rate;
  final double meals;
  final double spend;
  final String Function(double) fmtMeals;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen),
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
              Icons.calculate_outlined,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আজকের মিল রেট',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  formatTaka(rate),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
                ),
                Text(
                  'মিল ${fmtMeals(meals)} · বাজার ${formatTaka(spend)}',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallGrid extends StatelessWidget {
  const _OverallGrid({
    required this.isAdmin,
    required this.members,
    required this.monthMeals,
    required this.monthSpend,
    required this.mealRate,
    required this.fixedBills,
    required this.dueSpend,
    required this.todayMeals,
    required this.todaySpend,
    required this.fmtMeals,
  });

  final bool isAdmin;
  final int members;
  final double monthMeals;
  final double monthSpend;
  final double mealRate;
  final double fixedBills;
  final double dueSpend;
  final double todayMeals;
  final double todaySpend;
  final String Function(double) fmtMeals;

  @override
  Widget build(BuildContext context) {
    final cards = <_StatTileData>[
      _StatTileData('আজ মিল', fmtMeals(todayMeals), Icons.restaurant_rounded),
      _StatTileData(
        'আজ বাজার',
        formatTaka(todaySpend),
        Icons.shopping_cart_outlined,
      ),
      _StatTileData(
        isAdmin ? 'মাসিক মিল' : 'আমার মাসিক বাজার',
        isAdmin ? fmtMeals(monthMeals) : formatTaka(monthSpend),
        Icons.calendar_month_outlined,
      ),
      if (isAdmin) ...[
        _StatTileData(
          'মাসিক বাজার',
          formatTaka(monthSpend),
          Icons.storefront_outlined,
        ),
        _StatTileData(
          'মাসিক মিল রেট',
          formatTaka(mealRate),
          Icons.payments_outlined,
        ),
        _StatTileData(
          'মাসিক বিল',
          formatTaka(fixedBills),
          Icons.receipt_long_outlined,
        ),
        _StatTileData(
          'বাকি বাজার',
          formatTaka(dueSpend),
          Icons.account_balance_wallet_outlined,
        ),
        _StatTileData(
          'মেম্বার',
          '$members জন',
          Icons.groups_outlined,
        ),
      ] else ...[
        _StatTileData(
          'মেম্বার',
          '$members জন',
          Icons.groups_outlined,
        ),
      ],
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards
          .map(
            (c) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 50) / 2,
              child: _StatTile(data: c),
            ),
          )
          .toList(),
    );
  }
}

class _StatTileData {
  const _StatTileData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});
  final _StatTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: GoogleFonts.notoSansBengali(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberBalanceCard extends StatelessWidget {
  const _MemberBalanceCard({required this.row});

  final MemberMonthlySettlement row;

  @override
  Widget build(BuildContext context) {
    final net = row.netPayableReceivable;
    final payable = net < 0;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.member.name,
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'মিল: ${row.consumeMeal % 1 == 0 ? row.consumeMeal.toInt() : row.consumeMeal.toStringAsFixed(1)}'
                  '  ·  বাজার: ${formatTaka(row.depositMoney)}',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payable ? 'দিবে' : 'পাবে',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 11,
                  color: payable
                      ? const Color(0xFFC62828)
                      : AppColors.darkGreen,
                ),
              ),
              Text(
                formatTaka(payable ? -net : net),
                style: GoogleFonts.notoSansBengali(
                  fontWeight: FontWeight.w800,
                  color: payable
                      ? const Color(0xFFC62828)
                      : AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyMonthCard extends StatelessWidget {
  const _MyMonthCard({
    required this.report,
    required this.uid,
    required this.fmtMeals,
  });

  final MonthlySettlementReport report;
  final String uid;
  final String Function(double) fmtMeals;

  @override
  Widget build(BuildContext context) {
    final mine = report.members.where((m) => m.member.uid == uid);
    if (mine.isEmpty) return const SizedBox.shrink();
    final row = mine.first;
    final net = row.netPayableReceivable;
    final payable = net < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          _kv('আমার মিল', fmtMeals(row.consumeMeal)),
          _kv('মিল রেট', formatTaka(row.mealRate)),
          _kv('মিল খরচ', formatTaka(row.costOfMeal)),
          _kv('আমার বাজার', formatTaka(row.depositMoney)),
          _kv('বিল ভাগ', formatTaka(row.cookCost)),
          const Divider(height: 18),
          _kv(
            payable ? 'আমাকে দিতে হবে' : 'আমি পাব',
            formatTaka(payable ? -net : net),
            bold: true,
            color: payable ? const Color(0xFFC62828) : AppColors.darkGreen,
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(k, style: GoogleFonts.notoSansBengali(color: AppColors.textGrey)),
          const Spacer(),
          Text(
            v,
            style: GoogleFonts.notoSansBengali(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
