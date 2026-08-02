import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// Simple in-app privacy policy for store readiness.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: Text(
          s.privacyPolicy,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            s.isBengali
                ? 'Mass Manager মেস মিল, বাজার, বিল ও হিসাব পরিচালনার জন্য আপনার অ্যাকাউন্ট, মেস মেম্বারশিপ এবং সম্পর্কিত ডেটা Firebase-এ সংরক্ষণ করে।'
                : 'Mass Manager stores your account, mess membership, and related mess accounting data in Firebase to run meals, bazaar, bills, and settlements.',
            style: appFont(context: context, height: 1.45),
          ),
          const SizedBox(height: 14),
          Text(
            s.isBengali
                ? 'আমরা পাসওয়ার্ড সরাসরি সংরক্ষণ করি না (Firebase Auth)। নোটিফিকেশন টোকেন ডিভাইসে আপডেট পৌঁছাতে ব্যবহার হয়।'
                : 'We do not store passwords directly (Firebase Auth). Notification tokens are used to deliver updates to your device.',
            style: appFont(context: context, height: 1.45),
          ),
          const SizedBox(height: 14),
          Text(
            s.isBengali
                ? 'আপনি সেটিংস থেকে লগআউট করতে পারেন। মেস অ্যাডমিন মেম্বারশিপ ও হিসাব ডেটা পরিচালনা করে।'
                : 'You can sign out from Settings. Mess admins manage membership and accounting data.',
            style: appFont(context: context, height: 1.45),
          ),
        ],
      ),
    );
  }
}
