import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_entry.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mealService = MealService();
    final marketService = MarketService();
    final now = DateTime.now();
    final month = yearMonthKey(now);

    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((e) => e.uid == appUser.uid);
        final isAdmin = matched.isNotEmpty && matched.first.isAdmin;
        final me = matched.isNotEmpty ? matched.first : null;

        return StreamBuilder<List<MarketEntry>>(
          stream: marketService.watchMarkets(mess.id, yearMonth: month),
          builder: (context, marketSnap) {
            final allMarkets = marketSnap.data ?? [];
            final totalSpend =
                allMarkets.fold<double>(0, (s, e) => s + e.amount);

            final visibleMembers = isAdmin
                ? members
                : members.where((m) => m.uid == appUser.uid).toList();

            return FutureBuilder<Map<String, double>>(
              future: _monthMealCounts(mealService, mess.id, now),
              builder: (context, mealCountSnap) {
                final mealCounts = mealCountSnap.data ?? {};
                final totalMeals =
                    mealCounts.values.fold<double>(0, (s, v) => s + v);
                final rate = totalMeals == 0 ? 0.0 : totalSpend / totalMeals;

                String fmtMeals(double n) =>
                    n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

                final myMeals = mealCounts[appUser.uid] ?? 0;
                final myMarket = allMarkets
                    .where((e) => e.shopperUid == appUser.uid)
                    .fold<double>(0, (s, e) => s + e.amount);
                final myCost = myMeals * rate;
                final myBalance = myMarket - myCost;

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    MessAppHeader(title: mess.name, subtitle: mess.location),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        isAdmin
                            ? 'মাসিক রিপোর্ট (সব মেম্বার)'
                            : 'আমার মাসিক রিপোর্ট',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        formatBnDate(DateTime(now.year, now.month, 1)),
                        style: GoogleFonts.notoSansBengali(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    if (!isAdmin)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Text(
                          'শুধু আপনার হিসাব · অন্য মেম্বার দেখা যায় না',
                          style: GoogleFonts.notoSansBengali(
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Column(
                        children: [
                          if (isAdmin) ...[
                            _kv('মোট বাজার (মেস)', formatTaka(totalSpend)),
                            _kv('মোট মিল', fmtMeals(totalMeals)),
                            _kv('মিল রেট', formatTaka(rate)),
                          ] else ...[
                            _kv('আমার বাজার', formatTaka(myMarket)),
                            _kv('আমার মিল', fmtMeals(myMeals)),
                            _kv('মিল রেট', formatTaka(rate)),
                            _kv('আমার খরচ', formatTaka(myCost)),
                            _kv('আমার ব্যালেন্স', formatTaka(myBalance)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        isAdmin ? 'সব মেম্বারের হিসাব' : 'আমার হিসাব বিস্তারিত',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: GoogleFonts.notoSansBengali(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (me != null && m.uid == me.uid && !isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'আপনি',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 11,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'মিল: ${fmtMeals(meals)}  •  বাজার: ${formatTaka(marketSpend)}  •  ব্যালেন্স: ${formatTaka(balance)}',
                              style: GoogleFonts.notoSansBengali(
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
  }

  Future<Map<String, double>> _monthMealCounts(
    MealService mealService,
    String messId,
    DateTime now,
  ) async {
    final counts = <String, double>{};
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      final day = dateKey(DateTime(now.year, now.month, d));
      if (DateTime(now.year, now.month, d).isAfter(DateTime.now())) break;
      final entries = await mealService.watchDayMeals(messId, day).first;
      for (final e in entries) {
        counts[e.uid] = (counts[e.uid] ?? 0) + e.mealCount;
      }
    }
    return counts;
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k, style: GoogleFonts.notoSansBengali(color: AppColors.textGrey)),
          const Spacer(),
          Text(v, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
