import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import 'locale_controller.dart';

/// Full-app bn/en strings. Use [AppStrings.of] in widgets.
class AppStrings {
  AppStrings._(this._bn);

  final bool _bn;
  bool get isBengali => _bn;

  factory AppStrings.of(BuildContext context) {
    final c = LocaleScope.maybeOf(context);
    return AppStrings._(c?.isBengali ?? true);
  }

  factory AppStrings.bn() => AppStrings._(true);
  factory AppStrings.en() => AppStrings._(false);

  String _t(String bn, String en) => _bn ? bn : en;

  // —— App / common ——
  String get appTitle => _t('ম্যাস ম্যানেজার', 'Mass Manager');
  String get appTagline => _t('মেসের হিসাব, সহজে', 'Mess accounts, made easy');
  String get loadingApp => _t('অ্যাপ লোড হচ্ছে…', 'Loading app…');
  String get checkingSession => _t('সেশন যাচাই হচ্ছে…', 'Checking session…');
  String get loadingProfile => _t('প্রোফাইল লোড হচ্ছে…', 'Loading profile…');
  String get noLogin => _t('লগইন নেই', 'Not logged in');
  String get close => _t('বন্ধ করুন', 'Close');
  String get cancel => _t('বাতিল', 'Cancel');
  String get confirm => _t('হ্যাঁ', 'Yes');
  String get no => _t('না', 'No');
  String get save => _t('সেভ', 'Save');
  String get delete => _t('মুছুন', 'Delete');
  String get edit => _t('হালনাগাদ', 'Edit');
  String get add => _t('যোগ করুন', 'Add');
  String get update => _t('হালনাগাদ করুন', 'Update');
  String get retry => _t('আবার চেষ্টা', 'Try again');
  String get refresh => _t('রিফ্রেশ', 'Refresh');
  String get download => _t('ডাউনলোড', 'Download');
  String get today => _t('আজ', 'Today');
  String get change => _t('পরিবর্তন', 'Change');
  String get date => _t('তারিখ', 'Date');
  String get total => _t('মোট', 'Total');
  String get grandTotal => _t('সর্বমোট', 'Grand total');
  String get name => _t('নাম', 'Name');
  String get you => _t('আপনি', 'You');
  String get allMembers => _t('সব মেম্বার', 'All members');
  String get previousMonth => _t('আগের মাস', 'Previous month');
  String get nextMonth => _t('পরের মাস', 'Next month');
  String get monthClosedBadge => _t('ক্লোজড', 'Closed');

  // —— Language ——
  String get language => _t('ভাষা', 'Language');
  String get languageBn => _t('বাংলা', 'Bangla');
  String get languageEn => _t('ইংরেজি', 'English');
  String get languageTapHint =>
      _t('ট্যাপ করে ভাষা বদলান', 'Tap to switch language');
  String get languageChanged =>
      _t('ভাষা পরিবর্তন হয়েছে', 'Language updated');
  String get chooseLanguage => _t('ভাষা বেছে নিন', 'Choose language');

  // —— Onboarding ——
  String get skip => _t('স্কিপ', 'Skip');
  String get next => _t('পরবর্তী', 'Next');
  String get getStarted => _t('শুরু করুন', 'Get started');
  String get onboardingMealsTitle =>
      _t('মিল সহজে যোগ করুন', 'Add meals easily');
  String get onboardingMealsBody => _t(
        'সকাল, বিকাল ও রাতের মিল এক জায়গায় রাখুন — অনুমোদনের পর হিসাবে যোগ হবে।',
        'Track morning, evening and night meals in one place — they count after approval.',
      );
  String get onboardingBazaarTitle =>
      _t('বাজার খরচ ট্র্যাক করুন', 'Track bazaar expenses');
  String get onboardingBazaarBody => _t(
        'কে কত খরচ করল সব স্বচ্ছভাবে দেখুন। অ্যাডমিন অনুমোদন করলে হিসাবে যোগ হয়।',
        'See who spent what, clearly. Approved expenses go into the accounts.',
      );
  String get onboardingReportsTitle =>
      _t('মাসিক হিসাব ও রিপোর্ট', 'Monthly accounts & reports');
  String get onboardingReportsBody => _t(
        'মিল রেট, বিল ও সেটেলমেন্ট এক নজরে। Smart PDF ডাউনলোড করুন।',
        'Meal rate, bills and settlement at a glance. Download smart PDFs.',
      );
  String get onboardingJoinTitle =>
      _t('কোড দিয়ে মেসে জয়েন', 'Join a mess with a code');
  String get onboardingJoinBody => _t(
        'মেস তৈরি করুন বা ৬ ডিজিট কোড দিয়ে যোগ দিন — সবাই একসাথে হিসাব দেখবে।',
        'Create a mess or join with a 6-digit code — everyone sees the same accounts.',
      );

  String get appTheme => _t('থিম ও রঙ', 'Theme & colors');
  String get appThemeTapHint => _t(
        'থিম বদলালে অ্যাপের রঙ ও টেক্সট কালার দুটোই বদলাবে',
        'Changing theme updates app colors and text colors',
      );
  String get chooseTheme => _t('থিম বেছে নিন', 'Choose a theme');
  String get themeApplied => _t('থিম আপডেট হয়েছে', 'Theme updated');
  String get themeForest => _t('ফরেস্ট সবুজ', 'Forest green');
  String get themeOcean => _t('ওশান নীল', 'Ocean blue');
  String get themeTeal => _t('টিল', 'Teal');
  String get themeSunset => _t('সানসেট কমলা', 'Sunset orange');
  String get themeIndigo => _t('ইন্ডিগো', 'Indigo');
  String get themeMidnight => _t('মিডনাইট ডার্ক', 'Midnight dark');
  String get themeCustom => _t('কাস্টম রঙ', 'Custom color');
  String get pickThemeColor =>
      _t('নিজের থিম রঙ বাছুন', 'Pick your theme color');
  String get darkMode => _t('ডার্ক মোড', 'Dark mode');
  String get themePreviewPrimary => _t('প্রাইমারি', 'Primary');
  String get themePreviewText => _t('টেক্সট', 'Text');
  String get themePreviewBg => _t('ব্যাকগ্রাউন্ড', 'Background');

  String themeName(String id) {
    switch (id) {
      case 'ocean':
        return themeOcean;
      case 'teal':
        return themeTeal;
      case 'sunset':
        return themeSunset;
      case 'indigo':
        return themeIndigo;
      case 'midnight':
        return themeMidnight;
      case 'custom':
        return themeCustom;
      case 'forest':
      default:
        return themeForest;
    }
  }

  // —— Nav ——
  String get navHome => _t('হোম', 'Home');
  String get navMeal => _t('মিল', 'Meals');
  String get navMarket => _t('বাজার', 'Bazaar');
  String get navCommunity => _t('কমিউনিটি', 'Community');
  String get navReport => _t('রিপোর্ট', 'Report');
  String get navSettings => _t('সেটিংস', 'Settings');

