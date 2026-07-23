import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

const kBnMonthNames = [
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

String bnMonthLabel(DateTime month, [BuildContext? context]) {
  if (context != null) {
    return AppStrings.of(context).monthLabel(month);
  }
  return '${kBnMonthNames[month.month - 1]} ${month.year}';
}
String localizedMonthLabel(BuildContext context, DateTime month) =>
    AppStrings.of(context).monthLabel(month);

bool isSameYearMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

bool isCurrentOrFutureMonth(DateTime month) {
  final now = DateTime.now();
  final current = DateTime(now.year, now.month);
  final m = DateTime(month.year, month.month);
  return !m.isBefore(current);
}

/// Prev / next month picker. Next is disabled on the current calendar month.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({
    super.key,
    required this.month,
    required this.onChanged,
    this.locked = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final bool locked;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final canGoNext = !isCurrentOrFutureMonth(month);

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: s.previousMonth,
            onPressed: () => onChanged(
              DateTime(month.year, month.month - 1),
            ),
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.primaryGreen,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  s.monthLabel(month),
                  textAlign: TextAlign.center,
                  style: appFont(
                    context: context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (locked)
                  Text(
                    s.monthClosedBadge,
                    style: appFont(
                      context: context,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.monthRed,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.nextMonth,
            onPressed: canGoNext
                ? () => onChanged(DateTime(month.year, month.month + 1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: canGoNext ? AppColors.primaryGreen : AppColors.borderGrey,
          ),
        ],
      ),
    );
  }
}

class MonthClosedBanner extends StatelessWidget {
  const MonthClosedBanner({
    super.key,
    required this.monthLabel,
    this.isAdmin = false,
  });

  final String monthLabel;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = isAdmin
        ? (s.isBengali
            ? '$monthLabel মাস ক্লোজ করা আছে। মিল/বাজার/বিল এডিট বন্ধ। নতুন মাসের হিসাব আলাদা থাকবে। সেটিংস থেকে আনলক করা যায়।'
            : '$monthLabel is closed. Meal/bazaar/bill edits are off. New month calculates separately. Unlock from Settings.')
        : (s.isBengali
            ? '$monthLabel মাস ক্লোজ করা আছে। শুধু আগের হিসাব দেখা যাবে — এডিট করা যাবে না।'
            : '$monthLabel is closed. You can view history only — edits are disabled.');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.monthRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, size: 18, color: AppColors.monthRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: appFont(
                context: context,
                fontSize: 12,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
