import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/market_entry.dart';

class MarketService {
  MarketService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _markets(String messId) =>
      _firestore.collection('messes').doc(messId).collection('markets');

  List<MarketEntry> _sorted(List<MarketEntry> list) {
    list.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return list;
  }

  Stream<List<MarketEntry>> watchAllMarkets(String messId, {String? yearMonth}) {
    final col = _markets(messId);
    final query = yearMonth == null
        ? col.snapshots()
        : col.where('yearMonth', isEqualTo: yearMonth).snapshots();

    return query.map((snap) {
      final list =
          snap.docs.map((d) => MarketEntry.fromMap(d.id, d.data())).toList();
      return _sorted(list);
    });
  }

  /// Public list: only admin-approved bazaar.
  Stream<List<MarketEntry>> watchApprovedMarkets(
    String messId, {
    String? yearMonth,
  }) {
    return watchAllMarkets(messId, yearMonth: yearMonth).map(
      (list) => list.where((e) => e.isApproved).toList(),
    );
  }

  /// Admin inbox: pending member requests.
  Stream<List<MarketEntry>> watchPendingMarkets(String messId) {
    return watchAllMarkets(messId).map(
      (list) => list.where((e) => e.isPending).toList(),
    );
  }

  /// Member's own pending/rejected (not yet public).
  Stream<List<MarketEntry>> watchMyRequests(String messId, String uid) {
    return watchAllMarkets(messId).map(
      (list) => list
          .where((e) => e.shopperUid == uid && !e.isApproved)
          .toList(),
    );
  }

  /// @deprecated use watchApprovedMarkets for totals/lists
  Stream<List<MarketEntry>> watchMarkets(String messId, {String? yearMonth}) {
    return watchApprovedMarkets(messId, yearMonth: yearMonth);
  }

  Future<void> addMarket({
    required String messId,
    required String shopperUid,
    required String shopperName,
    required double amount,
    required String notes,
    required String dateKey,
    required String yearMonth,
    required List<MarketItem> items,
    required bool asAdmin,
    bool isDue = false,
  }) async {
    final status =
        asAdmin ? MarketStatus.approved : MarketStatus.pending;
    await _markets(messId).add({
      'shopperUid': shopperUid,
      'shopperName': shopperName,
      'amount': amount,
      'notes': notes.trim(),
      'items': items.map((e) => e.toMap()).toList(),
      'dateKey': dateKey,
      'yearMonth': yearMonth,
      'status': status.firestoreValue,
      'isDue': isDue,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': shopperUid,
    });
  }

  Future<void> updateMarket({
    required String messId,
    required String marketId,
    required double amount,
    required String notes,
    required List<MarketItem> items,
    bool? isDue,
    String? dateKey,
    String? yearMonth,
    String? editedByUid,
    String? editedByName,
  }) async {
    final data = <String, dynamic>{
      'amount': amount,
      'notes': notes.trim(),
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isDue != null) {
      data['isDue'] = isDue;
    }
    if (dateKey != null) {
      data['dateKey'] = dateKey;
    }
    if (yearMonth != null) {
      data['yearMonth'] = yearMonth;
    }
    if (editedByUid != null && editedByName != null) {
      data['editedByUid'] = editedByUid;
      data['editedByName'] = editedByName;
    }
    await _markets(messId).doc(marketId).update(data);
  }

  Future<void> approveMarket({
    required String messId,
    required String marketId,
    required String adminUid,
  }) async {
    await _markets(messId).doc(marketId).update({
      'status': MarketStatus.approved.firestoreValue,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectMarket({
    required String messId,
    required String marketId,
    required String adminUid,
  }) async {
    await _markets(messId).doc(marketId).update({
      'status': MarketStatus.rejected.firestoreValue,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMarket({
    required String messId,
    required String marketId,
  }) async {
    await _markets(messId).doc(marketId).delete();
  }

  Future<List<MarketEntry>> marketsForDay(String messId, String day) async {
    final snap = await _markets(messId).where('dateKey', isEqualTo: day).get();
    return snap.docs
        .map((d) => MarketEntry.fromMap(d.id, d.data()))
        .where((e) => e.isApproved)
        .toList();
  }
}