  // —— Auth / login ——
  String get welcome => _t('স্বাগতম', 'Welcome');
  String get quickActions => _t('দ্রুত কাজ', 'Quick actions');
  String get pullToRefresh =>
      _t('নিচে টেনে রিফ্রেশ করুন', 'Pull down to refresh');
  String get noMealsYetTitle => _t('এখনো কোনো মিল নেই', 'No meals yet');
  String get noMealsYetBody => _t(
        'আজকের মিল যোগ করুন — অনুমোদনের পর হিসাবে যোগ হবে।',
        'Add today’s meals — they count after approval.',
      );
  String get noMarketYetTitle => _t('কোনো বাজার নেই', 'No bazaar yet');
  String get noMarketYetBody => _t(
        'বাজার খরচ যোগ করলে এখানে দেখা যাবে।',
        'Bazaar expenses you add will show up here.',
      );
  String welcomeName(String name) =>
      _bn ? 'স্বাগতম, $name' : 'Welcome, $name';
  String get loginSubtitle => _t(
        'মিল, বাজার ও হিসাব — এক জায়গায় সহজে ম্যানেজ করুন',
        'Manage meals, bazaar and accounts in one place',
      );
  String get loginTerms => _t(
        'লগইন করে আপনি শর্তাবলী এবং গোপনীয়তা নীতি মেনে নিচ্ছেন',
        'By signing in you agree to the Terms and Privacy Policy',
      );
  String get continueGoogle =>
      _t('Google দিয়ে চালিয়ে যান', 'Continue with Google');
  String get loginEmail => _t('ইমেইল দিয়ে লগইন', 'Sign in with email');
  String get createAccount => _t('অ্যাকাউন্ট তৈরি', 'Create account');
  String get email => _t('ইমেইল', 'Email');
  String get password => _t('পাসওয়ার্ড', 'Password');
  String get logout => _t('লগ আউট', 'Log out');
  String get emailLoginTitle => _t('ইমেইল লগইন', 'Email login');
  String get emailLoginSubtitle => _t(
        'আপনার ইমেইল ও পাসওয়ার্ড দিয়ে লগইন করুন',
        'Sign in with your email and password',
      );
  String get emailRequired => _t('ইমেইল দিন', 'Enter email');
  String get emailInvalid => _t('সঠিক ইমেইল দিন', 'Enter a valid email');
  String get passwordRequired => _t('পাসওয়ার্ড দিন', 'Enter password');
  String get forgotPassword =>
      _t('পাসওয়ার্ড ভুলে গেছেন?', 'Forgot password?');
  String get loginAction => _t('লগইন করুন', 'Sign in');
  String get createNewAccount =>
      _t('নতুন অ্যাকাউন্ট তৈরি করুন', 'Create a new account');
  String get passwordResetTitle => _t('পাসওয়ার্ড রিসেট', 'Reset password');
  String get passwordResetBody => _t(
        'আপনার ইমেইলে পাসওয়ার্ড রিসেট লিংক পাঠানো হবে।',
        'A password reset link will be sent to your email.',
      );
  String get sendLink => _t('লিংক পাঠান', 'Send link');
  String get resetLinkSent => _t(
        'রিসেট লিংক পাঠানো হয়েছে — ইমেইল চেক করুন',
        'Reset link sent — check your email',
      );
  String get registerTitle => _t('নতুন অ্যাকাউন্ট', 'New account');
  String get registerSubtitle => _t(
        'নাম, ইমেইল ও পাসওয়ার্ড দিয়ে রেজিস্ট্রেশন করুন',
        'Register with name, email and password',
      );
  String get nameRequired => _t('নাম দিন', 'Enter name');
  String get passwordMinLength => _t(
        'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে',
        'Password must be at least 6 characters',
      );
  String get passwordMinLengthShort => _t(
        'কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন',
        'Enter a password of at least 6 characters',
      );
  String get confirmPassword =>
      _t('পাসওয়ার্ড নিশ্চিত করুন', 'Confirm password');
  String get passwordMismatch =>
      _t('পাসওয়ার্ড মিলছে না', 'Passwords do not match');
  String get registerAction => _t('রেজিস্ট্রেশন করুন', 'Register');
  String get alreadyHaveAccount => _t(
        'ইতিমধ্যে অ্যাকাউন্ট আছে? লগইন করুন',
        'Already have an account? Sign in',
      );
  String get logoutConfirm =>
      _t('আপনি কি লগআউট করতে চান?', 'Do you want to log out?');
  String get yesLogout => _t('হ্যাঁ, লগআউট', 'Yes, log out');
  String get logoutFailed => _t(
        'লগআউট ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
        'Log out failed. Please try again.',
      );
  String get googleLogin => _t('Google লগইন', 'Google login');

  // —— Mess setup ——
  String get messSetup => _t('মেস সেটআপ', 'Mess setup');
  String get createMess => _t('মেস তৈরি করুন', 'Create mess');
  String get joinMess => _t('মেসে যোগ দিন', 'Join mess');
  String get messName => _t('মেসের নাম', 'Mess name');
  String get messLocation => _t('ঠিকানা / লোকেশন', 'Location');
  String get messCode => _t('মেস কোড', 'Mess code');
  String get enterSixDigitCode =>
      _t('৬ ডিজিটের কোড দিন', 'Enter 6-digit code');
  String get messCodeSixDigit =>
      _t('মেস কোড (৬ ডিজিট)', 'Mess code (6 digits)');
  String get codeExampleHint => _t('যেমন: 482916', 'e.g. 482916');
  String get messSetupIntro => _t(
        'অ্যাডমিন মেস তৈরি করবে। অন্য ইউজার আলাদা অ্যাকাউন্ট দিয়ে লগইন করে মেস কোড দিয়ে মেম্বার হিসেবে জয়েন করবে।',
        'Admin creates the mess. Others sign in with their own account and join as members with the mess code.',
      );
  String get createMessAdmin =>
      _t('মেস তৈরি (অ্যাডমিন)', 'Create mess (admin)');
  String get youWillBeAdmin =>
      _t('আপনি অ্যাডমিন হবেন', 'You will be admin');
  String get joinMessShort => _t('মেসে জয়েন', 'Join mess');
  String get joinAsMember =>
      _t('মেম্বার হিসেবে যোগ', 'Join as member');
  String get messSetupFooter => _t(
        'মেস তৈরির পর ৬ ডিজিটের কোড পাবেন। অন্য ইউজার লগইন করে «মেসে যোগ দিন» থেকে সেই কোড দিয়ে জয়েন করবে।',
        'After creating, you get a 6-digit code. Others sign in and join via “Join mess” with that code.',
      );
  String get viewCommunityFindMess =>
      _t('কমিউনিটি দেখুন — মেস খুঁজুন', 'View community — find a mess');
  String get messCreatedTitle =>
      _t('মেস তৈরি হয়েছে!', 'Mess created!');
  String get messCreatedShareHint => _t(
        'অন্য ইউজারকে এই কোড দিয়ে মেসে যোগ দিতে বলুন:',
        'Share this code so others can join:',
      );
  String get copy => _t('কপি', 'Copy');
  String get share => _t('শেয়ার', 'Share');
  String get codeCopied => _t('কোড কপি হয়েছে', 'Code copied');
  String get ok => _t('ঠিক আছে', 'OK');
  String get joinedMessSuccess =>
      _t('মেসে সফলভাবে যোগ দিয়েছেন', 'Successfully joined mess');
  String get somethingWentWrong => _t(
        'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।',
        'Something went wrong. Please try again.',
      );
  String shareMessInvite(String name, String code) => _bn
      ? 'আমাদের মেস "$name"-এ যোগ দিন।\nমেস কোড: $code\nMass Manager অ্যাপে কোড দিয়ে জয়েন করুন।'
      : 'Join our mess "$name".\nMess code: $code\nJoin with the code in the Mass Manager app.';
  String shareMessInviteCode(String code) => _bn
      ? 'আমাদের মেসে যোগ দিন।\nমেস কোড: $code\nMass Manager অ্যাপে কোড দিয়ে জয়েন করুন।'
      : 'Join our mess.\nMess code: $code\nJoin with the code in the Mass Manager app.';
  String get loadingEllipsis => _t('লোড হচ্ছে...', 'Loading...');
  String get messCodeCopied =>
      _t('মেস কোড কপি হয়েছে', 'Mess code copied');
  String get messCodeSharedCopied =>
      _t('মেস কোড শেয়ার/কপি হয়েছে', 'Mess code shared/copied');

  // —— Home ——
  String overallCount(String month) =>
      _bn ? 'সার্বিক কাউন্ট ($month)' : 'Overall count ($month)';
  String myCount(String month) =>
      _bn ? 'আমার কাউন্ট ($month)' : 'My count ($month)';
  String get monthEndAllMembers =>
      _t('মাস শেষ — সব মেম্বারের হিসাব', 'Month end — all members');
  String get smartPdfHint => _t(
        'Smart PDF — প্রতি মেম্বারের মিল, বাজার, বিল ভাগ ও পাবে/দিবে',
        'Smart PDF — meals, bazaar, bill share & payable/receivable',
      );
  String get smartMonthlyPdf =>
      _t('Smart মাসিক হিসাব PDF', 'Smart monthly statement PDF');
  String get bills => _t('বিল', 'Bills');
  String get memberSummary =>
      _t('সব মেম্বারের হিসাব (সংক্ষেপ)', 'Member summary');
  String get recentMarket => _t('সাম্প্রতিক বাজার', 'Recent bazaar');
  String get noMarketThisMonth =>
      _t('এই মাসে এখনো কোনো বাজার এন্ট্রি নেই', 'No bazaar entries this month');
  String myMarketTotal(String amount) =>
      _bn ? 'এই মাসে আপনার মোট বাজার: $amount' : 'Your bazaar total this month: $amount';
  String get todayMealRate => _t('আজকের মিল রেট', "Today's meal rate");
  String todayMealMarket(String meals, String spend) =>
      _bn ? 'মিল $meals · বাজার $spend' : 'Meals $meals · Bazaar $spend';
  String get todayMeals => _t('আজ মিল', 'Meals today');
  String get todayMarket => _t('আজ বাজার', 'Bazaar today');
  String get monthlyMeals => _t('মাসিক মিল', 'Monthly meals');
  String get myMonthlyMarket => _t('আমার মাসিক বাজার', 'My monthly bazaar');
  String get monthlyMarket => _t('মাসিক বাজার', 'Monthly bazaar');
  String get monthlyMealRate => _t('মাসিক মিল রেট', 'Monthly meal rate');
  String get monthlyBillsShort => _t('মাসিক বিল', 'Monthly bills');
  String get dueMarket => _t('বাকি বাজার', 'Due bazaar');
  String get members => _t('মেম্বার', 'Members');
  String get willPay => _t('দিবে', 'Will pay');
  String get willReceive => _t('পাবে', 'Will receive');
  String get myMeals => _t('আমার মিল', 'My meals');
  String get mealRate => _t('মিল রেট', 'Meal rate');
  String get mealCost => _t('মিল খরচ', 'Meal cost');
  String get myMarket => _t('আমার বাজার', 'My bazaar');
  String get billShare => _t('বিল ভাগ', 'Bill share');
  String get iMustPay => _t('আমাকে দিতে হবে', 'I owe');
  String get iWillGet => _t('আমি পাব', 'I receive');
  String get pdfSavedDownloads =>
      _t('PDF ডাউনলোড ফোল্ডারে সেভ হয়েছে', 'PDF saved to Downloads');
  String get pdfSaved => _t('PDF সেভ হয়েছে', 'PDF saved');
  String get pdfFailed =>
      _t('PDF তৈরি ব্যর্থ — আবার চেষ্টা করুন', 'PDF failed — try again');
  String membersCount(int n) => _bn ? '$n জন' : '$n';
  String get balance => _t('ব্যালেন্স', 'Balance');
  String get myExpense => _t('আমার খরচ', 'My expense');
  String get myBalance => _t('আমার ব্যালেন্স', 'My balance');

