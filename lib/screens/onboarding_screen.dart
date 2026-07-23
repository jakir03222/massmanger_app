import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_colors.dart';

/// First-launch onboarding (4 pages). Shown once, then skipped.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  static const prefsKey = 'onboarding_done_v1';

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  List<_OnboardPage> _pages(AppStrings s) => [
        _OnboardPage(
          image: 'assets/images/onboarding/01_meals.png',
          title: s.onboardingMealsTitle,
          body: s.onboardingMealsBody,
        ),
        _OnboardPage(
          image: 'assets/images/onboarding/02_bazaar.png',
          title: s.onboardingBazaarTitle,
          body: s.onboardingBazaarBody,
        ),
        _OnboardPage(
          image: 'assets/images/onboarding/03_reports.png',
          title: s.onboardingReportsTitle,
          body: s.onboardingReportsBody,
        ),
        _OnboardPage(
          image: 'assets/images/onboarding/04_join.png',
          title: s.onboardingJoinTitle,
          body: s.onboardingJoinBody,
        ),
      ];

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (!mounted) return;
    widget.onFinished();
  }

  void _next(int pageCount) {
    if (_index >= pageCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final locale = LocaleScope.maybeOf(context);
    final pages = _pages(s);
    final isLast = _index == pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  if (locale != null)
                    TextButton(
                      onPressed: () => locale.toggle(),
                      child: Text(
                        locale.isBengali ? s.languageEn : s.languageBn,
                        style: appFont(
                          context: context,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                  const Spacer(),
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        s.skip,
                        style: appFont(
                          context: context,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 6,
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 360),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                page.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    ColoredBox(
                                  color: AppColors.featureGreenBg,
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 64,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: appFont(
                                  context: context,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                page.body,
                                textAlign: TextAlign.center,
                                style: appFont(
                                  context: context,
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.primaryGreen
                                : AppColors.borderGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => _next(pages.length),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isLast ? s.getStarted : s.next,
                        style: appFont(
                          context: context,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  const _OnboardPage({
    required this.image,
    required this.title,
    required this.body,
  });

  final String image;
  final String title;
  final String body;
}
