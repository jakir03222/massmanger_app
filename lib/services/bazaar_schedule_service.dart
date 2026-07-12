import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bazaar_schedule.dart';

class BazaarScheduleService {
  BazaarScheduleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String messId) =>
      _firestore.collection('messes').doc(messId).collection('bazaar_schedules');

  List<BazaarSchedule> _sorted(List<BazaarSchedule> list) {
    list.sort((a, b) {
      final c = a.dateKey.compareTo(b.dateKey);
      if (c != 0) return c;
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
    return list;
  }

  Stream<List<BazaarSchedule>> watchAll(String messId) {
    return _col(messId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => BazaarSchedule.fromMap(d.id, d.data()))
          .toList();
      return _sorted(list);
    });
  }

  Stream<List<BazaarSchedule>> watchApproved(String messId) {
    return watchAll(messId).map(
      (list) => list.where((e) => e.isApproved).toList(),
    );
  }

  Stream<List<BazaarSchedule>> watchPending(String messId) {
    return watchAll(messId).map(
      (list) => list.where((e) => e.isPending).toList(),
    );
  }

  Future<void> requestSchedule({
    required String messId,
    required String uid,
    required String memberName,
    required String startDateKey,
    required String endDateKey,
    required String yearMonth,
    required bool asAdmin,
  }) async {
    final status = asAdmin
        ? BazaarScheduleStatus.approved
        : BazaarScheduleStatus.pending;
    await _col(messId).add({
      'uid': uid,
      'memberName': memberName,
      'startDateKey': startDateKey,
      'endDateKey': endDateKey,
      // Keep dateKey for older clients / sorting compatibility.
      'dateKey': startDateKey,
      'yearMonth': yearMonth,
      'status': status.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
      if (asAdmin) 'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approve({
    required String messId,
    required String scheduleId,
    required String adminUid,
  }) async {
    await _col(messId).doc(scheduleId).update({
      'status': BazaarScheduleStatus.approved.firestoreValue,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reject({
    required String messId,
    required String scheduleId,
  }) async {
    await _col(messId).doc(scheduleId).delete();
  }

  Future<void> delete({
    required String messId,
    required String scheduleId,
  }) async {
    await _col(messId).doc(scheduleId).delete();
  }
}
