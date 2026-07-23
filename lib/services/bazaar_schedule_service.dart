import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bazaar_schedule.dart';
import 'notification_service.dart';

class BazaarScheduleService {
  BazaarScheduleService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notifications = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final NotificationService _notifications;

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

    if (!asAdmin) {
      await _notifications.notifyAdminsOfMess(
        messId: messId,
        titleBn: 'নতুন বাজার তারিখ অনুমোদন',
        titleEn: 'New bazaar date approval',
        bodyBn: '$memberName — $startDateKey → $endDateKey',
        bodyEn: '$memberName — $startDateKey → $endDateKey',
        type: 'bazaar_schedule_pending',
        data: {'messId': messId, 'startDateKey': startDateKey},
      );
    } else {
      await _notifications.notifyMessMembers(
        messId: messId,
        excludeUid: uid,
        titleBn: 'বাজার তারিখ নির্ধারিত',
        titleEn: 'Bazaar date scheduled',
        bodyBn: '$memberName — $startDateKey → $endDateKey',
        bodyEn: '$memberName — $startDateKey → $endDateKey',
        type: 'bazaar_schedule_approved_broadcast',
        data: {'messId': messId, 'startDateKey': startDateKey},
      );
    }
  }

  Future<void> approve({
    required String messId,
    required String scheduleId,
    required String adminUid,
  }) async {
    final snap = await _col(messId).doc(scheduleId).get();
    await _col(messId).doc(scheduleId).update({
      'status': BazaarScheduleStatus.approved.firestoreValue,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    final ownerUid = snap.data()?['uid'] as String?;
    final memberName = snap.data()?['memberName'] as String? ?? 'Member';
    final start = snap.data()?['startDateKey'] as String? ??
        snap.data()?['dateKey'] as String? ??
        '';
    final end = snap.data()?['endDateKey'] as String? ?? start;

    if (ownerUid != null && ownerUid != adminUid) {
      await _notifications.notifyUsers(
        uids: [ownerUid],
        titleBn: 'বাজার তারিখ অনুমোদিত ✅',
        titleEn: 'Bazaar date approved ✅',
        bodyBn: 'আপনার বাজার ডিউটি অনুমোদন হয়েছে ($start → $end)',
        bodyEn: 'Your bazaar duty was approved ($start → $end)',
        type: 'bazaar_schedule_approved',
        data: {'messId': messId, 'scheduleId': scheduleId},
      );
    }

    final members = await _firestore
        .collection('messes')
        .doc(messId)
        .collection('members')
        .get();
    final others = members.docs
        .map((d) => d.id)
        .where((id) => id != adminUid && id != ownerUid)
        .toList();
    if (others.isNotEmpty) {
      await _notifications.notifyUsers(
        uids: others,
        titleBn: 'বাজার তারিখ অনুমোদিত',
        titleEn: 'Bazaar date approved',
        bodyBn: '$memberName — $start → $end',
        bodyEn: '$memberName — $start → $end',
        type: 'bazaar_schedule_approved_broadcast',
        data: {'messId': messId, 'scheduleId': scheduleId},
      );
    }
  }

  Future<void> reject({
    required String messId,
    required String scheduleId,
    String? adminUid,
  }) async {
    final snap = await _col(messId).doc(scheduleId).get();
    final ownerUid = snap.data()?['uid'] as String?;
    await _col(messId).doc(scheduleId).delete();
    if (ownerUid != null && ownerUid != adminUid) {
      await _notifications.notifyUsers(
        uids: [ownerUid],
        titleBn: 'বাজার তারিখ বাতিল ❌',
        titleEn: 'Bazaar date rejected ❌',
        bodyBn: 'আপনার বাজার তারিখ রিকোয়েস্ট বাতিল হয়েছে',
        bodyEn: 'Your bazaar date request was rejected',
        type: 'bazaar_schedule_rejected',
        data: {'messId': messId},
      );
    }
  }

  Future<void> delete({
    required String messId,
    required String scheduleId,
  }) async {
    await _col(messId).doc(scheduleId).delete();
  }
}