  // —— Meals ——
  String get mealList => _t('মিল লিস্ট', 'Meal list');
  String get mealHint => _t(
        'সকাল / বিকাল / রাত / রেট আলাদা · পরিমাণ ০.৫ করে +/− · অনুমোদনের পর তালিকায়',
        'Morning / evening / night / rate · 0.5 steps · appears after approval',
      );
  String get addMemberMeal => _t('মেম্বারের মিল যোগ', 'Add member meal');
  String get addMeal => _t('মিল যোগ করুন', 'Add meal');
  String get addMorning => _t('সকাল যোগ', 'Add morning');
  String get addEvening => _t('বিকাল যোগ', 'Add evening');
  String get addNight => _t('রাত যোগ', 'Add night');
  String get addRate => _t('রেট যোগ', 'Add rate');
  String get bulkAddMeals =>
      _t('সব মেম্বারের মিল যোগ', 'Add meals for all members');
  String get bulkAddMealsTitle =>
      _t('একসাথে মিল যোগ', 'Bulk add meals');
  String get bulkAddMealsHint => _t(
        'কুইক প্রিসেট বা ডিফল্ট সেট করে সব মেম্বারে প্রয়োগ করুন। প্রতি মেম্বার আলাদা পরিমাণও দিতে পারবেন। যোগ হলে হিসাব আপডেট ও নোটিফিকেশন যাবে।',
        'Use quick presets or defaults, apply to all, then tweak per member. Meals calculate instantly and members get notified.',
      );
  String get applyDefaultsToAll =>
      _t('সব মেম্বারে প্রয়োগ', 'Apply to all members');
  String get defaultMealAmounts =>
      _t('ডিফল্ট পরিমাণ', 'Default amounts');
  String get perMemberAmounts =>
      _t('প্রতি মেম্বারের পরিমাণ', 'Per-member amounts');
  String get quickPresets => _t('কুইক প্রিসেট', 'Quick presets');
  String get presetAllOne => _t('সবাই ১·১·১', 'All 1·1·1');
  String get presetHalfMorning =>
      _t('সকাল ০.৫ · বিকাল/রাত ১', 'AM 0.5 · rest 1');
  String get presetMorningOnly => _t('শুধু সকাল ১', 'Morning only 1');
  String get liveMealTotal => _t('লাইভ মোট', 'Live total');
  String bulkLiveCalc({
    required int members,
    required String morning,
    required String evening,
    required String night,
    required String total,
  }) =>
      _bn
          ? '$members মেম্বার · সকাল $morning · বিকাল $evening · রাত $night · মোট $total'
          : '$members members · AM $morning · Eve $evening · Night $night · total $total';
  String get confirmBulkAddTitle =>
      _t('মিল যোগ নিশ্চিত?', 'Confirm meal add?');
  String get confirmBulkAddBody => _t(
        'সিলেক্টেড মেম্বারদের অনুমোদিত মিল যোগ হবে, হিসাব আপডেট হবে এবং নোটিফিকেশন পাঠানো হবে।',
        'Approved meals will be added for selected members, totals update, and notifications are sent.',
      );
  String get bulkAddSuccessTitle =>
      _t('মিল যোগ সম্পন্ন', 'Meals added');
  String bulkAddSuccessBody({
    required int members,
    required int items,
    required String morning,
    required String evening,
    required String night,
    required String total,
    required String date,
  }) =>
      _bn
          ? '$date\n$members মেম্বার · $items এন্ট্রি\nসকাল $morning · বিকাল $evening · রাত $night\nমোট মিল: $total\nমেম্বারদের নোটিফিকেশন পাঠানো হয়েছে।'
          : '$date\n$members members · $items entries\nAM $morning · Eve $evening · Night $night\nTotal meals: $total\nMembers have been notified.';
  String get selectMealTypes =>
      _t('মিলের ধরন সিলেক্ট করুন', 'Select meal types');
  String get selectMembers =>
      _t('মেম্বার সিলেক্ট করুন', 'Select members');
  String get selectAllMembers =>
      _t('সব সিলেক্ট', 'Select all');
  String get clearMembers => _t('ক্লিয়ার', 'Clear');
  String get bulkAddConfirm =>
      _t('মিল যোগ করুন', 'Add meals');
  String get pickAtLeastOneMember =>
      _t('কমপক্ষে একজন মেম্বার সিলেক্ট করুন', 'Select at least one member');
  String get pickAtLeastOneMealType => _t(
        'কমপক্ষে একটি মিল (সকাল/বিকাল/রাত) সিলেক্ট করুন',
        'Select at least one meal type',
      );
  String bulkMealsAdded(int members, int items, String date) => _bn
      ? '$members মেম্বার · $items মিল যোগ হয়েছে ($date)'
      : '$members members · $items meals added ($date)';
  String get mealPendingHint => _t(
        'মুছতে পারবেন না · অ্যাডমিন অনুমোদন করলে হিসাব/তালিকায় যোগ হবে',
        'Cannot delete after send · admin approval adds to accounts',
      );
  String mealRequests(int n) =>
      _bn ? 'মিল অনুরোধ ($n)' : 'Meal requests ($n)';
  String get myPendingRequests =>
      _t('আমার অনুরোধ (অপেক্ষমাণ)', 'My pending requests');
  String get approvedMealList =>
      _t('অনুমোদিত মিল লিস্ট', 'Approved meals');
  String get approvedMealHint => _t(
        'অনুমোদন এর পর এখানে আলাদা আলাদা দেখা যায়',
        'Shows separately after approval',
      );
  String get noApprovedMealsDay =>
      _t('এই তারিখে অনুমোদিত মিল নেই', 'No approved meals on this date');
  String get selectMember => _t('মেম্বার সিলেক্ট করুন', 'Select member');
  String get selectMealDate =>
      _t('মিলের তারিখ সিলেক্ট করুন', 'Select meal date');
  String get quantityStep =>
      _t('পরিমাণ · ০.৫ করে বাড়ান / কমান', 'Quantity · adjust by 0.5');
  String get deleteMealTitle => _t('মিল মুছবেন?', 'Delete meal?');
  String get accept => _t('গ্রহণ', 'Accept');
  String get reject => _t('প্রত্যাখ্যান', 'Reject');
  String get morning => _t('সকাল', 'Morning');
  String get evening => _t('বিকাল', 'Evening');
  String get night => _t('রাত', 'Night');
  String get rateMeal => _t('রেট মিল', 'Rate meal');
  String get pending => _t('অপেক্ষমাণ', 'Pending');
  String get approved => _t('অনুমোদিত', 'Approved');
  String get rejected => _t('বাতিল', 'Rejected');
  String mealUpdatedBy(String name) =>
      _bn ? 'হালনাগাদ হয়েছে — সম্পাদনা: $name' : 'Updated — edited by: $name';
  String mealAddedOnDate(String type, String qty, String date) =>
      _bn ? '$type $qty যোগ হয়েছে ($date)' : '$type $qty added ($date)';
  String mealRequestSent(String type, String qty) => _bn
      ? '$type $qty অনুরোধ — অনুমোদন হলে তালিকায় যোগ হবে'
      : '$type $qty requested — appears after approval';
  String mealApprovedSnack(String label) =>
      _bn ? 'অনুমোদন — $label তালিকায় যোগ হয়েছে' : 'Approved — $label added to list';
  String get mealRejectedSnack =>
      _t('প্রত্যাখ্যান — তালিকা থেকে মুছে গেছে', 'Rejected — removed from list');
  String deleteMealBody(String name, String label) =>
      _bn ? '$name — $label মুছে যাবে।' : '$name — $label will be deleted.';
  String mealDayTotals(
    String morning,
    String evening,
    String night,
    String rate,
  ) =>
      _bn
          ? 'সকাল: $morning  •  বিকাল: $evening  •  রাত: $night  •  রেট: $rate'
          : 'Morning: $morning  •  Evening: $evening  •  Night: $night  •  Rate: $rate';
  String addMealType(String type) => _bn ? '$type যোগ' : 'Add $type';
  String addedAt(String when) => _bn ? 'যোগ: $when' : 'Added: $when';
  String addedByName(String name) =>
      _bn ? 'যোগ করেছেন: $name' : 'Added by: $name';
  String editedByName(String name) =>
      _bn ? 'সম্পাদনা: $name' : 'Edited: $name';

