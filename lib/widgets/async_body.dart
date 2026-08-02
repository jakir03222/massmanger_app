import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'app_error_state.dart';
import 'app_surface.dart';

/// Uniform loading · error · empty · data handling for [AsyncSnapshot].
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.snapshot,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
    this.errorBuilder,
  });

  final AsyncSnapshot<T> snapshot;
  final Widget Function(BuildContext context, T data) builder;

  /// When true, [empty] is shown instead of [builder].
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return loading ??
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryGreen),
                const SizedBox(height: 12),
                Text(
                  s.loadingLabel,
                  style: appFont(
                    context: context,
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          );
    }

    if (snapshot.hasError) {
      final err = snapshot.error!;
      if (errorBuilder != null) return errorBuilder!(context, err);
      return AppErrorState(title: s.somethingWentWrong);
    }

    final data = snapshot.data;
    if (data == null) {
      return empty ??
          AppEmptyState(
            icon: Icons.inbox_outlined,
            title: s.noData,
          );
    }

    if (isEmpty != null && isEmpty!(data)) {
      return empty ??
          AppEmptyState(
            icon: Icons.inbox_outlined,
            title: s.noData,
          );
    }

    return builder(context, data);
  }
}
