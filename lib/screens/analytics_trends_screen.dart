import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../utils/format_qty.dart';
import '../widgets/app_surface.dart';
import '../widgets/mess_session_builder.dart';

/// Simple 6-month trend cards for meal rate and spend.
class AnalyticsTrendsScreen extends StatefulWidget {
  const AnalyticsTrendsScreen({super.key});

  @override
  State<AnalyticsTrendsScreen> createState() => _AnalyticsTrendsScreenState();
}

class _AnalyticsTrendsScreenState extends State<AnalyticsTrendsScreen> {
  final _mealService = MealService();
  final _marketService = MarketService();
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month);
  }

  List<DateTime> get _months {
    return List.generate(6, (i) {
      return DateTime(_anchor.year, _anchor.month - i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: Text(
          s.analyticsTrends,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
      ),
      body: MessSessionBuilder(
        builder: (context, appUser, mess, members) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                s.lastMonthsTrend,
                style: appFont(
                  context: context,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ..._months.map((month) {
                return FutureBuilder<_MonthTrend>(
                  future: _loadTrend(mess.id, month),
                  builder: (context, snap) {
                    final t = snap.data;
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevated: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.monthLabel(month),
                            style: appFont(
                              context: context,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (t == null)
                            LinearProgressIndicator(
                              color: AppColors.primaryGreen,
                              backgroundColor: AppColors.featureGreenBg,
                            )
                          else ...[
                            AppKeyValueRow(
                              label: s.monthlyMeals,
                              value: formatQty(t.meals),
                            ),
                            AppKeyValueRow(
                              label: s.monthlyMarket,
                              value: formatTaka(t.spend),
                            ),
                            AppKeyValueRow(
                              label: s.mealRate,
                              value: formatTaka(t.rate),
                              bold: true,
                              valueColor: AppColors.darkGreen,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<_MonthTrend> _loadTrend(String messId, DateTime month) async {
    final mealsMap =
        await _mealService.watchMonthMealCounts(messId, month).first;
    final markets = await _marketService
        .watchMarkets(messId, yearMonth: yearMonthKey(month))
        .first;
    final meals = mealsMap.values.fold<double>(0, (a, b) => a + b);
    final spend = markets.fold<double>(0, (a, e) => a + e.amount);
    final rate = meals <= 0 ? 0.0 : spend / meals;
    return _MonthTrend(meals: meals, spend: spend, rate: rate);
  }
}

class _MonthTrend {
  const _MonthTrend({
    required this.meals,
    required this.spend,
    required this.rate,
  });
  final double meals;
  final double spend;
  final double rate;
}
