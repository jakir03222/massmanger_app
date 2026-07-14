import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/social.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';
import 'public_profile_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    required this.otherUid,
    required this.otherName,
    this.otherPhotoUrl,
  });

  final String conversationId;
  final String otherUid;
  final String otherName;
  final String? otherPhotoUrl;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _service = ChatService();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await _service.sendMessage(
        conversationId: widget.conversationId,
        text: _controller.text,
      );
      _controller.clear();
      if (_scrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e', style: GoogleFonts.notoSansBengali())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PublicProfileScreen(uid: widget.otherUid),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.otherPhotoUrl != null
                    ? NetworkImage(widget.otherPhotoUrl!)
                    : null,
                child: widget.otherPhotoUrl == null
                    ? Text(
                        widget.otherName.isNotEmpty ? widget.otherName[0] : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.otherName,
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _service.watchMessages(widget.conversationId),
              builder: (context, snap) {
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'মেসেজ শুরু করুন',
                      style: GoogleFonts.notoSansBengali(
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final mine = m.senderId == me;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? AppColors.primaryGreen
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: mine
                              ? null
                              : Border.all(color: AppColors.borderGrey),
                        ),
                        child: Text(
                          m.text,
                          style: GoogleFonts.notoSansBengali(
                            color: mine ? Colors.white : AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.notoSansBengali(),
                      decoration: InputDecoration(
                        hintText: 'মেসেজ লিখুন…',
                        hintStyle: GoogleFonts.notoSansBengali(
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
                      onSubmitted: (_) => _sending ? null : _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
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
      ),
    );
  }
}
