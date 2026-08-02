import '../utils/firestore_parsers.dart';

class MemberPayment {
  const MemberPayment({
    required this.uid,
    required this.yearMonth,
    required this.paid,
    this.amount = 0,
    this.note = '',
    this.updatedBy,
    this.updatedAt,
  });

  final String uid;
  final String yearMonth;
  final bool paid;
  final double amount;
  final String note;
  final String? updatedBy;
  final DateTime? updatedAt;

  factory MemberPayment.fromMap(
    String uid,
    String yearMonth,
    Map<String, dynamic> data,
  ) {
    return MemberPayment(
      uid: uid,
      yearMonth: yearMonth,
      paid: data['paid'] == true,
      amount: readDouble(data['amount'], 0),
      note: readString(data['note'], ''),
      updatedBy: data['updatedBy'] as String?,
      updatedAt: readTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({required String adminUid}) => {
        'uid': uid,
        'yearMonth': yearMonth,
        'paid': paid,
        'amount': amount,
        'note': note,
        'updatedBy': adminUid,
        'updatedAt': DateTime.now().toIso8601String(),
      };
}
