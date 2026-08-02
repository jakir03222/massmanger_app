import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/market_entry.dart';
import '../models/meal_entry.dart';
import '../models/member_payment.dart';
import '../models/mess.dart';
import '../models/monthly_settlement.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../services/month_close_pack_service.dart';
import '../services/month_lock_service.dart';
import '../services/monthly_report_pdf_service.dart';
import '../services/monthly_settlement_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../services/pdf_download_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_feedback.dart';
import '../utils/format_qty.dart';
import '../utils/mess_member_lookup.dart';
import '../widgets/app_surface.dart';
import '../widgets/home_top_tab_bar.dart';
import '../widgets/mess_session_builder.dart';
import '../widgets/month_navigator.dart';
import '../widgets/payment_status_chip.dart';
import 'bazaar_schedule_screen.dart';
import 'market_hub_screen.dart';
import 'meal_screen.dart';
import 'mess_bills_screen.dart';
import 'notification_inbox_screen.dart';
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
    _tabController = TabController(length: HomeTopTabBar.tabCount, vsync: this);
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

  List<Widget> get _pages => [
    _HomeTab(onOpenTab: _openTab),
    const MealScreen(),
    const MarketHubScreen(),
    const ReportScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            HomeTopTabBar(controller: _tabController),
            Expanded(
              child: TabBarView(controller: _tabController, children: _pages),
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
  final _paymentService = PaymentService();
  final _pdfService = MonthlyReportPdfService();
  final _pdfDownload = PdfDownloadService();
  final _packService = MonthClosePackService();
  final _notifications = NotificationService();

  bool _exporting = false;
  bool _sharingPack = false;
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
        filename: 'invoice-report-${yearMonthKey(_month)}.pdf',
      );
      if (!mounted) return;
      final s = AppStrings.of(context);
      showAppSnack(
        context,
        result.savedToDownloads ? s.pdfSavedDownloads : s.pdfSaved,
      );
    } catch (e, st) {
      debugPrint('[InvoicePDF] home export failed: $e\n$st');
      if (!mounted) return;
      showAppSnack(context, AppStrings.of(context).pdfFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _shareMonthPack({
    required Mess mess,
    required List<MessMember> members,
  }) async {
    if (_sharingPack) return;
    setState(() => _sharingPack = true);
    try {
      final report = await _settlementService.buildReport(
        mess: mess,
        members: members,
        month: _month,
      );
      final payments = await _paymentService
          .watchMonthPayments(messId: mess.id, yearMonth: yearMonthKey(_month))
          .first;
      if (!mounted) return;
      await _packService.sharePack(
        report: report,
        members: members,
        payments: payments,
        isBengali: AppStrings.of(context).isBengali,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, '$e');
    } finally {
      if (mounted) setState(() => _sharingPack = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final today = dateKey(DateTime.now());
        final month = yearMonthKey(_month);
        final me = members.byUid(appUser.uid);
        final isAdmin = me?.isAdmin ?? false;
        final displayName = me?.name ?? (appUser.name ?? appUser.email);

        return StreamBuilder<bool>(
          stream: MonthLockService().watchLocked(mess.id, month),
          builder: (context, lockSnap) {
            final monthLocked = lockSnap.data ?? false;

            return StreamBuilder<List<MealEntry>>(
              stream: _isCurrentMonth
                  ? _mealService.watchDayMeals(mess.id, today)
                  : Stream.value(const <MealEntry>[]),
              builder: (context, mealSnap) {
                final todayMeals = (mealSnap.data ?? [])
                    .where((e) => e.isApproved)
                    .toList();
                final todayMealTotal = todayMeals.fold<double>(
                  0,
                  (s, e) => s + e.mealCount,
                );

                return StreamBuilder<List<MarketEntry>>(
                  stream: _marketService.watchMarkets(
                    mess.id,
                    yearMonth: month,
                  ),
                  builder: (context, marketSnap) {
                    final markets = marketSnap.data ?? [];
                    final monthSpendAll = markets.fold<double>(
                      0,
                      (s, e) => s + e.amount,
                    );
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
                        return StreamBuilder<Map<String, MemberPayment>>(
                          stream: _paymentService.watchMonthPayments(
                            messId: mess.id,
                            yearMonth: month,
                          ),
                          builder: (context, paySnap) {
                            final report = reportSnap.data;
                            final payments = paySnap.data ?? {};
                            final loadingReport =
                                reportSnap.connectionState ==
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
                                padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
                                children: [
                                  _HomeHero(
                                    messName: mess.name,
                                    location: mess.location,
                                    userName: displayName,
                                    roleLabel:
                                        me?.roleLabel(bn: s.isBengali) ??
                                        s.member,
                                    monthLabel: monthLabel,
                                    uid: appUser.uid,
                                    notifications: _notifications,
                                  ),
                                  const SizedBox(height: 12),
                                  _QuickActionsRow(
                                    onMeal: () => widget.onOpenTab(1),
                                    onBazaarDates: () {
                                      final label = AppStrings.of(
                                        context,
                                      ).bazaarDates;
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (ctx) => Scaffold(
                                            backgroundColor:
                                                AppColors.pageBackground,
                                            appBar: AppBar(
                                              backgroundColor:
                                                  AppColors.pageBackground,
                                              title: Text(
                                                label,
                                                style: appFont(
                                                  context: ctx,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            body: const BazaarScheduleScreen(),
                                          ),
                                        ),
                                      );
                                    },
                                    onNotifications: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const NotificationInboxScreen(),
                                        ),
                                      );
                                    },
                                    onReport: () => widget.onOpenTab(3),
                                  ),
                                  if (_isCurrentMonth) ...[
                                    const SizedBox(height: 12),
                                    _TodaySnapshot(
                                      meals: todayMealTotal,
                                      spend: todaySpend,
                                      rate: isAdmin ? todayMealRate : null,
                                      fmtMeals: formatQty,
                                    ),
                                  ],
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
                                  const SizedBox(height: 16),
                                  AppSectionHeader(
                                    title: isAdmin
                                        ? s.overallCount(monthLabel)
                                        : s.myCount(monthLabel),
                                  ),
                                  const SizedBox(height: 10),
                                  if (loadingReport)
                                    Padding(
                                      padding: const EdgeInsets.all(28),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: AppSpace.pageH,
                                      child: _OverallGrid(
                                        isAdmin: isAdmin,
                                        members: members.length,
                                        monthMeals:
                                            report?.totalConsumeMeal ?? 0,
                                        monthSpend: isAdmin
                                            ? (report?.totalDeposit ??
                                                  monthSpendAll)
                                            : myMarketTotal,
                                        mealRate: report?.mealRate ?? 0,
                                        fixedBills: report?.totalCookCost ?? 0,
                                        dueSpend: dueSpend,
                                        todayMeals: _isCurrentMonth
                                            ? todayMealTotal
                                            : 0,
                                        todaySpend: _isCurrentMonth
                                            ? todaySpend
                                            : 0,
                                        fmtMeals: formatQty,
                                      ),
                                    ),
                                  if (isAdmin) ...[
                                    const SizedBox(height: 16),
                                    _AdminActionsCard(
                                      exporting: _exporting,
                                      sharingPack: _sharingPack,
                                      onPdf: () => _exportMonthPdf(
                                        mess: mess,
                                        members: members,
                                      ),
                                      onSharePack: () => _shareMonthPack(
                                        mess: mess,
                                        members: members,
                                      ),
                                      onBills: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MessBillsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (report != null) ...[
                                      const SizedBox(height: 16),
                                      AppSectionHeader(title: s.memberSummary),
                                      const SizedBox(height: 10),
                                      _MemberSummaryList(
                                        members: report.members,
                                        payments: payments,
                                        isAdmin: isAdmin,
                                        messId: mess.id,
                                        yearMonth: month,
                                        adminUid: appUser.uid,
                                        monthLocked: monthLocked,
                                      ),
                                    ],
                                  ] else ...[
                                    const SizedBox(height: 14),
                                    if (report != null)
                                      _MyMonthCard(
                                        report: report,
                                        uid: appUser.uid,
                                        fmtMeals: formatQty,
                                        paid:
                                            payments[appUser.uid]?.paid == true,
                                      ),
                                  ],
                                  const SizedBox(height: 16),
                                  AppSectionHeader(
                                    title: s.recentMarket,
                                    trailing: InkWell(
                                      onTap: () => widget.onOpenTab(2),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              s.navMarket,
                                              style: appFont(
                                                context: context,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryGreen,
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 18,
                                              color: AppColors.primaryGreen,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (recentList.isEmpty)
                                    Padding(
                                      padding: AppSpace.pageH,
                                      child: AppEmptyState(
                                        icon: Icons.shopping_bag_outlined,
                                        title: s.noMarketYetTitle,
                                        subtitle: s.noMarketYetBody,
                                        actionLabel: s.navMarket,
                                        onAction: () => widget.onOpenTab(2),
                                      ),
                                    )
                                  else
                                    _RecentMarketList(
                                      entries: recentList,
                                      footer: !isAdmin
                                          ? s.myMarketTotal(
                                              formatTaka(myMarketTotal),
                                            )
                                          : null,
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
      },
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.messName,
    required this.location,
    required this.userName,
    required this.roleLabel,
    required this.monthLabel,
    required this.uid,
    required this.notifications,
  });

  final String messName;
  final String location;
  final String userName;
  final String roleLabel;
  final String monthLabel;
  final String uid;
  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final displayMess = messName.trim().isEmpty ? s.appTitle : messName.trim();
    final short = userName.trim().isEmpty
        ? '—'
        : userName.trim().split(RegExp(r'\s+')).first;

    return AppCard(
      margin: AppSpace.pageH,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              _initial(short),
              style: appFont(
                context: context,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.welcomeName(userName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(
                    context: context,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayMess,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(
                    context: context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.featureGreenBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        roleLabel,
                        style: appFont(
                          context: context,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ),
                    Text(
                      [
                        if (location.trim().isNotEmpty) location.trim(),
                        formatBnDate(DateTime.now()),
                        monthLabel,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appFont(
                        context: context,
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StreamBuilder<int>(
            stream: notifications.watchUnreadCount(uid),
            builder: (context, snap) {
              final unread = snap.data ?? 0;
              return IconButton(
                tooltip: s.notificationsInbox,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationInboxScreen(),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 9 ? '9+' : '$unread'),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.headerIcon,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onMeal,
    required this.onBazaarDates,
    required this.onNotifications,
    required this.onReport,
  });

  final VoidCallback onMeal;
  final VoidCallback onBazaarDates;
  final VoidCallback onNotifications;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppCard(
      margin: AppSpace.pageH,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      elevated: false,
      child: Row(
        children: [
          Expanded(
            child: _QuickChip(
              icon: Icons.restaurant_rounded,
              label: s.navMeal,
              color: AppColors.primaryGreen,
              onTap: onMeal,
            ),
          ),
          Expanded(
            child: _QuickChip(
              icon: Icons.event_available_rounded,
              label: s.bazaarDates,
              color: AppColors.marketOrange,
              onTap: onBazaarDates,
            ),
          ),
          Expanded(
            child: _QuickChip(
              icon: Icons.notifications_outlined,
              label: s.notificationsInbox,
              color: AppColors.actionBlueIcon,
              onTap: onNotifications,
            ),
          ),
          Expanded(
            child: _QuickChip(
              icon: Icons.bar_chart_rounded,
              label: s.navReport,
              color: AppColors.darkGreen,
              onTap: onReport,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appFont(
                context: context,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySnapshot extends StatelessWidget {
  const _TodaySnapshot({
    required this.meals,
    required this.spend,
    required this.fmtMeals,
    this.rate,
  });

  final double meals;
  final double spend;
  final double? rate;
  final String Function(double) fmtMeals;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final showRate = rate != null;

    return AppCard(
      margin: AppSpace.pageH,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.featureGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.today,
                  style: appFont(
                    context: context,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatBnDate(DateTime.now()),
                style: appFont(
                  context: context,
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SnapshotCell(
                  icon: Icons.restaurant_rounded,
                  label: s.todayMeals,
                  value: fmtMeals(meals),
                  color: AppColors.primaryGreen,
                ),
              ),
              _SnapshotDivider(),
              Expanded(
                child: _SnapshotCell(
                  icon: Icons.shopping_cart_outlined,
                  label: s.todayMarket,
                  value: formatTaka(spend),
                  color: AppColors.marketOrange,
                ),
              ),
              if (showRate) ...[
                _SnapshotDivider(),
                Expanded(
                  child: _SnapshotCell(
                    icon: Icons.payments_outlined,
                    label: s.todayMealRate,
                    value: formatTaka(rate!),
                    color: AppColors.actionBlueIcon,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: AppColors.borderGrey.withValues(alpha: 0.8),
    );
  }
}

class _SnapshotCell extends StatelessWidget {
  const _SnapshotCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: appFont(
              context: context,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: appFont(
              context: context,
              fontSize: 10,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionsCard extends StatelessWidget {
  const _AdminActionsCard({
    required this.exporting,
    required this.sharingPack,
    required this.onPdf,
    required this.onSharePack,
    required this.onBills,
  });

  final bool exporting;
  final bool sharingPack;
  final VoidCallback onPdf;
  final VoidCallback onSharePack;
  final VoidCallback onBills;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppCard(
      margin: AppSpace.pageH,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.monthEndAllMembers,
            style: appFont(
              context: context,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.smartPdfHint,
            style: appFont(
              context: context,
              fontSize: 12,
              height: 1.35,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppPrimaryButton(
                  label: s.smartMonthlyPdf,
                  loading: exporting,
                  icon: Icons.picture_as_pdf_outlined,
                  height: 46,
                  onPressed: onPdf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AppOutlinedButton(
                  label: s.bills,
                  height: 46,
                  onPressed: onBills,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppOutlinedButton(
            label: sharingPack ? '...' : s.monthClosePack,
            height: 44,
            onPressed: sharingPack ? null : onSharePack,
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
      if (!isAdmin) ...[
        _StatTileData(
          s.todayMeals,
          fmtMeals(todayMeals),
          Icons.restaurant_rounded,
          AppColors.primaryGreen,
        ),
        _StatTileData(
          s.todayMarket,
          formatTaka(todaySpend),
          Icons.shopping_cart_outlined,
          AppColors.marketOrange,
        ),
      ],
      _StatTileData(
        isAdmin ? s.monthlyMeals : s.myMonthlyMarket,
        isAdmin ? fmtMeals(monthMeals) : formatTaka(monthSpend),
        Icons.calendar_month_outlined,
        AppColors.primaryGreen,
      ),
      if (isAdmin) ...[
        _StatTileData(
          s.monthlyMarket,
          formatTaka(monthSpend),
          Icons.storefront_outlined,
          AppColors.marketOrange,
        ),
        _StatTileData(
          s.monthlyMealRate,
          formatTaka(mealRate),
          Icons.payments_outlined,
          AppColors.actionBlueIcon,
        ),
        _StatTileData(
          s.monthlyBillsShort,
          formatTaka(fixedBills),
          Icons.receipt_long_outlined,
          AppColors.statusOrange,
        ),
        _StatTileData(
          s.dueMarket,
          formatTaka(dueSpend),
          Icons.account_balance_wallet_outlined,
          AppColors.monthRed,
        ),
      ],
      _StatTileData(
        s.members,
        s.membersCount(members),
        Icons.groups_outlined,
        AppColors.actionBlueIcon,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in cards)
              SizedBox(
                width: width,
                child: _StatTile(data: c),
              ),
          ],
        );
      },
    );
  }
}

class _StatTileData {
  const _StatTileData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});
  final _StatTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, color: data.color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appFont(
              context: context,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: appFont(
              context: context,
              fontSize: 11,
              height: 1.25,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSummaryList extends StatelessWidget {
  const _MemberSummaryList({
    required this.members,
    required this.payments,
    required this.isAdmin,
    required this.messId,
    required this.yearMonth,
    required this.adminUid,
    required this.monthLocked,
  });

  final List<MemberMonthlySettlement> members;
  final Map<String, MemberPayment> payments;
  final bool isAdmin;
  final String messId;
  final String yearMonth;
  final String adminUid;
  final bool monthLocked;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: AppSpace.pageH,
      padding: EdgeInsets.zero,
      elevated: false,
      child: Column(
        children: [
          for (var i = 0; i < members.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderGrey.withValues(alpha: 0.7),
              ),
            _MemberBalanceRow(
              row: members[i],
              payment: payments[members[i].member.uid],
              isAdmin: isAdmin,
              messId: messId,
              yearMonth: yearMonth,
              adminUid: adminUid,
              monthLocked: monthLocked,
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberBalanceRow extends StatelessWidget {
  const _MemberBalanceRow({
    required this.row,
    required this.payment,
    required this.isAdmin,
    required this.messId,
    required this.yearMonth,
    required this.adminUid,
    required this.monthLocked,
  });

  final MemberMonthlySettlement row;
  final MemberPayment? payment;
  final bool isAdmin;
  final String messId;
  final String yearMonth;
  final String adminUid;
  final bool monthLocked;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final net = row.netPayableReceivable;
    final payable = net < 0;
    final meals = row.consumeMeal % 1 == 0
        ? row.consumeMeal.toInt().toString()
        : row.consumeMeal.toStringAsFixed(1);
    final name = row.member.name.trim().isEmpty ? '?' : row.member.name.trim();
    final amountColor = payable ? AppColors.monthRed : AppColors.darkGreen;
    final paid = payment?.paid == true;

    return InkWell(
      onTap: !isAdmin || monthLocked
          ? null
          : () => showMarkPaymentDialog(
              context: context,
              messId: messId,
              yearMonth: yearMonth,
              memberUid: row.member.uid,
              memberName: name,
              adminUid: adminUid,
              currentlyPaid: paid,
              existing: payment,
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.featureGreenBg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                _initial(name),
                style: appFont(
                  context: context,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appFont(
                            context: context,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      PaymentStatusChip(paid: paid, compact: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.navMeal}: $meals  ·  ${s.market}: ${formatTaka(row.depositMoney)}',
                    style: appFont(
                      context: context,
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  payable ? s.willPay : s.willReceive,
                  style: appFont(
                    context: context,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatTaka(payable ? -net : net),
                  style: appFont(
                    context: context,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyMonthCard extends StatelessWidget {
  const _MyMonthCard({
    required this.report,
    required this.uid,
    required this.fmtMeals,
    required this.paid,
  });

  final MonthlySettlementReport report;
  final String uid;
  final String Function(double) fmtMeals;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final mine = report.members.where((m) => m.member.uid == uid);
    if (mine.isEmpty) return const SizedBox.shrink();
    final row = mine.first;
    final net = row.netPayableReceivable;
    final payable = net < 0;

    return AppCard(
      margin: AppSpace.pageH,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.myAccountDetail,
                  style: appFont(
                    context: context,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PaymentStatusChip(paid: paid),
            ],
          ),
          const SizedBox(height: 10),
          AppKeyValueRow(label: s.myMeals, value: fmtMeals(row.consumeMeal)),
          AppKeyValueRow(label: s.mealRate, value: formatTaka(row.mealRate)),
          AppKeyValueRow(label: s.mealCost, value: formatTaka(row.costOfMeal)),
          AppKeyValueRow(
            label: s.myMarket,
            value: formatTaka(row.depositMoney),
          ),
          AppKeyValueRow(label: s.billShare, value: formatTaka(row.cookCost)),
          const Divider(height: 20),
          AppKeyValueRow(
            label: payable ? s.iMustPay : s.iWillGet,
            value: formatTaka(payable ? -net : net),
            bold: true,
            valueColor: payable ? AppColors.monthRed : AppColors.darkGreen,
          ),
        ],
      ),
    );
  }
}

class _RecentMarketList extends StatelessWidget {
  const _RecentMarketList({required this.entries, this.footer});

  final List<MarketEntry> entries;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: AppSpace.pageH,
      padding: EdgeInsets.zero,
      elevated: false,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 62,
                color: AppColors.borderGrey.withValues(alpha: 0.7),
              ),
            _RecentMarketRow(entry: entries[i]),
          ],
          if (footer != null) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderGrey.withValues(alpha: 0.7),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  footer!,
                  style: appFont(
                    context: context,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentMarketRow extends StatelessWidget {
  const _RecentMarketRow({required this.entry});

  final MarketEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.featureOrangeBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.marketOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.shopperName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(context: context, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
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
          Text(
            formatTaka(entry.amount),
            style: appFont(
              context: context,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}
