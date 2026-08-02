import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bazaar_swap_request.dart';
import 'month_lock_service.dart';
import 'notification_service.dart';

class BazaarSwapException implements Exception {
  BazaarSwapException(this.message);
  final String message;
  @override
  String toString() => message;
}

String _firebaseErrorMessage(Object e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'অনুমতি নেই — Firestore rules আপডেট/ডিপ্লয় করুন, অথবা আবার লগইন করুন।';
      case 'unavailable':
        return 'নেটওয়ার্ক সমস্যা — ইন্টারনেট চেক করে আবার চেষ্টা করুন।';
      default:
        return e.message ?? e.code;
    }
  }
  return e.toString();
}

/// Same-mess bazaar date swap.
///
/// Flow:
///   1. Member picks own date + another same-mess member's date → pending
///   2. Admin approves → atomic schedule swap + notify both
///      OR rejects → notify requester
///   3. Requester can cancel while pending
class BazaarSwapService {
  BazaarSwapService({
    FirebaseFirestore? firestore,
    NotificationService? notifications,
    MonthLockService? locks,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notifications = notifications ?? NotificationService(),
        _locks = locks ?? MonthLockService();

  final FirebaseFirestore _firestore;
  final NotificationService _notifications;
  final MonthLockService _locks;

  CollectionReference<Map<String, dynamic>> _col(String messId) => _firestore
      .collection('messes')
      .doc(messId)
      .collection('bazaar_swap_requests');

  CollectionReference<Map<String, dynamic>> _schedules(String messId) =>
      _firestore.collection('messes').doc(messId).collection('bazaar_schedules');

  Stream<List<BazaarSwapRequest>> watchAll(String messId) {
    // No orderBy — avoids requiring a composite index; sort client-side.
    return _col(messId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => BazaarSwapRequest.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Stream<List<BazaarSwapRequest>> watchPending(String messId) =>
      watchAll(messId).map((l) => l.where((r) => r.isPending).toList());

  Stream<List<BazaarSwapRequest>> watchMine(String messId, String uid) =>
      watchAll(messId).map(
        (l) => l
            .where((r) => r.requesterUid == uid || r.targetUid == uid)
            .toList(),
      );

  /// Member requests swap with another same-mess member.
  Future<void> requestSwap({
    required String messId,
    required String requesterUid,
    required String requesterName,
    required String scheduleId,
    required String dateKey,
    required String endDateKey,
    required String yearMonth,
    required String targetUid,
    required String targetName,
    required String targetScheduleId,
    required String targetDateKey,
    required String targetEndDateKey,
    String? note,
  }) async {
    if (requesterUid == targetUid) {
      throw BazaarSwapException('নিজের সাথে swap করা যাবে না।');
    }
    await _locks.assertUnlocked(messId, yearMonth);
    _assertNotPast(dateKey);
    _assertNotPast(targetDateKey);

    final existing = await _col(messId)
        .where('requesterUid', isEqualTo: requesterUid)
        .where('scheduleId', isEqualTo: scheduleId)
        .get();
    final openDup = existing.docs.where((d) {
      final st = BazaarSwapStatus.fromString(d.data()['status'] as String?);
      return st == BazaarSwapStatus.pending;
    });
    if (openDup.isNotEmpty) {
      throw BazaarSwapException(
          'এই তারিখের জন্য ইতিমধ্যে একটি swap request চলমান আছে।');
    }

    try {
      await _col(messId).add({
        'messId': messId,
        'requesterUid': requesterUid,
        'requesterName': requesterName,
        'scheduleId': scheduleId,
        'dateKey': dateKey,
        'endDateKey': endDateKey,
        'yearMonth': yearMonth,
        'targetUid': targetUid,
        'targetName': targetName,
        'targetScheduleId': targetScheduleId,
        'targetDateKey': targetDateKey,
        'targetEndDateKey': targetEndDateKey,
        'note': note,
        'status': BazaarSwapStatus.pending.firestoreValue,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw BazaarSwapException(_firebaseErrorMessage(e));
    }

    // Notify partner + all admins / super admins
    try {
      await _notifications.notifyUsers(
        uids: [targetUid],
        titleBn: 'বাজার swap অনুরোধ',
        titleEn: 'Bazaar swap request',
        bodyBn:
            '$requesterName আপনার সাথে swap করতে চান ($dateKey ↔ $targetDateKey)',
        bodyEn:
            '$requesterName wants to swap with you ($dateKey ↔ $targetDateKey)',
        type: 'bazaar_swap_request',
        data: {'messId': messId},
      );

      await _notifications.notifyAdminsOfMess(
        messId: messId,
        titleBn: 'নতুন বাজার swap অনুরোধ',
        titleEn: 'New bazaar swap request',
        bodyBn:
            '$requesterName ↔ $targetName ($dateKey ↔ $targetDateKey) — অনুমোদন দিন',
        bodyEn:
            '$requesterName ↔ $targetName ($dateKey ↔ $targetDateKey) — please approve',
        type: 'bazaar_swap_request',
        data: {'messId': messId},
      );
    } catch (_) {
      // Request already saved — notification failure should not block UI.
    }
  }

  /// Admin approves — uses the partner already chosen by the member.
  Future<void> approveByAdmin({
    required String messId,
    required String swapId,
    required String adminUid,
  }) async {
    final doc = await _col(messId).doc(swapId).get();
    final data = doc.data();
    if (data == null) throw BazaarSwapException('Request পাওয়া যায়নি।');
    final status = BazaarSwapStatus.fromString(data['status'] as String?);
    if (status != BazaarSwapStatus.pending) {
      throw BazaarSwapException('শুধু pending requests approve করা যাবে।');
    }

    final ym = data['yearMonth'] as String? ?? '';
    if (ym.isNotEmpty) await _locks.assertUnlocked(messId, ym);

    final rScheduleId = data['scheduleId'] as String;
    final rUid = data['requesterUid'] as String;
    final rName = data['requesterName'] as String? ?? '';
    final rStart = data['dateKey'] as String;
    final rEnd = data['endDateKey'] as String? ?? rStart;

    final tUid = (data['targetUid'] as String?) ??
        (data['swappedWithUid'] as String?);
    final tName = (data['targetName'] as String?) ??
        (data['swappedWithName'] as String?) ??
        '';
    final tScheduleId = (data['targetScheduleId'] as String?) ??
        (data['swappedWithScheduleId'] as String?);
    final tStart = (data['targetDateKey'] as String?) ??
        (data['swappedWithDateKey'] as String?);
    final tEnd = (data['targetEndDateKey'] as String?) ??
        (data['swappedWithEndDateKey'] as String?) ??
        tStart;

    if (tUid == null ||
        tScheduleId == null ||
        tStart == null ||
        tStart.isEmpty) {
      throw BazaarSwapException(
          'এই request-এ partner নির্ধারিত নেই। মেম্বারকে নতুন করে অনুরোধ করতে বলুন।');
    }

    final batch = _firestore.batch();

    batch.update(_schedules(messId).doc(rScheduleId), {
      'uid': tUid,
      'memberName': tName,
      'startDateKey': rStart,
      'endDateKey': rEnd,
      'dateKey': rStart,
    });

    batch.update(_schedules(messId).doc(tScheduleId), {
      'uid': rUid,
      'memberName': rName,
      'startDateKey': tStart,
      'endDateKey': tEnd,
      'dateKey': tStart,
    });

    batch.update(_col(messId).doc(swapId), {
      'status': BazaarSwapStatus.approved.firestoreValue,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
    });

    try {
      await batch.commit();
    } catch (e) {
      throw BazaarSwapException(_firebaseErrorMessage(e));
    }

    try {
      await _notifications.notifyUsers(
        uids: [rUid, tUid],
        titleBn: 'বাজার swap সম্পন্ন ✅',
        titleEn: 'Bazaar swap done ✅',
        bodyBn: '$rName ($rStart) ↔ $tName ($tStart) swap হয়েছে।',
        bodyEn: '$rName ($rStart) ↔ $tName ($tStart) swap complete.',
        type: 'bazaar_swap_approved',
        data: {'messId': messId, 'swapId': swapId},
      );
    } catch (_) {}
  }

  Future<void> rejectByAdmin({
    required String messId,
    required String swapId,
    required String adminUid,
  }) async {
    final doc = await _col(messId).doc(swapId).get();
    final data = doc.data();
    if (data == null) throw BazaarSwapException('Request পাওয়া যায়নি।');

    final rUid = data['requesterUid'] as String?;
    final tUid = data['targetUid'] as String?;
    final dateKey = data['dateKey'] as String? ?? '';

    await _col(messId).doc(swapId).update({
      'status': BazaarSwapStatus.rejected.firestoreValue,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
    });

    final uids = [rUid, tUid].whereType<String>().toSet().toList();
    if (uids.isNotEmpty) {
      await _notifications.notifyUsers(
        uids: uids,
        titleBn: 'Swap অনুরোধ বাতিল',
        titleEn: 'Swap request rejected',
        bodyBn: '$dateKey তারিখের swap অনুরোধ অ্যাডমিন বাতিল করেছেন।',
        bodyEn: 'Admin rejected the swap request for $dateKey.',
        type: 'bazaar_swap_rejected',
        data: {'messId': messId},
      );
    }
  }

  Future<void> cancelByRequester({
    required String messId,
    required String swapId,
    required String requesterUid,
  }) async {
    final doc = await _col(messId).doc(swapId).get();
    final data = doc.data();
    if (data == null) throw BazaarSwapException('Request পাওয়া যায়নি।');
    if (data['requesterUid'] != requesterUid) {
      throw BazaarSwapException('শুধু অনুরোধকারী নিজে বাতিল করতে পারবেন।');
    }
    if (BazaarSwapStatus.fromString(data['status'] as String?) !=
        BazaarSwapStatus.pending) {
      throw BazaarSwapException('এই request আর pending নেই।');
    }

    await _col(messId).doc(swapId).update({
      'status': BazaarSwapStatus.cancelled.firestoreValue,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin / Super admin immediately swaps two approved schedules (no request).
  /// Restricted to schedules in [yearMonth] (typically current month).
  Future<void> adminDirectSwap({
    required String messId,
    required String adminUid,
    required String scheduleAId,
    required String uidA,
    required String nameA,
    required String dateKeyA,
    required String endDateKeyA,
    required String scheduleBId,
    required String uidB,
    required String nameB,
    required String dateKeyB,
    required String endDateKeyB,
    required String yearMonth,
  }) async {
    if (uidA == uidB) {
      throw BazaarSwapException('একই সদস্যের দুই তারিখ এইভাবে swap করা যাবে না।');
    }
    await _locks.assertUnlocked(messId, yearMonth);

    final batch = _firestore.batch();

    batch.update(_schedules(messId).doc(scheduleAId), {
      'uid': uidB,
      'memberName': nameB,
      'startDateKey': dateKeyA,
      'endDateKey': endDateKeyA,
      'dateKey': dateKeyA,
    });
    batch.update(_schedules(messId).doc(scheduleBId), {
      'uid': uidA,
      'memberName': nameA,
      'startDateKey': dateKeyB,
      'endDateKey': endDateKeyB,
      'dateKey': dateKeyB,
    });

    final auditRef = _col(messId).doc();
    batch.set(auditRef, {
      'messId': messId,
      'requesterUid': uidA,
      'requesterName': nameA,
      'scheduleId': scheduleAId,
      'dateKey': dateKeyA,
      'endDateKey': endDateKeyA,
      'yearMonth': yearMonth,
      'targetUid': uidB,
      'targetName': nameB,
      'targetScheduleId': scheduleBId,
      'targetDateKey': dateKeyB,
      'targetEndDateKey': endDateKeyB,
      'note': 'Admin direct swap (no member request)',
      'status': BazaarSwapStatus.approved.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'directByAdmin': true,
    });

    try {
      await batch.commit();
    } catch (e) {
      throw BazaarSwapException(_firebaseErrorMessage(e));
    }

    try {
      await _notifications.notifyUsers(
        uids: [uidA, uidB],
        titleBn: 'বাজার তারিখ পরিবর্তন ✅',
        titleEn: 'Bazaar schedule changed ✅',
        bodyBn: 'অ্যাডমিন আপনার বাজার স্লট পরিবর্তন করেছেন: $nameA ($dateKeyA) ↔ $nameB ($dateKeyB)',
        bodyEn: 'Admin changed your bazaar slot: $nameA ($dateKeyA) ↔ $nameB ($dateKeyB)',
        type: 'bazaar_swap_approved',
        data: {'messId': messId},
      );
    } catch (_) {}
  }

  /// Admin / Super admin reassigns one schedule slot to another mess member.
  /// No member request. No need for the new member to already have a slot.
  Future<void> adminReassignSlot({
    required String messId,
    required String adminUid,
    required String scheduleId,
    required String fromUid,
    required String fromName,
    required String dateKey,
    required String endDateKey,
    required String yearMonth,
    required String toUid,
    required String toName,
  }) async {
    if (fromUid == toUid) {
      throw BazaarSwapException('একই সদস্যকে আবার assign করা যাবে না।');
    }
    await _locks.assertUnlocked(messId, yearMonth);

    final batch = _firestore.batch();
    batch.update(_schedules(messId).doc(scheduleId), {
      'uid': toUid,
      'memberName': toName,
    });

    final auditRef = _col(messId).doc();
    batch.set(auditRef, {
      'messId': messId,
      'requesterUid': fromUid,
      'requesterName': fromName,
      'scheduleId': scheduleId,
      'dateKey': dateKey,
      'endDateKey': endDateKey,
      'yearMonth': yearMonth,
      'targetUid': toUid,
      'targetName': toName,
      'targetScheduleId': scheduleId,
      'targetDateKey': dateKey,
      'targetEndDateKey': endDateKey,
      'note': 'Admin reassign slot (no member request)',
      'status': BazaarSwapStatus.approved.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'directByAdmin': true,
      'reassignOnly': true,
    });

    try {
      await batch.commit();
    } catch (e) {
      throw BazaarSwapException(_firebaseErrorMessage(e));
    }

    try {
      await _notifications.notifyUsers(
        uids: [fromUid, toUid],
        titleBn: 'বাজার স্লট পরিবর্তন ✅',
        titleEn: 'Bazaar slot reassigned ✅',
        bodyBn: '$dateKey — এখন দায়িত্ব: $toName (আগে: $fromName)',
        bodyEn: '$dateKey — now assigned to $toName (was: $fromName)',
        type: 'bazaar_swap_approved',
        data: {'messId': messId},
      );
    } catch (_) {}
  }

  /// True if [yearMonth] is the current calendar month (YYYY-MM).
  static bool isCurrentMonth(String yearMonth) {
    final now = DateTime.now();
    final cur =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    return yearMonth == cur;
  }

  static String currentYearMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  static void _assertNotPast(String dateKey) {
    final date = _parseKey(dateKey);
    if (date == null) return;
    if (date.isBefore(_today())) {
      throw BazaarSwapException('অতীতের তারিখের বাজার swap করা যাবে না।');
    }
  }

  /// Schedule is swappable if its range has not fully ended (end >= today).
  static bool isSwappable(String startDateKey, [String? endDateKey]) {
    final end = _parseKey(endDateKey ?? startDateKey) ?? _parseKey(startDateKey);
    if (end == null) return false;
    return !end.isBefore(_today());
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? _parseKey(String key) {
    final p = key.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
