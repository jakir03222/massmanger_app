import '../utils/firestore_parsers.dart';

/// Status of a bazaar date swap request.
///
/// Flow:
///   1. Member picks THEIR upcoming date + another SAME-MESS member's date
///      → status = pending (admin notified)
///   2. Admin approves → schedules swapped atomically → status = approved
///      (both members get notification)
///      OR admin rejects → status = rejected
///   3. Requester can cancel while pending → status = cancelled
enum BazaarSwapStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static BazaarSwapStatus fromString(String? v) {
    switch (v) {
      case 'approved':
        return BazaarSwapStatus.approved;
      case 'rejected':
        return BazaarSwapStatus.rejected;
      case 'cancelled':
        return BazaarSwapStatus.cancelled;
      default:
        return BazaarSwapStatus.pending;
    }
  }

  String get firestoreValue => name;

  String label({required bool bn}) {
    switch (this) {
      case BazaarSwapStatus.pending:
        return bn ? 'অপেক্ষমাণ' : 'Pending';
      case BazaarSwapStatus.approved:
        return bn ? 'অনুমোদিত ✅' : 'Approved ✅';
      case BazaarSwapStatus.rejected:
        return bn ? 'বাতিল ❌' : 'Rejected ❌';
      case BazaarSwapStatus.cancelled:
        return bn ? 'প্রত্যাহার' : 'Cancelled';
    }
  }
}

/// Member A requests to swap their bazaar date with Member B (same mess).
/// Admin only approves or rejects — partner is already chosen by the requester.
///
/// Firestore: messes/{messId}/bazaar_swap_requests/{id}
class BazaarSwapRequest {
  const BazaarSwapRequest({
    required this.id,
    required this.messId,
    required this.requesterUid,
    required this.requesterName,
    required this.scheduleId,
    required this.dateKey,
    required this.endDateKey,
    required this.yearMonth,
    // Partner chosen by requester (same mess member)
    required this.targetUid,
    required this.targetName,
    required this.targetScheduleId,
    required this.targetDateKey,
    required this.targetEndDateKey,
    this.note,
    this.status = BazaarSwapStatus.pending,
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String messId;
  final String requesterUid;
  final String requesterName;
  final String scheduleId;
  final String dateKey;
  final String endDateKey;
  final String yearMonth;

  final String targetUid;
  final String targetName;
  final String targetScheduleId;
  final String targetDateKey;
  final String targetEndDateKey;

  final String? note;
  final BazaarSwapStatus status;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  bool get isPending => status == BazaarSwapStatus.pending;
  bool get isApproved => status == BazaarSwapStatus.approved;
  bool get isRejected => status == BazaarSwapStatus.rejected;
  bool get isCancelled => status == BazaarSwapStatus.cancelled;
  bool get isResolved => isApproved || isRejected || isCancelled;

  /// Legacy aliases used by older UI cards.
  String? get swappedWithUid => targetUid.isEmpty ? null : targetUid;
  String? get swappedWithName => targetName.isEmpty ? null : targetName;
  String? get swappedWithDateKey =>
      targetDateKey.isEmpty ? null : targetDateKey;

  factory BazaarSwapRequest.fromMap(String id, Map<String, dynamic> data) {
    final legacyDate = readString(data['dateKey']);
    // Support old docs that used swappedWith* instead of target*
    final targetUid = readString(
      data['targetUid'],
      readString(data['swappedWithUid']),
    );
    final targetName = readString(
      data['targetName'],
      readString(data['swappedWithName'], 'সদস্য'),
    );
    final targetScheduleId = readString(
      data['targetScheduleId'],
      readString(data['swappedWithScheduleId']),
    );
    final targetDateKey = readString(
      data['targetDateKey'],
      readString(data['swappedWithDateKey']),
    );
    final targetEndDateKey = readString(
      data['targetEndDateKey'],
      readString(data['swappedWithEndDateKey'], targetDateKey),
    );

    return BazaarSwapRequest(
      id: id,
      messId: readString(data['messId']),
      requesterUid: readString(data['requesterUid']),
      requesterName: readString(data['requesterName'], 'সদস্য'),
      scheduleId: readString(data['scheduleId']),
      dateKey: readString(data['dateKey'], legacyDate),
      endDateKey: readString(data['endDateKey'], legacyDate),
      yearMonth: readString(data['yearMonth']),
      targetUid: targetUid,
      targetName: targetName,
      targetScheduleId: targetScheduleId,
      targetDateKey: targetDateKey,
      targetEndDateKey: targetEndDateKey,
      note: data['note'] as String?,
      status: BazaarSwapStatus.fromString(data['status'] as String?),
      createdAt: readTimestamp(data['createdAt']),
      reviewedAt: readTimestamp(data['reviewedAt']),
      reviewedBy: data['reviewedBy'] as String?,
    );
  }
}
