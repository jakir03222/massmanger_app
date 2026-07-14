import 'package:cloud_firestore/cloud_firestore.dart';

class MonthLockedException implements Exception {
  MonthLockedException([this.message = 'এই মাস লক করা আছে — পরিবর্তন করা যায় না।']);
  final String message;

  @override
  String toString() => message;
}

class MonthLockService {
  MonthLockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String messId, String yearMonth) =>
      _firestore
          .collection('messes')
          .doc(messId)
          .collection('month_locks')
          .doc(yearMonth);

  Stream<bool> watchLocked(String messId, String yearMonth) {
    return _doc(messId, yearMonth).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return false;
      return snap.data()!['locked'] == true;
    });
  }

  Future<bool> isLocked(String messId, String yearMonth) async {
    final snap = await _doc(messId, yearMonth).get();
    if (!snap.exists || snap.data() == null) return false;
    return snap.data()!['locked'] == true;
  }

  Future<void> assertUnlocked(String messId, String yearMonth) async {
    if (await isLocked(messId, yearMonth)) {
      throw MonthLockedException();
    }
  }

  Future<void> setLocked({
    required String messId,
    required String yearMonth,
    required bool locked,
    required String adminUid,
  }) async {
    await _doc(messId, yearMonth).set({
      'locked': locked,
      'yearMonth': yearMonth,
      'lockedAt': FieldValue.serverTimestamp(),
      'lockedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// YYYY-MM from dateKey YYYY-MM-DD or already YYYY-MM.
  static String yearMonthFromDateKey(String dateKey) {
    if (dateKey.length >= 7) return dateKey.substring(0, 7);
    return dateKey;
  }
}
