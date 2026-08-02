import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member_payment.dart';
import 'month_lock_service.dart';
import 'notification_service.dart';

class PaymentService {
  PaymentService({
    FirebaseFirestore? firestore,
    MonthLockService? monthLockService,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _locks = monthLockService ?? MonthLockService(),
        _notifications = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final MonthLockService _locks;
  final NotificationService _notifications;

  DocumentReference<Map<String, dynamic>> _doc(
    String messId,
    String yearMonth,
    String uid,
  ) =>
      _firestore
          .collection('messes')
          .doc(messId)
          .collection('payments')
          .doc(yearMonth)
          .collection('members')
          .doc(uid);

  CollectionReference<Map<String, dynamic>> _membersCol(
    String messId,
    String yearMonth,
  ) =>
      _firestore
          .collection('messes')
          .doc(messId)
          .collection('payments')
          .doc(yearMonth)
          .collection('members');

  Stream<Map<String, MemberPayment>> watchMonthPayments({
    required String messId,
    required String yearMonth,
  }) {
    return _membersCol(messId, yearMonth).snapshots().map((snap) {
      final map = <String, MemberPayment>{};
      for (final d in snap.docs) {
        map[d.id] = MemberPayment.fromMap(d.id, yearMonth, d.data());
      }
      return map;
    });
  }

  Future<void> setPaid({
    required String messId,
    required String yearMonth,
    required String uid,
    required bool paid,
    required String adminUid,
    double amount = 0,
    String note = '',
    String? memberName,
  }) async {
    await _locks.assertUnlocked(messId, yearMonth);
    await _doc(messId, yearMonth, uid).set({
      'uid': uid,
      'yearMonth': yearMonth,
      'paid': paid,
      'amount': amount,
      'note': note.trim(),
      'updatedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (uid != adminUid) {
      await _notifications.notifyUsers(
        uids: [uid],
        titleBn: paid ? 'পেমেন্ট পেইড ✅' : 'পেমেন্ট আনপেইড',
        titleEn: paid ? 'Payment marked paid ✅' : 'Payment marked unpaid',
        bodyBn: paid
            ? 'আপনার $yearMonth হিসাব পেইড হয়েছে'
            : 'আপনার $yearMonth হিসাব আনপেইড করা হয়েছে',
        bodyEn: paid
            ? 'Your $yearMonth account was marked paid'
            : 'Your $yearMonth account was marked unpaid',
        type: 'payment_status',
        data: {'messId': messId, 'yearMonth': yearMonth, 'paid': paid},
      );
    }
  }
}