  // —— Market ——
  String get market => _t('বাজার', 'Bazaar');
  String get addMarket => _t('বাজার যোগ', 'Add bazaar');
  String get marketList => _t('বাজার লিস্ট', 'Bazaar list');
  String get bazaarSchedule => _t('বাজার শিডিউল', 'Bazaar schedule');
  String get bazaarDates => _t('বাজার তারিখ', 'Bazaar dates');
  String get amount => _t('পরিমাণ', 'Amount');
  String get note => _t('নোট', 'Note');
  String get thisMonth => _t('এই মাস', 'This month');
  String get lastMonth => _t('গত মাস', 'Last month');
  String get all => _t('সব', 'All');
  String get select => _t('সিলেক্ট', 'Select');
  String get due => _t('বাকি', 'Due');
  String get dateFilter => _t('তারিখ ফিল্টার', 'Date filter');
  String get memberFilter => _t('মেম্বার ফিল্টার', 'Member filter');
  String get marketDateFilterHelp =>
      _t('বাজার তারিখ ফিল্টার', 'Bazaar date filter');
  String get marketListTitle => _t('বাজারের তালিকা', 'Bazaar list');
  String get marketAdded => _t('বাজার যোগ হয়েছে', 'Bazaar added');
  String get marketUpdated =>
      _t('বাজার হালনাগাদ হয়েছে', 'Bazaar updated');
  String get marketRequestSentSnack => _t(
        'অনুরোধ পাঠানো হয়েছে — অ্যাডমিন অনুমোদন করলে সবাই দেখতে পাবে',
        'Request sent — visible to all after admin approval',
      );
  String get marketApprovedSnack => _t(
        'অনুমোদন হয়েছে — এখন সবাই দেখতে পাবে',
        'Approved — now visible to everyone',
      );
  String get marketRejectedSnack => _t(
        'প্রত্যাখ্যান করা হয়েছে — সবাই দেখতে পারবে না',
        'Rejected — not visible to others',
      );
  String get approveFailed => _t('অনুমোদন ব্যর্থ', 'Approval failed');
  String get rejectFailed => _t('প্রত্যাখ্যান ব্যর্থ', 'Rejection failed');
  String memberRequests(int n) =>
      _bn ? 'মেম্বার অনুরোধ ($n)' : 'Member requests ($n)';
  String get marketPendingApproveHint => _t(
        'অনুমোদন করলে সবাই দেখতে পাবে · প্রত্যাখ্যান করলে যোগ হবে না',
        'Approve to show everyone · reject to discard',
      );
  String get myRequests => _t('আমার অনুরোধ', 'My requests');
  String get allDatesMonthFilter =>
      _t('সব তারিখ (মাস ফিল্টার)', 'All dates (month filter)');
  String get approvedMarketVisible => _t(
        'অনুমোদিত বাজার (সবাই দেখতে পাবে)',
        'Approved bazaar (visible to all)',
      );
  String get myApprovedMarket =>
      _t('আমার বাজার (অনুমোদিত)', 'My bazaar (approved)');
  String get includingDue => _t('এর মধ্যে বাকি', 'Of which due');
  String expenseCount(int n) => _bn ? '$n টি খরচ' : '$n expenses';
  String get myMarketOnlyHint => _t(
        'শুধু আপনার বাজার · অন্য মেম্বার দেখা যায় না',
        'Only your bazaar · other members hidden',
      );
  String get noMarketOnDate =>
      _t('এই তারিখে কোনো বাজার নেই', 'No bazaar on this date');
  String get noApprovedMarketYet =>
      _t('এখনো কোনো অনুমোদিত বাজার নেই', 'No approved bazaar yet');
  String get noMarketForMember =>
      _t('এই মেম্বারের কোনো বাজার নেই', 'No bazaar for this member');
  String get noMyMarketOnDate => _t(
        'এই তারিখে আপনার কোনো বাজার নেই',
        'No bazaar for you on this date',
      );
  String get noMyApprovedMarket =>
      _t('আপনার কোনো অনুমোদিত বাজার নেই', 'You have no approved bazaar');
  String createdAtLabel(String when) =>
      _bn ? 'তৈরি: $when' : 'Created: $when';
  String get selectMarketDate =>
      _t('বাজারের তারিখ সিলেক্ট করুন', 'Select bazaar date');
  String get itemNameRequired =>
      _t('প্রতিটি আইটেমের নাম দিন', 'Enter a name for each item');
  String itemAmountRequired(String name) =>
      _bn ? '"$name" এর সঠিক টাকা দিন' : 'Enter a valid amount for "$name"';
  String get addAtLeastOneItem => _t(
        'কমপক্ষে একটি বাজার আইটেম যোগ করুন',
        'Add at least one bazaar item',
      );
  String get updateFailed => _t('হালনাগাদ ব্যর্থ', 'Update failed');
  String get marketSaveFailed =>
      _t('বাজার সংরক্ষণ ব্যর্থ', 'Failed to save bazaar');
  String get deleteMarketTitle => _t('বাজার মুছবেন?', 'Delete bazaar?');
  String get deleteMarketBody =>
      _t('এই বাজার এন্ট্রি মুছে যাবে।', 'This bazaar entry will be deleted.');
  String get deleteFailed => _t('মুছে ফেলা ব্যর্থ', 'Delete failed');
  String get editMarket => _t('বাজার সম্পাদনা করুন', 'Edit bazaar');
  String get addMarketFull => _t('বাজার যোগ করুন', 'Add bazaar');
  String get marketRequestTitle => _t('বাজার অনুরোধ', 'Bazaar request');
  String get deleteAdminOnlyTooltip =>
      _t('মুছুন (শুধু অ্যাডমিন)', 'Delete (admin only)');
  String get memberMarketRequestHint => _t(
        'মেম্বার হিসেবে বাজার অ্যাডমিনের কাছে অনুরোধ যাবে। অ্যাডমিন অনুমোদন করলে সবাই দেখতে পাবে।',
        'As a member, your bazaar goes to admin for approval. Everyone sees it once approved.',
      );
  String get pickDate => _t('তারিখ বাছুন', 'Pick date');
  String get tapDateThenSave => _t(
        'তারিখে ট্যাপ করলেই সিলেক্ট হবে · তারপর বাজার সেভ করুন',
        'Tap to select a date · then save the bazaar',
      );
  String shopperLabel(String name) =>
      _bn ? 'বাজারকারী: $name' : 'Shopper: $name';
  String editedByFull(String name) =>
      _bn ? 'সম্পাদনা করেছেন: $name' : 'Edited by: $name';
  String get onlyAdminCanDelete =>
      _t('মুছতে শুধু অ্যাডমিন পারবে', 'Only admin can delete');
  String get marketItems => _t('বাজারের আইটেম', 'Bazaar items');
  String get addItemTooltip => _t('আইটেম যোগ', 'Add item');
  String itemNumber(int n) => _bn ? 'আইটেম $n' : 'Item $n';
  String get remove => _t('রিমুভ', 'Remove');
  String get marketItemName => _t('বাজারের নাম', 'Item name');
  String get marketItemNameHint => _t('যেমন: চাল', 'e.g. rice');
  String get quantityHint => _t('৫ কেজি', '5 kg');
  String get taka => _t('টাকা', 'Amount');
  String get addMoreItems =>
      _t('আরও আইটেম যোগ করুন', 'Add more items');
  String get dueMarketSubtitle => _t(
        'দোকানে টাকা এখনো বাকি — পরে পরিশোধ হবে',
        'Still unpaid at the shop — will settle later',
      );
  String get totalAmountDue => _t('মোট টাকা (বাকি)', 'Total (due)');
  String get totalAmount => _t('মোট টাকা', 'Total amount');
  String get saveMarket => _t('বাজার সংরক্ষণ করুন', 'Save bazaar');
  String get sendRequestToAdmin =>
      _t('অ্যাডমিনকে অনুরোধ পাঠান', 'Send request to admin');
  String get selectShopper =>
      _t('বাজারকারী (মেম্বার সিলেক্ট করুন)', 'Shopper (select member)');

