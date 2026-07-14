import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import 'chat_inbox_tab.dart';
import 'community_feed_tab.dart';
import 'friends_tab.dart';

/// Community hub: feed / friends / chat.
/// Used as Home tab and from MessSetup for users without a mess.
class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({
    super.key,
    this.embedded = false,
  });

  /// When true, no Scaffold — used inside HomeScreen body.
  final bool embedded;

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Text(
                  'কমিউনিটি',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'কমিউনিটি',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          ),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primaryGreen,
          labelStyle: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'ফিড'),
            Tab(text: 'ফ্রেন্ডস'),
            Tab(text: 'চ্যাট'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CommunityFeedTab(),
              FriendsTab(),
              ChatInboxTab(),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Material(
        color: AppColors.pageBackground,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(child: body),
    );
  }
}
