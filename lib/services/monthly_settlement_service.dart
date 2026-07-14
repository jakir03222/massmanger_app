import 'dart:async';

import '../models/market_entry.dart';
import '../models/mess.dart';
import '../models/mess_bill.dart';
import '../models/monthly_settlement.dart';
import '../widgets/mess_session_builder.dart' show yearMonthKey;
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

  /// Live settlement — updates when bills, markets, or meals change.
  Stream<MonthlySettlementReport> watchReport({
    required Mess mess,
    required List<MessMember> members,
    required DateTime month,
  }) {
    final yearMonth = yearMonthKey(month);
    return _combineLatest3(
      _billService.watchByMonth(mess.id, yearMonth),
      _marketService.watchApprovedMarkets(mess.id, yearMonth: yearMonth),
      _mealService.watchMonthMealCounts(mess.id, month),
      (bills, markets, mealCounts) => _buildReportFromData(
        mess: mess,
        members: members,
        month: month,
        bills: bills,
        markets: markets,
        mealCounts: mealCounts,
      ),
    );
  }

  Future<MonthlySettlementReport> buildReport({
    required Mess mess,
    required List<MessMember> members,
    required DateTime month,
  }) {
    return watchReport(mess: mess, members: members, month: month).first;
  }

  MonthlySettlementReport _buildReportFromData({
    required Mess mess,
    required List<MessMember> members,
    required DateTime month,
    required List<MessBill> bills,
    required List<MarketEntry> markets,
    required Map<String, double> mealCounts,
  }) {
    final cookBills = bills.where((b) => b.type.countsAsCookCost).toList();
    final eidBills =
        bills.where((b) => b.type == MessBillType.eidBonus).toList();

    final totalFixedBills =
        cookBills.fold<double>(0, (sum, bill) => sum + bill.amount);
    final totalEidPool =
        eidBills.fold<double>(0, (sum, bill) => sum + bill.amount);
    final totalMarketSpend =
        markets.fold<double>(0, (sum, entry) => sum + entry.amount);
    final totalMeals =
        mealCounts.values.fold<double>(0, (sum, count) => sum + count);
    final mealRate = totalMeals == 0 ? 0.0 : totalMarketSpend / totalMeals;

    final memberCount = members.isEmpty ? 1 : members.length;
    final cookShare = totalFixedBills / memberCount;
    final eidShare = totalEidPool / memberCount;

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
      final eidBonus = eidShare;
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
}

Stream<R> _combineLatest3<A, B, C, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  R Function(A, B, C) combiner,
) {
  A? latestA;
  B? latestB;
  C? latestC;
  late StreamSubscription<A> subA;
  late StreamSubscription<B> subB;
  late StreamSubscription<C> subC;

  final controller = StreamController<R>.broadcast();

  void emitIfReady() {
    if (latestA == null || latestB == null || latestC == null) return;
    controller.add(combiner(latestA as A, latestB as B, latestC as C));
  }

  controller.onListen = () {
    subA = streamA.listen(
      (v) {
        latestA = v;
        emitIfReady();
      },
      onError: controller.addError,
    );
    subB = streamB.listen(
      (v) {
        latestB = v;
        emitIfReady();
      },
      onError: controller.addError,
    );
    subC = streamC.listen(
      (v) {
        latestC = v;
        emitIfReady();
      },
      onError: controller.addError,
    );
  };

  controller.onCancel = () async {
    await subA.cancel();
    await subB.cancel();
    await subC.cancel();
  };

  return controller.stream;
}
