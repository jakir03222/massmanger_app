import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/market_entry.dart';
import '../models/mess.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../services/month_lock_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';
import '../widgets/month_navigator.dart';
import 'meal_chart_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final _mealService = MealService();
  final _marketService = MarketService();
  late DateTime _month;

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
                    final mealCounts = mealCountSnap.data ?? {};
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FilledButton.icon(
                            onPressed: () => _openMealChart(
                              mess: mess,
                              members: visibleMembers,
                              canDownload: isAdmin,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.grid_on_rounded, size: 20),
                            label: Text(
                              isAdmin ? s.smartMealChart : s.myMealChart,
                              style: appFont(
                                context: context,
                                fontWeight: FontWeight.w700,
                              ),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            isAdmin
                                ? '${s.monthlyReportAll} · $monthLabel'
                                : '${s.myMonthlyReport} · $monthLabel',
                            style: appFont(
                              context: context,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!isAdmin)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            child: Text(
                              s.memberOnlyHint,
                              style: appFont(
                                context: context,
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Column(
                            children: [
                              if (isAdmin) ...[
                                _kv(s.totalMessMarket, formatTaka(totalSpend)),
                                _kv(s.totalMeals, fmtMeals(totalMeals)),
                                _kv(s.mealRate, formatTaka(rate)),
                              ] else ...[
                                _kv(s.myMarket, formatTaka(myMarket)),
                                _kv(s.myMeals, fmtMeals(myMeals)),
                                _kv(s.mealRate, formatTaka(rate)),
                                _kv(s.myExpense, formatTaka(myCost)),
                                _kv(s.myBalance, formatTaka(myBalance)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            isAdmin
                                ? s.allMembersAccounts
                                : s.myAccountDetail,
                            style: appFont(
                              context: context,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                          return Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppColors.borderGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: appFont(
                                    context: context,
                                    fontWeight: FontWeight.w700,
                                  ),
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
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            k,
            style: appFont(context: context, color: AppColors.textGrey),
          ),
          const Spacer(),
          Text(
            v,
            style: appFont(context: context, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
