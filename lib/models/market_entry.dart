import '../utils/firestore_parsers.dart';
import 'approval_status.dart';

enum MarketStatus {
  pending,
  approved,
  rejected;

  static MarketStatus fromString(String? value) {
    switch (ApprovalStatus.fromString(value)) {
      case ApprovalStatus.pending:
        return MarketStatus.pending;
      case ApprovalStatus.rejected:
        return MarketStatus.rejected;
      case ApprovalStatus.approved:
        return MarketStatus.approved;
    }
  }

  String get firestoreValue => name;

  String get bnLabel => label(bn: true);

  String label({required bool bn}) => ApprovalStatus.values[index].label(bn: bn);
}

class MarketItem {
  const MarketItem({
    required this.name,
    required this.quantity,
    required this.amount,
  });

  final String name;
  final String quantity;
  final double amount;

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'amount': amount,
      };

  factory MarketItem.fromMap(Map<String, dynamic> data) {
    return MarketItem(
      name: readString(data['name']),
      quantity: readString(data['quantity']),
      amount: readDouble(data['amount']),
    );
  }
}

class MarketEntry {
  const MarketEntry({
    required this.id,
    required this.shopperUid,
    required this.shopperName,
    required this.amount,
    required this.notes,
    required this.dateKey,
    required this.yearMonth,
    this.items = const [],
    this.status = MarketStatus.approved,
    this.isDue = false,
    this.createdAt,
    this.updatedAt,
    this.editedByUid,
    this.editedByName,
  });

  final String id;
  final String shopperUid;
  final String shopperName;
  final double amount;
  final String notes;
  final String dateKey;
  final String yearMonth;
  final List<MarketItem> items;
  final MarketStatus status;

  /// বাকিতে বাজার — দোকানে টাকা এখনো পরিশোধ করা হয়নি।
  final bool isDue;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? editedByUid;
  final String? editedByName;

  bool get isPending => status == MarketStatus.pending;
  bool get isApproved => status == MarketStatus.approved;
  bool get isRejected => status == MarketStatus.rejected;
  bool get wasEditedByAdmin =>
      editedByName != null && editedByName!.trim().isNotEmpty;

  factory MarketEntry.fromMap(String id, Map<String, dynamic> data) {
    final items = [
      for (final item in readMapList(data['items'])) MarketItem.fromMap(item),
    ];

    return MarketEntry(
      id: id,
      shopperUid: readString(data['shopperUid']),
      shopperName: readString(data['shopperName']),
      amount: readDouble(data['amount']),
      notes: readString(data['notes']),
      dateKey: readString(data['dateKey']),
      yearMonth: readString(data['yearMonth']),
      items: items,
      status: MarketStatus.fromString(data['status'] as String?),
      isDue: readBool(data['isDue']),
      createdAt: readTimestamp(data['createdAt']),
      updatedAt: readTimestamp(data['updatedAt']),
      editedByUid: data['editedByUid'] as String?,
      editedByName: data['editedByName'] as String?,
    );
  }
}
