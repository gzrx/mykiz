import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/dashboard/application/dashboard_utils.dart';

void main() {
  group('computeColumnCount', () {
    test('returns 2 for width < 360', () {
      expect(computeColumnCount(100), 2);
      expect(computeColumnCount(359.9), 2);
    });

    test('returns 3 for 360 <= width < 600', () {
      expect(computeColumnCount(360), 3);
      expect(computeColumnCount(599.9), 3);
    });

    test('returns max(4, floor(width/120)) for width >= 600', () {
      expect(computeColumnCount(600), 5); // floor(600/120) = 5
      expect(computeColumnCount(480), 3); // still in 360-600 range
      expect(computeColumnCount(720), 6);
      expect(computeColumnCount(1200), 10);
    });
  });

  group('formatGreeting', () {
    test('returns fallback for null or blank', () {
      expect(formatGreeting(null), 'Hi, Student');
      expect(formatGreeting(''), 'Hi, Student');
      expect(formatGreeting('   '), 'Hi, Student');
    });

    test('returns first name for normal input', () {
      expect(formatGreeting('Alice'), 'Hi, Alice');
      expect(formatGreeting('Alice Johnson'), 'Hi, Alice');
    });

    test('truncates first name at 20 chars with ellipsis', () {
      // 21 chars first name
      expect(formatGreeting('Abcdefghijklmnopqrstu'), 'Hi, Abcdefghijklmnopqrst…');
      // exactly 20 chars - no truncation
      expect(formatGreeting('Abcdefghijklmnopqrst'), 'Hi, Abcdefghijklmnopqrst');
    });
  });
}
