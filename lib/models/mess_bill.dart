import 'package:cloud_firestore/cloud_firestore.dart';

/// মেসের মাসিক স্থায়ী বিলের ধরন।
enum MessBillType {
  cook,
  rent,
  electricity,
  water,
  utility,
  eidBonus;

  static MessBillType fromString(String? value) {
    switch (value) {
      case 'cook':
      case 'khala':
        return MessBillType.cook;
      case 'rent':
        return MessBillType.rent;
      case 'electricity':
        return MessBillType.electricity;
      case 'water':
        return MessBillType.water;
      case 'eidBonus':
      case 'eid_bonus':
      case 'eid':
        return MessBillType.eidBonus;
      case 'utility':
      default:
        return MessBillType.utility;
    }
  }

  String get firestoreValue => name;

  String get bnLabel {
    switch (this) {
      case MessBillType.cook:
        return 'খালা বিল';
      case MessBillType.rent:
        return 'বাসা ভাড়া';
      case MessBillType.electricity:
        return 'বিদ্যুৎ বিল';
      case MessBillType.water:
        return 'পানির বিল';
      case MessBillType.utility:
        return 'ইউটিলিটি বিল';
      case MessBillType.eidBonus:
        return 'ঈদ বোনাস';
    }
  }

  String label({required bool bn}) {
    switch (this) {
      case MessBillType.cook:
        return bn ? 'খালা বিল' : 'Cook bill';
      case MessBillType.rent:
        return bn ? 'বাসা ভাড়া' : 'House rent';
      case MessBillType.electricity:
        return bn ? 'বিদ্যুৎ বিল' : 'Electricity';
      case MessBillType.water:
        return bn ? 'পানির বিল' : 'Water';
      case MessBillType.utility:
        return bn ? 'ইউটিলিটি বিল' : 'Utility';
      case MessBillType.eidBonus:
        return bn ? 'ঈদ বোনাস' : 'Eid bonus';
    }
  }

  /// Cook-cost share excludes eid bonus (applied as Eid Bonus column).
  bool get countsAsCookCost => this != MessBillType.eidBonus;
}

class MessBill {
  const MessBill({
    required this.id,
    required this.type,
    required this.amount,
    required this.yearMonth,
    this.note = '',
    this.createdBy,
    this.createdByName,
    this.updatedAt,
    this.createdAt,
  });

  final String id;
  final MessBillType type;
  final double amount;
  final String yearMonth;
  final String note;
  final String? createdBy;
  final String? createdByName;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  factory MessBill.fromMap(String id, Map<String, dynamic> data) {
    final createdRaw = data['createdAt'];
    final updatedRaw = data['updatedAt'];
    return MessBill(
      id: id,
      type: MessBillType.fromString(data['type'] as String?),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      yearMonth: data['yearMonth'] as String? ?? '',
      note: data['note'] as String? ?? '',
      createdBy: data['createdBy'] as String?,
      createdByName: data['createdByName'] as String?,
      createdAt: createdRaw is Timestamp ? createdRaw.toDate() : null,
      updatedAt: updatedRaw is Timestamp ? updatedRaw.toDate() : null,
    );
  }
}
