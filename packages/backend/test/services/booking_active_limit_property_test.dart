// Feature: booking-services, Property 6: Active booking limit per student per facility
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 8.4**
///
/// Property 6: Active booking limit per student per facility
/// For any student and facility, the system SHALL permit at most one booking
/// with status 'pending' or 'confirmed' at any time. A student MAY hold active
/// bookings for different facilities concurrently. Once a booking transitions to
/// a terminal status, the student SHALL be permitted to submit a new booking.

const _activeStatuses = {'pending', 'confirmed'};
const _terminalStatuses = {'cancelled', 'completed', 'no_show', 'rejected'};
const _allStatuses = [
  'pending',
  'confirmed',
  'cancelled',
  'completed',
  'no_show',
  'rejected',
];

/// Pure decision: can a student submit a new booking for a facility given
/// the statuses of their existing bookings for that same facility?
bool canSubmitBooking({required List<String> existingBookingStatuses}) {
  return !existingBookingStatuses.any((s) => _activeStatuses.contains(s));
}

void main() {
  // Generator: a list of 0-5 booking statuses for a single facility.
  final statusListGen = any.simple<List<String>>(
    generate: (random, size) {
      final length = random.nextInt(6); // 0..5
      return List.generate(length, (_) => _allStatuses[random.nextInt(6)]);
    },
    shrink: (input) => [if (input.isNotEmpty) input.sublist(1)],
  );

  group('Property 6: Active booking limit per student per facility', () {
    // 6a: If any existing booking is active → reject (ACTIVE_BOOKING_EXISTS).
    Glados(statusListGen, ExploreConfig(numRuns: 200)).test(
      'rejects submission when an active booking exists',
      (statuses) {
        final hasActive = statuses.any((s) => _activeStatuses.contains(s));
        if (hasActive) {
          expect(canSubmitBooking(existingBookingStatuses: statuses), isFalse,
              reason: 'statuses=$statuses should reject (ACTIVE_BOOKING_EXISTS)');
        }
      },
    );

    // 6b: If all existing bookings are terminal → allow submission.
    Glados(statusListGen, ExploreConfig(numRuns: 200)).test(
      'allows submission when all bookings are terminal',
      (statuses) {
        final allTerminal =
            statuses.every((s) => _terminalStatuses.contains(s));
        if (allTerminal) {
          expect(canSubmitBooking(existingBookingStatuses: statuses), isTrue,
              reason: 'statuses=$statuses should allow submission');
        }
      },
    );

    // 6c: Different facilities are independent — model with two separate lists.
    Glados2(statusListGen, statusListGen, ExploreConfig(numRuns: 200)).test(
      'facilities are evaluated independently',
      (facilityAStatuses, facilityBStatuses) {
        final canBookA =
            canSubmitBooking(existingBookingStatuses: facilityAStatuses);
        final canBookB =
            canSubmitBooking(existingBookingStatuses: facilityBStatuses);

        // Each facility's decision depends only on its own statuses.
        final expectA =
            !facilityAStatuses.any((s) => _activeStatuses.contains(s));
        final expectB =
            !facilityBStatuses.any((s) => _activeStatuses.contains(s));

        expect(canBookA, equals(expectA));
        expect(canBookB, equals(expectB));
      },
    );
  });
}
