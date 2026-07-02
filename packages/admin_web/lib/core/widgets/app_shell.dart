import 'package:flutter/material.dart';

import '../theme/kiz_theme.dart';

/// Persistent admin navigation shell: a collapsible left rail + content area.
/// Expanded by default; the header button toggles collapsed (icons only).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const destinations = <({IconData icon, String label})>[
    (icon: Icons.dashboard_outlined, label: 'Overview'),
    (icon: Icons.campaign_outlined, label: 'Announcements'),
    (icon: Icons.report_problem_outlined, label: 'Complaints'),
    (icon: Icons.apartment_outlined, label: 'Accommodation'),
    (icon: Icons.event_available_outlined, label: 'Bookings'),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _extended = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: _extended,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: KizSpacing.sm),
              child: IconButton(
                tooltip: 'Toggle sidebar',
                color: KizColors.background,
                icon: Icon(_extended ? Icons.menu_open : Icons.menu),
                onPressed: () => setState(() => _extended = !_extended),
              ),
            ),
            destinations: [
              for (final d in AppShell.destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
