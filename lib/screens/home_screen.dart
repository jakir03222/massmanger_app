import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../l10n/app_strings.dart';
import '../models/market_entry.dart';
import '../models/meal_entry.dart';
import '../models/mess.dart';
import '../models/monthly_settlement.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../services/month_lock_service.dart';
import '../services/monthly_report_pdf_service.dart';
import '../services/monthly_settlement_service.dart';
import '../services/pdf_download_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_surface.dart';
import '../widgets/home_top_tab_bar.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';
import '../widgets/month_navigator.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: HomeTopTabBar.tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openTab(int index) {
    if (index < 0 || index >= _tabController.length) return;
    _tabController.animateTo(index);
  }

  List<Widget> get _pages {
    if (FeatureFlags.communityEnabled) {
      return [
        _HomeTab(onOpenTab: _openTab),
        const MealScreen(),
        const MarketHubScreen(),
        const CommunityHubScreen(embedded: true),
        const ReportScreen(),
        const SettingsScreen(),
      ];
    }
    return [
      _HomeTab(onOpenTab: _openTab),
      const MealScreen(),
      const MarketHubScreen(),
      const ReportScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            HomeTopTabBar(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

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
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  String _monthLabel(BuildContext context) =>
      AppStrings.of(context).monthLabel(_month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return isSameYearMonth(_month, now);
  }

  void _shiftMonth(DateTime next) {
    setState(() {
      _month = DateTime(next.year, next.month);
      _refreshTick++;
    });
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
      final s = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.savedToDownloads ? s.pdfSavedDownloads : s.pdfSaved,
            style: appFont(context: context),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).pdfFailed,
            style: appFont(context: context),
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

        return StreamBuilder<bool>(
          stream: MonthLockService().watchLocked(mess.id, month),
          builder: (context, lockSnap) {
            final monthLocked = lockSnap.data ?? false;

            return StreamBuilder<List<MealEntry>>(
              stream: _isCurrentMonth
                  ? _mealService.watchDayMeals(mess.id, today)
                  : Stream.value(const <MealEntry>[]),
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
                      key: ValueKey('home-report-$_refreshTick-$month'),
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
                        final s = AppStrings.of(context);
                        final monthLabel = _monthLabel(context);

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
                              const SizedBox(height: 12),
                              MonthNavigator(
                                month: _month,
                                locked: monthLocked,
                                onChanged: _shiftMonth,
                              ),
                              if (monthLocked) ...[
                                const SizedBox(height: 10),
                                MonthClosedBanner(
                                  monthLabel: monthLabel,
                                  isAdmin: isAdmin,
                                ),
                              ],
                              const SizedBox(height: 12),
                              _WelcomeBanner(
                                name: displayName,
                                monthLabel: monthLabel,
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppQuickAction(
                                        icon: Icons.restaurant_rounded,
                                        label: s.navMeal,
                                        onTap: () => widget.onOpenTab(1),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: AppQuickAction(
                                        icon: Icons.shopping_cart_rounded,
                                        label: s.navMarket,
                                        color: AppColors.marketOrange,
                                        onTap: () => widget.onOpenTab(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: AppQuickAction(
                                        icon: Icons.bar_chart_rounded,
                                        label: s.navReport,
                                        color: AppColors.actionBlueIcon,
                                        onTap: () => widget.onOpenTab(
                                          FeatureFlags.communityEnabled ? 4 : 3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAdmin && _isCurrentMonth) ...[
                                const SizedBox(height: 14),
                                _TodayRateCard(
                                  rate: todayMealRate,
                                  meals: todayMealTotal,
                                  spend: todaySpend,
                                  fmtMeals: _fmtMeals,
                                ),
                              ],
                              const SizedBox(height: 18),
                              AppSectionHeader(
                                title: isAdmin
                                    ? s.overallCount(monthLabel)
                                    : s.myCount(monthLabel),
                              ),
                              const SizedBox(height: 10),
                              if (loadingReport)
                                Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: _OverallGrid(
                                    isAdmin: isAdmin,
                                    members: members.length,
                                    monthMeals: report?.totalConsumeMeal ?? 0,
                                    monthSpend: isAdmin
                                        ? (report?.totalDeposit ??
                                            monthSpendAll)
                                        : myMarketTotal,
                                    mealRate: report?.mealRate ?? 0,
                                    fixedBills: report?.totalCookCost ?? 0,
                                    dueSpend: dueSpend,
                                    todayMeals:
                                        _isCurrentMonth ? todayMealTotal : 0,
                                    todaySpend:
                                        _isCurrentMonth ? todaySpend : 0,
                                    fmtMeals: _fmtMeals,
                                  ),
                                ),
                              if (isAdmin) ...[
                            const SizedBox(height: 18),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                s.monthEndAllMembers,
                                style: appFont(
                                  context: context,
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
                                s.smartPdfHint,
                                style: appFont(
                                  context: context,
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
                                        s.smartMonthlyPdf,
                                        style: appFont(
                                          context: context,
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
                                      side: BorderSide(
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
                                      s.bills,
                                      style: appFont(
                                        context: context,
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
                                  s.memberSummary,
                                  style: appFont(
                                    context: context,
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
                          AppSectionHeader(title: s.recentMarket),
                          const SizedBox(height: 10),
                          if (recentList.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: AppEmptyState(
                                icon: Icons.shopping_bag_outlined,
                                title: s.noMarketYetTitle,
                                subtitle: s.noMarketYetBody,
                                actionLabel: s.navMarket,
                                onAction: () => widget.onOpenTab(2),
                              ),
                            )
                          else
                            ...recentList.map(
                              (entry) => AppCard(
                                margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${entry.shopperName} · ${formatTaka(entry.amount)}',
                                        style: appFont(
                                          context: context,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      entry.dateKey,
                                      style: appFont(
                                        context: context,
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
                                s.myMarketTotal(formatTaka(myMarketTotal)),
                                style: appFont(
                                  context: context,
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
    final s = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bannerGreen,
            AppColors.darkGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.welcomeName(name),
            style: appFont(
              context: context,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.card,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatBnDate(DateTime.now())}  ·  $monthLabel',
            style: appFont(
              context: context,
              fontSize: 13,
              color: AppColors.card.withValues(alpha: 0.9),
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
    final s = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.featureGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
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
                  s.todayMealRate,
                  style: appFont(
                    context: context,
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  formatTaka(rate),
                  style: appFont(
                    context: context,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
                ),
                Text(
                  s.todayMealMarket(fmtMeals(meals), formatTaka(spend)),
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
    final s = AppStrings.of(context);
    final cards = <_StatTileData>[
      _StatTileData(s.todayMeals, fmtMeals(todayMeals), Icons.restaurant_rounded),
      _StatTileData(
        s.todayMarket,
        formatTaka(todaySpend),
        Icons.shopping_cart_outlined,
      ),
      _StatTileData(
        isAdmin ? s.monthlyMeals : s.myMonthlyMarket,
        isAdmin ? fmtMeals(monthMeals) : formatTaka(monthSpend),
        Icons.calendar_month_outlined,
      ),
      if (isAdmin) ...[
        _StatTileData(
          s.monthlyMarket,
          formatTaka(monthSpend),
          Icons.storefront_outlined,
        ),
        _StatTileData(
          s.monthlyMealRate,
          formatTaka(mealRate),
          Icons.payments_outlined,
        ),
        _StatTileData(
          s.monthlyBillsShort,
          formatTaka(fixedBills),
          Icons.receipt_long_outlined,
        ),
        _StatTileData(
          s.dueMarket,
          formatTaka(dueSpend),
          Icons.account_balance_wallet_outlined,
        ),
        _StatTileData(
          s.members,
          s.membersCount(members),
          Icons.groups_outlined,
        ),
      ] else ...[
        _StatTileData(
          s.members,
          s.membersCount(members),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.featureGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: AppColors.primaryGreen, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: appFont(
              context: context,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: appFont(
              context: context,
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
    final s = AppStrings.of(context);
    final net = row.netPayableReceivable;
    final payable = net < 0;
    final meals = row.consumeMeal % 1 == 0
        ? row.consumeMeal.toInt().toString()
        : row.consumeMeal.toStringAsFixed(1);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
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
                  style: appFont(
                    context: context,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.navMeal}: $meals  ·  ${s.market}: ${formatTaka(row.depositMoney)}',
                  style: appFont(
                    context: context,
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
                payable ? s.willPay : s.willReceive,
                style: appFont(
                  context: context,
                  fontSize: 11,
                  color: payable
                      ? const Color(0xFFC62828)
                      : AppColors.darkGreen,
                ),
              ),
              Text(
                formatTaka(payable ? -net : net),
                style: appFont(
                  context: context,
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
    final s = AppStrings.of(context);
    final mine = report.members.where((m) => m.member.uid == uid);
    if (mine.isEmpty) return const SizedBox.shrink();
    final row = mine.first;
    final net = row.netPayableReceivable;
    final payable = net < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          _kv(context, s.myMeals, fmtMeals(row.consumeMeal)),
          _kv(context, s.mealRate, formatTaka(row.mealRate)),
          _kv(context, s.mealCost, formatTaka(row.costOfMeal)),
          _kv(context, s.myMarket, formatTaka(row.depositMoney)),
          _kv(context, s.billShare, formatTaka(row.cookCost)),
          const Divider(height: 18),
          _kv(
            context,
            payable ? s.iMustPay : s.iWillGet,
            formatTaka(payable ? -net : net),
            bold: true,
            color: payable ? const Color(0xFFC62828) : AppColors.darkGreen,
          ),
        ],
      ),
    );
  }

  Widget _kv(
    BuildContext context,
    String k,
    String v, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            k,
            style: appFont(context: context, color: AppColors.textGrey),
          ),
          const Spacer(),
          Text(
            v,
            style: appFont(
              context: context,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
