import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// English digits → locale digits (Bangla when locale is BN).
String toBnDigits(String input, [BuildContext? context]) {
  if (context != null) {
    return AppStrings.of(context).digits(input);
  }
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  var out = input;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(en[i], bn[i]);
  }
  return out;
}

String formatBnDateFull(DateTime d, BuildContext context) {
  return AppStrings.of(context).formatDate(d);
}

/// Locale-aware calendar date picker.
Future<DateTime?> showBnDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
}) {
  final s = AppStrings.of(context);
  final first = firstDate ?? DateTime(2024);
  final last = lastDate ?? DateTime.now().add(const Duration(days: 1));
  var initial = DateTime(initialDate.year, initialDate.month, initialDate.day);
  final firstDay = DateTime(first.year, first.month, first.day);
  final lastDay = DateTime(last.year, last.month, last.day);
  if (initial.isBefore(firstDay)) initial = firstDay;
  if (initial.isAfter(lastDay)) initial = lastDay;

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      final maxH = MediaQuery.sizeOf(context).height * 0.75;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: _BnCalendarSheet(
          initialDate: initial,
          firstDate: firstDay,
          lastDate: lastDay,
          helpText: helpText ?? s.selectDate,
        ),
      );
    },
  );
}

class _BnCalendarSheet extends StatefulWidget {
  const _BnCalendarSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.helpText,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String helpText;

  @override
  State<_BnCalendarSheet> createState() => _BnCalendarSheetState();
}

class _BnCalendarSheetState extends State<_BnCalendarSheet> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(widget.firstDate) && !day.isAfter(widget.lastDate);
  }

  void _prevMonth() {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final firstMonth =
        DateTime(widget.firstDate.year, widget.firstDate.month);
    if (prev.isBefore(firstMonth)) return;
    setState(() => _visibleMonth = prev);
  }

  void _nextMonth() {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    if (next.isAfter(lastMonth)) return;
    setState(() => _visibleMonth = next);
  }

  void _confirm([DateTime? day]) {
    final value = day ?? _selected;
    if (!_inRange(value)) return;
    Navigator.pop(context, DateTime(value.year, value.month, value.day));
  }

  List<DateTime?> _daysInGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = <DateTime?>[];
    for (var i = 0; i < leading; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cells = _daysInGrid();
    final today = DateTime.now();
    final weekdays = s.weekdaysShort;
    final months = s.months;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.helpText,
              style: appFont(
                context: context,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.tapDateToSelect,
              style: appFont(
                context: context,
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatBnDateFull(_selected, context),
              style: appFont(
                context: context,
                fontSize: 14,
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.darkGreen,
                ),
                Expanded(
                  child: Text(
                    s.digits(
                      '${months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                    ),
                    textAlign: TextAlign.center,
                    style: appFont(
                      context: context,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.darkGreen,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: weekdays
                  .map(
                    (w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: appFont(
                            context: context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: cells.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final day = cells[index];
                  if (day == null) return const SizedBox.shrink();
                  final enabled = _inRange(day);
                  final selected = _isSameDay(day, _selected);
                  final isToday = _isSameDay(day, today);

                  return Material(
                    color: selected
                        ? AppColors.primaryGreen
                        : (isToday
                            ? AppColors.featureGreenBg
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: enabled
                          ? () {
                              setState(() => _selected = day);
                              _confirm(day);
                            }
                          : null,
                      child: Center(
                        child: Text(
                          s.digits('${day.day}'),
                          style: appFont(
                            context: context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !enabled
                                ? AppColors.borderGrey
                                : (selected
                                    ? Colors.white
                                    : AppColors.textDark),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      s.cancel,
                      style: appFont(
                        context: context,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                    ),
                    child: Text(
                      s.ok,
                      style: appFont(
                        context: context,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
