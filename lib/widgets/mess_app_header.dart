import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class MessAppHeader extends StatelessWidget {
  const MessAppHeader({
    super.key,
    this.title,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final displayTitle = (title == null || title!.trim().isEmpty)
        ? 'মেস ম্যানেজার'
        : title!.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: subtitle == null
                ? Text(
                    displayTitle,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreen,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGreen,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        subtitle!,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textGrey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: AppColors.headerIcon),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
