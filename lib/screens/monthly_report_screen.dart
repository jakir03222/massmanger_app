import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_entry.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';

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

  bool get _isCurrentOrFuture {
    final now = DateTime.now();
    return _month.year > now.year ||
        (_month.year == now.year && _month.month >= now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  static const _months = [
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

  String get _monthLabel => '${_months[_month.month - 1]} ${_month.year}';

  @override
  Widget build(BuildContext context) {
    final month = yearMonthKey(_month);

    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final matched = members.where((e) => e.uid == appUser.uid);
        final isAdmin = matched.isNotEmpty && matched.first.isAdmin;
        final me = matched.isNotEmpty ? matched.first : null;

        return StreamBuilder<List<MarketEntry>>(
          stream: _marketService.watchMarkets(mess.id, yearMonth: month),
          builder: (context, marketSnap) {
            final allMarkets = marketSnap.data ?? [];
            final totalSpend =
                allMarkets.fold<double>(0, (s, e) => s + e.amount);

            final visibleMembers = isAdmin
                ? members
                : members.where((m) => m.uid == appUser.uid).toList();

            return FutureBuilder<Map<String, double>>(
              future: _monthMealCounts(_mealService, mess.id, _month),
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
                    _MonthSelector(
                      label: _monthLabel,
                      onPrev: () => _shiftMonth(-1),
                      onNext: _isCurrentOrFuture ? null : () => _shiftMonth(1),
                    ),
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
                    if (mealCountSnap.connectionState ==
                        ConnectionState.waiting)
                      const Padding(
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
    DateTime month,
  ) async {
    final counts = <String, double>{};
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    for (var d = 1; d <= daysInMonth; d++) {
      final dayDate = DateTime(month.year, month.month, d);
      if (isCurrentMonth && dayDate.isAfter(now)) break;
      final entries =
          await mealService.watchDayMeals(messId, dateKey(dayDate)).first;
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

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: Icon(
                Icons.chevron_right,
                color: onNext == null ? AppColors.borderGrey : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
