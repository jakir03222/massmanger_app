import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../models/social.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import 'chat_thread_screen.dart';

class ChatInboxTab extends StatelessWidget {
  const ChatInboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final s = AppStrings.of(context);
    if (uid == null) {
      return Center(
        child: Text(s.pleaseLogin, style: appFont(context: context)),
      );
    }

    final chatService = ChatService();
    final userService = UserService();

    return StreamBuilder<List<Conversation>>(
      stream: chatService.watchInbox(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.chatLoadFailed(snap.error!),
                textAlign: TextAlign.center,
                style: appFont(context: context, color: AppColors.textGrey),
              ),
            ),
          );
        }
        final conversations = snap.data ?? [];
        if (conversations.isEmpty) {
          return Center(
            child: Text(
              s.noConversations,
              textAlign: TextAlign.center,
              style: appFont(context: context, color: AppColors.textGrey),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: conversations.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = conversations[i];
            final other = c.otherUid(uid);
            final time = c.updatedAt != null
                ? DateFormat('d MMM').format(c.updatedAt!)
                : '';
            return StreamBuilder<AppUser?>(
              stream: userService.watchUser(other),
              builder: (context, userSnap) {
                final user = userSnap.data;
                final name = user?.name ?? s.friendFallback;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
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
                    c.lastMessage ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appFont(
                      context: context,
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  trailing: Text(
                    time,
                    style: appFont(
                      context: context,
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatThreadScreen(
                          conversationId: c.id,
                          otherUid: other,
                          otherName: name,
                          otherPhotoUrl: user?.photoUrl,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
