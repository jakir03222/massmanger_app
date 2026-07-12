import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_entry.dart';
import '../models/meal_entry.dart';
import '../services/market_service.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/mess_app_header.dart';
import '../widgets/mess_session_builder.dart';
import 'market_hub_screen.dart';
import 'meal_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: switch (_navIndex) {
          0 => const _HomeTab(),
          1 => const MealScreen(),
          2 => const MarketHubScreen(),
          3 => const ReportScreen(),
          4 => const SettingsScreen(),
          _ => const _HomeTab(),
        },
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final mealService = MealService();
        final marketService = MarketService();
        final today = dateKey(DateTime.now());
        final month = yearMonthKey(DateTime.now());
        final displayName = () {
          final m = members.where((e) => e.uid == appUser.uid);
          if (m.isNotEmpty) return m.first.name;
          return appUser.name ?? appUser.email;
        }();

        return StreamBuilder<List<MealEntry>>(
          stream: mealService.watchDayMeals(mess.id, today),
          builder: (context, mealSnap) {
            final meals =
                (mealSnap.data ?? []).where((e) => e.isApproved).toList();
            final morning = meals.where((e) => e.morning).length;
            final evening = meals.where((e) => e.evening).length;
            final night = meals.where((e) => e.night).length;

            return StreamBuilder<List<MarketEntry>>(
              stream: marketService.watchMarkets(mess.id, yearMonth: month),
              builder: (context, marketSnap) {
                final markets = marketSnap.data ?? [];
                final matched = members.where((e) => e.uid == appUser.uid);
                final isAdmin =
                    matched.isNotEmpty && matched.first.isAdmin;
                final visibleMarkets = isAdmin
                    ? markets
                    : markets
                        .where((e) => e.shopperUid == appUser.uid)
                        .toList();
                final monthTotal =
                    visibleMarkets.fold<double>(0, (s, e) => s + e.amount);
                final todayMarkets =
                    visibleMarkets.where((e) => e.dateKey == today).toList();
                final todayTotal =
                    todayMarkets.fold<double>(0, (s, e) => s + e.amount);
                final myMarkets =
                    markets.where((e) => e.shopperUid == appUser.uid);
                final myMarketTotal =
                    myMarkets.fold<double>(0, (s, e) => s + e.amount);
                final recent =
                    visibleMarkets.isEmpty ? null : visibleMarkets.first;

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MessAppHeader(
                        title: mess.name,
                        subtitle: mess.location,
                      ),
                      const SizedBox(height: 16),
                      Container(
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
                              'স্বাগতম, $displayName',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatBnDate(DateTime.now()),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'আজ মিল',
                                value: '${morning + evening + night}',
                                icon: Icons.restaurant_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'আজ বাজার',
                                value: formatTaka(todayTotal),
                                icon: Icons.shopping_cart_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'এই মাস',
                                value: formatTaka(monthTotal),
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'আমার সারাংশ',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                            _row('আমার বাজার (মাস)', formatTaka(myMarketTotal)),
                            _row(
                              'মেম্বার সংখ্যা',
                              '${members.length} জন',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      if (recent == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'এখনো কোনো আপডেট নেই',
                            style: GoogleFonts.notoSansBengali(
                              color: AppColors.textGrey,
                            ),
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Text(
                            isAdmin
                                ? '${recent.shopperName} ${formatTaka(recent.amount)} বাজার যোগ করেছে'
                                : 'আপনি ${formatTaka(recent.amount)} বাজার যোগ করেছেন',
                            style: GoogleFonts.notoSansBengali(height: 1.4),
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
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.notoSansBengali(color: AppColors.textGrey)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
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
