import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_session_builder.dart';

/// Settlement details are shown in Monthly Report (live Firestore).
class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGreen,
        title: Text(
          s.settlement,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
      ),
      body: MessSessionBuilder(
        builder: (context, appUser, mess, members) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.settlementHint,
                textAlign: TextAlign.center,
                style: appFont(
                  context: context,
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
