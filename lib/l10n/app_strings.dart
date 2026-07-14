import 'package:flutter/widgets.dart';

import 'locale_controller.dart';

/// Minimal bn/en strings for Phase 1 core screens.
class AppStrings {
  AppStrings._(this._bn);

  final bool _bn;

  factory AppStrings.of(BuildContext context) {
    final c = LocaleScope.maybeOf(context);
    return AppStrings._(c?.isBengali ?? true);
  }

  factory AppStrings.bn() => AppStrings._(true);
  factory AppStrings.en() => AppStrings._(false);

  String get appTitle => _bn ? 'ম্যাস ম্যানেজার' : 'Mass Manager';
  String get noLogin => _bn ? 'লগইন নেই' : 'Not logged in';
  String get language => _bn ? 'ভাষা' : 'Language';
  String get languageBn => _bn ? 'বাংলা' : 'Bangla';
  String get languageEn => _bn ? 'ইংরেজি' : 'English';
  String get monthlyBills => _bn ? 'মাসিক বিল' : 'Monthly bills';
  String get monthlyBillsSubtitle =>
      _bn ? 'খালা · ভাড়া · বিদ্যুৎ · পানি · ইউটিলিটি' : 'Cook · rent · utility';
  String get notifications => _bn ? 'নোটিফিকেশন' : 'Notifications';
  String get notificationsSubtitle =>
      _bn ? 'অনুমোদন ও আপডেট' : 'Approvals and updates';
  String get lockMonth => _bn ? 'এই মাস লক করুন' : 'Lock this month';
  String get unlockMonth => _bn ? 'মাস আনলক করুন' : 'Unlock month';
  String get monthLocked =>
      _bn ? 'এই মাস লক করা — এডিট বন্ধ' : 'Month locked — edits disabled';
  String get monthLockedHint => _bn
      ? 'লক করলে এই মাসের মিল, বাজার ও বিল পরিবর্তন করা যাবে না।'
      : 'When locked, meals, markets and bills for this month cannot be edited.';
  String get privacy => _bn ? 'প্রাইভেসি' : 'Privacy';
  String get help => _bn ? 'সাহায্য' : 'Help';
  String get about => _bn ? 'অ্যাপ সম্পর্কে' : 'About';
  String get leaveMess => _bn ? 'মেস ছাড়ুন' : 'Leave mess';
  String get leaveMessSubtitle =>
      _bn ? 'এই মেস থেকে বের হয়ে যান' : 'Exit this mess';
  String get logout => _bn ? 'লগ আউট' : 'Log out';
  String get members => _bn ? 'মেম্বার' : 'Members';
  String get settings => _bn ? 'সেটিংস' : 'Settings';
  String get close => _bn ? 'বন্ধ করুন' : 'Close';
  String get cancel => _bn ? 'না' : 'Cancel';
  String get confirm => _bn ? 'হ্যাঁ' : 'Yes';
  String get monthLockedWrite => _bn
      ? 'এই মাস লক করা আছে — পরিবর্তন করা যায় না।'
      : 'This month is locked — changes are not allowed.';
}
