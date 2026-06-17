import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/dashboard/application/dashboard_utils.dart';

/// Property-based tests for dashboard pure functions.
/// Uses randomized inputs (100+ iterations) to verify universal properties.
///
/// ponytail: glados is incompatible with riverpod_generator (analyzer version conflict).
/// Using manual randomized property tests — same guarantees, zero extra deps.
/// Upgrade path: switch to glados when analyzer constraints align.

// -- Generators --

String _randomChars(Random rng, int len, String alphabet) {
  return List.generate(len, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
}

String _randomStringWithSpaces(Random rng, int len) {
  const alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ';
  return _randomChars(rng, len, alphabet);
}

String? _randomNullableString(Random rng) {
  final kind = rng.nextInt(5);
  switch (kind) {
    case 0:
      return null;
    case 1:
      return '';
    case 2:
      return ' ' * (1 + rng.nextInt(5));
    default:
      return _randomStringWithSpaces(rng, 1 + rng.nextInt(50));
  }
}

double _randomWidth(Random rng) => 100.0 + rng.nextDouble() * 1900.0;

void main() {
  final random = Random(42); // deterministic seed for reproducibility

  // -- Property 2: Greeting format correctness --
  // **Validates: Requirements 2.1, 2.2**
  group('Property 2: Greeting format correctness', () {
    test('null or whitespace-only input returns "Hi, Student"', () {
      expect(formatGreeting(null), 'Hi, Student');

      for (var i = 0; i < 100; i++) {
        final blank = ' ' * random.nextInt(10);
        expect(
          formatGreeting(blank),
          'Hi, Student',
          reason: 'Blank input (len=${blank.length}) should produce fallback',
        );
      }
    });

    test('non-blank input returns "Hi, [firstToken]" with 20-char truncation',
        () {
      for (var i = 0; i < 200; i++) {
        final name =
            _randomStringWithSpaces(random, 1 + random.nextInt(60));
        if (name.trim().isEmpty) continue;

        final result = formatGreeting(name);
        final expectedFirstName = name.split(' ').first;

        if (expectedFirstName.length > 20) {
          expect(
            result,
            'Hi, ${expectedFirstName.substring(0, 20)}\u2026',
            reason:
                'firstName "$expectedFirstName" (len=${expectedFirstName.length}) should be truncated',
          );
        } else {
          expect(
            result,
            'Hi, $expectedFirstName',
            reason:
                'firstName "$expectedFirstName" should appear in full',
          );
        }
      }
    });

    test('greeting always starts with "Hi, "', () {
      for (var i = 0; i < 100; i++) {
        final input = _randomNullableString(random);
        final result = formatGreeting(input);
        expect(result.startsWith('Hi, '), isTrue,
            reason: 'formatGreeting($input) = "$result" must start with "Hi, "');
      }
    });

    test('displayed name portion never exceeds 20 characters (+ ellipsis)',
        () {
      for (var i = 0; i < 100; i++) {
        final input = _randomNullableString(random);
        final result = formatGreeting(input);
        final nameDisplay = result.substring(4); // strip "Hi, "
        if (nameDisplay.endsWith('\u2026')) {
          // 20 chars + ellipsis character
          expect(nameDisplay.length, 21,
              reason: 'Truncated display must be 20 chars + ellipsis');
        } else {
          expect(nameDisplay.length, lessThanOrEqualTo(20),
              reason: 'Non-truncated display must be <= 20 chars');
        }
      }
    });
  });

  // -- Property 3: Column count from screen width --
  // **Validates: Requirements 3.2, 3.3, 3.4**
  group('Property 3: Column count from screen width', () {
    test('width < 360 always returns 2', () {
      for (var i = 0; i < 100; i++) {
        final width = random.nextDouble() * 359.99 + 0.01;
        expect(computeColumnCount(width), 2,
            reason: 'Width $width < 360 should give 2 columns');
      }
    });

    test('360 <= width < 600 always returns 3', () {
      for (var i = 0; i < 100; i++) {
        final width = 360.0 + random.nextDouble() * 239.99;
        expect(computeColumnCount(width), 3,
            reason: 'Width $width in [360,600) should give 3 columns');
      }
    });

    test('width >= 600 returns max(4, floor(width/120))', () {
      for (var i = 0; i < 100; i++) {
        final width = 600.0 + random.nextDouble() * 1400.0;
        final expected = max(4, (width / 120).floor());
        expect(computeColumnCount(width), expected,
            reason: 'Width $width >= 600 should give $expected columns');
      }
    });

    test('column count is always >= 2 for any positive width', () {
      for (var i = 0; i < 100; i++) {
        final width = _randomWidth(random);
        expect(computeColumnCount(width), greaterThanOrEqualTo(2),
            reason: 'Width $width must produce at least 2 columns');
      }
    });

    test('column count is monotonically non-decreasing', () {
      final widths = List.generate(100, (_) => _randomWidth(random))..sort();
      int prevCols = 0;
      for (final width in widths) {
        final cols = computeColumnCount(width);
        expect(cols, greaterThanOrEqualTo(prevCols),
            reason:
                'Columns must not decrease as width grows (width=$width)');
        prevCols = cols;
      }
    });
  });
}