  // —— Bazaar schedule ——
  String get scheduleApprovedSnack => _t(
        'অনুমোদন — এখন সব মেম্বার দেখতে পাবে',
        'Approved — all members can see it now',
      );
  String get deleteScheduleTitle =>
      _t('সময়সূচি মুছবেন?', 'Delete schedule?');
  String deleteScheduleBody(String name, String range) =>
      _bn ? '$name — $range মুছে যাবে।' : '$name — $range will be deleted.';
  String get bazaarDateStatus =>
      _t('বাজার তারিখ / স্ট্যাটাস', 'Bazaar dates / status');
  String get bazaarScheduleAdminHint => _t(
        'মেম্বার অনুরোধ অনুমোদন করলে সবাই দেখবে কে কোন দিন বাজার করবে',
        'Approve member requests so everyone sees who shops which day',
      );
  String get bazaarScheduleMemberHint => _t(
        'তারিখ অনুরোধ পাঠান · অনুমোদন হলে সব মেম্বার দেখতে পাবে',
        'Request dates · all members see them after approval',
      );
  String bazaarDateRequests(int n) =>
      _bn ? 'বাজার তারিখ অনুরোধ ($n)' : 'Bazaar date requests ($n)';
  String get bazaarStatusAllMembers => _t(
        'বাজার স্ট্যাটাস (সব মেম্বার)',
        'Bazaar status (all members)',
      );
  String get bazaarStatusHint => _t(
        'কে কোন তারিখে বাজার করবে — অনুমোদন এর পর এখানে দেখা যায়',
        'Who shops which date — appears here after approval',
      );
  String get running => _t('চলমান', 'Running');
  String get upcoming => _t('আসন্ন', 'Upcoming');
  String get completed => _t('সম্পন্ন', 'Completed');
  String get noScheduledBazaarDates => _t(
        'এখনো কোনো নির্ধারিত বাজার তারিখ নেই',
        'No scheduled bazaar dates yet',
      );
  String get setDate => _t('তারিখ নির্ধারণ', 'Set date');
  String get requestDate => _t('তারিখ অনুরোধ', 'Request date');
  String get whoseBazaarDate =>
      _t('কার বাজার তারিখ?', 'Whose bazaar date?');
  String get selectStartDate =>
      _t('শুরুর তারিখ সিলেক্ট করুন', 'Select start date');
  String get selectEndDate =>
      _t('শেষ তারিখ সিলেক্ট করুন', 'Select end date');
  String scheduleSetSnack(String name, String range) =>
      _bn ? '$name: $range নির্ধারিত' : '$name: $range scheduled';
  String scheduleRequestSnack(String range) => _bn
      ? 'অনুরোধ ($range) পাঠানো হয়েছে — অনুমোদন হলে সবাই দেখবে'
      : 'Request ($range) sent — visible after approval';
  String requestAt(String when) =>
      _bn ? 'অনুরোধ: $when' : 'Requested: $when';
  String get statusPendingLabel =>
      _t('স্ট্যাটাস: অপেক্ষমাণ', 'Status: Pending');

  // —— Mess bills ——
  String get billAdded => _t('বিল যোগ হয়েছে', 'Bill added');
  String get billUpdated =>
      _t('বিল হালনাগাদ হয়েছে', 'Bill updated');
  String get saveFailedRetry => _t(
        'সংরক্ষণ ব্যর্থ — আবার চেষ্টা করুন',
        'Save failed — try again',
      );
  String get deleteBillTitle => _t('বিল মুছবেন?', 'Delete bill?');
  String deleteBillBody(String type, String amount) =>
      _bn ? '$type — $amount মুছে যাবে।' : '$type — $amount will be deleted.';
  String get billDeleted => _t('বিল মুছে গেছে', 'Bill deleted');
  String get addBill => _t('বিল যোগ', 'Add bill');
  String get billsAdminHint => _t(
        'অ্যাডমিন বিল যোগ/সম্পাদনা করতে পারবে · মাস শেষে সব মেম্বারের হিসাব PDF এক্সপোর্ট',
        'Admin can add/edit bills · export all-member PDF at month end',
      );
  String get billsMemberHint => _t(
        'এই মাসের মেস বিল — অ্যাডমিন যোগ করেছে',
        "This month's mess bills — added by admin",
      );
  String get monthEndClosingPdf => _t(
        'মাস শেষ ক্লোজিং — সব মেম্বারের হিসাব PDF',
        'Month-end closing — all members PDF',
      );
  String get noBillsThisMonth =>
      _t('এই মাসে কোনো বিল নেই', 'No bills this month');
  String get totalBills => _t('মোট বিল', 'Total bills');
  String get addBillFull => _t('বিল যোগ করুন', 'Add bill');
  String get editBill => _t('বিল সম্পাদনা', 'Edit bill');
  String get billType => _t('বিলের ধরন', 'Bill type');
  String get month => _t('মাস', 'Month');
  String get selectMonth => _t('মাস সিলেক্ট করুন', 'Select month');
  String get amountTaka => _t('টাকার পরিমাণ', 'Amount');
  String get amountExampleHint => _t('যেমন: ৫০০০', 'e.g. 5000');
  String get noteOptional => _t('নোট (ঐচ্ছিক)', 'Note (optional)');
  String get optionalDetails => _t('ঐচ্ছিক বিবরণ', 'Optional details');
  String get enterValidAmount =>
      _t('সঠিক টাকার পরিমাণ দিন', 'Enter a valid amount');

