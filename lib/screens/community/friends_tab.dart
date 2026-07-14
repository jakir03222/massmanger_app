import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (uid == null) {
      return Center(
        child: Text('লগইন করুন', style: GoogleFonts.notoSansBengali()),
      );
    }

    final social = SocialService();
    final userService = UserService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'ফ্রেন্ড রিকোয়েস্ট',
          style: GoogleFonts.notoSansBengali(
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
                  'কোনো নতুন রিকোয়েস্ট নেই',
                  style: GoogleFonts.notoSansBengali(
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
                    color: Colors.white,
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
                            r.fromName ?? 'ইউজার',
                            style: GoogleFonts.notoSansBengali(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => social.acceptFriendRequest(r.id),
                        child: Text(
                          'একসেপ্ট',
                          style: GoogleFonts.notoSansBengali(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => social.rejectFriendRequest(r.id),
                        child: Text(
                          'না',
                          style: GoogleFonts.notoSansBengali(
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
          'আমার ফ্রেন্ডস',
          style: GoogleFonts.notoSansBengali(
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
                'এখনো কোনো ফ্রেন্ড নেই। প্রোফাইল থেকে রিকোয়েস্ট পাঠান।',
                style: GoogleFonts.notoSansBengali(
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
                    final name = friend?.name ?? 'ফ্রেন্ড';
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
                        style: GoogleFonts.notoSansBengali(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        friend?.hasMess == true
                            ? (friend?.messName ?? 'মেস যুক্ত')
                            : 'মেস নেই',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
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
                                  style: GoogleFonts.notoSansBengali(),
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
