import '../models/market_entry.dart';
import '../models/mess.dart';
import '../models/monthly_settlement.dart';
import '../widgets/mess_session_builder.dart';
import 'market_service.dart';
import 'meal_service.dart';
import 'mess_bill_service.dart';

class MonthlySettlementService {
  MonthlySettlementService({
    MessBillService? billService,
    MarketService? marketService,
    MealService? mealService,
  })  : _billService = billService ?? MessBillService(),
        _marketService = marketService ?? MarketService(),
        _mealService = mealService ?? MealService();

  final MessBillService _billService;
  final MarketService _marketService;
  final MealService _mealService;

  Future<MonthlySettlementReport> buildReport({
    required Mess mess,
    required List<MessMember> members,
    required DateTime month,
  }) async {
    final yearMonth = yearMonthKey(month);

    final bills = await _billService.getByMonth(mess.id, yearMonth);
    final markets = await _fetchApprovedMarkets(mess.id, yearMonth);
    final mealCounts = await _monthMealCounts(mess.id, month);

    final totalFixedBills =
        bills.fold<double>(0, (sum, bill) => sum + bill.amount);
    final totalMarketSpend =
        markets.fold<double>(0, (sum, entry) => sum + entry.amount);
    final totalMeals =
        mealCounts.values.fold<double>(0, (sum, count) => sum + count);
    final mealRate = totalMeals == 0 ? 0.0 : totalMarketSpend / totalMeals;

    final memberCount = members.isEmpty ? 1 : members.length;
    final cookShare = totalFixedBills / memberCount;

    final sortedMembers = [...members]
      ..sort((a, b) => a.name.compareTo(b.name));

    var totalConsumeMeal = 0.0;
    var totalCostOfMeal = 0.0;
    var totalCookCost = 0.0;
    var totalDue = 0.0;
    var totalDeposit = 0.0;
    var totalEidBonus = 0.0;
    var totalCost = 0.0;
    var totalNet = 0.0;

    final settlements = <MemberMonthlySettlement>[];
    var serial = 1;
    for (final member in sortedMembers) {
      final consumeMeal = mealCounts[member.uid] ?? 0;
      final costOfMeal = consumeMeal * mealRate;
      final cookCost = cookShare;
      final due = costOfMeal + cookCost;
      final depositMoney = markets
          .where((entry) => entry.shopperUid == member.uid)
          .fold<double>(0, (sum, entry) => sum + entry.amount);
      const eidBonus = 0.0;
      final cost = due - eidBonus;
      final net = depositMoney - cost;

      settlements.add(
        MemberMonthlySettlement(
          serial: serial++,
          member: member,
          consumeMeal: consumeMeal,
          mealRate: mealRate,
          costOfMeal: costOfMeal,
          cookCost: cookCost,
          totalDue: due,
          depositMoney: depositMoney,
          eidBonus: eidBonus,
          totalCost: cost,
          netPayableReceivable: net,
        ),
      );

      totalConsumeMeal += consumeMeal;
      totalCostOfMeal += costOfMeal;
      totalCookCost += cookCost;
      totalDue += due;
      totalDeposit += depositMoney;
      totalEidBonus += eidBonus;
      totalCost += cost;
      totalNet += net;
    }

    return MonthlySettlementReport(
      mess: mess,
      month: month,
      fixedBills: bills,
      members: settlements,
      totalConsumeMeal: totalConsumeMeal,
      mealRate: mealRate,
      totalCostOfMeal: totalCostOfMeal,
      totalCookCost: totalCookCost,
      totalDue: totalDue,
      totalDeposit: totalDeposit,
      totalEidBonus: totalEidBonus,
      totalCost: totalCost,
      totalNet: totalNet,
    );
  }

  Future<List<MarketEntry>> _fetchApprovedMarkets(
    String messId,
    String yearMonth,
  ) {
    return _marketService
        .watchApprovedMarkets(messId, yearMonth: yearMonth)
        .first;
  }

  Future<Map<String, double>> _monthMealCounts(
    String messId,
    DateTime month,
  ) async {
    final counts = <String, double>{};
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    for (var day = 1; day <= daysInMonth; day++) {
      final dayDate = DateTime(month.year, month.month, day);
      if (isCurrentMonth && dayDate.isAfter(now)) break;

      final entries =
          await _mealService.watchDayMeals(messId, dateKey(dayDate)).first;
      for (final entry in entries) {
        counts[entry.uid] = (counts[entry.uid] ?? 0) + entry.mealCount;
      }
    }

    return counts;
  }
}
