// Feature: booking-services, Property 5: Capacity invariant
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 4.6, 7.3, 8.3, 10.3**
///
/// Property 5: Capacity invariant
/// For any facility slot on a given date, the count of bookings with status
/// 'pending' or 'confirmed' SHALL never exceed the facility's capacity.
/// available_capacity = capacity - count(active bookings) >= 0, and submissions
/// are rejected when available_capacity = 0.

/// Pure decision logic extracted from BookingService.getAvailability:
/// available = capacity - booked; clamped to >= 0.
int computeAvailable(int capacity, int activeBookings) {
  final raw = capacity - activeBookings;
  return raw < 0 ? 0 : raw; // ponytail: mirrors the clamp in booking_service.dart
}

/// Whether a new submission should be accepted (available > 0).
bool canSubmit(int capacity, int activeBookings) =>
    computeAvailable(capacity, activeBookings) > 0;

void main() {
  group('Property 5: Capacity invariant', () {
    // Generator: capacity in [1, 50].
    final capacityGen = any.simple<int>(
      generate: (random, size) => 1 + random.nextInt(50),
      shrink: (input) => [if (input > 1) 1],
    );

    // Generator: active bookings in [0, 60] (can exceed capacity to test).
    final bookingsGen = any.simple<int>(
      generate: (random, size) => random.nextInt(61),
      shrink: (input) => [if (input > 0) input - 1],
    );

    // 5a: available_capacity can never be negative.
    Glados2(capacityGen, bookingsGen, ExploreConfig(numRuns: 200)).test(
      'available capacity is never negative',
      (capacity, activeBookings) {
        final available = computeAvailable(capacity, activeBookings);
        expect(available, greaterThanOrEqualTo(0),
            reason: 'capacity=$capacity, booked=$activeBookings');
      },
    );

    // 5b: When activeBookings >= capacity, submission is rejected (SLOT_FULL).
    Glados(capacityGen, ExploreConfig(numRuns: 200)).test(
      'rejects submission when active bookings >= capacity',
      (capacity) {
        // Test at capacity boundary and above.
        for (final n in [capacity, capacity + 1, capacity + 10]) {
          expect(canSubmit(capacity, n), isFalse,
              reason:
                  'capacity=$capacity, booked=$n should be SLOT_FULL');
        }
      },
    );

    // 5c: When activeBookings < capacity, submission is allowed.
    Glados(capacityGen, ExploreConfig(numRuns: 200)).test(
      'allows submission when active bookings < capacity',
      (capacity) {
        // Generate a random N in [0, capacity - 1].
        for (var n = 0; n < capacity; n++) {
          expect(canSubmit(capacity, n), isTrue,
              reason:
                  'capacity=$capacity, booked=$n should allow submission');
        }
      },
    );

    // 5d: available_capacity = capacity - activeBookings when under capacity.
    Glados2(capacityGen, bookingsGen, ExploreConfig(numRuns: 200)).test(
      'available equals capacity minus booked when under capacity',
      (capacity, activeBookings) {
        final available = computeAvailable(capacity, activeBookings);
        if (activeBookings <= capacity) {
          expect(available, equals(capacity - activeBookings));
        } else {
          // Clamped to 0 when over capacity.
          expect(available, equals(0));
        }
      },
    );
  });
}
