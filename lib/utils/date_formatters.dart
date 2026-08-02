import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'bn_date_format.dart';

/// Canonical date keys used in Firestore docs (`YYYY-MM-DD` / `YYYY-MM`).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String yearMonthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}';

/// Bangla long date — e.g. `২৫ জুলাই ২০২৬`.
String formatBnDate(DateTime d) {
  return toBnDigits('${d.day} ${bnMonths[d.month - 1]} ${d.year}');
}

/// Indian-grouping taka amount with ৳ suffix.
String formatTaka(num amount) {
  final s = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return '${buf.toString()}৳';
}

/// Bangladesh Standard Time (UTC+6).
/// Pass [context] to use [AppStrings.formatDateTimeLocal]; otherwise Bangla.
String formatDateTime(DateTime? d, [BuildContext? context]) {
  if (context != null) {
    return AppStrings.of(context).formatDateTimeLocal(d);
  }
  if (d == null) return '—';
  final bd = d.toUtc().add(const Duration(hours: 6));
  final datePart = formatBnDate(DateTime(bd.year, bd.month, bd.day));
  var hour = bd.hour % 12;
  if (hour == 0) hour = 12;
  final minute = bd.minute.toString().padLeft(2, '0');
  final period = bd.hour < 12 ? 'পূর্বাহ্ন' : 'অপরাহ্ন';
  final time = toBnDigits('$hour:$minute');
  return '$datePart, $time $period';
}
