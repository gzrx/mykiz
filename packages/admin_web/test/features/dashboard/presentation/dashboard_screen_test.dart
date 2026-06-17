// Feature: admin-dashboard, Property 4: Route uniqueness enforcement
// **Validates: Requirements 3.3**

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_web/features/dashboard/data/module_entry.dart';
import 'package:admin_web/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  group('Property 4: Route uniqueness enforcement', () {
    final random = Random(42); // fixed seed for reproducibility

    /// Generates a random valid route (starts with '/', non-empty after trim).
    String randomValidRoute() {
      final segment = String.fromCharCodes(
        List.generate(
          1 + random.nextInt(10),
          (_) => 0x61 + random.nextInt(26), // a-z
        ),
      );
      return '/$segment';
    }

    /// Builds a random list of ModuleEntry with intentional duplicate routes.
    List<ModuleEntry> randomEntriesWithDuplicates() {
      // Pick a small pool of routes so duplicates are likely
      final routePool = List.generate(3 + random.nextInt(3), (_) => randomValidRoute());
      final count = 2 + random.nextInt(10);
      return List.generate(count, (i) {
        return ModuleEntry(
          name: 'Module $i',
          icon: Icons.star,
          route: routePool[random.nextInt(routePool.length)],
        );
      });
    }

    test('filterEntries produces no duplicate routes for 150 random lists', () {
      for (var i = 0; i < 150; i++) {
        final entries = randomEntriesWithDuplicates();
        final filtered = DashboardScreen.filterEntries(entries);
        final routes = filtered.map((e) => e.route).toList();

        expect(
          routes.toSet().length,
          equals(routes.length),
          reason: 'Duplicate route found at iteration $i. '
              'Input routes: ${entries.map((e) => e.route).toList()}, '
              'Output routes: $routes',
        );
      }
    });
  });
}
