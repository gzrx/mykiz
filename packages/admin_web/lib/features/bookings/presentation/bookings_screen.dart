import 'package:flutter/material.dart';

import 'bookings_tab.dart';
import 'facilities_tab.dart';
import 'reports_tab.dart';

/// Shell screen for the Bookings module with tabbed navigation.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bookings'),
              Tab(text: 'Facilities'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookingsTab(),
            FacilitiesTab(),
            ReportsTab(),
          ],
        ),
      ),
    );
  }
}
