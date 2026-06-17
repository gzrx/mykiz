import 'package:flutter/material.dart';

import 'accommodation_settings_tab.dart';
import 'applications_tab.dart';
import 'check_in_out_tab.dart';
import 'occupancy_tab.dart';

/// Shell screen for the Accommodation module with tabbed navigation.
class AccommodationShell extends StatelessWidget {
  const AccommodationShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accommodation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Settings'),
              Tab(text: 'Applications'),
              Tab(text: 'Check-In/Out'),
              Tab(text: 'Occupancy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AccommodationSettingsTab(),
            ApplicationsTab(),
            CheckInOutTab(),
            OccupancyTab(),
          ],
        ),
      ),
    );
  }
}
