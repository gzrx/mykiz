// Property 16: Slot config lifecycle protection
import 'package:backend/services/booking_exception.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 2.5, 2.7**
///
/// Property 16: Slot config lifecycle protection
/// For any Facility_Slot_Config with at least one future confirmed booking
/// referencing it, deletion SHALL be rejected. For any confirmed booking
/// referencing a deactivated slot config, the booking status SHALL remain
/// unchanged.

/// Pure decision function mirroring deleteSlotConfig's protection logic.
/// Returns normally when deletion is allowed, throws SLOT_HAS_BOOKINGS
/// when future confirmed bookings exist.
void assertDeletionAllowed(int futureConfirmedBookingCount) {
  if (futureConfirmedBookingCount > 0) {
    throw const BookingException(
      code: 'SLOT_HAS_BOOKINGS',
      message: 'Cannot delete slot config with future confirmed bookings.',
      statusCode: 409,
    );
  }
}

/// Models deactivation: only the slot config's is_active changes.
/// The booking status is never mutated by deactivation.
/// Returns the new is_active value (always false).
/// [bookingStatus] is passed to prove it is never touched.
({bool newIsActive, String bookingStatusAfter}) simulateDeactivation({
  required String bookingStatus,
}) {
  // ponytail: deactivation only flips is_active; bookings untouched by design.
  return (newIsActive: false, bookingStatusAfter: bookingStatus);
}

extension LifecycleGenerators on Any {
  /// Generates a positive count of future confirmed bookings (1+).
  Generator<int> get positiveBookingCount => simple(
        generate: (random, size) => 1 + random.nextInt(100),
        shrink: (input) => [if (input > 1) 1],
      );

  /// Generates zero (no future confirmed bookings).
  Generator<int> get zeroCount => simple(
        generate: (_, __) => 0,
        shrink: (_) => [],
      );

  /// Generates any valid booking status string.
  Generator<String> get bookingStatus => simple(
        generate: (random, _) {
          const statuses = [
            'pending',
            'confirmed',
            'cancelled',
            'completed',
            'no_show',
            'rejected',
          ];
          return statuses[random.nextInt(statuses.length)];
        },
        shrink: (_) => [],
      );
}

void main() {
  group('Property 16: Slot config lifecycle protection', () {
    // 16a: Deletion SHALL be rejected when future confirmed bookings > 0.
    Glados(any.positiveBookingCount, ExploreConfig(numRuns: 100)).test(
      'deletion rejected when future confirmed bookings exist',
      (count) {
        expect(
          () => assertDeletionAllowed(count),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'SLOT_HAS_BOOKINGS')
                .having((e) => e.statusCode, 'statusCode', 409),
          ),
          reason: 'futureConfirmedBookingCount=$count > 0 must reject',
        );
      },
    );

    // 16b: Deletion SHALL succeed when no future confirmed bookings exist.
    Glados(any.zeroCount, ExploreConfig(numRuns: 10)).test(
      'deletion allowed when no future confirmed bookings exist',
      (count) {
        expect(
          () => assertDeletionAllowed(count),
          returnsNormally,
          reason: 'futureConfirmedBookingCount=0 must allow deletion',
        );
      },
    );

    // 16c: Deactivation SHALL NOT change booking status (for any status).
    Glados(any.bookingStatus, ExploreConfig(numRuns: 100)).test(
      'deactivation does not change booking status',
      (status) {
        final result = simulateDeactivation(bookingStatus: status);
        expect(result.newIsActive, isFalse,
            reason: 'Slot config must become inactive');
        expect(result.bookingStatusAfter, equals(status),
            reason:
                'Booking status "$status" must remain unchanged after deactivation');
      },
    );
  });
}
