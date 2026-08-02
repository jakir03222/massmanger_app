import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/market_entry.dart';
import '../models/meal_entry.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../utils/format_qty.dart';
import '../utils/mess_member_lookup.dart';
import '../widgets/app_surface.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final _mealService = MealService();
  final _marketService = MarketService();
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _day.year == now.year &&
        _day.month == now.month &&
        _day.day == now.day;
  }

  void _shiftDay(int delta) {
    setState(() => _day = _day.add(Duration(days: delta)));
  }

  @override
  Widget build(BuildContext context) {
    final day = dateKey(_day);
    final s = AppStrings.of(context);

    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final isAdmin = members.isAdminUid(appUser.uid);

        return StreamBuilder<List<MealEntry>>(
          stream: _mealService.watchDayMeals(mess.id, day),
          builder: (context, mealSnap) {
            final allMeals =
                (mealSnap.data ?? []).where((e) => e.isApproved).toList();
            final meals = isAdmin
                ? allMeals
                : allMeals.where((e) => e.uid == appUser.uid).toList();

            final morning = meals
                .where((e) => e.morning)
                .fold<double>(0, (s, e) => s + e.rateValue);
            final evening = meals
                .where((e) => e.evening)
                .fold<double>(0, (s, e) => s + e.rateValue);
            final night = meals
                .where((e) => e.night)
                .fold<double>(0, (s, e) => s + e.rateValue);
            final rateTotal = meals
                .where((e) => e.isRate)
                .fold<double>(0, (s, e) => s + e.rateValue);
            final myMealTotal =
                meals.fold<double>(0, (s, e) => s + e.mealCount);

            // সব মেম্বার (অ্যাডমিন মিল রেট হিসাবের জন্য)
            final allMembersMealTotal =
                allMeals.fold<double>(0, (s, e) => s + e.mealCount);

            return StreamBuilder<List<MarketEntry>>(
              stream: _marketService.watchMarketsForDay(mess.id, day),
              builder: (context, marketSnap) {
                final allMarkets = marketSnap.data ?? [];
                final markets = isAdmin
                    ? allMarkets
                    : allMarkets
                        .where((e) => e.shopperUid == appUser.uid)
                        .toList();
                final spend = markets.fold<double>(0, (s, e) => s + e.amount);
                final allSpend =
                    allMarkets.fold<double>(0, (s, e) => s + e.amount);
                final dayMealRate = allMembersMealTotal == 0
                    ? 0.0
                    : allSpend / allMembersMealTotal;
                final attendanceMembers =
                    members.visibleFor(uid: appUser.uid, isAdmin: isAdmin);

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    MessAppHeader(title: mess.name, subtitle: mess.location),
                    const SizedBox(height: 12),
                    _DaySelector(
                      label: formatBnDate(_day),
                      onPrev: () => _shiftDay(-1),
                      onNext: _isToday ? null : () => _shiftDay(1),
                    ),
                    const SizedBox(height: 14),
                    AppSectionHeader(
                      title: isAdmin ? s.dailyReportAll : s.myDailyReport,
                      subtitle: isAdmin ? null : s.myDailyReportHint,
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      _AdminMealRateCard(
                        totalMeals: allMembersMealTotal,
                        totalSpend: allSpend,
                        mealRate: dayMealRate,
                        fmtMeals: formatQty,
                      ),
                    ],
                    const SizedBox(height: 14),
                    AppCard(
                      margin: AppSpace.pageH,
                      padding: const EdgeInsets.all(16),
                      elevated: false,
                      child: Column(
                        children: [
                          AppKeyValueRow(
                            label: isAdmin ? s.todayMarketAdmin : s.myMarket,
                            value: formatTaka(spend),
                          ),
                          if (isAdmin)
                            AppKeyValueRow(
                              label: s.totalMealsAllMembers,
                              value: formatQty(allMembersMealTotal),
                            ),
                          if (!isAdmin)
                            AppKeyValueRow(
                              label: s.myTotalMeals,
                              value: formatQty(myMealTotal),
                            ),
                          AppKeyValueRow(
                            label: isAdmin ? s.morningMeals : s.myMorning,
                            value: formatQty(morning),
                          ),
                          AppKeyValueRow(
                            label: isAdmin ? s.eveningMeals : s.myEvening,
                            value: formatQty(evening),
                          ),
                          AppKeyValueRow(
                            label: isAdmin ? s.nightMeals : s.myNight,
                            value: formatQty(night),
                          ),
                          AppKeyValueRow(
                            label: isAdmin ? s.rateMeal : s.myRate,
                            value: formatQty(rateTotal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppSectionHeader(
                      title: isAdmin
                          ? s.allMembersMealRateCalc
                          : s.myAttendance,
                    ),
                    const SizedBox(height: 10),
                    ...attendanceMembers.map((m) {
                      final e = meals.where((x) => x.uid == m.uid);
                      final mMorning = e
                          .where((x) => x.morning)
                          .fold<double>(0, (s, x) => s + x.rateValue);
                      final mEvening = e
                          .where((x) => x.evening)
                          .fold<double>(0, (s, x) => s + x.rateValue);
                      final mNight = e
                          .where((x) => x.night)
                          .fold<double>(0, (s, x) => s + x.rateValue);
                      final mRate = e
                          .where((x) => x.isRate)
                          .fold<double>(0, (s, x) => s + x.rateValue);
                      final memberMeals =
                          e.fold<double>(0, (s, x) => s + x.mealCount);
                      final memberCost = memberMeals * dayMealRate;
                      return AppCard(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        padding: const EdgeInsets.all(14),
                        elevated: false,
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
                            const SizedBox(height: 4),
                            Text(
                              s.mealDayTotals(
                                formatQty(mMorning),
                                formatQty(mEvening),
                                formatQty(mNight),
                                formatQty(mRate),
                              ),
                              style: appFont(
                                context: context,
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(height: 6),
                              Text(
                                s.totalMealsAndCost(
                                  formatQty(memberMeals),
                                  formatTaka(memberCost),
                                ),
                                style: appFont(
                                  context: context,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    if (markets.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      AppSectionHeader(
                        title: isAdmin ? s.dayShoppers : s.myMarketList,
                      ),
                      const SizedBox(height: 8),
                      ...markets.map(
                        (e) => AppCard(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          elevated: false,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.shopperName,
                                      style: appFont(
                                        context: context,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (e.dateKey.isNotEmpty)
                                      Text(
                                        e.dateKey,
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
                                formatTaka(e.amount),
                                style: appFont(
                                  context: context,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminMealRateCard extends StatelessWidget {
  const _AdminMealRateCard({
    required this.totalMeals,
    required this.totalSpend,
    required this.mealRate,
    required this.fmtMeals,
  });

  final double totalMeals;
  final double totalSpend;
  final double mealRate;
  final String Function(double) fmtMeals;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.todayMealRateAllMembers,
            style: appFont(
              context: context,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatTaka(mealRate),
            style: appFont(
              context: context,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.marketDividedByMeals(
              formatTaka(totalSpend),
              fmtMeals(totalMeals),
            ),
            style: appFont(
              context: context,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: AppSpace.pageH,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevated: false,
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: onNext == null
                  ? AppColors.borderGrey
                  : AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
