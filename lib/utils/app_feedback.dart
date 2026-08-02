import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

// appFont lives in app_strings.dart

/// Single snackbar entry point — avoids stacked snacks and inconsistent styling.
void showAppSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
  bool isError = false,
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: appFont(
          context: context,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      duration: duration,
      action: action,
      backgroundColor: isError ? AppColors.monthRed : null,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
