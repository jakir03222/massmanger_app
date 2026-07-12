import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderGrey.withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'হোম',
                icon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                label: 'মিল',
                icon: Icons.restaurant_rounded,
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                label: 'বাজার',
                icon: Icons.shopping_cart_outlined,
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                label: 'রিপোর্ট',
                icon: Icons.bar_chart_rounded,
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                label: 'সেটিংস',
                icon: Icons.settings_outlined,
                selected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              )
            else
              Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: AppColors.textGrey, size: 22),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.notoSansBengali(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primaryGreen : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
