/// Bengali weekday, month, and digit formatting for meal charts.
library;

const bnMonths = [
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

/// [DateTime.weekday]: 1 = Monday … 7 = Sunday
const bnWeekdays = [
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
  'রবিবার',
];

String toBnDigits(String input) {
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  var text = input;
  for (var i = 0; i < 10; i++) {
    text = text.replaceAll(en[i], bn[i]);
  }
  return text;
}

/// e.g. জুন ২০২৬ মাস
String formatBnMonthTitle(DateTime month) {
  return '${bnMonths[month.month - 1]} ${toBnDigits('${month.year}')} মাস';
}

/// e.g. সোমবার, ১ জুন ২০২৬
String formatBnDayLabel(DateTime day) {
  final weekday = bnWeekdays[day.weekday - 1];
  final datePart =
      '${toBnDigits('${day.day}')} ${bnMonths[day.month - 1]} ${toBnDigits('${day.year}')}';
  return '$weekday, $datePart';
}

/// Short day label for compact views — e.g. সোম, ১ জুন
String formatBnDayShort(DateTime day) {
  final shortWeekday = bnWeekdays[day.weekday - 1].substring(0, 3);
  return '$shortWeekday, ${toBnDigits('${day.day}')} ${bnMonths[day.month - 1]}';
}
