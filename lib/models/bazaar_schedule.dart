import 'approval_status.dart';
import '../utils/firestore_parsers.dart';

enum BazaarScheduleStatus {
  pending,
  approved,
  rejected;

  static BazaarScheduleStatus fromString(String? value) {
    switch (ApprovalStatus.fromString(value)) {
      case ApprovalStatus.pending:
        return BazaarScheduleStatus.pending;
      case ApprovalStatus.rejected:
        return BazaarScheduleStatus.rejected;
      case ApprovalStatus.approved:
        return BazaarScheduleStatus.approved;
    }
  }

  String get firestoreValue => name;

  String get bnLabel => label(bn: true);

  String label({required bool bn}) => ApprovalStatus.values[index].label(
        bn: bn,
        approvedBn: 'নির্ধারিত',
        approvedEn: 'Scheduled',
      );
}

/// Accept এর পর তারিখ অনুযায়ী চলমান স্ট্যাটাস (৩টি)।
enum BazaarRunStatus {
  upcoming,
  running,
  completed;

  String get bnLabel {
    switch (this) {
      case BazaarRunStatus.upcoming:
        return 'আসন্ন';
      case BazaarRunStatus.running:
        return 'চলমান';
      case BazaarRunStatus.completed:
        return 'সম্পন্ন';
    }
  }

  String label({required bool bn}) {
    switch (this) {
      case BazaarRunStatus.upcoming:
        return bn ? 'আসন্ন' : 'Upcoming';
      case BazaarRunStatus.running:
        return bn ? 'চলমান' : 'Running';
      case BazaarRunStatus.completed:
        return bn ? 'সম্পন্ন' : 'Completed';
    }
  }
}

class BazaarSchedule {
  const BazaarSchedule({
    required this.id,
    required this.uid,
    required this.memberName,
    required this.startDateKey,
    required this.endDateKey,
    required this.yearMonth,
    this.status = BazaarScheduleStatus.pending,
    this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String uid;
  final String memberName;
  final String startDateKey;
  final String endDateKey;
  final String yearMonth;
  final BazaarScheduleStatus status;
  final DateTime? createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  bool get isPending => status == BazaarScheduleStatus.pending;
  bool get isApproved => status == BazaarScheduleStatus.approved;
  bool get isSingleDay => startDateKey == endDateKey;

  /// Sort key (start of range).
  String get dateKey => startDateKey;

  static DateTime? parseDateKey(String key) {
    final p = key.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// তারিখ অনুযায়ী: Upcoming / Running / Completed
  BazaarRunStatus runStatus([DateTime? now]) {
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final start = parseDateKey(startDateKey) ?? day;
    final end = parseDateKey(endDateKey) ?? start;
    if (day.isBefore(start)) return BazaarRunStatus.upcoming;
    if (day.isAfter(end)) return BazaarRunStatus.completed;
    return BazaarRunStatus.running;
  }

  factory BazaarSchedule.fromMap(String id, Map<String, dynamic> data) {
    final legacyDate = readString(data['dateKey']);
    final start = readString(data['startDateKey'], legacyDate);
    final end = readString(data['endDateKey'], start);
    return BazaarSchedule(
      id: id,
      uid: readString(data['uid']),
      memberName: readString(data['memberName'], 'সদস্য'),
      startDateKey: start,
      endDateKey: end,
      yearMonth: readString(data['yearMonth']),
      status: BazaarScheduleStatus.fromString(data['status'] as String?),
      createdAt: readTimestamp(data['createdAt']),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: readTimestamp(data['reviewedAt']),
    );
  }
}
