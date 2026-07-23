import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings.dart';
import '../../models/community_post.dart';
import '../../services/community_post_service.dart';
import '../../theme/app_colors.dart';
import 'public_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _service = CommunityPostService();
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _share(CommunityPost post) async {
    final s = AppStrings.of(context);
    final buffer = StringBuffer()
      ..writeln(s.seatsVacantShare(post.messName, post.seatsAvailable))
      ..writeln(post.body);
    if (post.messCode != null) {
      buffer.writeln(s.messCodeLine(post.messCode!));
    }
    buffer.writeln('\n${s.communityShareFooter}');
    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Future<void> _sendComment() async {
    setState(() => _sending = true);
    try {
      await _service.addComment(widget.postId, _commentController.text);
      _commentController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e', style: appFont(context: context))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          s.post,
          style: appFont(context: context, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: StreamBuilder<CommunityPost?>(
        stream: _service.watchPost(widget.postId),
        builder: (context, postSnap) {
          final post = postSnap.data;
          if (postSnap.connectionState == ConnectionState.waiting &&
              post == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (post == null) {
            return Center(
              child: Text(
                s.postNotFound,
                style: appFont(context: context),
              ),
            );
          }

          final date = post.createdAt != null
              ? DateFormat('d MMM y, h:mm a').format(post.createdAt!)
              : '';

          final meta = StringBuffer(s.seatsLabel(post.seatsAvailable));
          if (post.rentHint != null && post.rentHint!.isNotEmpty) {
            meta.write(' · ${post.rentHint}');
          }
          if (post.messLocation != null) {
            meta.write('\n${post.messLocation}');
          }
          if (post.messCode != null) {
            meta.write('\n${s.messCodeLine(post.messCode!)}');
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
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
                                      builder: (_) => PublicProfileScreen(
                                        uid: post.authorId,
                                      ),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundImage: post.authorPhotoUrl != null
                                      ? NetworkImage(post.authorPhotoUrl!)
                                      : null,
                                  child: post.authorPhotoUrl == null
                                      ? Text(post.authorName.isNotEmpty
                                          ? post.authorName[0]
                                          : '?')
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
                                      style: appFont(
                                        context: context,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${post.messName} · $date',
                                      style: appFont(
                                        context: context,
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (uid == post.authorId && post.active)
                                TextButton(
                                  onPressed: () async {
                                    await _service.closePost(post.id);
                                  },
                                  child: Text(
                                    s.close,
                                    style: appFont(
                                      context: context,
                                      fontSize: 12,
                                      color: AppColors.monthRed,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.body,
                            style: appFont(
                              context: context,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meta.toString(),
                            style: appFont(
                              context: context,
                              fontSize: 12,
                              color: AppColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (uid != null)
                                StreamBuilder<bool>(
                                  stream: _service.watchLiked(post.id, uid),
                                  builder: (context, likeSnap) {
                                    final liked = likeSnap.data == true;
                                    return IconButton(
                                      onPressed: () =>
                                          _service.toggleLike(post.id),
                                      icon: Icon(
                                        liked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: liked
                                            ? AppColors.monthRed
                                            : AppColors.textGrey,
                                      ),
                                    );
                                  },
                                ),
                              Text(
                                s.likesAndComments(
                                  post.likeCount,
                                  post.commentCount,
                                ),
                                style: appFont(
                                  context: context,
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => _share(post),
                                icon: const Icon(Icons.share_outlined),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.comments,
                      style: appFont(
                        context: context,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<PostComment>>(
                      stream: _service.watchComments(widget.postId),
                      builder: (context, snap) {
                        final comments = snap.data ?? [];
                        if (comments.isEmpty) {
                          return Text(
                            s.noCommentsYet,
                            style: appFont(
                              context: context,
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                          );
                        }
                        return Column(
                          children: comments
                              .map(
                                (c) {
                                  final timeLabel = c.createdAt != null
                                      ? DateFormat('d MMM, h:mm a')
                                          .format(c.createdAt!)
                                      : '';
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundImage: c.authorPhotoUrl != null
                                          ? NetworkImage(c.authorPhotoUrl!)
                                          : null,
                                      child: c.authorPhotoUrl == null
                                          ? Text(
                                              c.authorName.isNotEmpty
                                                  ? c.authorName[0]
                                                  : '?',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            )
                                          : null,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c.authorName,
                                            style: appFont(
                                              context: context,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (timeLabel.isNotEmpty)
                                          Text(
                                            timeLabel,
                                            style: appFont(
                                              context: context,
                                              fontSize: 11,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      c.text,
                                      style: appFont(
                                        context: context,
                                        fontSize: 13,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => PublicProfileScreen(
                                            uid: c.authorId,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: appFont(context: context),
                          decoration: InputDecoration(
                            hintText: s.writeCommentHint,
                            hintStyle: appFont(
                              context: context,
                              color: AppColors.textGrey,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _sendComment,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
