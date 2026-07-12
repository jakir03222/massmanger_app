import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mess_bill.dart';

class MessBillService {
  MessBillService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String messId) =>
      _firestore.collection('messes').doc(messId).collection('bills');

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
    String note = '',
  }) async {
    await _col(messId).add({
      'type': type.firestoreValue,
      'amount': amount,
      'yearMonth': yearMonth,
      'note': note,
      'createdBy': adminUid,
      'createdByName': adminName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBill({
    required String messId,
    required String billId,
    required MessBillType type,
    required double amount,
    required String yearMonth,
    String note = '',
  }) async {
    await _col(messId).doc(billId).update({
      'type': type.firestoreValue,
      'amount': amount,
      'yearMonth': yearMonth,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBill({
    required String messId,
    required String billId,
  }) async {
    await _col(messId).doc(billId).delete();
  }
}
