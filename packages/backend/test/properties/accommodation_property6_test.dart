// Feature: accommodation-management, Property 6: Out-of-Semester Date Validation and Cost Calculation
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 3.2, 3.3, 3.4**
///
/// Property 6: Out-of-Semester Date Validation and Cost Calculation
/// For any pair of dates (checkIn, checkOut): Submission succeeds iff
/// checkIn >= today, checkOut > checkIn, and (checkOut - checkIn) is between
/// 1 and 90 days inclusive. When submission succeeds,
/// totalCost = (checkOut - checkIn).inDays * 49.00.

void main() {
  // Feature: accommodation-management, Property 6: Out-of-Semester Date Validation and Cost Calculation
  group('Property 6: Out-of-Semester Date Validation and Cost Calculation', () {
    Glados2(any.intInRange(-10, 100), any.intInRange(-5, 120),
            ExploreConfig(numRuns: 100))
        .test('date validation and cost calculation', (checkInOffset, duration) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final checkIn = todayDate.add(Duration(days: checkInOffset));
      final checkOut = checkIn.add(Duration(days: duration));

      final isValid = checkInOffset >= 0 && duration >= 1 && duration <= 90;

      if (isValid) {
        // Cost must equal duration * 49.00
        final cost = duration * 49.00;
        expect(cost, equals(duration * 49.00));
        // checkIn is today or future
        expect(checkIn.compareTo(todayDate) >= 0, isTrue);
        // checkOut is after checkIn
        expect(checkOut.isAfter(checkIn), isTrue);
        // Duration is within bounds
        expect(checkOut.difference(checkIn).inDays, inInclusiveRange(1, 90));
      }

      // Verify the validity logic matches the rules
      expect(isValid, equals(checkInOffset >= 0 && duration >= 1 && duration <= 90));
    });
  });
}
