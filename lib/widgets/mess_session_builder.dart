import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/mess.dart';
import '../services/mess_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';

/// Resolves current user's messId + mess doc for live screens.
class MessSessionBuilder extends StatelessWidget {
  const MessSessionBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    AppUser appUser,
    Mess mess,
    List<MessMember> members,
  ) builder;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(child: Text(AppStrings.of(context).noLogin));
    }

    final userService = UserService();
    final messService = MessService();

    return StreamBuilder<AppUser?>(
      stream: userService.watchUser(uid),
      builder: (context, userSnap) {
        final appUser = userSnap.data;
        final messId = appUser?.messId;
        if (appUser == null || messId == null || messId.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        return StreamBuilder<Mess?>(
          stream: messService.watchMess(messId),
          builder: (context, messSnap) {
            final mess = messSnap.data;
            if (mess == null) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            }

            return StreamBuilder<List<MessMember>>(
              stream: messService.watchMembers(messId),
              builder: (context, membersSnap) {
                final members = membersSnap.data ?? [];
                // If the current user was removed from the mess, don't crash —
                // show a friendly notice and let them leave cleanly.
                final removed = membersSnap.hasData &&
                    members.isNotEmpty &&
                    !members.any((m) => m.uid == uid);
                if (removed) {
                  return _RemovedFromMessView(uid: uid);
                }
                return builder(context, appUser, mess, members);
              },
            );
          },
        );
      },
    );
  }
}

class _RemovedFromMessView extends StatelessWidget {
  const _RemovedFromMessView({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline,
                color: AppColors.primaryGreen, size: 48),
            const SizedBox(height: 16),
            Text(
              s.notInThisMess,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.removedFromMessHint,
              textAlign: TextAlign.center,
              style: appFont(
                context: context,
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => UserService().clearMessId(uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                s.goToMessSetup,
                style: appFont(context: context, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatBnDate(DateTime d) {
  const months = [
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
  ];
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  var text = '${d.day} ${months[d.month - 1]} ${d.year}';
  for (var i = 0; i < 10; i++) {
    text = text.replaceAll(en[i], bn[i]);
  }
  return text;
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String yearMonthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

String formatTaka(num amount) {
  final n = amount.round();
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return '${buf.toString()}৳';
}

/// Bangladesh Standard Time (UTC+6).
/// Pass [context] to use [AppStrings.formatDateTimeLocal]; otherwise Bangla.
String formatDateTime(DateTime? d, [BuildContext? context]) {
  if (context != null) {
    return AppStrings.of(context).formatDateTimeLocal(d);
  }
  if (d == null) return '—';
  final bd = d.toUtc().add(const Duration(hours: 6));
  final datePart = formatBnDate(DateTime(bd.year, bd.month, bd.day));
  var hour = bd.hour % 12;
  if (hour == 0) hour = 12;
  final minute = bd.minute.toString().padLeft(2, '0');
  final period = bd.hour < 12 ? 'পূর্বাহ্ন' : 'অপরাহ্ন';
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  var time = '$hour:$minute';
  for (var i = 0; i < 10; i++) {
    time = time.replaceAll(en[i], bn[i]);
  }
  return '$datePart, $time $period';
}
