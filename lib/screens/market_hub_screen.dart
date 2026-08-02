import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/app_surface.dart';
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
    final s = AppStrings.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        AppSegmentedControl(
          labels: [s.marketList, s.bazaarDates],
          index: _view == MarketHubView.list ? 0 : 1,
          onChanged: (i) => setState(
            () => _view = i == 0 ? MarketHubView.list : MarketHubView.schedule,
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
