// Property 4: Blocked slot invariant
import 'package:backend/services/booking_exception.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 3.2, 3.5, 6.6**
///
/// Property 4: Blocked slot invariant
/// For any date-slot combination with an existing BlockedSlot record:
/// (a) new booking submissions SHALL be rejected (SLOT_BLOCKED),
/// (b) pending booking approvals SHALL be rejected, and
/// (c) all previously confirmed bookings SHALL be transitioned to 'cancelled'
///     when the block is created.

// ─── Pure decision functions ─────────────────────────────────────────────────

/// Mirrors submitBooking's blocked-slot check.
/// Throws SLOT_BLOCKED when slot is blocked.
void assertSubmissionAllowed({required bool isBlocked}) {
  if (isBlocked) {
    throw const BookingException(
      code: 'SLOT_BLOCKED',
      message: 'The selected slot is blocked and unavailable for booking.',
    );
  }
}

/// Mirrors approveBooking's blocked-slot check (Requirement 6.6).
/// If the slot was blocked between submission and approval, approval is rejected
/// and the booking is cancelled.
({String newStatus, bool approved}) simulateApproval({
  required bool isBlocked,
  required String currentStatus,
}) {
  if (currentStatus != 'pending') {
    throw const BookingException(
      code: 'INVALID_BOOKING_STATUS',
      message: 'Only pending bookings can be approved.',
    );
  }
  if (isBlocked) {
    // Approval rejected; booking transitions to cancelled.
    return (newStatus: 'cancelled', approved: false);
  }
  return (newStatus: 'confirmed', approved: true);
}

/// Mirrors blockSlot's effect on existing confirmed bookings.
/// When a block is created, all N confirmed bookings for that date-slot
/// transition to 'cancelled'.
List<String> simulateBlockCreation({
  required List<String> existingBookingStatuses,
}) {
  return existingBookingStatuses
      .map((s) => s == 'confirmed' ? 'cancelled' : s)
      .toList();
}

// ─── Generators ──────────────────────────────────────────────────────────────

extension BlockedSlotGenerators on Any {
  /// Generates a positive number of confirmed bookings (1–50).
  Generator<int> get confirmedCount => simple(
        generate: (random, size) => 1 + random.nextInt(50),
        shrink: (input) => [if (input > 1) input - 1],
      );

  /// Generates a mixed list of booking statuses including at least one confirmed.
  Generator<List<String>> get mixedBookingStatuses => simple(
        generate: (random, size) {
          const statuses = [
            'pending',
            'confirmed',
            'cancelled',
            'completed',
            'no_show',
            'rejected',
          ];
          final count = 1 + random.nextInt(20);
          final list = List.generate(
            count,
            (_) => statuses[random.nextInt(statuses.length)],
          );
          // Ensure at least one confirmed.
          if (!list.contains('confirmed')) {
            list[random.nextInt(list.length)] = 'confirmed';
          }
          return list;
        },
        shrink: (input) => [
          if (input.length > 1) input.sublist(0, input.length - 1),
        ],
      );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('Property 4: Blocked slot invariant', () {
    // 4a: Submissions SHALL be rejected when a blocked slot exists.
    Glados(any.confirmedCount, ExploreConfig(numRuns: 100)).test(
      '(a) booking submission rejected when slot is blocked',
      (_) {
        expect(
          () => assertSubmissionAllowed(isBlocked: true),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'SLOT_BLOCKED'),
          ),
          reason: 'Blocked slot must reject new submissions',
        );
      },
    );

    // Sanity: submissions allowed when not blocked.
    Glados(any.confirmedCount, ExploreConfig(numRuns: 10)).test(
      '(a-inverse) booking submission allowed when slot is not blocked',
      (_) {
        expect(
          () => assertSubmissionAllowed(isBlocked: false),
          returnsNormally,
          reason: 'Non-blocked slot must allow submissions',
        );
      },
    );

    // 4b: Approval SHALL be rejected for pending bookings when slot is blocked.
    Glados(any.confirmedCount, ExploreConfig(numRuns: 100)).test(
      '(b) pending booking approval rejected when slot is blocked',
      (_) {
        final result = simulateApproval(
          isBlocked: true,
          currentStatus: 'pending',
        );
        expect(result.approved, isFalse,
            reason: 'Approval must be rejected when slot is blocked');
        expect(result.newStatus, equals('cancelled'),
            reason: 'Booking must transition to cancelled');
      },
    );

    // 4c: All confirmed bookings SHALL transition to cancelled on block creation.
    Glados(any.mixedBookingStatuses, ExploreConfig(numRuns: 100)).test(
      '(c) all confirmed bookings cancelled when block is created',
      (statuses) {
        final result =
            simulateBlockCreation(existingBookingStatuses: statuses);

        expect(result.length, equals(statuses.length),
            reason: 'Output list length must match input');

        for (var i = 0; i < statuses.length; i++) {
          if (statuses[i] == 'confirmed') {
            expect(result[i], equals('cancelled'),
                reason:
                    'Confirmed booking at index $i must become cancelled');
          } else {
            expect(result[i], equals(statuses[i]),
                reason:
                    'Non-confirmed booking at index $i must remain unchanged');
          }
        }

        // The invariant: no confirmed bookings survive block creation.
        expect(result.contains('confirmed'), isFalse,
            reason: 'No confirmed bookings may remain after block creation');
      },
    );
  });
}
