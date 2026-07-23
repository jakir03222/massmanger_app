import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// Facebook-style top tab bar using custom asset icons.
class HomeTopTabBar extends StatelessWidget {
  const HomeTopTabBar({
    super.key,
    required this.controller,
  });

  final TabController controller;

  static int get tabCount => FeatureFlags.communityEnabled ? 6 : 5;

  static List<_FbTab> _tabs(BuildContext context) {
    final s = AppStrings.of(context);
    return [
      _FbTab(
        label: s.navHome,
        asset: 'assets/images/tab/home.png',
        fallback: Icons.home_rounded,
      ),
      _FbTab(
        label: s.navMeal,
        asset: 'assets/images/tab/meal.png',
        fallback: Icons.restaurant_rounded,
      ),
      _FbTab(
        label: s.navMarket,
        asset: 'assets/images/tab/market.png',
        fallback: Icons.storefront_rounded,
      ),
      if (FeatureFlags.communityEnabled)
        _FbTab(
          label: s.navCommunity,
          fallback: Icons.groups_rounded,
        ),
      _FbTab(
        label: s.navReport,
        asset: 'assets/images/tab/report.png',
        fallback: Icons.bar_chart_rounded,
      ),
      _FbTab(
        label: s.navSettings,
        asset: 'assets/images/tab/settings.png',
        fallback: Icons.settings_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.maybeOf(context);
    ThemeScope.maybeOf(context);

    final items = _tabs(context);
    final active = AppColors.primaryGreen;
    final inactive = AppColors.textGrey;

    return Material(
      color: AppColors.card,
      elevation: 0,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return TabBar(
            controller: controller,
            isScrollable: false,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.2, color: active),
              insets: const EdgeInsets.symmetric(horizontal: 10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
            dividerColor: AppColors.borderGrey.withValues(alpha: 0.85),
            dividerHeight: 1,
            splashFactory: InkRipple.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return active.withValues(alpha: 0.08);
              }
              return Colors.transparent;
            }),
            labelColor: active,
            unselectedLabelColor: inactive,
            tabs: [
              for (var i = 0; i < items.length; i++)
                Tab(
                  height: 56,
                  child: _FbTabItem(
                    tab: items[i],
                    selected: controller.index == i,
                    selectedColor: active,
                    unselectedColor: inactive,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FbTab {
  const _FbTab({
    required this.label,
    required this.fallback,
    this.asset,
  });

  final String label;
  final String? asset;
  final IconData fallback;
}

class _FbTabItem extends StatelessWidget {
  const _FbTabItem({
    required this.tab,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final _FbTab tab;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: tab.asset == null
              ? Icon(tab.fallback, size: 26, color: color)
              : ImageIcon(
                  AssetImage(tab.asset!),
                  size: 26,
                  color: color,
                ),
        ),
        const SizedBox(height: 3),
        Text(
          tab.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appFont(
            context: context,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
