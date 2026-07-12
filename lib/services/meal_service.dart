import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meal_entry.dart';

class MealService {
  MealService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
      // Merge legacy docs if items empty or always merge for old data.
      final legacy = await _legacyEntries(messId, day).get();
      for (final d in legacy.docs) {
        list.addAll(_expandLegacy(day, d));
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
  }

  Future<void> approveMeal({
    required String messId,
    required String day,
    required String itemId,
    required String adminUid,
  }) async {
    final legacyTypes = ['_morning', '_evening', '_night', '_rate'];
    if (legacyTypes.any(itemId.endsWith)) return;
    await _items(messId, day).doc(itemId).update({
      'status': MealStatus.approved.firestoreValue,
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject = remove from list entirely (not counted in hisab).
  Future<void> rejectMeal({
    required String messId,
    required String day,
    required String itemId,
    required String adminUid,
  }) async {
    final legacyTypes = ['_morning', '_evening', '_night', '_rate'];
    if (legacyTypes.any(itemId.endsWith)) return;
    await _items(messId, day).doc(itemId).delete();
  }

  Future<void> updateMealItem({
    required String messId,
    required String day,
    required String itemId,
    required double rateValue,
    required String editedByUid,
    required String editedByName,
  }) async {
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
    final legacyTypes = ['_morning', '_evening', '_night', '_rate'];
    if (legacyTypes.any(itemId.endsWith)) return;
    await _items(messId, day).doc(itemId).delete();
  }
}
