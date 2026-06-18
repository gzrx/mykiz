// Property 9: Cancellation window
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 7.1, 7.2, 7.4, 7.5**
///
/// For any booking with status 'confirmed' where the current time is more than
/// 2 hours before the slot start, cancellation SHALL succeed. Where the current
/// time is 2 hours or less before slot start, cancellation SHALL be rejected.
/// For any booking with status 'pending', cancellation SHALL always succeed
/// regardless of time.

/// Pure decision function extracted from BookingService.cancelBooking logic.
/// Returns null if cancellation is allowed, or the error code if rejected.
String? canCancel({
  required String status,
  required Duration timeUntilSlotStart,
}) {
  if (status == 'pending') return null; // always cancellable
  if (status == 'confirmed') {
    if (timeUntilSlotStart > const Duration(hours: 2)) return null;
    return 'CANCELLATION_WINDOW_PASSED';
  }
  return 'INVALID_BOOKING_STATUS'; // terminal statuses
}

/// Generates a Duration in the range [-24h, +48h] to cover past and future.
extension CancellationGenerators on Any {
  Generator<Duration> get timeUntilSlot => simple(
        generate: (random, size) {
          // Range: -24h to +48h in minute granularity
          final minutes = random.nextInt(72 * 60) - (24 * 60);
          return Duration(minutes: minutes);
        },
        shrink: (input) => [],
      );

  Generator<String> get bookingStatus => simple(
        generate: (random, size) {
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
        shrink: (input) => [],
      );
}

void main() {
  group('Property 9: Cancellation window', () {
    // 9a: Pending bookings are always cancellable regardless of time.
    Glados(any.timeUntilSlot, ExploreConfig(numRuns: 200)).test(
      'pending bookings are always cancellable regardless of time',
      (duration) {
        expect(
          canCancel(status: 'pending', timeUntilSlotStart: duration),
          isNull,
          reason: 'Pending booking should be cancellable at any time '
              '(timeUntilSlot=$duration)',
        );
      },
    );

    // 9b: Confirmed bookings > 2h before slot start → cancellation succeeds.
    Glados(any.timeUntilSlot, ExploreConfig(numRuns: 200)).test(
      'confirmed bookings > 2h before slot start can be cancelled',
      (duration) {
        // Only test durations strictly > 2h
        if (duration <= const Duration(hours: 2)) return;
        expect(
          canCancel(status: 'confirmed', timeUntilSlotStart: duration),
          isNull,
          reason: 'Confirmed booking with $duration until slot start '
              'should be cancellable (> 2h)',
        );
      },
    );

    // 9c: Confirmed bookings <= 2h before slot start → rejection.
    Glados(any.timeUntilSlot, ExploreConfig(numRuns: 200)).test(
      'confirmed bookings <= 2h before slot start are rejected',
      (duration) {
        // Only test durations <= 2h
        if (duration > const Duration(hours: 2)) return;
        expect(
          canCancel(status: 'confirmed', timeUntilSlotStart: duration),
          equals('CANCELLATION_WINDOW_PASSED'),
          reason: 'Confirmed booking with $duration until slot start '
              'should be rejected (<= 2h)',
        );
      },
    );

    // 9d: Terminal statuses are never cancellable.
    Glados2(any.timeUntilSlot, any.bookingStatus, ExploreConfig(numRuns: 200))
        .test(
      'terminal statuses are never cancellable',
      (duration, status) {
        if (status == 'pending' || status == 'confirmed') return;
        expect(
          canCancel(status: status, timeUntilSlotStart: duration),
          equals('INVALID_BOOKING_STATUS'),
          reason: 'Status "$status" should never be cancellable',
        );
      },
    );
  });
}
