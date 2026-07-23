import 'package:cloud_firestore/cloud_firestore.dart';

enum MarketStatus {
  pending,
  approved,
  rejected;

  static MarketStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return MarketStatus.pending;
      case 'rejected':
        return MarketStatus.rejected;
      case 'approved':
      default:
        // Old docs without status count as approved.
        return MarketStatus.approved;
    }
  }

  String get firestoreValue => name;

  String get bnLabel {
    switch (this) {
      case MarketStatus.pending:
        return 'অপেক্ষমাণ';
      case MarketStatus.approved:
        return 'অনুমোদিত';
      case MarketStatus.rejected:
        return 'বাতিল';
    }
  }

  String label({required bool bn}) {
    switch (this) {
      case MarketStatus.pending:
        return bn ? 'অপেক্ষমাণ' : 'Pending';
      case MarketStatus.approved:
        return bn ? 'অনুমোদিত' : 'Approved';
      case MarketStatus.rejected:
        return bn ? 'বাতিল' : 'Rejected';
    }
  }
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
      name: data['name'] as String? ?? '',
      quantity: data['quantity'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
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
    final createdAtRaw = data['createdAt'];
    final updatedAtRaw = data['updatedAt'];
    final rawItems = data['items'];
    final items = <MarketItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(MarketItem.fromMap(item));
        } else if (item is Map) {
          items.add(MarketItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return MarketEntry(
      id: id,
      shopperUid: data['shopperUid'] as String? ?? '',
      shopperName: data['shopperName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String? ?? '',
      dateKey: data['dateKey'] as String? ?? '',
      yearMonth: data['yearMonth'] as String? ?? '',
      items: items,
      status: MarketStatus.fromString(data['status'] as String?),
      isDue: data['isDue'] as bool? ?? false,
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
      updatedAt: updatedAtRaw is Timestamp ? updatedAtRaw.toDate() : null,
      editedByUid: data['editedByUid'] as String?,
      editedByName: data['editedByName'] as String?,
    );
  }
}
