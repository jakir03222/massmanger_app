import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'app_surface.dart';

/// Shared loading / error / empty helpers for stream screens.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.onRetry,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.monthRed),
            const SizedBox(height: 14),
            Text(
              title ?? s.sessionLoadFailed,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle ?? s.somethingWentWrong,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: s.retry,
                height: 44,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
