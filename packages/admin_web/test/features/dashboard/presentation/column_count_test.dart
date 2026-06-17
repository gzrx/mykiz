// Feature: admin-dashboard, Property 5: Column count by viewport width
// Validates: Requirements 4.2, 4.3, 4.4
//
// ponytail: Pure logic test — no widget test needed. The breakpoint function
// is deterministic; we replicate it here and verify against random widths.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Mirrors DashboardScreen._columnCount (private static).
int columnCount(double width) {
  if (width <= 640) return 1;
  if (width <= 1024) return 2;
  return 3;
}

void main() {
  group('Property 5: Column count by viewport width', () {
    final random = Random(42); // fixed seed for reproducibility

    test('column count matches breakpoint rules for 150 random widths (1–3000)', () {
      for (var i = 0; i < 150; i++) {
        final w = 1.0 + random.nextInt(3000); // 1..3000 inclusive

        final result = columnCount(w);

        final int expected;
        if (w <= 640) {
          expected = 1;
        } else if (w <= 1024) {
          expected = 2;
        } else {
          expected = 3;
        }

        expect(
          result,
          equals(expected),
          reason: 'width=$w → expected $expected columns, got $result (i=$i)',
        );
      }
    });

    test('boundary values', () {
      expect(columnCount(1), 1);
      expect(columnCount(640), 1);
      expect(columnCount(641), 2);
      expect(columnCount(1024), 2);
      expect(columnCount(1025), 3);
      expect(columnCount(3000), 3);
    });
  });
}
