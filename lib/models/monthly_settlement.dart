import 'mess.dart';
import 'mess_bill.dart';

/// এক মেম্বারের এক মাসের পূর্ণ হিসাব (মেস স্টেটমেন্ট ফরম্যাট)।
class MemberMonthlySettlement {
  const MemberMonthlySettlement({
    required this.serial,
    required this.member,
    required this.consumeMeal,
    required this.mealRate,
    required this.costOfMeal,
    required this.cookCost,
    required this.totalDue,
    required this.depositMoney,
    required this.eidBonus,
    required this.totalCost,
    required this.netPayableReceivable,
  });

  final int serial;
  final MessMember member;

  /// এই মাসে খাওয়া মোট মিল।
  final double consumeMeal;

  /// মিল রেট (টাকা)।
  final double mealRate;

  /// খাবারের খরচ = মিল × রেট।
  final double costOfMeal;

  /// রাঁধুনি/মাসিক বিলের সমান ভাগ।
  final double cookCost;

  /// মোট বকেয়া = খাবারের খরচ + কুক খরচ।
  final double totalDue;

  /// জমা টাকা (মেম্বারের অনুমোদিত বাজার জমা)।
  final double depositMoney;

  /// ঈদ বোনাস / সমন্বয় (থাকলে)।
  final double eidBonus;

  /// মোট খরচ = মোট বকেয়া − ঈদ বোনাস।
  final double totalCost;

  /// নেট = জমা − মোট খরচ। ধনাত্মক = পাবে, ঋণাত্মক = দিবে।
  final double netPayableReceivable;

  /// পাবে (ধনাত্মক হলে)।
  double get willReceive => netPayableReceivable > 0 ? netPayableReceivable : 0;

  /// দিবে (ঋণাত্মক হলে)।
  double get willPay =>
      netPayableReceivable < 0 ? -netPayableReceivable : 0;
}

/// পুরো মেসের এক মাসের ক্লোজিং স্টেটমেন্ট।
class MonthlySettlementReport {
  const MonthlySettlementReport({
    required this.mess,
    required this.month,
    required this.fixedBills,
    required this.members,
    required this.totalConsumeMeal,
    required this.mealRate,
    required this.totalCostOfMeal,
    required this.totalCookCost,
    required this.totalDue,
    required this.totalDeposit,
    required this.totalEidBonus,
    required this.totalCost,
    required this.totalNet,
  });

  final Mess mess;
  final DateTime month;
  final List<MessBill> fixedBills;
  final List<MemberMonthlySettlement> members;

  final double totalConsumeMeal;
  final double mealRate;
  final double totalCostOfMeal;
  final double totalCookCost;
  final double totalDue;
  final double totalDeposit;
  final double totalEidBonus;
  final double totalCost;
  final double totalNet;
}
