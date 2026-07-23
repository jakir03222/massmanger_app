import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_session_builder.dart';
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
        final matched = members.where((m) => m.uid == appUser.uid);
        final isAdmin = matched.isNotEmpty && matched.first.isAdmin;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? AppColors.featureGreenBg
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAdmin ? s.adminReportMode : s.memberReportMode,
                  textAlign: TextAlign.center,
                  style: appFont(
                    context: context,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAdmin
                        ? AppColors.darkGreen
                        : const Color(0xFFF9A825),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _ReportViewToggle(
                view: _view,
                onChanged: (v) => setState(() => _view = v),
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

class _ReportViewToggle extends StatelessWidget {
  const _ReportViewToggle({
    required this.view,
    required this.onChanged,
  });

  final ReportView view;
  final ValueChanged<ReportView> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: s.monthly,
              selected: view == ReportView.monthly,
              onTap: () => onChanged(ReportView.monthly),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: s.daily,
              selected: view == ReportView.daily,
              onTap: () => onChanged(ReportView.daily),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: appFont(
            context: context,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}
