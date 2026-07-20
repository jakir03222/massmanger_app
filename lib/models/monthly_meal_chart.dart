import '../models/meal_entry.dart';
import '../models/mess.dart';
import '../services/meal_service.dart';
import '../utils/bn_date_format.dart';
import '../widgets/mess_session_builder.dart' show dateKey;

class MealBld {
  const MealBld({this.b = 0, this.l = 0, this.d = 0});

  final double b;
  final double l;
  final double d;

  double get total => b + l + d;
}

class MealChartDayRow {
  const MealChartDayRow({
    required this.day,
    required this.byUid,
    required this.dayTotal,
  });

  final DateTime day;
  final Map<String, MealBld> byUid;
  final double dayTotal;
}

class MonthlyMealChart {
  const MonthlyMealChart({
    required this.month,
    required this.monthLabel,
    required this.members,
    required this.days,
    required this.memberB,
    required this.memberL,
    required this.memberD,
    required this.grandTotal,
  });

  final DateTime month;
  final String monthLabel;
  final List<MessMember> members;
  final List<MealChartDayRow> days;
  final List<double> memberB;
  final List<double> memberL;
  final List<double> memberD;
  final double grandTotal;

  double personTotal(int index) =>
      memberB[index] + memberL[index] + memberD[index];

  static const memberColorValues = [
    0xFFB3E5FC,
    0xFFFFCDD2,
    0xFFFFFFFF,
    0xFFE1BEE7,
    0xFFFFF9C4,
    0xFFBBDEFB,
    0xFFC8E6C9,
    0xFFD1C4E9,
    0xFFFFE0B2,
    0xFFF3E5F5,
    0xFFC5E1A5,
    0xFFB2EBF2,
    0xFFF8BBD0,
    0xFFDCEDC8,
  ];

  static String formatQty(double n) {
    if (n <= 0) return '';
    return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
  }

  static String formatQtyOrZero(double n) {
    if (n == 0) return '0';
    return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
  }
}

class MonthlyMealChartBuilder {
  MonthlyMealChartBuilder({MealService? mealService})
      : _meals = mealService ?? MealService();

  final MealService _meals;

  Future<MonthlyMealChart> buildForMess({
    required String messId,
    required List<MessMember> members,
    required DateTime month,
  }) async {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final dayDates = [
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(month.year, month.month, d),
    ];

    final grid = <String, Map<String, _MutableBld>>{
      for (final day in dayDates)
        dateKey(day): {for (final m in members) m.uid: _MutableBld()},
    };

    await Future.wait(dayDates.map((day) async {
      final key = dateKey(day);
      final entries = await _meals.getDayMeals(messId, key);
      final byUid = grid[key]!;
      for (final e in entries) {
        if (!e.isApproved) continue;
        final cell = byUid[e.uid];
        if (cell == null) continue;
        switch (e.type) {
          case MealType.morning:
            cell.b += e.rateValue; // সকাল
          case MealType.evening:
            cell.l += e.rateValue; // বিকাল
          case MealType.night:
            cell.d += e.rateValue; // রাত
          case MealType.rate:
            // রেট মিল রাত কলামে যোগ হয়
            cell.d += e.rateValue;
        }
      }
    }));

    final memberCount = members.length;
    final memberB = List<double>.filled(memberCount, 0);
    final memberL = List<double>.filled(memberCount, 0);
    final memberD = List<double>.filled(memberCount, 0);
    var grandTotal = 0.0;
    final rows = <MealChartDayRow>[];

    for (final day in dayDates) {
      final byUidRaw = grid[dateKey(day)]!;
      final byUid = <String, MealBld>{};
      var dayTotal = 0.0;
      for (var i = 0; i < memberCount; i++) {
        final uid = members[i].uid;
        final raw = byUidRaw[uid] ?? _MutableBld();
        final bld = MealBld(b: raw.b, l: raw.l, d: raw.d);
        byUid[uid] = bld;
        memberB[i] += bld.b;
        memberL[i] += bld.l;
        memberD[i] += bld.d;
        dayTotal += bld.total;
      }
      grandTotal += dayTotal;
      rows.add(MealChartDayRow(day: day, byUid: byUid, dayTotal: dayTotal));
    }

    final monthLabel = formatBnMonthTitle(month);

    return MonthlyMealChart(
      month: month,
      monthLabel: monthLabel,
      members: members,
      days: rows,
      memberB: memberB,
      memberL: memberL,
      memberD: memberD,
      grandTotal: grandTotal,
    );
  }
}

class _MutableBld {
  double b = 0;
  double l = 0;
  double d = 0;
}
