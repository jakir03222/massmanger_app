import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/app_user.dart';
import '../../models/community_post.dart';
import '../../services/community_post_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import 'create_vacancy_post_screen.dart';
import 'post_detail_screen.dart';
import 'public_profile_screen.dart';

class CommunityFeedTab extends StatelessWidget {
  const CommunityFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final postService = CommunityPostService();
    final userService = UserService();

    return StreamBuilder<AppUser?>(
      stream: uid == null ? null : userService.watchUser(uid),
      builder: (context, userSnap) {
        final me = userSnap.data;
        final canPost = me?.hasMess == true;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'মেসে সিট খালি? বা খুঁজছেন?',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  if (canPost)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CreateVacancyPostScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'পোস্ট',
                        style: GoogleFonts.notoSansBengali(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<CommunityPost>>(
                stream: postService.watchFeed(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'ফিড লোড ব্যর্থ। ইন্টারনেট/ইন্ডেক্স চেক করুন।\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansBengali(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    );
                  }
                  final posts = snap.data ?? [];
                  if (posts.isEmpty) {
                    return Center(
                      child: Text(
                        'এখনো কোনো ভ্যাকান্সি পোস্ট নেই।',
                        style: GoogleFonts.notoSansBengali(
                          color: AppColors.textGrey,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _PostCard(post: posts[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  Future<void> _share() async {
    final buffer = StringBuffer()
      ..writeln('${post.messName} — সিট খালি: ${post.seatsAvailable}')
      ..writeln(post.body);
    if (post.messLocation != null && post.messLocation!.isNotEmpty) {
      buffer.writeln('ঠিকানা: ${post.messLocation}');
    }
    if (post.rentHint != null && post.rentHint!.isNotEmpty) {
      buffer.writeln('ভাড়া/খরচ: ${post.rentHint}');
    }
    if (post.messCode != null && post.messCode!.isNotEmpty) {
      buffer.writeln('মেস কোড: ${post.messCode}');
    }
    buffer.writeln('\n— ম্যাস ম্যানেজার কমিউনিটি');
    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final date = post.createdAt != null
        ? DateFormat('d MMM, h:mm a').format(post.createdAt!)
        : '';
    final postService = CommunityPostService();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PostDetailScreen(postId: post.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PublicProfileScreen(uid: post.authorId),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.featureGreenBg,
                      backgroundImage: post.authorPhotoUrl != null
                          ? NetworkImage(post.authorPhotoUrl!)
                          : null,
                      child: post.authorPhotoUrl == null
                          ? Text(
                              (post.authorName.isNotEmpty
                                      ? post.authorName[0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${post.messName}${date.isNotEmpty ? ' · $date' : ''}',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.featureGreenBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${post.seatsAvailable} সিট',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textDark,
                ),
              ),
              if (post.messLocation != null &&
                  post.messLocation!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '📍 ${post.messLocation}',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (uid != null)
                    StreamBuilder<bool>(
                      stream: postService.watchLiked(post.id, uid),
                      builder: (context, likeSnap) {
                        final liked = likeSnap.data == true;
                        return TextButton.icon(
                          onPressed: () => postService.toggleLike(post.id),
                          icon: Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: liked
                                ? AppColors.monthRed
                                : AppColors.textGrey,
                          ),
                          label: Text(
                            '${post.likeCount}',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Text(
                      '❤ ${post.likeCount}',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PostDetailScreen(postId: post.id),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: AppColors.textGrey,
                    ),
                    label: Text(
                      '${post.commentCount}',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _share,
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: AppColors.textGrey,
                    ),
                    label: Text(
                      'শেয়ার',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
