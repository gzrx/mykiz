import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/dashboard/application/dashboard_providers.dart';

/// Property-based tests for badge provider logic.
/// Uses randomized inputs (100+ iterations) to verify universal properties.
///
/// ponytail: glados is incompatible with riverpod_generator (analyzer version conflict).
/// Using manual randomized property tests — same guarantees, zero extra deps.
/// Upgrade path: switch to glados when analyzer constraints align.

// -- Generators --

const _statuses = ['submitted', 'in_progress', 'resolved'];

String _randomStatus(Random rng) => _statuses[rng.nextInt(_statuses.length)];

List<String> _randomNonEmptyStatusList(Random rng) {
  final length = 1 + rng.nextInt(20);
  return List.generate(length, (_) => _randomStatus(rng));
}

void main() {
  final random = Random(42); // deterministic seed for reproducibility

  // -- Property 5: Badge text formatting --
  // **Validates: Requirements 5.1, 5.2**
  group('Property 5: Badge text formatting', () {
    test('count == 0 returns null (no badge)', () {
      expect(formatBadgeCount(0), isNull);
    });

    test('negative counts return null', () {
      for (var i = 0; i < 100; i++) {
        final count = -(1 + random.nextInt(1000));
        expect(formatBadgeCount(count), isNull,
            reason: 'Negative count $count should return null');
      }
    });

    test('1 <= count <= 99 returns count.toString()', () {
      for (var i = 0; i < 100; i++) {
        final count = 1 + random.nextInt(99);
        expect(formatBadgeCount(count), '$count',
            reason: 'Count $count in [1,99] should return "$count"');
      }
    });

    test('count > 99 always returns "99+"', () {
      for (var i = 0; i < 100; i++) {
        final count = 100 + random.nextInt(10000);
        expect(formatBadgeCount(count), '99+',
            reason: 'Count $count > 99 should return "99+"');
      }
    });

    test('result is either null or a non-empty string for any non-negative int',
        () {
      for (var i = 0; i < 200; i++) {
        final count = random.nextInt(500);
        final result = formatBadgeCount(count);
        if (count == 0) {
          expect(result, isNull, reason: 'Zero should be null');
        } else {
          expect(result, isNotNull, reason: 'Positive count must produce text');
          expect(result!.isNotEmpty, isTrue,
              reason: 'Badge text must be non-empty');
        }
      }
    });

    test('boundary: count == 99 returns "99", count == 100 returns "99+"', () {
      expect(formatBadgeCount(99), '99');
      expect(formatBadgeCount(100), '99+');
    });
  });

  // -- Property 6: Most recent complaint status selection --
  // **Validates: Requirements 5.3**
  group('Property 6: Most recent complaint status selection', () {
    test('empty list returns null', () {
      expect(mostRecentComplaintStatus([]), isNull);
    });

    test('non-empty list returns the first element (most recent)', () {
      for (var i = 0; i < 100; i++) {
        final statuses = _randomNonEmptyStatusList(random);
        final result = mostRecentComplaintStatus(statuses);
        expect(result, statuses.first,
            reason:
                'Should return first status "${statuses.first}" from list of ${statuses.length}');
      }
    });

    test('single-element list returns that element', () {
      for (var i = 0; i < 100; i++) {
        final status = _randomStatus(random);
        expect(mostRecentComplaintStatus([status]), status,
            reason: 'Single-element list [$status] should return "$status"');
      }
    });

    test('result is always a valid status string from the input list', () {
      for (var i = 0; i < 100; i++) {
        final statuses = _randomNonEmptyStatusList(random);
        final result = mostRecentComplaintStatus(statuses);
        expect(statuses.contains(result), isTrue,
            reason: 'Result "$result" must be in the input list');
      }
    });
  });
}
