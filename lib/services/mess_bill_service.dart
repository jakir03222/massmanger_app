import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mess_bill.dart';
import 'month_lock_service.dart';
import 'notification_service.dart';

class MessBillService {
  MessBillService({
    FirebaseFirestore? firestore,
    MonthLockService? monthLockService,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _locks = monthLockService ?? MonthLockService(),
        _notifications = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final MonthLockService _locks;
  final NotificationService _notifications;

  CollectionReference<Map<String, dynamic>> _col(String messId) =>
      _firestore.collection('messes').doc(messId).collection('bills');

  Future<List<MessBill>> getByMonth(String messId, String yearMonth) async {
    final snap = await _col(messId)
        .where('yearMonth', isEqualTo: yearMonth)
        .get();
    final list = snap.docs
        .map((d) => MessBill.fromMap(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));
    return list;
  }

  Stream<List<MessBill>> watchByMonth(String messId, String yearMonth) {
    return _col(messId)
        .where('yearMonth', isEqualTo: yearMonth)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MessBill.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.type.index.compareTo(b.type.index));
      return list;
    });
  }

  Future<void> addBill({
    required String messId,
    required MessBillType type,
    required double amount,
    required String yearMonth,
    required String adminUid,
    required String adminName,
    required List<String> assignedMemberUids,
    String note = '',
  }) async {
    await _locks.assertUnlocked(messId, yearMonth);
    final assignees = assignedMemberUids.toSet().toList();
    if (assignees.isEmpty) {
      throw StateError('Select at least one member for this bill.');
    }
    await _col(messId).add({
      'type': type.firestoreValue,
      'amount': amount,
      'yearMonth': yearMonth,
      'note': note,
      'assignedMemberUids': assignees,
      'createdBy': adminUid,
      'createdByName': adminName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final notifyUids = assignees.where((id) => id != adminUid).toList();
    if (notifyUids.isNotEmpty) {
      await _notifications.notifyUsers(
        uids: notifyUids,
        titleBn: 'নতুন বিল',
        titleEn: 'New bill',
        bodyBn:
            '${type.label(bn: true)}: ৳${amount.toStringAsFixed(0)} ($yearMonth)',
        bodyEn:
            '${type.label(bn: false)}: ৳${amount.toStringAsFixed(0)} ($yearMonth)',
        type: 'bill_added',
        data: {'messId': messId, 'yearMonth': yearMonth},
      );
    }
  }

  Future<void> updateBill({
    required String messId,
    required String billId,
    required MessBillType type,
    required double amount,
    required String yearMonth,
    required List<String> assignedMemberUids,
    String note = '',
  }) async {
    await _locks.assertUnlocked(messId, yearMonth);
    final assignees = assignedMemberUids.toSet().toList();
    if (assignees.isEmpty) {
      throw StateError('Select at least one member for this bill.');
    }
    await _col(messId).doc(billId).update({
      'type': type.firestoreValue,
      'amount': amount,
      'yearMonth': yearMonth,
      'note': note,
      'assignedMemberUids': assignees,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBill({
    required String messId,
    required String billId,
  }) async {
    final snap = await _col(messId).doc(billId).get();
    final ym = snap.data()?['yearMonth'] as String?;
    if (ym != null) await _locks.assertUnlocked(messId, ym);
    await _col(messId).doc(billId).delete();
  }
}
