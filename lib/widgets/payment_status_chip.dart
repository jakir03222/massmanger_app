import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/member_payment.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_feedback.dart';

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({
    super.key,
    required this.paid,
    this.compact = false,
  });

  final bool paid;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final color = paid ? AppColors.darkGreen : AppColors.monthRed;
    final bg = paid
        ? AppColors.featureGreenBg
        : AppColors.monthRed.withValues(alpha: 0.12);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        paid ? s.paid : s.unpaid,
        style: appFont(
          context: context,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

Future<void> showMarkPaymentDialog({
  required BuildContext context,
  required String messId,
  required String yearMonth,
  required String memberUid,
  required String memberName,
  required String adminUid,
  required bool currentlyPaid,
  MemberPayment? existing,
}) async {
  final s = AppStrings.of(context);
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  final markPaid = !currentlyPaid;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        markPaid ? s.markPaid : s.markUnpaid,
        style: appFont(context: ctx, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            memberName,
            style: appFont(context: ctx, fontWeight: FontWeight.w600),
          ),
          if (markPaid) ...[
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: s.paymentNoteOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.cancel, style: appFont(context: ctx)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          child: Text(
            markPaid ? s.markPaid : s.markUnpaid,
            style: appFont(context: ctx, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  if (ok != true || !context.mounted) {
    noteCtrl.dispose();
    return;
  }

  try {
    await PaymentService().setPaid(
      messId: messId,
      yearMonth: yearMonth,
      uid: memberUid,
      paid: markPaid,
      adminUid: adminUid,
      note: noteCtrl.text.trim(),
      memberName: memberName,
    );
    if (!context.mounted) return;
    showAppSnack(context, s.paymentUpdated);
  } catch (e) {
    if (!context.mounted) return;
    showAppSnack(context, '$e');
  } finally {
    noteCtrl.dispose();
  }
}
