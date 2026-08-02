import '../utils/firestore_parsers.dart';
import 'approval_status.dart';

enum MealStatus {
  pending,
  approved,
  rejected;

  static MealStatus fromString(String? value) {
    switch (ApprovalStatus.fromString(value)) {
      case ApprovalStatus.pending:
        return MealStatus.pending;
      case ApprovalStatus.rejected:
        return MealStatus.rejected;
      case ApprovalStatus.approved:
        return MealStatus.approved;
    }
  }

  String get firestoreValue => name;

  String get bnLabel => label(bn: true);

  String label({required bool bn}) => ApprovalStatus.values[index].label(bn: bn);
}

enum MealType {
  morning,
  evening,
  night,
  rate,
  guest;

  static MealType fromString(String? value) {
    switch (value) {
      case 'evening':
        return MealType.evening;
      case 'night':
        return MealType.night;
      case 'rate':
        return MealType.rate;
      case 'guest':
        return MealType.guest;
      case 'morning':
      default:
        return MealType.morning;
    }
  }

  String get firestoreValue => name;

  String get bnLabel {
    switch (this) {
      case MealType.morning:
        return 'সকাল';
      case MealType.evening:
        return 'বিকাল';
      case MealType.night:
        return 'রাত';
      case MealType.rate:
        return 'রেট মিল';
      case MealType.guest:
        return 'গেস্ট';
    }
  }

  String label({required bool bn}) {
    switch (this) {
      case MealType.morning:
        return bn ? 'সকাল' : 'Morning';
      case MealType.evening:
        return bn ? 'বিকাল' : 'Evening';
      case MealType.night:
        return bn ? 'রাত' : 'Night';
      case MealType.rate:
        return bn ? 'রেট মিল' : 'Rate meal';
      case MealType.guest:
        return bn ? 'গেস্ট' : 'Guest';
    }
  }
}

/// One list row = one meal add (সকাল / বিকাল / রাত / রেট) — does not replace others.
class MealEntry {
  const MealEntry({
    required this.id,
    required this.uid,
    required this.name,
    required this.type,
    this.rateValue = 1,
    this.status = MealStatus.approved,
    this.dateKey = '',
    this.createdAt,
    this.updatedAt,
    this.editedByUid,
    this.editedByName,
    this.addedByUid,
    this.addedByName,
  });

  final String id;
  final String uid;
  final String name;
  final MealType type;
  /// Quantity (0.5 steps). Used for all meal types.
  final double rateValue;
  final MealStatus status;
  final String dateKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? editedByUid;
  final String? editedByName;
  /// When admin adds meal for a member.
  final String? addedByUid;
  final String? addedByName;

  bool get isPending => status == MealStatus.pending;
  bool get isApproved => status == MealStatus.approved;
  bool get isRejected => status == MealStatus.rejected;

  bool get morning => type == MealType.morning;
  bool get evening => type == MealType.evening;
  bool get night => type == MealType.night;
  bool get isRate => type == MealType.rate;
  bool get isGuest => type == MealType.guest;

  bool get wasEditedByAdmin =>
      editedByName != null && editedByName!.trim().isNotEmpty;

  bool get wasAddedByAdmin =>
      addedByName != null &&
      addedByName!.trim().isNotEmpty &&
      addedByUid != null &&
      addedByUid != uid;

  double get mealRate => isRate ? rateValue : 0;

  /// Approved quantity used in hisab (supports 0.5 steps).
  double get mealCount => isApproved ? rateValue : 0;

  String get quantityLabel {
    final v = rateValue;
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  String get displayLabel => '${type.bnLabel} ($quantityLabel)';

  String localizedDisplayLabel({required bool bn}) =>
      '${type.label(bn: bn)} ($quantityLabel)';

  factory MealEntry.fromMap(String id, Map<String, dynamic> data, {String? day}) {
    // New item shape.
    if (data['type'] != null) {
      return MealEntry(
        id: id,
        uid: readString(data['uid'], id),
        name: readString(data['name'], 'সদস্য'),
        type: MealType.fromString(data['type'] as String?),
        rateValue: readDouble(data['rateValue'] ?? data['mealRate'], 1),
        status: MealStatus.fromString(data['status'] as String?),
        dateKey: readString(data['dateKey'], day ?? ''),
        createdAt: readTimestamp(data['createdAt']),
        updatedAt: readTimestamp(data['updatedAt']),
        editedByUid: data['editedByUid'] as String?,
        editedByName: data['editedByName'] as String?,
        addedByUid: data['addedByUid'] as String?,
        addedByName: data['addedByName'] as String?,
      );
    }

    // Legacy combined doc → expand not here; service may expand.
    return MealEntry(
      id: id,
      uid: readString(data['uid'], id),
      name: readString(data['name'], 'সদস্য'),
      type: MealType.morning,
      rateValue: 1,
      status: MealStatus.fromString(data['status'] as String?),
      dateKey: readString(data['dateKey'], day ?? ''),
      createdAt: readTimestamp(data['createdAt']),
      updatedAt: readTimestamp(data['updatedAt']),
      editedByUid: data['editedByUid'] as String?,
      editedByName: data['editedByName'] as String?,
      addedByUid: data['addedByUid'] as String?,
      addedByName: data['addedByName'] as String?,
    );
  }
}