  // —— Report ——
  String get report => _t('রিপোর্ট', 'Report');
  String get monthly => _t('মাসিক', 'Monthly');
  String get daily => _t('দৈনিক', 'Daily');
  String get adminReportMode =>
      _t('অ্যাডমিন মোড · সব মেম্বারের রিপোর্ট', 'Admin mode · all members');
  String get memberReportMode =>
      _t('মেম্বার মোড · শুধু আপনার রিপোর্ট', 'Member mode · your report only');
  String get monthlyReportAll =>
      _t('মাসিক রিপোর্ট (সব মেম্বার)', 'Monthly report (all members)');
  String get myMonthlyReport =>
      _t('আমার মাসিক রিপোর্ট', 'My monthly report');
  String get memberOnlyHint => _t(
        'শুধু আপনার হিসাব · অন্য মেম্বার দেখা যায় না',
        'Only your account · other members hidden',
      );
  String get totalMessMarket =>
      _t('মোট বাজার (মেস)', 'Total bazaar (mess)');
  String get totalMeals => _t('মোট মিল', 'Total meals');
  String get allMembersAccounts =>
      _t('সব মেম্বারের হিসাব', 'All member accounts');
  String get myAccountDetail =>
      _t('আমার হিসাব বিস্তারিত', 'My account details');
  String get smartMealChart =>
      _t('Smart মিল চার্ট দেখুন / ডাউনলোড', 'Smart meal chart / download');
  String get myMealChart =>
      _t('আমার মিল চার্ট দেখুন', 'View my meal chart');
  String get mealChartPdfExcelHint => _t(
        'Excel / PDF মিল চার্ট · সকাল / বিকাল / রাত · স্ক্রল করে দেখুন',
        'Excel / PDF meal chart · morning / evening / night',
      );
  String get myBldSheet => _t(
        'আপনার প্রতিদিনের সকাল / বিকাল / রাত মিল শিট',
        'Your daily morning / evening / night sheet',
      );
  String get mealChart => _t('মিল চার্ট', 'Meal chart');
  String get smartPdf => _t('Smart PDF', 'Smart PDF');
  String get excel => _t('Excel', 'Excel');
  String get chartLoadFailed =>
      _t('চার্ট লোড হয়নি', 'Could not load chart');
  String get downloadPdf => _t('PDF ডাউনলোড', 'Download PDF');
  String get downloadExcel => _t('Excel ডাউনলোড', 'Download Excel');
  String get pdfExporting => _t('PDF…', 'PDF…');
  String get excelExporting => _t('Excel…', 'Excel…');
  String get excelSavedDownloads =>
      _t('Excel ডাউনলোড ফোল্ডারে সেভ হয়েছে', 'Excel saved to Downloads');
  String get excelSaved => _t('Excel সেভ হয়েছে', 'Excel saved');
  String get excelFailed =>
      _t('Excel তৈরি ব্যর্থ — আবার চেষ্টা করুন', 'Excel failed — try again');
  String get mealChartPdfSavedDownloads => _t(
        'মিল চার্ট PDF ডাউনলোড ফোল্ডারে সেভ হয়েছে',
        'Meal chart PDF saved to Downloads',
      );
  String get mealChartPdfSaved =>
      _t('মিল চার্ট PDF সেভ হয়েছে', 'Meal chart PDF saved');
  String get dailyReportAll =>
      _t('দৈনিক রিপোর্ট (সব মেম্বার)', 'Daily report (all members)');
  String get myDailyReport =>
      _t('আমার দৈনিক রিপোর্ট', 'My daily report');
  String get myDailyReportHint => _t(
        'শুধু আপনার মিল ও বাজারের রিপোর্ট',
        'Only your meals and bazaar report',
      );
  String get todayMarketAdmin => _t('আজকের বাজার', "Today's bazaar");
  String get totalMealsAllMembers =>
      _t('মোট মিল (সব মেম্বার)', 'Total meals (all members)');
  String get myTotalMeals => _t('আমার মোট মিল', 'My total meals');
  String get morningMeals => _t('সকাল মিল', 'Morning meals');
  String get myMorning => _t('আমার সকাল', 'My morning');
  String get eveningMeals => _t('বিকাল মিল', 'Evening meals');
  String get myEvening => _t('আমার বিকাল', 'My evening');
  String get nightMeals => _t('রাত মিল', 'Night meals');
  String get myNight => _t('আমার রাত', 'My night');
  String get myRate => _t('আমার রেট', 'My rate');
  String get allMembersMealRateCalc =>
      _t('সব মেম্বারের হিসাব (মিল × রেট)', 'All members (meals × rate)');
  String get myAttendance => _t('আমার উপস্থিতি', 'My attendance');
  String totalMealsAndCost(String meals, String cost) => _bn
      ? 'মোট মিল: $meals  •  খরচ: $cost'
      : 'Total meals: $meals  •  Cost: $cost';
  String get dayShoppers => _t('এই দিনের বাজারকারী', "Day's shoppers");
  String get myMarketList => _t('আমার বাজার লিস্ট', 'My bazaar list');
  String get todayMealRateAllMembers =>
      _t('আজকের মিল রেট (সব মেম্বার)', "Today's meal rate (all members)");
  String marketDividedByMeals(String spend, String meals) => _bn
      ? 'মোট বাজার $spend ÷ মোট মিল $meals'
      : 'Total bazaar $spend ÷ total meals $meals';

  // —— Settlement ——
  String get settlement => _t('সেটেলমেন্ট', 'Settlement');
  String get settlementHint => _t(
        'মেম্বার হিসাব ও ব্যালেন্স দেখতে রিপোর্ট → মাসিক রিপোর্ট খুলুন। সব ডেটা অ্যাপ থেকে আসে।',
        'Open Report → Monthly report to see member accounts and balances. All data comes from the app.',
      );

  // —— Community ——
  String get tabFeed => _t('ফিড', 'Feed');
  String get tabFriends => _t('ফ্রেন্ডস', 'Friends');
  String get tabChat => _t('চ্যাট', 'Chat');
  String get vacancyFeedHint =>
      _t('মেসে সিট খালি? বা খুঁজছেন?', 'Seat free? Or looking for one?');
  String get post => _t('পোস্ট', 'Post');
  String feedLoadFailed(Object error) => _bn
      ? 'ফিড লোড ব্যর্থ। ইন্টারনেট/ইন্ডেক্স চেক করুন।\n$error'
      : 'Feed failed to load. Check internet/index.\n$error';
  String get noVacancyPosts =>
      _t('এখনো কোনো ভ্যাকান্সি পোস্ট নেই।', 'No vacancy posts yet.');
  String seatsVacantShare(String messName, int seats) =>
      _bn ? '$messName — সিট খালি: $seats' : '$messName — seats available: $seats';
  String addressLine(String location) =>
      _bn ? 'ঠিকানা: $location' : 'Address: $location';
  String rentCostLine(String rent) =>
      _bn ? 'ভাড়া/খরচ: $rent' : 'Rent/cost: $rent';
  String messCodeLine(String code) =>
      _bn ? 'মেস কোড: $code' : 'Mess code: $code';
  String get communityShareFooter =>
      _t('— ম্যাস ম্যানেজার কমিউনিটি', '— Mass Manager Community');
  String seatsCount(int n) => _bn ? '$n সিট' : '$n seats';
  String get pleaseLogin => _t('লগইন করুন', 'Please sign in');
  String get friendRequests => _t('ফ্রেন্ড রিকোয়েস্ট', 'Friend requests');
  String get noNewRequests =>
      _t('কোনো নতুন রিকোয়েস্ট নেই', 'No new requests');
  String get userFallback => _t('ইউজার', 'User');
  String get acceptRequest => _t('একসেপ্ট', 'Accept');
  String get rejectRequest => _t('রিজেক্ট', 'Reject');
  String get myFriends => _t('আমার ফ্রেন্ডস', 'My friends');
  String get noFriendsYet => _t(
        'এখনো কোনো ফ্রেন্ড নেই। প্রোফাইল থেকে রিকোয়েস্ট পাঠান।',
        'No friends yet. Send a request from a profile.',
      );
  String get friendFallback => _t('ফ্রেন্ড', 'Friend');
  String get messLinked => _t('মেস যুক্ত', 'In a mess');
  String get noMess => _t('মেস নেই', 'No mess');
  String chatLoadFailed(Object error) =>
      _bn ? 'চ্যাট লোড ব্যর্থ।\n$error' : 'Chat failed to load.\n$error';
  String get noConversations => _t(
        'কোনো কথোপকথন নেই।\nফ্রেন্ড থেকে মেসেজ শুরু করুন।',
        'No conversations.\nStart a message from Friends.',
      );
  String get startMessaging => _t('মেসেজ শুরু করুন', 'Start messaging');
  String get writeMessageHint => _t('মেসেজ লিখুন…', 'Write a message…');
  String get postNotFound => _t('পোস্ট পাওয়া যায়নি', 'Post not found');
  String seatsLabel(int n) => _bn ? 'সিট: $n' : 'Seats: $n';
  String likesAndComments(int likes, int comments) => _bn
      ? '$likes লাইক · $comments কমেন্ট'
      : '$likes likes · $comments comments';
  String get comments => _t('কমেন্ট', 'Comments');
  String get noCommentsYet =>
      _t('এখনো কোনো কমেন্ট নেই।', 'No comments yet.');
  String get writeCommentHint => _t('কমেন্ট লিখুন…', 'Write a comment…');
  String get profile => _t('প্রোফাইল', 'Profile');
  String get userNotFound => _t('ইউজার পাওয়া যায়নি', 'User not found');
  String get noName => _t('নাম নেই', 'No name');
  String messColon(String name) => _bn ? 'মেস: $name' : 'Mess: $name';
  String get messJoinedShort => _t('যুক্ত', 'Joined');
  String get notInAnyMess =>
      _t('এখনো কোনো মেসে নেই', 'Not in a mess yet');
  String get editBio => _t('বায়ো এডিট', 'Edit bio');
  String get bio => _t('বায়ো', 'Bio');
  String get bioHint =>
      _t('নিজের সম্পর্কে লিখুন…', 'Write about yourself…');
  String get unfollow => _t('আনফলো', 'Unfollow');
  String get follow => _t('ফলো', 'Follow');
  String get message => _t('মেসেজ', 'Message');
  String get requestSent =>
      _t('রিকোয়েস্ট পাঠানো হয়েছে', 'Request sent');
  String get friendRequestSentSnack =>
      _t('ফ্রেন্ড রিকোয়েস্ট পাঠানো হয়েছে', 'Friend request sent');
  String get friendRequest => _t('ফ্রেন্ড রিকোয়েস্ট', 'Friend request');
  String get vacancyPost => _t('ভ্যাকান্সি পোস্ট', 'Vacancy post');
  String get seatsCountLabel =>
      _t('খালি সিটের সংখ্যা', 'Number of free seats');
  String get seatsHint => _t('যেমন: ২', 'e.g. 2');
  String get rentOptional =>
      _t('ভাড়া / খরচ (ঐচ্ছিক)', 'Rent / cost (optional)');
  String get rentHintExample =>
      _t('যেমন: মাসিক ~৩৫০০ টাকা', 'e.g. monthly ~3500 BDT');
  String get description => _t('বিবরণ', 'Description');
  String get descriptionHint => _t(
        'মেসের পরিবেশ, নিয়ম, লোকেশন ইত্যাদি…',
        'Atmosphere, rules, location…',
      );
  String get showMessCodeOnPost =>
      _t('মেস জয়েন কোড পোস্টে দেখাও', 'Show mess join code on post');
  String get publishPost => _t('পোস্ট করুন', 'Publish');
  String get postUploaded => _t('পোস্ট আপলোড হয়েছে', 'Post uploaded');

