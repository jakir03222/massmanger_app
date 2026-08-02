/// Shared pending / approved / rejected workflow used by meal, market, bazaar.
///
/// Domain enums ([MealStatus], [MarketStatus], [BazaarScheduleStatus]) stay
/// typed per feature; parsing + default labels live here once (DRY + SRP).
enum ApprovalStatus {
  pending,
  approved,
  rejected;

  /// Old docs without status count as approved.
  static ApprovalStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'approved':
      default:
        return ApprovalStatus.approved;
    }
  }

  String get firestoreValue => name;

  bool get isPending => this == ApprovalStatus.pending;
  bool get isApproved => this == ApprovalStatus.approved;
  bool get isRejected => this == ApprovalStatus.rejected;

  String label({
    required bool bn,
    String approvedBn = 'অনুমোদিত',
    String approvedEn = 'Approved',
  }) {
    switch (this) {
      case ApprovalStatus.pending:
        return bn ? 'অপেক্ষমাণ' : 'Pending';
      case ApprovalStatus.approved:
        return bn ? approvedBn : approvedEn;
      case ApprovalStatus.rejected:
        return bn ? 'বাতিল' : 'Rejected';
    }
  }

  String get bnLabel => label(bn: true);
}
