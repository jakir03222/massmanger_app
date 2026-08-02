import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/inbox_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_surface.dart';
import 'bazaar_schedule_screen.dart';
import 'bazaar_swap_screen.dart';
import 'meal_screen.dart';
import 'mess_bills_screen.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  final _service = NotificationService();
  bool _deletingAll = false;

  Future<void> _confirmDeleteAll(String uid) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.deleteAllNotificationsTitle,
          style: appFont(context: ctx, fontWeight: FontWeight.w700),
        ),
        content: Text(
          s.deleteAllNotificationsBody,
          style: appFont(context: ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.no, style: appFont(context: ctx)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.delete,
              style: appFont(
                context: ctx,
                color: AppColors.monthRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deletingAll = true);
    try {
      await _service.deleteAllNotifications(uid);
      if (!mounted) return;
      showAppSnack(context, s.allNotificationsDeleted);
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, s.deleteFailed, isError: true);
    } finally {
      if (mounted) setState(() => _deletingAll = false);
    }
  }

  Future<void> _openNotification(String uid, InboxNotification n) async {
    if (!n.read) {
      await _service.markRead(uid, n.id);
    }
    if (!mounted) return;
    final type = n.type.toLowerCase();
    Widget? page;
    if (type.contains('meal')) {
      page = Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.pageBackground,
          title: Text(
            AppStrings.of(context).navMeal,
            style: appFont(context: context, fontWeight: FontWeight.w700),
          ),
        ),
        body: const MealScreen(),
      );
    } else if (type.contains('bazaar_swap') || type.contains('swap')) {
      page = const BazaarSwapScreen();
    } else if (type.contains('bazaar') || type.contains('market')) {
      page = Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.pageBackground,
          title: Text(
            AppStrings.of(context).bazaarDates,
            style: appFont(context: context, fontWeight: FontWeight.w700),
          ),
        ),
        body: const BazaarScheduleScreen(),
      );
    } else if (type.contains('bill')) {
      page = const MessBillsScreen();
    }
    if (page != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page!),
      );
    }
  }

  Widget _swipeBackground({required bool fromStart}) {
    return Container(
      alignment: fromStart ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.monthRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final s = AppStrings.of(context);
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.notificationsInbox)),
        body: Center(child: Text(s.noLogin)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        title: Text(
          s.notificationsInbox,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _deletingAll ? null : () => _service.markAllRead(uid),
            child: Text(
              s.markAllRead,
              style: appFont(
                context: context,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          TextButton(
            onPressed: _deletingAll ? null : () => _confirmDeleteAll(uid),
            child: _deletingAll
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.monthRed,
                    ),
                  )
                : Text(
                    s.deleteAllNotifications,
                    style: appFont(
                      context: context,
                      fontWeight: FontWeight.w700,
                      color: AppColors.monthRed,
                    ),
                  ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.watchInbox(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorState(title: s.somethingWentWrong);
          }
          if (!snap.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }
          final items = snap.data!
              .map((m) => InboxNotification.fromMap(
                    m['id'] as String,
                    Map<String, dynamic>.from(m)..remove('id'),
                  ))
              .toList();
          if (items.isEmpty) {
            return Padding(
              padding: AppSpace.pageH,
              child: AppEmptyState(
                icon: Icons.notifications_none_rounded,
                title: s.noNotifications,
                subtitle: s.notificationsInfoBody,
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.swipe_rounded,
                      size: 16,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.swipeToDeleteHint,
                        style: appFont(
                          context: context,
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final n = items[index];
                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.horizontal,
                      background: _swipeBackground(fromStart: true),
                      secondaryBackground: _swipeBackground(fromStart: false),
                      confirmDismiss: (_) async {
                        try {
                          await _service.deleteNotification(uid, n.id);
                          if (!context.mounted) return true;
                          showAppSnack(context, s.notificationDeleted);
                          return true;
                        } catch (_) {
                          if (!context.mounted) return false;
                          showAppSnack(context, s.deleteFailed, isError: true);
                          return false;
                        }
                      },
                      child: AppCard(
                        elevated: false,
                        color: n.read
                            ? AppColors.card
                            : AppColors.featureGreenBg,
                        onTap: () => _openNotification(uid, n),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: appFont(
                                      context: context,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.textGrey,
                                ),
                                if (!n.read) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (n.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: appFont(
                                  context: context,
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
