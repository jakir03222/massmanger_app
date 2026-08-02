import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/mess.dart';
import '../services/mess_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import 'app_error_state.dart';

// Re-export date/money helpers so existing screen imports keep compiling.
export '../utils/date_formatters.dart';

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
      return Center(
        child: Text(
          AppStrings.of(context).noLogin,
          style: appFont(context: context),
        ),
      );
    }

    final userService = UserService();
    final messService = MessService();

    return StreamBuilder<AppUser?>(
      stream: userService.watchUser(uid),
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          return AppErrorState(title: AppStrings.of(context).sessionLoadFailed);
        }
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
            if (messSnap.hasError) {
              return AppErrorState(
                title: AppStrings.of(context).sessionLoadFailed,
              );
            }
            final mess = messSnap.data;
            if (mess == null) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            }

            return StreamBuilder<List<MessMember>>(
              stream: messService.watchMembers(messId),
              builder: (context, membersSnap) {
                if (membersSnap.hasError) {
                  return AppErrorState(
                    title: AppStrings.of(context).sessionLoadFailed,
                  );
                }
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
            Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 48),
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
