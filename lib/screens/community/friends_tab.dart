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
import 'public_profile_screen.dart';

class FriendsTab extends StatelessWidget {
  const FriendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final s = AppStrings.of(context);
    if (uid == null) {
      return Center(
        child: Text(s.pleaseLogin, style: appFont(context: context)),
      );
    }

    final social = SocialService();
    final userService = UserService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          s.friendRequests,
          style: appFont(
            context: context,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<FriendRequest>>(
          stream: social.watchIncomingRequests(uid),
          builder: (context, snap) {
            final requests = snap.data ?? [];
            if (requests.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  s.noNewRequests,
                  style: appFont(
                    context: context,
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              );
            }
            return Column(
              children: requests.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: r.fromPhotoUrl != null
                            ? NetworkImage(r.fromPhotoUrl!)
                            : null,
                        child: r.fromPhotoUrl == null
                            ? Text(
                                (r.fromName?.isNotEmpty == true
                                        ? r.fromName![0]
                                        : '?')
                                    .toUpperCase(),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PublicProfileScreen(uid: r.fromUid),
                              ),
                            );
                          },
                          child: Text(
                            r.fromName ?? s.userFallback,
                            style: appFont(
                              context: context,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => social.acceptFriendRequest(r.id),
                        child: Text(
                          s.acceptRequest,
                          style: appFont(
                            context: context,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => social.rejectFriendRequest(r.id),
                        child: Text(
                          s.no,
                          style: appFont(
                            context: context,
                            color: AppColors.monthRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          s.myFriends,
          style: appFont(
            context: context,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Friendship>>(
          stream: social.watchFriendships(uid),
          builder: (context, snap) {
            final friendships = snap.data ?? [];
            if (friendships.isEmpty) {
              return Text(
                s.noFriendsYet,
                style: appFont(
                  context: context,
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              );
            }
            return Column(
              children: friendships.map((f) {
                final other = f.otherUid(uid);
                return StreamBuilder<AppUser?>(
                  stream: userService.watchUser(other),
                  builder: (context, userSnap) {
                    final friend = userSnap.data;
                    final name = friend?.name ?? s.friendFallback;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: friend?.photoUrl != null
                            ? NetworkImage(friend!.photoUrl!)
                            : null,
                        child: friend?.photoUrl == null
                            ? Text(name.isNotEmpty ? name[0] : '?')
                            : null,
                      ),
                      title: Text(
                        name,
                        style: appFont(
                          context: context,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        friend?.hasMess == true
                            ? (friend?.messName ?? s.messLinked)
                            : s.noMess,
                        style: appFont(
                          context: context,
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.chat_rounded,
                          color: AppColors.primaryGreen,
                        ),
                        onPressed: () async {
                          try {
                            final convId = await ChatService()
                                .getOrCreateConversation(other);
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ChatThreadScreen(
                                  conversationId: convId,
                                  otherUid: other,
                                  otherName: name,
                                  otherPhotoUrl: friend?.photoUrl,
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
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PublicProfileScreen(uid: other),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
