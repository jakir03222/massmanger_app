import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meal_entry.dart';
import '../utils/date_formatters.dart' show dateKey;
import 'month_lock_service.dart';
import 'notification_service.dart';

class MealService {
  MealService({
    FirebaseFirestore? firestore,
    MonthLockService? monthLockService,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _locks = monthLockService ?? MonthLockService(),
        _notifications = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final MonthLockService _locks;
  final NotificationService _notifications;

  CollectionReference<Map<String, dynamic>> _items(String messId, String day) =>
      _firestore
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .doc(day)
          .collection('items');

  /// Legacy combined entries (read-only expand for old data).
  CollectionReference<Map<String, dynamic>> _legacyEntries(
    String messId,
    String day,
  ) =>
      _firestore
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .doc(day)
          .collection('entries');

  List<MealEntry> _expandLegacy(String day, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data['type'] != null) {
      return [MealEntry.fromMap(doc.id, data, day: day)];
    }
    final uid = doc.id;
    final name = data['name'] as String? ?? 'সদস্য';
    final status = MealStatus.fromString(data['status'] as String?);
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final list = <MealEntry>[];
    final morning = data['morning'] as bool? ?? data['lunch'] as bool? ?? false;
    final evening = data['evening'] as bool? ?? false;
    final night = data['night'] as bool? ?? data['dinner'] as bool? ?? false;
    final rate = (data['mealRate'] as num?)?.toDouble() ?? 0;
    void add(MealType type, [double rateValue = 1]) {
      list.add(MealEntry(
        id: '${doc.id}_${type.name}',
        uid: uid,
        name: name,
        type: type,
        rateValue: rateValue,
        status: status,
        dateKey: day,
        createdAt: createdAt,
      ));
    }
    if (morning) add(MealType.morning);
    if (evening) add(MealType.evening);
    if (night) add(MealType.night);
    if (rate > 0) add(MealType.rate, rate);
    return list;
  }

  Stream<List<MealEntry>> watchDayMeals(String messId, String day) {
    return _items(messId, day).snapshots().asyncMap((itemsSnap) async {
      final list = <MealEntry>[];
      for (final d in itemsSnap.docs) {
        list.add(MealEntry.fromMap(d.id, d.data(), day: day));
      }
      // Legacy only when no modern items (avoids double-count).
      if (list.isEmpty) {
        final legacy = await _legacyEntries(messId, day).get();
        for (final d in legacy.docs) {
          list.addAll(_expandLegacy(day, d));
        }
      }
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Future<void> addMealItem({
    required String messId,
    required String day,
    required String uid,
    required String name,
    required MealType type,
    double rateValue = 1,
    required bool asAdmin,
    String? addedByUid,
    String? addedByName,
  }) async {
    await _locks.assertUnlocked(
      messId,
      MonthLockService.yearMonthFromDateKey(day),
    );
    final status = asAdmin ? MealStatus.approved : MealStatus.pending;
    final data = <String, dynamic>{
      'uid': uid,
      'name': name,
      'type': type.firestoreValue,
      'rateValue': rateValue,
      'status': status.firestoreValue,
      'dateKey': day,
      'messId': messId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Admin added for a member → store admin name on the meal.
    if (asAdmin &&
        addedByUid != null &&
        addedByName != null &&
        addedByUid != uid) {
      data['addedByUid'] = addedByUid;
      data['addedByName'] = addedByName;
    }
    await _items(messId, day).add(data);

    if (!asAdmin) {
      await _notifications.notifyAdminsOfMess(
        messId: messId,
        titleBn: 'নতুন মিল অনুমোদন',
        titleEn: 'New meal approval',
        bodyBn: '$name — ${type.label(bn: true)} ($day)',
        bodyEn: '$name — ${type.label(bn: false)} ($day)',
        type: 'meal_pending',
        data: {'messId': messId, 'day': day},
      );
    } else {
      await _notifications.notifyMessMembers(
        messId: messId,
        excludeUid: addedByUid ?? uid,
        titleBn: 'নতুন মিল অনুমোদিত',
        titleEn: 'New meal approved',
        bodyBn: '$name — ${type.label(bn: true)} ($day)',
        bodyEn: '$name — ${type.label(bn: false)} ($day)',
        type: 'meal_approved_broadcast',
        data: {'messId': messId, 'day': day},
      );
    }
  }

  /// Admin/super-admin bulk add with per-member × per-type quantities.
  /// Writes approved meals, recalculates via live streams, and notifies
  /// each affected member with their own meal summary.
  Future<BulkMealAddResult> addMealsBulk({
    required String messId,
    required String day,
    required List<
            ({
              String uid,
              String name,
              Map<MealType, double> quantities,
            })>
        memberMeals,
    required String addedByUid,
    required String addedByName,
  }) async {
    final rows = <({String uid, String name, MealType type, double qty})>[];
    for (final m in memberMeals) {
      for (final e in m.quantities.entries) {
        if (e.key != MealType.morning &&
            e.key != MealType.evening &&
            e.key != MealType.night) {
          continue;
        }
        if (e.value < 0.5) continue;
        rows.add((
          uid: m.uid,
          name: m.name,
          type: e.key,
          qty: e.value,
        ));
      }
    }
    if (rows.isEmpty) {
      return const BulkMealAddResult(
        written: 0,
        memberCount: 0,
        morningTotal: 0,
        eveningTotal: 0,
        nightTotal: 0,
      );
    }
    await _locks.assertUnlocked(
      messId,
      MonthLockService.yearMonthFromDateKey(day),
    );

    var written = 0;
    var morningTotal = 0.0;
    var eveningTotal = 0.0;
    var nightTotal = 0.0;
    WriteBatch? batch;
    var opsInBatch = 0;

    Future<void> commitBatch() async {
      if (batch == null || opsInBatch == 0) return;
      await batch!.commit();
      batch = null;
      opsInBatch = 0;
    }

    for (final row in rows) {
      final qty = row.qty < 0.5 ? 0.5 : row.qty;
      batch ??= _firestore.batch();
      final ref = _items(messId, day).doc();
      final data = <String, dynamic>{
        'uid': row.uid,
        'name': row.name,
        'type': row.type.firestoreValue,
        'rateValue': qty,
        'status': MealStatus.approved.firestoreValue,
        'dateKey': day,
        'messId': messId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (addedByUid != row.uid) {
        data['addedByUid'] = addedByUid;
        data['addedByName'] = addedByName;
      }
      batch!.set(ref, data);
      opsInBatch++;
      written++;
      switch (row.type) {
        case MealType.morning:
          morningTotal += qty;
        case MealType.evening:
          eveningTotal += qty;
        case MealType.night:
          nightTotal += qty;
        case MealType.rate:
        case MealType.guest:
          break;
      }
      if (opsInBatch >= 450) {
        await commitBatch();
      }
    }
    await commitBatch();

    final memberCount = memberMeals.map((m) => m.uid).toSet().length;

    final grand = morningTotal + eveningTotal + nightTotal;
    final grandLabel =
        grand % 1 == 0 ? grand.toInt().toString() : grand.toStringAsFixed(1);

    // Personal inbox notification for each member who received meals.
    for (final m in memberMeals) {
      if (m.uid == addedByUid) continue;
      final partsBn = <String>[];
      final partsEn = <String>[];
      for (final type in [
        MealType.morning,
        MealType.evening,
        MealType.night,
      ]) {
        final q = m.quantities[type];
        if (q == null || q < 0.5) continue;
        final qLabel =
            q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);
        partsBn.add('${type.label(bn: true)} $qLabel');
        partsEn.add('${type.label(bn: false)} $qLabel');
      }
      if (partsBn.isEmpty) continue;
      await _notifications.notifyUsers(
        uids: [m.uid],
        titleBn: 'আপনার মিল যোগ হয়েছে ✅',
        titleEn: 'Your meals were added ✅',
        bodyBn: '$addedByName যোগ করেছেন · ${partsBn.join(' · ')} ($day)',
        bodyEn: '$addedByName added · ${partsEn.join(' · ')} ($day)',
        type: 'meal_bulk_personal',
        data: {'messId': messId, 'day': day},
      );
    }

    // Broadcast so other members / devices also see a mess-wide update.
    await _notifications.notifyMessMembers(
      messId: messId,
      excludeUid: addedByUid,
      titleBn: 'মেসে নতুন মিল যোগ',
      titleEn: 'New meals in mess',
      bodyBn: '$addedByName — $memberCount মেম্বার · মোট $grandLabel মিল ($day)',
      bodyEn:
          '$addedByName — $memberCount members · total $grandLabel meals ($day)',
      type: 'meal_bulk_approved',
      data: {'messId': messId, 'day': day},
    );

    return BulkMealAddResult(
      written: written,
      memberCount: memberCount,
      morningTotal: morningTotal,
      eveningTotal: eveningTotal,
      nightTotal: nightTotal,
    );
  }

  Future<void> approveMeal({
    required String messId,
    required String day,
    required String itemId,
    required String adminUid,
  }) async {
    await _locks.assertUnlocked(
      messId,
      MonthLockService.yearMonthFromDateKey(day),
    );
    final legacyTypes = ['_morning', '_evening', '_night', '_rate'];
    if (legacyTypes.any(itemId.endsWith)) return;
    final ref = _items(messId, day).doc(itemId);
    final snap = await ref.get();
    await ref.update({
      'status': MealStatus.approved.firestoreValue,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final ownerUid = snap.data()?['uid'] as String?;
    final ownerName = snap.data()?['name'] as String? ?? 'Member';
    final typeRaw = snap.data()?['type'] as String? ?? '';
    final mealType = MealType.fromString(typeRaw);
    final typeLabelBn = mealType.label(bn: true);
    final typeLabelEn = mealType.label(bn: false);

    // Requester gets a personal approval notice.
    if (ownerUid != null && ownerUid != adminUid) {
      await _notifications.notifyUsers(
        uids: [ownerUid],
        titleBn: 'মিল অনুমোদিত ✅',
        titleEn: 'Meal approved ✅',
        bodyBn: 'আপনার $typeLabelBn মিল অনুমোদন হয়েছে ($day)',
        bodyEn: 'Your $typeLabelEn meal has been approved ($day)',
        type: 'meal_approved',
        data: {'messId': messId, 'day': day},
      );
    }

    // Other mess members also learn about the approval.
    final snapMembers = await _firestore
        .collection('messes')
        .doc(messId)
        .collection('members')
        .get();
    final others = snapMembers.docs
        .map((d) => d.id)
        .where((id) => id != adminUid && id != ownerUid)
        .toList();
    if (others.isNotEmpty) {
      await _notifications.notifyUsers(
        uids: others,
        titleBn: 'মিল অনুমোদিত',
        titleEn: 'Meal approved',
        bodyBn: '$ownerName — $typeLabelBn ($day)',
        bodyEn: '$ownerName — $typeLabelEn ($day)',
        type: 'meal_approved_broadcast',
        data: {'messId': messId, 'day': day, 'uid': ownerUid},
      );
    }
  }

  /// Reject = remove from list entirely (not counted in hisab).
  Future<void> rejectMeal({
    required String messId,
    required String day,
    required String itemId,
    required String adminUid,
  }) async {
    await _locks.assertUnlocked(
      messId,
      MonthLockService.yearMonthFromDateKey(day),
    );
    final legacyTypes = ['_morning', '_evening', '_night', '_rate'];
    if (legacyTypes.any(itemId.endsWith)) return;
    final ref = _items(messId, day).doc(itemId);
    final snap = await ref.get();
    final ownerUid = snap.data()?['uid'] as String?;
    await ref.delete();
    if (ownerUid != null && ownerUid != adminUid) {
      await _notifications.notifyUsers(
        uids: [ownerUid],
        titleBn: 'মিল বাতিল ❌',
        titleEn: 'Meal rejected ❌',
        bodyBn: 'আপনার মিল রিকোয়েস্ট বাতিল হয়েছে ($day)',
        bodyEn: 'Your meal request was rejected ($day)',
        type: 'meal_rejected',
        data: {'messId': messId, 'day': day},
      );
    }
  }

  Future<void> updateMealItem({
    required String messId,
    required String day,
    required String itemId,
    required double rateValue,
    required String editedByUid,
    required String editedByName,
  }) async {
    await _locks.assertUnlocked(
      messId,
      MonthLockService.yearMonthFromDateKey(day),
    );
    final legacyTypes = ['_morning', '_evening', '_night', '_rate'];
    if (legacyTypes.any(itemId.endsWith)) return;
    await _items(messId, day).doc(itemId).update({
      'rateValue': rateValue,
      'editedByUid': editedByUid,
      'editedByName': editedByName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMeal({
    required String messId,
    required String day,
    required String itemId,
  }) async {
    await _locks.assertUnlocked(
      messId,
      MonthLockService.yearMonthFromDateKey(day),
    );
    final legacyTypes = ['_morning', '_evening', '_night', '_rate'];
    if (legacyTypes.any(itemId.endsWith)) return;
    await _items(messId, day).doc(itemId).delete();
  }

  /// One-shot day read (no live stream) — used for month totals.
  Future<List<MealEntry>> getDayMeals(String messId, String day) async {
    final itemsSnap = await _items(messId, day).get();
    final list = <MealEntry>[];
    for (final d in itemsSnap.docs) {
      list.add(MealEntry.fromMap(d.id, d.data(), day: day));
    }
    if (list.isEmpty) {
      final legacy = await _legacyEntries(messId, day).get();
      for (final d in legacy.docs) {
        list.addAll(_expandLegacy(day, d));
      }
    }
    return list;
  }

  /// Live month meal totals — re-emits when any meal item in the month changes.
  ///
  /// Uses per-day paths (same as day meal screen) so we don't depend on a
  /// collection-group index / rules, which previously caused monthly totals
  /// to stay at 0 while "আজ মিল" still worked.
  Stream<Map<String, double>> watchMonthMealCounts(
    String messId,
    DateTime month,
  ) {
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final endDay =
        isCurrentMonth ? now.day.clamp(1, daysInMonth) : daysInMonth;

    final days = [
      for (var d = 1; d <= endDay; d++)
        dateKey(DateTime(month.year, month.month, d)),
    ];

    return _watchMonthMealCountsByDay(messId, days);
  }

  Stream<Map<String, double>> _watchMonthMealCountsByDay(
    String messId,
    List<String> days,
  ) {
    if (days.isEmpty) return Stream.value({});

    final dayCounts = <String, Map<String, double>>{};
    final ready = <String>{};
    late StreamController<Map<String, double>> out;
    final subs = <StreamSubscription<List<MealEntry>>>[];

    void emit() {
      if (ready.length < days.length) return;
      final merged = <String, double>{};
      for (final day in days) {
        final map = dayCounts[day];
        if (map == null) continue;
        map.forEach((uid, mealTotal) {
          merged[uid] = (merged[uid] ?? 0) + mealTotal;
        });
      }
      if (!out.isClosed) out.add(merged);
    }

    out = StreamController<Map<String, double>>.broadcast(
      onListen: () {
        for (final day in days) {
          dayCounts[day] = {};
          subs.add(
            watchDayMeals(messId, day).listen((entries) {
              final counts = <String, double>{};
              for (final e in entries) {
                if (!e.isApproved) continue;
                counts[e.uid] = (counts[e.uid] ?? 0) + e.mealCount;
              }
              dayCounts[day] = counts;
              ready.add(day);
              emit();
            }, onError: (Object e, StackTrace st) {
              // Don't block the whole month if one day fails.
              dayCounts[day] = {};
              ready.add(day);
              emit();
            }),
          );
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        subs.clear();
      },
    );
    return out.stream;
  }

  /// One-shot month aggregation (PDF export).
  Future<Map<String, double>> monthMealCounts(
    String messId,
    DateTime month,
  ) {
    return watchMonthMealCounts(messId, month).first;
  }
}

class BulkMealAddResult {
  const BulkMealAddResult({
    required this.written,
    required this.memberCount,
    required this.morningTotal,
    required this.eveningTotal,
    required this.nightTotal,
  });

  final int written;
  final int memberCount;
  final double morningTotal;
  final double eveningTotal;
  final double nightTotal;

  double get grandTotal => morningTotal + eveningTotal + nightTotal;

  static String fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
}