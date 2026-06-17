// Feature: admin-dashboard, Property 3: ModuleEntry validity predicate
// Validates: Requirements 3.1
//
// ponytail: glados ^1.1.1 conflicts with flutter_test's pinned test_api.
// Using randomized property loop (100 iterations) as equivalent.
// Upgrade path: when Flutter SDK unpins test_api, switch to glados.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_web/features/dashboard/data/module_entry.dart';

void main() {
  group('Property 3: ModuleEntry validity predicate', () {
    final random = Random(42); // fixed seed for reproducibility

    /// Generates a random string of [maxLength] with optional whitespace-only bias.
    String randomString(int maxLength, {double emptyChance = 0.1}) {
      if (random.nextDouble() < emptyChance) {
        // Return whitespace-only or empty string
        return ' ' * random.nextInt(4);
      }
      final length = random.nextInt(maxLength + 1);
      return String.fromCharCodes(
        List.generate(length, (_) => 0x20 + random.nextInt(95)),
      );
    }

    String randomRoute() {
      final r = random.nextDouble();
      if (r < 0.15) return ''; // empty
      if (r < 0.3) return '   '; // whitespace only
      if (r < 0.5) return '/${randomString(20, emptyChance: 0.0)}'; // valid prefix
      return randomString(30, emptyChance: 0.0); // might or might not start with /
    }

    test('isValid matches manual predicate for 100+ random (name, route) pairs', () {
      for (var i = 0; i < 150; i++) {
        final name = randomString(60);
        final route = randomRoute();

        final entry = ModuleEntry(
          name: name,
          icon: Icons.star,
          route: route,
        );

        final expected = name.trim().isNotEmpty &&
            name.length <= 50 &&
            route.trim().isNotEmpty &&
            route.startsWith('/');

        expect(
          entry.isValid,
          equals(expected),
          reason: 'Failed for name="$name" (len=${name.length}), route="$route" '
              'at iteration $i',
        );
      }
    });
  });
}
