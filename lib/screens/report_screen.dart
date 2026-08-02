import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../utils/mess_member_lookup.dart';
import '../widgets/app_surface.dart';
import '../widgets/mess_session_builder.dart';
import 'analytics_trends_screen.dart';
import 'daily_report_screen.dart';
import 'monthly_report_screen.dart';

enum ReportView { monthly, daily }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportView _view = ReportView.monthly;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return MessSessionBuilder(
      builder: (context, appUser, mess, members) {
        final isAdmin = members.isAdminUid(appUser.uid);

        return Column(
          children: [
            const SizedBox(height: 8),
            AppSoftBanner(
              text: isAdmin ? s.adminReportMode : s.memberReportMode,
              tone: isAdmin ? AppBannerTone.info : AppBannerTone.warning,
              icon: isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline_rounded,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AnalyticsTrendsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.trending_up_rounded, size: 18),
                  label: Text(s.analyticsTrends),
                ),
              ),
            ),
            AppSegmentedControl(
              labels: [s.monthly, s.daily],
              index: _view == ReportView.monthly ? 0 : 1,
              onChanged: (i) => setState(
                () => _view = i == 0 ? ReportView.monthly : ReportView.daily,
              ),
            ),
            Expanded(
              child: switch (_view) {
                ReportView.monthly => const MonthlyReportScreen(),
                ReportView.daily => const DailyReportScreen(),
              },
            ),
          ],
        );
      },
    );
  }
}
