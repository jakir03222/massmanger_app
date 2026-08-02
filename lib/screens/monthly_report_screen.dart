import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/market_entry.dart';
import '../models/member_payment.dart';
import '../models/mess.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../services/month_lock_service.dart';
import '../services/monthly_report_pdf_service.dart';
import '../services/monthly_settlement_service.dart';
import '../services/payment_service.dart';
import '../services/pdf_download_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_surface.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';
import '../widgets/month_navigator.dart';
import '../widgets/payment_status_chip.dart';
import 'meal_chart_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final _mealService = MealService();
  final _marketService = MarketService();
  final _paymentService = PaymentService();
  final _settlementService = MonthlySettlementService();
  final _pdfService = MonthlyReportPdfService();
  final _pdfDownload = PdfDownloadService();
  late DateTime _month;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(DateTime next) {
    setState(() {
      _month = DateTime(next.year, next.month);
    });
  }

  void _openMealChart({
    required Mess mess,
    required List<MessMember> members,
    required bool canDownload,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MealChartScreen(
          mess: mess,
          members: members,
          month: _month,
          canDownload: canDownload,
        ),
      ),
    );
  }

  Future<void> _exportSmartInvoice({
    required Mess mess,
    required List<MessMember> members,
  }) async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
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
      debugPrint('[InvoicePDF] failed: $e\n$st');
      if (!mounted) return;
      showAppSnack(context, AppStrings.of(context).pdfFailed);
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  String _monthLabel(BuildContext context) =>
      AppStrings.of(context).monthLabel(_month);

  @override
  Widget build(BuildContext context) {
    final month = yearMonthKey(_month);
    final s = AppStrings.of(context);
    final monthLabel = _monthLabel(context);

    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((e) => e.uid == appUser.uid);
        final isAdmin = matched.isNotEmpty && matched.first.isAdmin;
        final me = matched.isNotEmpty ? matched.first : null;

        return StreamBuilder<bool>(
          stream: MonthLockService().watchLocked(mess.id, month),
          builder: (context, lockSnap) {
            final monthLocked = lockSnap.data ?? false;

            return StreamBuilder<List<MarketEntry>>(
              stream: _marketService.watchMarkets(mess.id, yearMonth: month),
              builder: (context, marketSnap) {
                final allMarkets = marketSnap.data ?? [];
                final totalSpend =
                    allMarkets.fold<double>(0, (s, e) => s + e.amount);

                final visibleMembers = isAdmin
                    ? members
                    : members.where((m) => m.uid == appUser.uid).toList();

                return StreamBuilder<Map<String, double>>(
                  stream: _mealService.watchMonthMealCounts(mess.id, _month),
                  builder: (context, mealCountSnap) {
                    return StreamBuilder<Map<String, MemberPayment>>(
                      stream: _paymentService.watchMonthPayments(
                        messId: mess.id,
                        yearMonth: month,
                      ),
                      builder: (context, paySnap) {
                    final mealCounts = mealCountSnap.data ?? {};
                    final payments = paySnap.data ?? {};
                    final totalMeals =
                        mealCounts.values.fold<double>(0, (s, v) => s + v);
                    final rate =
                        totalMeals == 0 ? 0.0 : totalSpend / totalMeals;

                    String fmtMeals(double n) => n % 1 == 0
                        ? n.toInt().toString()
                        : n.toStringAsFixed(1);

                    final myMeals = mealCounts[appUser.uid] ?? 0;
                    final myMarket = allMarkets
                        .where((e) => e.shopperUid == appUser.uid)
                        .fold<double>(0, (s, e) => s + e.amount);
                    final myCost = myMeals * rate;
                    final myBalance = myMarket - myCost;
                    final myPaid = payments[appUser.uid]?.paid == true;

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 20),
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
                        if (isAdmin) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: AppPrimaryButton(
                              label: s.smartInvoiceReport,
                              icon: Icons.picture_as_pdf_outlined,
                              height: 48,
                              loading: _exportingPdf,
                              onPressed: _exportingPdf
                                  ? null
                                  : () => _exportSmartInvoice(
                                        mess: mess,
                                        members: members,
                                      ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                            child: Text(
                              s.smartInvoiceReportHint,
                              textAlign: TextAlign.center,
                              style: appFont(
                                context: context,
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AppPrimaryButton(
                            label: isAdmin ? s.smartMealChart : s.myMealChart,
                            icon: Icons.grid_on_rounded,
                            height: 48,
                            onPressed: () => _openMealChart(
                              mess: mess,
                              members: visibleMembers,
                              canDownload: isAdmin,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                          child: Text(
                            isAdmin ? s.mealChartPdfExcelHint : s.myBldSheet,
                            textAlign: TextAlign.center,
                            style: appFont(
                              context: context,
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppSectionHeader(
                          title: isAdmin
                              ? '${s.monthlyReportAll} · $monthLabel'
                              : '${s.myMonthlyReport} · $monthLabel',
                          subtitle: isAdmin ? null : s.memberOnlyHint,
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          margin: AppSpace.pageH,
                          padding: const EdgeInsets.all(16),
                          elevated: false,
                          child: Column(
                            children: [
                              if (isAdmin) ...[
                                AppKeyValueRow(
                                  label: s.totalMessMarket,
                                  value: formatTaka(totalSpend),
                                ),
                                AppKeyValueRow(
                                  label: s.totalMeals,
                                  value: fmtMeals(totalMeals),
                                ),
                                AppKeyValueRow(
                                  label: s.mealRate,
                                  value: formatTaka(rate),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.payments,
                                        style: appFont(
                                          context: context,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    PaymentStatusChip(paid: myPaid),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AppKeyValueRow(
                                  label: s.myMarket,
                                  value: formatTaka(myMarket),
                                ),
                                AppKeyValueRow(
                                  label: s.myMeals,
                                  value: fmtMeals(myMeals),
                                ),
                                AppKeyValueRow(
                                  label: s.mealRate,
                                  value: formatTaka(rate),
                                ),
                                AppKeyValueRow(
                                  label: s.myExpense,
                                  value: formatTaka(myCost),
                                ),
                                AppKeyValueRow(
                                  label: s.myBalance,
                                  value: formatTaka(myBalance),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppSectionHeader(
                          title: isAdmin
                              ? s.allMembersAccounts
                              : s.myAccountDetail,
                        ),
                        const SizedBox(height: 10),
                        if (mealCountSnap.connectionState ==
                            ConnectionState.waiting)
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ...visibleMembers.map((m) {
                          final marketSpend = allMarkets
                              .where((e) => e.shopperUid == m.uid)
                              .fold<double>(0, (s, e) => s + e.amount);
                          final meals = mealCounts[m.uid] ?? 0;
                          final cost = meals * rate;
                          final balance = marketSpend - cost;
                          final paid = payments[m.uid]?.paid == true;
                          return AppCard(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            padding: const EdgeInsets.all(14),
                            elevated: false,
                            onTap: !isAdmin || monthLocked
                                ? null
                                : () => showMarkPaymentDialog(
                                      context: context,
                                      messId: mess.id,
                                      yearMonth: month,
                                      memberUid: m.uid,
                                      memberName: m.name,
                                      adminUid: appUser.uid,
                                      currentlyPaid: paid,
                                      existing: payments[m.uid],
                                    ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.name,
                                        style: appFont(
                                          context: context,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    PaymentStatusChip(paid: paid, compact: true),
                                  ],
                                ),
                                if (me != null &&
                                    m.uid == me.uid &&
                                    !isAdmin)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      s.you,
                                      style: appFont(
                                        context: context,
                                        fontSize: 11,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  '${s.navMeal}: ${fmtMeals(meals)}  •  ${s.market}: ${formatTaka(marketSpend)}  •  ${s.balance}: ${formatTaka(balance)}',
                                  style: appFont(
                                    context: context,
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
