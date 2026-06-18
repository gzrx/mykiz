// Property 12: No-show processor
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 10.1, 10.4**
///
/// For any booking with status 'confirmed' whose slot date is today and whose
/// grace period end time (slot_start + grace_after_minutes) has passed, the
/// no-show processor SHALL transition it to 'no_show'. For any booking on a
/// future date or whose grace period has not yet elapsed, the processor SHALL
/// not modify it.

/// Pure decision function extracted from BookingService.processNoShows logic.
bool shouldMarkNoShow({
  required String status,
  required DateTime bookingDate,
  required DateTime slotStart,
  required int graceAfterMinutes,
  required DateTime now,
}) {
  if (status != 'confirmed') return false;
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly =
      DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
  if (!dateOnly.isAtSameMomentAs(today)) return false;
  final graceEnd = slotStart.add(Duration(minutes: graceAfterMinutes));
  return now.isAfter(graceEnd);
}

// --- Generators ---

extension NoShowGenerators on Any {
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

  /// Grace after minutes in valid range [0, 120].
  Generator<int> get graceAfterMinutes => simple(
        generate: (random, size) => random.nextInt(121),
        shrink: (input) => [],
      );

  /// Offset in minutes from slot start to "now" — range [-60, 180].
  Generator<int> get minutesAfterSlotStart => simple(
        generate: (random, size) => random.nextInt(241) - 60,
        shrink: (input) => [],
      );

  /// Day offset from today: 0 = today, positive = future, negative = past.
  Generator<int> get dayOffset => simple(
        generate: (random, size) => random.nextInt(15) - 2, // -2..+12
        shrink: (input) => [],
      );
}

void main() {
  group('Property 12: No-show processor', () {
    // 12a: Confirmed + today + grace elapsed → should mark no-show.
    Glados2(any.graceAfterMinutes, any.minutesAfterSlotStart,
            ExploreConfig(numRuns: 200))
        .test(
      'confirmed booking today with elapsed grace is marked no-show',
      (grace, minutesAfter) {
        // Only consider cases where grace has elapsed
        if (minutesAfter <= grace) return;

        final now = DateTime(2025, 6, 15, 10, 0).add(
          Duration(minutes: minutesAfter),
        );
        final bookingDate = DateTime(2025, 6, 15);
        final slotStart = DateTime(2025, 6, 15, 10, 0);

        expect(
          shouldMarkNoShow(
            status: 'confirmed',
            bookingDate: bookingDate,
            slotStart: slotStart,
            graceAfterMinutes: grace,
            now: now,
          ),
          isTrue,
          reason: 'Grace=$grace min, now is $minutesAfter min after slot start '
              '→ should mark no-show',
        );
      },
    );

    // 12b: Confirmed + future date → should NOT mark.
    Glados2(any.graceAfterMinutes, any.minutesAfterSlotStart,
            ExploreConfig(numRuns: 200))
        .test(
      'confirmed booking on future date is not marked no-show',
      (grace, minutesAfter) {
        final now = DateTime(2025, 6, 15, 10, 0);
        final bookingDate = DateTime(2025, 6, 16); // tomorrow
        final slotStart = DateTime(2025, 6, 16, 10, 0);

        expect(
          shouldMarkNoShow(
            status: 'confirmed',
            bookingDate: bookingDate,
            slotStart: slotStart,
            graceAfterMinutes: grace,
            now: now,
          ),
          isFalse,
          reason: 'Booking is on a future date → should not mark no-show',
        );
      },
    );

    // 12c: Non-confirmed + today + grace elapsed → should NOT mark.
    Glados2(any.bookingStatus, any.graceAfterMinutes,
            ExploreConfig(numRuns: 200))
        .test(
      'non-confirmed booking is never marked no-show',
      (status, grace) {
        if (status == 'confirmed') return; // skip confirmed

        final now = DateTime(2025, 6, 15, 14, 0); // well past any grace
        final bookingDate = DateTime(2025, 6, 15);
        final slotStart = DateTime(2025, 6, 15, 10, 0);

        expect(
          shouldMarkNoShow(
            status: status,
            bookingDate: bookingDate,
            slotStart: slotStart,
            graceAfterMinutes: grace,
            now: now,
          ),
          isFalse,
          reason: 'Status "$status" should never be marked no-show',
        );
      },
    );

    // 12d: Confirmed + today + grace NOT elapsed → should NOT mark.
    Glados2(any.graceAfterMinutes, any.minutesAfterSlotStart,
            ExploreConfig(numRuns: 200))
        .test(
      'confirmed booking today with grace not elapsed is not marked',
      (grace, minutesAfter) {
        // Only consider cases where grace has NOT elapsed
        if (minutesAfter > grace) return;

        final now = DateTime(2025, 6, 15, 10, 0).add(
          Duration(minutes: minutesAfter),
        );
        final bookingDate = DateTime(2025, 6, 15);
        final slotStart = DateTime(2025, 6, 15, 10, 0);

        expect(
          shouldMarkNoShow(
            status: 'confirmed',
            bookingDate: bookingDate,
            slotStart: slotStart,
            graceAfterMinutes: grace,
            now: now,
          ),
          isFalse,
          reason: 'Grace=$grace min, now is $minutesAfter min after slot start '
              '→ grace not elapsed, should not mark',
        );
      },
    );
  });
}
