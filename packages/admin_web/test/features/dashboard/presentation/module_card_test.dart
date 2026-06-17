// Feature: admin-dashboard, Property 2: Tap navigates to registered route
// Validates: Requirements 2.2
//
// ponytail: Using randomized property loop (100 iterations, fixed seed)
// since glados has dependency conflicts with flutter_test's pinned test_api.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_web/features/dashboard/data/module_entry.dart';
import 'package:admin_web/features/dashboard/presentation/module_card.dart';

void main() {
  group('Property 2: Tap navigates to registered route', () {
    final random = Random(42);

    /// Generates a random valid name (1–50 chars, non-whitespace-only).
    String randomValidName() {
      final length = 1 + random.nextInt(50);
      // Ensure at least one non-space character
      final chars = List.generate(length, (_) => 0x21 + random.nextInt(94));
      return String.fromCharCodes(chars);
    }

    /// Generates a random valid route starting with '/'.
    String randomValidRoute() {
      final segmentLength = 1 + random.nextInt(20);
      final segment = String.fromCharCodes(
        List.generate(segmentLength, (_) {
          // alphanumeric + hyphen for route segments
          const chars = 'abcdefghijklmnopqrstuvwxyz0123456789-';
          return chars.codeUnitAt(random.nextInt(chars.length));
        }),
      );
      return '/$segment';
    }

    testWidgets(
      'tapping ModuleCard navigates to entry.route for 100+ random entries',
      (tester) async {
        for (var i = 0; i < 100; i++) {
          final route = randomValidRoute();
          final entry = ModuleEntry(
            name: randomValidName(),
            icon: Icons.star,
            route: route,
          );

          String? navigatedTo;

          final router = GoRouter(
            initialLocation: '/test-home',
            routes: [
              GoRoute(
                path: '/test-home',
                builder: (context, state) => Scaffold(
                  body: ModuleCard(entry: entry),
                ),
              ),
              GoRoute(
                path: route,
                builder: (context, state) {
                  navigatedTo = route;
                  return const Scaffold(body: Text('target'));
                },
              ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp.router(routerConfig: router),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byType(InkWell));
          await tester.pumpAndSettle();

          expect(
            navigatedTo,
            equals(route),
            reason: 'Iteration $i: expected navigation to "$route"',
          );
        }
      },
    );
  });
}
