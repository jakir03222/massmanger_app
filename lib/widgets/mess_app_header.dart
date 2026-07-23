import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

class MessAppHeader extends StatelessWidget {
  const MessAppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final displayTitle = (title == null || title!.trim().isEmpty)
        ? s.appTitle
        : title!.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.featureGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.home_work_rounded,
              color: AppColors.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(
                    context: context,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty)
                  Text(
                    subtitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appFont(
                      context: context,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGrey,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