  // —— Settings ——
  String get settings => _t('সেটিংস', 'Settings');
  String get monthlyBills => _t('মাসিক বিল', 'Monthly bills');
  String get monthlyBillsSubtitle =>
      _t('খালা · ভাড়া · বিদ্যুৎ · পানি · ইউটিলিটি', 'Cook · rent · utility');
  String get notifications => _t('নোটিফিকেশন', 'Notifications');
  String get notificationsSubtitle =>
      _t('অনুমোদন ও আপডেট', 'Approvals and updates');
  String get lockMonth => _t('মাস শেষ ক্লোজ করুন', 'Close month end');
  String get unlockMonth => _t('মাস আনলক করুন', 'Unlock month');
  String get monthLocked =>
      _t('এই মাস ক্লোজড — এডিট বন্ধ', 'Month closed — edits disabled');
  String get monthLockedHint => _t(
        'ক্লোজ করলে সেই মাসের হিসাব ফিক্সড থাকবে। নতুন মাসের হিসাব আলাদা নতুন করে গণনা হবে। আগের মাস হোম/রিপোর্ট থেকে দেখা যাবে।',
        'Closing freezes that month. The next month calculates fresh. Browse past months on Home/Report.',
      );
  String get closeMonthTitle => _t('মাস শেষ ক্লোজ?', 'Close this month?');
  String get closeMonthConfirm => _t(
        'ক্লোজ করলে এই মাসের মিল, বাজার ও বিল আর এডিট করা যাবে না। সব মেম্বারের হিসাব এই মাসের জন্য আলাদা থাকবে। নতুন মাসে হিসাব নতুন করে শুরু হবে। আগের মাস পরেও দেখা যাবে।',
        'After close, meals/markets/bills for this month cannot be edited. Member balances stay per month. The next month starts fresh. You can still view past months.',
      );
  String get closeMonthAction => _t('ক্লোজ করুন', 'Close month');
  String get monthClosedSuccess => _t(
        'মাস ক্লোজ হয়েছে — নতুন মাসের হিসাব আলাদা থাকবে',
        'Month closed — new month calculates separately',
      );
  String get monthUnlockedSuccess =>
      _t('মাস আনলক হয়েছে', 'Month unlocked');
  String get privacy => _t('প্রাইভেসি', 'Privacy');
  String get help => _t('সাহায্য', 'Help');
  String get about => _t('অ্যাপ সম্পর্কে', 'About');
  String get leaveMess => _t('মেস ছাড়ুন', 'Leave mess');
  String get leaveMessSubtitle =>
      _t('এই মেস থেকে বের হয়ে যান', 'Exit this mess');
  String get monthLockedWrite => _t(
        'এই মাস ক্লোজ করা আছে — পরিবর্তন করা যায় না।',
        'This month is closed — changes are not allowed.',
      );
  String get memberAdded =>
      _t('নতুন মেম্বার যোগ হয়েছে', 'New member added');
  String get noPermissionManageMember => _t(
        'এই মেম্বার ম্যানেজ করার অনুমতি নেই।',
        'You do not have permission to manage this member.',
      );
  String get editRoomNumber =>
      _t('রুম নম্বর সম্পাদনা', 'Edit room number');
  String get removeAsAdmin =>
      _t('অ্যাডমিন থেকে সরান', 'Remove as admin');
  String get makeAdmin => _t('অ্যাডমিন বানান', 'Make admin');
  String get onlySuperAdminCan => _t(
        'শুধু সুপার অ্যাডমিন করতে পারে',
        'Only super admin can do this',
      );
  String get transferSuperAdmin =>
      _t('সুপার অ্যাডমিন হস্তান্তর', 'Transfer super admin');
  String get transferOwnershipHint => _t(
        'মেসের মালিকানা এঁকে দিবেন',
        'You will hand over mess ownership',
      );
  String get removeFromMess =>
      _t('মেস থেকে রিমুভ', 'Remove from mess');
  String get makeAdminConfirmTitle =>
      _t('অ্যাডমিন বানাবেন?', 'Make admin?');
  String get removeAdminConfirmTitle =>
      _t('অ্যাডমিন থেকে সরাবেন?', 'Remove admin?');
  String makeAdminConfirmBody(String name) => _bn
      ? '$name কে অ্যাডমিন করা হবে। অ্যাডমিন মেম্বার ম্যানেজ করতে পারবে, কিন্তু সুপার অ্যাডমিনের রোল বদলাতে পারবে না।'
      : '$name will be made admin. Admins can manage members but cannot change the super admin role.';
  String demoteToMemberBody(String name) =>
      _bn ? '$name কে সাধারণ মেম্বার করা হবে।' : '$name will become a regular member.';
  String get removeRoleAction => _t('সরান', 'Remove');
  String get adminMadeSuccess =>
      _t('অ্যাডমিন করা হয়েছে', 'Made admin');
  String get adminRemovedSuccess =>
      _t('অ্যাডমিন সরানো হয়েছে', 'Admin removed');
  String get transferSuperAdminTitle =>
      _t('সুপার অ্যাডমিন হস্তান্তর?', 'Transfer super admin?');
  String transferSuperAdminBody(String name) => _bn
      ? '$name সুপার অ্যাডমিন হবেন। আপনি অ্যাডমিন হয়ে যাবেন। এই কাজ পরে আর উল্টানো যায় না সহজে।'
      : '$name will become super admin. You will become an admin. This cannot be easily undone.';
  String get transferAction => _t('হস্তান্তর করুন', 'Transfer');
  String get transferSuccess =>
      _t('সুপার অ্যাডমিন হস্তান্তর হয়েছে', 'Super admin transferred');
  String get roomNumber => _t('রুম নম্বর', 'Room number');
  String get roomHint => _t('যেমন: A-১', 'e.g. A-1');
  String get roomUpdated =>
      _t('রুম হালনাগাদ হয়েছে', 'Room updated');
  String get removeMemberTitle =>
      _t('মেম্বার রিমুভ?', 'Remove member?');
  String removeMemberBody(String name) =>
      _bn ? '$name কে মেস থেকে রিমুভ করা হবে।' : '$name will be removed from the mess.';
  String get removeAction => _t('রিমুভ', 'Remove');
  String get memberRemoved =>
      _t('মেম্বার রিমুভ হয়েছে', 'Member removed');
  String get noMembersYet =>
      _t('এখনো কোনো মেম্বার নেই', 'No members yet');
  String get noMembersHint => _t(
        'কোড শেয়ার করে বা নতুন অ্যাকাউন্ট তৈরি করে যোগ করুন',
        'Share the code or create a new account to add members',
      );
  String get roomEmpty => _t('রুম —', 'Room —');
  String get superAdminManageHint => _t(
        'সুপার অ্যাডমিন: ইমেইল দিয়ে মেম্বার যোগ করতে পারেন, অ্যাডমিন বানাতে পারেন ও মেম্বার ম্যানেজ করতে পারেন।',
        'Super admin: can add members by email, make admins, and manage members.',
      );
  String get adminManageHint => _t(
        'অ্যাডমিন: শুধু সাধারণ মেম্বার ম্যানেজ করতে পারবেন। সুপার অ্যাডমিনের রোল বদলানো যায় না।',
        'Admin: can only manage regular members. The super admin role cannot be changed.',
      );
  String get addMember => _t('মেম্বার যোগ করুন', 'Add member');
  String get addNewMemberTitle =>
      _t('নতুন মেম্বার যোগ', 'Add new member');
  String get addMemberHint => _t(
        'ইমেইল ও পাসওয়ার্ড দিয়ে নতুন অ্যাকাউন্ট তৈরি হবে এবং এই মেসে যোগ হবে।',
        'A new account will be created with email and password and joined to this mess.',
      );
  String get shareMessCode =>
      _t('মেস কোড শেয়ার করুন', 'Share mess code');
  String get leaveMessConfirmBody => _t(
        'আপনি এই মেস থেকে বের হয়ে যাবেন। পরে আবার কোড দিয়ে যোগ দিতে পারবেন।',
        'You will leave this mess. You can join again later with the code.',
      );
  String get leftMessSuccess =>
      _t('মেস ছেড়ে দেওয়া হয়েছে', 'You have left the mess');
  String get notificationsInfoBody => _t(
        'মিল/বাজার অনুমোদন ও বিল যোগ হলে নোটিফিকেশন পাবেন। ডিভাইস পারমিশন চালু রাখুন।',
        'You will get notifications for meal/bazaar approvals and new bills. Keep device permission on.',
      );
  String get youtubeChannel => _t('ইউটিউব চ্যানেল', 'YouTube channel');
  String get youtubeChannelSubtitle =>
      _t('Journey English Daily দেখুন', 'Watch Journey English Daily');
  String get facebookPage => _t('ফেসবুক পেজ', 'Facebook page');
  String get facebookPageSubtitle =>
      _t('আমাদের ফেসবুক পেজ খুলুন', 'Open our Facebook page');
  String get openLinkFailed => _t(
        'লিংক খোলা যায়নি। আবার চেষ্টা করুন।',
        'Could not open the link. Try again.',
      );
  String get privacyInfoBody => _t(
        'আপনার তথ্য শুধুমাত্র আপনার মেসের হিসাব পরিচালনার জন্য ব্যবহৃত হয়। মেসের ডেটা শুধু মেসের মেম্বাররাই দেখতে পারে। আমরা কোনো তথ্য তৃতীয় পক্ষের কাছে বিক্রি করি না।',
        'Your data is used only to manage your mess accounts. Mess data is visible only to mess members. We do not sell data to third parties.',
      );
  String get helpInfoBody => _t(
        '• মিল: প্রতিদিন সকাল/বিকাল/রাতের মিল যোগ করুন।\n'
            '• বাজার: বাজার এন্ট্রি দিন — অ্যাডমিন অনুমোদন করবে।\n'
            '• রিপোর্ট / হোম: মাস বদলে আগের মাসের হিসাব দেখুন।\n'
            '• মাস শেষ ক্লোজ: অ্যাডমিন মাস ক্লোজ করলে সেই মাসের এডিট বন্ধ — নতুন মাসের হিসাব আলাদা নতুন করে চলবে।\n'
            '• মাসিক বিল: অ্যাডমিন বিল যোগ করে মাস শেষে PDF এক্সপোর্ট করতে পারে।\n'
            '• মেম্বার যোগ: সুপার অ্যাডমিন ইমেইল/পাসওয়ার্ড দিয়ে অ্যাকাউন্ট তৈরি করতে পারে, অথবা মেস কোড শেয়ার করুন।',
        '• Meals: add morning/evening/night meals daily.\n'
            '• Bazaar: add bazaar entries — admin will approve.\n'
            '• Report / Home: switch months to view past accounts.\n'
            '• Close month: when admin closes a month, edits stop — the next month starts fresh.\n'
            '• Monthly bills: admin can add bills and export PDF at month end.\n'
            '• Add members: super admin can create accounts with email/password, or share the mess code.',
      );
  String get aboutSubtitle =>
      _t('মেস ম্যানেজার · সংস্করণ ১.০.০', 'Mass Manager · version 1.0.0');
  String get aboutBody => _t(
        'সংস্করণ ১.০.০\n\nমেস/হোস্টেলের মিল, বাজার, বিল ও মাসিক হিসাব সহজে পরিচালনার অ্যাপ। সব মেম্বারের হিসাব এক জায়গায়, স্বচ্ছভাবে।',
        'Version 1.0.0\n\nAn app to manage mess/hostel meals, bazaar, bills and monthly accounts easily. Everyone’s accounts in one place, transparently.',
      );

