import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../models/social.dart';
import '../../services/chat_service.dart';
import '../../services/social_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import 'chat_thread_screen.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final userService = UserService();
    final social = SocialService();
    final isSelf = me == uid;
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          s.profile,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: StreamBuilder<AppUser?>(
        stream: userService.watchUser(uid),
        builder: (context, snap) {
          final user = snap.data;
          if (snap.connectionState == ConnectionState.waiting && user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (user == null) {
            return Center(
              child: Text(
                s.userNotFound,
                style: appFont(context: context),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.featureGreenBg,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          ((user.name?.isNotEmpty == true
                                      ? user.name![0]
                                      : user.email.isNotEmpty
                                          ? user.email[0]
                                          : '?'))
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.name?.trim().isNotEmpty == true
                    ? user.name!
                    : s.noName,
                textAlign: TextAlign.center,
                style: appFont(
                  context: context,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.hasMess
                    ? s.messColon(user.messName ?? s.messJoinedShort)
                    : s.notInAnyMess,
                textAlign: TextAlign.center,
                style: appFont(
                  context: context,
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
              if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  user.bio!,
                  textAlign: TextAlign.center,
                  style: appFont(
                    context: context,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              if (isSelf) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => _editBio(context, user),
                  child: Text(
                    s.editBio,
                    style: appFont(context: context),
                  ),
                ),
              ] else if (me != null) ...[
                const SizedBox(height: 24),
                _SocialActions(me: me, target: user, social: social),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _editBio(BuildContext context, AppUser user) async {
    final s = AppStrings.of(context);
    final controller = TextEditingController(text: user.bio ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          s.bio,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: appFont(context: context),
          decoration: InputDecoration(
            hintText: s.bioHint,
            hintStyle: appFont(context: context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel, style: appFont(context: context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              s.save,
              style: appFont(
                context: context,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      await UserService().updateBio(user.uid, result);
    }
  }
}

class _SocialActions extends StatelessWidget {
  const _SocialActions({
    required this.me,
    required this.target,
    required this.social,
  });

  final String me;
  final AppUser target;
  final SocialService social;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      children: [
        StreamBuilder<bool>(
          stream: social.watchIsFollowing(me, target.uid),
          builder: (context, followSnap) {
            final following = followSnap.data == true;
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    if (following) {
                      await social.unfollow(target.uid);
                    } else {
                      await social.follow(target.uid);
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$e', style: appFont(context: context)),
                      ),
                    );
                  }
                },
                child: Text(
                  following ? s.unfollow : s.follow,
                  style: appFont(
                    context: context,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        StreamBuilder<bool>(
          stream: social.watchAreFriends(me, target.uid),
          builder: (context, friendSnap) {
            final areFriends = friendSnap.data == true;
            if (areFriends) {
              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      final convId =
                          await ChatService().getOrCreateConversation(
                        target.uid,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatThreadScreen(
                            conversationId: convId,
                            otherUid: target.uid,
                            otherName: target.name ?? s.friendFallback,
                            otherPhotoUrl: target.photoUrl,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('$e', style: appFont(context: context)),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_rounded),
                  label: Text(
                    s.message,
                    style: appFont(
                      context: context,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                ),
              );
            }

            return StreamBuilder<FriendRequest?>(
              stream: social.watchPendingRequestBetween(me, target.uid),
              builder: (context, reqSnap) {
                final req = reqSnap.data;
                if (req != null && req.fromUid == me) {
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: null,
                      child: Text(
                        s.requestSent,
                        style: appFont(context: context),
                      ),
                    ),
                  );
                }
                if (req != null && req.toUid == me) {
                  return Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              social.acceptFriendRequest(req.id),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                          child: Text(
                            s.acceptRequest,
                            style: appFont(
                              context: context,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              social.rejectFriendRequest(req.id),
                          child: Text(
                            s.rejectRequest,
                            style: appFont(context: context),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await social.sendFriendRequest(target.uid);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              s.friendRequestSentSnack,
                              style: appFont(context: context),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$e',
                              style: appFont(context: context),
                            ),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                    ),
                    child: Text(
                      s.friendRequest,
                      style: appFont(
                        context: context,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
