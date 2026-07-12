import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/meal_entry.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';

class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  String _fmtQty(double n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final mealService = MealService();
    final marketService = MarketService();
    final today = DateTime.now();
    final day = dateKey(today);

    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((e) => e.uid == appUser.uid);
        final isAdmin = matched.isNotEmpty && matched.first.isAdmin;

        return StreamBuilder<List<MealEntry>>(
          stream: mealService.watchDayMeals(mess.id, day),
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

            return FutureBuilder(
              future: marketService.marketsForDay(mess.id, day),
              builder: (context, marketSnap) {
                final allMarkets = marketSnap.data ?? [];
                final markets = isAdmin
                    ? allMarkets
                    : allMarkets
                        .where((e) => e.shopperUid == appUser.uid)
                        .toList();
                final spend = markets.fold<double>(0, (s, e) => s + e.amount);
                final attendanceMembers = isAdmin
                    ? members
                    : members.where((m) => m.uid == appUser.uid).toList();

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    MessAppHeader(title: mess.name, subtitle: mess.location),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        isAdmin ? 'দৈনিক রিপোর্ট (সব মেম্বার)' : 'আমার দৈনিক রিপোর্ট',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        formatBnDate(today),
                        style: GoogleFonts.notoSansBengali(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    if (!isAdmin)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Text(
                          'শুধু আপনার মিল ও বাজারের রিপোর্ট',
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
                          _kv(
                            isAdmin ? 'আজকের বাজার' : 'আমার আজকের বাজার',
                            formatTaka(spend),
                          ),
                          if (!isAdmin)
                            _kv('আমার মোট মিল', _fmtQty(myMealTotal)),
                          _kv(
                            isAdmin ? 'সকাল মিল' : 'আমার সকাল',
                            _fmtQty(morning),
                          ),
                          _kv(
                            isAdmin ? 'বিকাল মিল' : 'আমার বিকাল',
                            _fmtQty(evening),
                          ),
                          _kv(
                            isAdmin ? 'রাত মিল' : 'আমার রাত',
                            _fmtQty(night),
                          ),
                          _kv(
                            isAdmin ? 'রেট মিল' : 'আমার রেট',
                            _fmtQty(rateTotal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        isAdmin ? 'সব মেম্বারের উপস্থিতি' : 'আমার উপস্থিতি',
                        style: GoogleFonts.notoSansBengali(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
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
                      return ListTile(
                        title: Text(
                          m.name,
                          style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'সকাল: ${_fmtQty(mMorning)}  ·  বিকাল: ${_fmtQty(mEvening)}  ·  রাত: ${_fmtQty(mNight)}  ·  রেট: ${_fmtQty(mRate)}',
                          style: GoogleFonts.notoSansBengali(fontSize: 12),
                        ),
                      );
                    }),
                    if (markets.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          isAdmin ? 'আজকের বাজারকারী' : 'আমার আজকের বাজার লিস্ট',
                          style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...markets.map(
                        (e) => ListTile(
                          title: Text(
                            e.shopperName,
                            style: GoogleFonts.notoSansBengali(),
                          ),
                          subtitle: e.dateKey.isNotEmpty
                              ? Text(
                                  e.dateKey,
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 11,
                                    color: AppColors.textGrey,
                                  ),
                                )
                              : null,
                          trailing: Text(
                            formatTaka(e.amount),
                            style: GoogleFonts.notoSansBengali(
                              fontWeight: FontWeight.w700,
                            ),
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