  // —— Roles ——
  String get superAdmin => _t('সুপার অ্যাডমিন', 'Super admin');
  String get admin => _t('অ্যাডমিন', 'Admin');
  String get member => _t('মেম্বার', 'Member');

  // —— Login extras ——
  String get orDivider => _t('অথবা', 'or');
  String get secureLogin => _t('সুরক্ষিত লগইন', 'Secure login');
  String get easyMessManagement =>
      _t('সহজ মেস ম্যানেজমেন্ট', 'Easy mess management');

  // —— Header / banner / session ——
  String get noNewNotifications =>
      _t('নতুন কোনো নোটিফিকেশন নেই', 'No new notifications');
  String get startNewMess => _t('নতুন মেস শুরু করুন', 'Start a new mess');
  String get keepAccountsTogether =>
      _t('সহজেই হিসাব রাখুন সবার সাথে', 'Keep accounts easily with everyone');
  String get notInThisMess =>
      _t('আপনি আর এই মেসে নেই', 'You are no longer in this mess');
  String get removedFromMessHint => _t(
        'অ্যাডমিন আপনাকে রিমুভ করেছেন অথবা আপনি মেস ছেড়েছেন। নতুন মেসে যোগ দিতে নিচে ট্যাপ করুন।',
        'An admin removed you or you left the mess. Tap below to join a new mess.',
      );
  String get goToMessSetup => _t('মেস সেটআপে যান', 'Go to mess setup');

  // —— Date picker / time ——
  String get selectDate => _t('তারিখ সিলেক্ট করুন', 'Select a date');
  String get tapDateToSelect =>
      _t('তারিখে ট্যাপ করলেই সিলেক্ট হবে', 'Tap a date to select it');
  String get amPeriod => _t('পূর্বাহ্ন', 'AM');
  String get pmPeriod => _t('অপরাহ্ন', 'PM');

  List<String> get weekdaysShort => _bn
      ? const ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি']
      : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // —— Meal chart sheet ——
  String mealChartTitle(String monthLabel, {String? messName}) {
    if (messName != null && messName.trim().isNotEmpty) {
      return _t(
        'মিল চার্ট — ${messName.trim()} — $monthLabel',
        'Meal chart — ${messName.trim()} — $monthLabel',
      );
    }
    return _t('মিল চার্ট — $monthLabel', 'Meal chart — $monthLabel');
  }

  String get morningEveningNight =>
      _t('সকাল  ·  বিকাল  ·  রাত', 'Morning  ·  Evening  ·  Night');
  String get mealChartScrollHint => _t(
        'বামে স্ক্রল → মেম্বার · উপরে-নিচে → তারিখ  ·  সকাল / বিকাল / রাত',
        'Scroll sideways → members · up/down → dates  ·  morning / evening / night',
      );

  // —— Months ——
  List<String> get months => _bn
      ? const [
          'জানুয়ারি',
          'ফেব্রুয়ারি',
          'মার্চ',
          'এপ্রিল',
          'মে',
          'জুন',
          'জুলাই',
          'আগস্ট',
          'সেপ্টেম্বর',
          'অক্টোবর',
          'নভেম্বর',
          'ডিসেম্বর',
        ]
      : const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];

  String monthLabel(DateTime month) =>
      '${months[month.month - 1]} ${month.year}';

  String formatDate(DateTime d) {
    final text = '${d.day} ${months[d.month - 1]} ${d.year}';
    return _bn ? _toBnDigits(text) : text;
  }

  String formatDateTimeLocal(DateTime? d) {
    if (d == null) return '—';
    final bd = d.toUtc().add(const Duration(hours: 6));
    final datePart = formatDate(DateTime(bd.year, bd.month, bd.day));
    var hour = bd.hour % 12;
    if (hour == 0) hour = 12;
    final minute = bd.minute.toString().padLeft(2, '0');
    final period = bd.hour < 12 ? amPeriod : pmPeriod;
    var time = '$hour:$minute';
    if (_bn) time = _toBnDigits(time);
    return '$datePart, $time $period';
  }

  String digits(String input) => _bn ? _toBnDigits(input) : input;

  static String _toBnDigits(String input) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(en[i], bn[i]);
    }
    return out;
  }
}

/// Locale + theme aware text style.
/// Depends on [LocaleScope] / [ThemeScope] so language & colors stay in sync.
TextStyle appFont({
  required BuildContext context,
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  // Register rebuild deps when language or theme changes.
  LocaleScope.maybeOf(context);
  ThemeScope.maybeOf(context);

  final bn = AppStrings.of(context).isBengali;
  final resolved = color ?? AppColors.textDark;
  final base = bn
      ? GoogleFonts.notoSansBengali(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: resolved,
          height: height,
          letterSpacing: letterSpacing,
        )
      : GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: resolved,
          height: height,
          letterSpacing: letterSpacing,
        );
  return base;
}
