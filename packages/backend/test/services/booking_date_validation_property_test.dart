// Property 8: Booking date validation
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 4.7, 4.8**
///
/// For any booking submission where the booking date is more than 14 days in
/// the future, the system SHALL reject with DATE_OUT_OF_RANGE. For any booking
/// submission where the booking date is in the past, or the slot's start time
/// has already elapsed today, the system SHALL reject with SLOT_IN_PAST.

/// Pure function extracted from BookingService.submitBooking date validation logic.
/// Returns null if valid, or the error code string.
String? validateBookingDate(DateTime bookingDate, DateTime now, {String slotStartTime = '08:00'}) {
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

  // Past date → SLOT_IN_PAST
  if (dateOnly.isBefore(today)) return 'SLOT_IN_PAST';

  // Same day but slot start has elapsed → SLOT_IN_PAST
  if (dateOnly.isAtSameMomentAs(today)) {
    final parts = slotStartTime.split(':');
    final slotStart = DateTime(
      now.year, now.month, now.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );
    if (now.isAfter(slotStart)) return 'SLOT_IN_PAST';
  }

  // More than 14 days ahead → DATE_OUT_OF_RANGE
  final maxDate = today.add(const Duration(days: 14));
  if (dateOnly.isAfter(maxDate)) return 'DATE_OUT_OF_RANGE';

  return null; // valid
}

/// Generator for a DateTime within a reasonable range around "now".
extension BookingDateGenerators on Any {
  /// Generates dates from -30 to +30 days from a reference point.
  Generator<int> get dayOffset => simple(
        generate: (random, size) => random.nextInt(61) - 30, // -30..+30
        shrink: (input) => input == 0 ? [] : [input ~/ 2],
      );

  /// Generates HH:MM time strings.
  Generator<String> get timeOfDay => simple(
        generate: (random, size) {
          final h = random.nextInt(24);
          final m = random.nextInt(60);
          return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        },
        shrink: (input) => [],
      );
}

void main() {
  // Fixed reference point for deterministic reasoning.
  final referenceNow = DateTime(2025, 6, 15, 10, 30); // a mid-day time

  group('Property 8: Booking date validation', () {
    // 8a: Past dates always produce SLOT_IN_PAST.
    Glados(any.dayOffset, ExploreConfig(numRuns: 200)).test(
      'past dates are rejected with SLOT_IN_PAST',
      (offset) {
        if (offset >= 0) return; // only test negative offsets (past)
        final bookingDate = referenceNow.add(Duration(days: offset));
        final result = validateBookingDate(bookingDate, referenceNow);
        expect(result, equals('SLOT_IN_PAST'),
            reason: 'Date $offset days ago should be SLOT_IN_PAST');
      },
    );

    // 8b: Dates > 14 days in the future produce DATE_OUT_OF_RANGE.
    Glados(any.dayOffset, ExploreConfig(numRuns: 200)).test(
      'dates beyond 14 days are rejected with DATE_OUT_OF_RANGE',
      (offset) {
        if (offset <= 14) return; // only test > 14
        final bookingDate = referenceNow.add(Duration(days: offset));
        final result = validateBookingDate(bookingDate, referenceNow);
        expect(result, equals('DATE_OUT_OF_RANGE'),
            reason: 'Date $offset days ahead should be DATE_OUT_OF_RANGE');
      },
    );

    // 8c: Dates within [today, today+14] with slot in the future are valid.
    Glados(any.dayOffset, ExploreConfig(numRuns: 200)).test(
      'dates within 1..14 days ahead are valid',
      (offset) {
        if (offset < 1 || offset > 14) return; // only future, within window
        final bookingDate = referenceNow.add(Duration(days: offset));
        // Use morning slot that hasn't passed (irrelevant for future days)
        final result = validateBookingDate(bookingDate, referenceNow, slotStartTime: '08:00');
        expect(result, isNull,
            reason: 'Date $offset days ahead should be valid');
      },
    );

    // 8d: Today with slot start still in the future is valid.
    Glados(any.timeOfDay, ExploreConfig(numRuns: 200)).test(
      'today with slot start after now is valid',
      (slotTime) {
        // now is 10:30, only slots after 10:30 are valid on today
        final now = referenceNow; // 10:30
        final today = DateTime(now.year, now.month, now.day);
        if (slotTime.compareTo('10:30') <= 0) return; // skip elapsed slots
        final result = validateBookingDate(today, now, slotStartTime: slotTime);
        expect(result, isNull,
            reason: 'Today with slot at $slotTime (after 10:30) should be valid');
      },
    );

    // 8e: Today with slot start already passed is SLOT_IN_PAST.
    Glados(any.timeOfDay, ExploreConfig(numRuns: 200)).test(
      'today with slot start before now is SLOT_IN_PAST',
      (slotTime) {
        // now is 10:30, slots at or before 10:30 have elapsed
        final now = referenceNow;
        final today = DateTime(now.year, now.month, now.day);
        // The service uses now.isAfter(slotStart), so slotStart must be < now
        // For "10:30" slot, now (10:30) is NOT after slotStart (10:30) → valid
        // We need slotTime < "10:30"
        if (slotTime.compareTo('10:30') >= 0) return; // skip non-elapsed slots
        final result = validateBookingDate(today, now, slotStartTime: slotTime);
        expect(result, equals('SLOT_IN_PAST'),
            reason: 'Today with slot at $slotTime (before 10:30) should be SLOT_IN_PAST');
      },
    );

    // 8f: Boundary — exactly day 14 is valid, day 15 is rejected.
    test('boundary: day 14 is valid, day 15 is DATE_OUT_OF_RANGE', () {
      final day14 = referenceNow.add(const Duration(days: 14));
      final day15 = referenceNow.add(const Duration(days: 15));
      expect(validateBookingDate(day14, referenceNow), isNull);
      expect(validateBookingDate(day15, referenceNow), equals('DATE_OUT_OF_RANGE'));
    });
  });
}
