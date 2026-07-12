import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/mess_session_builder.dart';

/// Settlement details are shown in Monthly Report (live Firestore).
class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGreen,
        title: Text(
          'সেটেলমেন্ট',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
      ),
      body: MessSessionBuilder(
        builder: (context, appUser, mess, members) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'মেম্বার হিসাব ও ব্যালেন্স দেখতে রিপোর্ট → মাসিক রিপোর্ট খুলুন। সব ডেটা অ্যাপ থেকে আসে।',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(
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
