import 'package:flutter/material.dart';

import '../data/module_entry.dart';
import '../data/module_registry.dart';
import 'module_card.dart';

/// Dashboard landing page displaying a responsive grid of module cards.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Filters registry to valid, route-unique entries (first wins).
  static List<ModuleEntry> filterEntries(List<ModuleEntry> entries) {
    final seen = <String>{};
    return [
      for (final e in entries)
        if (e.isValid && seen.add(e.route)) e,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final entries = filterEntries(moduleRegistry);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _columnCount(constraints.maxWidth);
          return GridView.count(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            padding: const EdgeInsets.all(16),
            children: [for (final e in entries) ModuleCard(entry: e)],
          );
        },
      ),
    );
  }

  /// Breakpoints: ≤640→1, ≤1024→2, ≥1025→3.
  static int _columnCount(double width) {
    if (width <= 640) return 1;
    if (width <= 1024) return 2;
    return 3;
  }
}
