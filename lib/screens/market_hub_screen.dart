import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'bazaar_schedule_screen.dart';
import 'market_list_screen.dart';

enum MarketHubView { list, schedule }

class MarketHubScreen extends StatefulWidget {
  const MarketHubScreen({super.key});

  @override
  State<MarketHubScreen> createState() => _MarketHubScreenState();
}

class _MarketHubScreenState extends State<MarketHubScreen> {
  MarketHubView _view = MarketHubView.list;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _MarketHubToggle(
            view: _view,
            onChanged: (v) => setState(() => _view = v),
          ),
        ),
        Expanded(
          child: switch (_view) {
            MarketHubView.list => const MarketListScreen(),
            MarketHubView.schedule => const BazaarScheduleScreen(),
          },
        ),
      ],
    );
  }
}

class _MarketHubToggle extends StatelessWidget {
  const _MarketHubToggle({
    required this.view,
    required this.onChanged,
  });

  final MarketHubView view;
  final ValueChanged<MarketHubView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.featureGreenBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'বাজার লিস্ট',
              selected: view == MarketHubView.list,
              onTap: () => onChanged(MarketHubView.list),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'বাজার তারিখ',
              selected: view == MarketHubView.schedule,
              onTap: () => onChanged(MarketHubView.schedule),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansBengali(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.darkGreen,
          ),
        ),
      ),
    );
  }
}
