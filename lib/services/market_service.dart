import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/market_entry.dart';
import 'month_lock_service.dart';
import 'notification_service.dart';

class MarketService {
  MarketService({
    FirebaseFirestore? firestore,
    MonthLockService? monthLockService,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _locks = monthLockService ?? MonthLockService(),
        _notifications = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final MonthLockService _locks;
  final NotificationService _notifications;

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
    await _locks.assertUnlocked(messId, yearMonth);
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
    if (!asAdmin) {
      await _notifications.notifyAdminsOfMess(
        messId: messId,
        titleBn: 'নতুন বাজার অনুমোদন',
        titleEn: 'New market approval',
        bodyBn: '$shopperName — ৳${amount.toStringAsFixed(0)} ($dateKey)',
        bodyEn: '$shopperName — ৳${amount.toStringAsFixed(0)} ($dateKey)',
        type: 'market_pending',
        data: {'messId': messId, 'dateKey': dateKey},
      );
    } else {
      await _notifications.notifyMessMembers(
        messId: messId,
        excludeUid: shopperUid,
        titleBn: 'নতুন বাজার অনুমোদিত',
        titleEn: 'New market approved',
        bodyBn: '$shopperName — ৳${amount.toStringAsFixed(0)} ($dateKey)',
        bodyEn: '$shopperName — ৳${amount.toStringAsFixed(0)} ($dateKey)',
        type: 'market_approved_broadcast',
        data: {'messId': messId, 'dateKey': dateKey},
      );
    }
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
    if (yearMonth != null) {
      await _locks.assertUnlocked(messId, yearMonth);
    } else {
      final snap = await _markets(messId).doc(marketId).get();
      final ym = snap.data()?['yearMonth'] as String?;
      if (ym != null) await _locks.assertUnlocked(messId, ym);
    }
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
    final snap = await _markets(messId).doc(marketId).get();
    final ym = snap.data()?['yearMonth'] as String?;
    if (ym != null) await _locks.assertUnlocked(messId, ym);
    await _markets(messId).doc(marketId).update({
      'status': MarketStatus.approved.firestoreValue,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final shopperUid = snap.data()?['shopperUid'] as String?;
    final shopperName = snap.data()?['shopperName'] as String? ?? 'Member';
    final amount = (snap.data()?['amount'] as num?)?.toDouble() ?? 0;
    final dateKey = snap.data()?['dateKey'] as String? ?? '';
    final amountLabel = '৳${amount.toStringAsFixed(0)}';
    final dateSuffix = dateKey.isEmpty ? '' : ' ($dateKey)';

    if (shopperUid != null && shopperUid != adminUid) {
      await _notifications.notifyUsers(
        uids: [shopperUid],
        titleBn: 'বাজার অনুমোদিত ✅',
        titleEn: 'Market approved ✅',
        bodyBn: 'আপনার বাজার এন্ট্রি অনুমোদন হয়েছে — $amountLabel',
        bodyEn: 'Your market entry was approved — $amountLabel',
        type: 'market_approved',
        data: {'messId': messId, 'marketId': marketId},
      );
    }

    final members = await _firestore
        .collection('messes')
        .doc(messId)
        .collection('members')
        .get();
    final others = members.docs
        .map((d) => d.id)
        .where((id) => id != adminUid && id != shopperUid)
        .toList();
    if (others.isNotEmpty) {
      await _notifications.notifyUsers(
        uids: others,
        titleBn: 'বাজার অনুমোদিত',
        titleEn: 'Market approved',
        bodyBn: '$shopperName — $amountLabel$dateSuffix',
        bodyEn: '$shopperName — $amountLabel$dateSuffix',
        type: 'market_approved_broadcast',
        data: {'messId': messId, 'marketId': marketId},
      );
    }
  }

  Future<void> rejectMarket({
    required String messId,
    required String marketId,
    required String adminUid,
  }) async {
    final snap = await _markets(messId).doc(marketId).get();
    final ym = snap.data()?['yearMonth'] as String?;
    if (ym != null) await _locks.assertUnlocked(messId, ym);
    await _markets(messId).doc(marketId).update({
      'status': MarketStatus.rejected.firestoreValue,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final shopperUid = snap.data()?['shopperUid'] as String?;
    if (shopperUid != null && shopperUid != adminUid) {
      await _notifications.notifyUsers(
        uids: [shopperUid],
        titleBn: 'বাজার বাতিল ❌',
        titleEn: 'Market rejected ❌',
        bodyBn: 'আপনার বাজার রিকোয়েস্ট বাতিল হয়েছে',
        bodyEn: 'Your market request was rejected',
        type: 'market_rejected',
        data: {'messId': messId, 'marketId': marketId},
      );
    }
  }

  Future<void> deleteMarket({
    required String messId,
    required String marketId,
  }) async {
    final snap = await _markets(messId).doc(marketId).get();
    final ym = snap.data()?['yearMonth'] as String?;
    if (ym != null) await _locks.assertUnlocked(messId, ym);
    await _markets(messId).doc(marketId).delete();
  }

  /// Live approved markets for a single day.
  Stream<List<MarketEntry>> watchMarketsForDay(String messId, String day) {
    return _markets(messId)
        .where('dateKey', isEqualTo: day)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MarketEntry.fromMap(d.id, d.data()))
              .where((e) => e.isApproved)
              .toList(),
        );
  }

  Future<List<MarketEntry>> marketsForDay(String messId, String day) async {
    final snap = await _markets(messId).where('dateKey', isEqualTo: day).get();
    return snap.docs
        .map((d) => MarketEntry.fromMap(d.id, d.data()))
        .where((e) => e.isApproved)
        .toList();
  }
}
