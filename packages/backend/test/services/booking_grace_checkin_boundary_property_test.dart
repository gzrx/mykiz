// Property 11: Grace period check-in boundary
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 9.3, 9.4, 9.5**
///
/// For any confirmed booking with slot start time S, facility
/// grace_before_minutes B, and grace_after_minutes A:
/// check-in SHALL succeed if and only if S - B <= now <= S + A.
/// Check-in outside this window SHALL be rejected.

/// Pure function mirroring BookingService.checkIn grace window logic.
bool isWithinGraceWindow({
  required DateTime now,
  required DateTime slotStart,
  required int graceBeforeMinutes,
  required int graceAfterMinutes,
}) {
  final windowStart =
      slotStart.subtract(Duration(minutes: graceBeforeMinutes));
  final windowEnd = slotStart.add(Duration(minutes: graceAfterMinutes));
  return !now.isBefore(windowStart) && !now.isAfter(windowEnd);
}

extension GraceCheckinGenerators on Any {
  /// A slot start time: some DateTime today-ish.
  Generator<DateTime> get slotStart => simple(
        generate: (random, size) {
          // Random day within ±30 days, random hour 0-23, random minute 0-59
          final base = DateTime(2025, 6, 15);
          final dayOffset = random.nextInt(60) - 30;
          final hour = random.nextInt(24);
          final minute = random.nextInt(60);
          return base.add(Duration(days: dayOffset, hours: hour, minutes: minute));
        },
        shrink: (input) => [],
      );

  /// Grace before minutes in valid range [0, 60].
  Generator<int> get graceBefore => simple(
        generate: (random, size) => random.nextInt(61),
        shrink: (input) => [],
      );

  /// Grace after minutes in valid range [0, 120].
  Generator<int> get graceAfter => simple(
        generate: (random, size) => random.nextInt(121),
        shrink: (input) => [],
      );

}

void main() {
  group('Property 11: Grace period check-in boundary', () {
    // 11a: now within [slotStart - B, slotStart + A] → check-in succeeds.
    Glados3(
      any.slotStart,
      any.graceBefore,
      any.graceAfter,
      ExploreConfig(numRuns: 300),
    ).test(
      'check-in succeeds when now is within grace window',
      (slotStart, graceBefore, graceAfter) {
        // Generate a "now" inside the window: at slotStart (always valid)
        // Then shift by a fraction of the window to test interior points
        final windowSize = graceBefore + graceAfter;
        if (windowSize == 0) {
          // Degenerate: only slotStart itself is valid
          expect(
            isWithinGraceWindow(
              now: slotStart,
              slotStart: slotStart,
              graceBeforeMinutes: 0,
              graceAfterMinutes: 0,
            ),
            isTrue,
          );
          return;
        }
        // Test at the midpoint of the window
        final midOffset = -graceBefore + (windowSize ~/ 2);
        final now = slotStart.add(Duration(minutes: midOffset));
        expect(
          isWithinGraceWindow(
            now: now,
            slotStart: slotStart,
            graceBeforeMinutes: graceBefore,
            graceAfterMinutes: graceAfter,
          ),
          isTrue,
          reason: 'midpoint offset=$midOffset within [-$graceBefore, +$graceAfter]',
        );
      },
    );

    // 11b: now before (slotStart - B) → rejected.
    Glados3(
      any.slotStart,
      any.graceBefore,
      any.graceAfter,
      ExploreConfig(numRuns: 300),
    ).test(
      'check-in rejected when now is before grace window',
      (slotStart, graceBefore, graceAfter) {
        // 1 minute before the window opens
        final now =
            slotStart.subtract(Duration(minutes: graceBefore + 1));
        expect(
          isWithinGraceWindow(
            now: now,
            slotStart: slotStart,
            graceBeforeMinutes: graceBefore,
            graceAfterMinutes: graceAfter,
          ),
          isFalse,
          reason: 'now is 1 min before window start',
        );
      },
    );

    // 11c: now after (slotStart + A) → rejected.
    Glados3(
      any.slotStart,
      any.graceBefore,
      any.graceAfter,
      ExploreConfig(numRuns: 300),
    ).test(
      'check-in rejected when now is after grace window',
      (slotStart, graceBefore, graceAfter) {
        // 1 minute after the window closes
        final now = slotStart.add(Duration(minutes: graceAfter + 1));
        expect(
          isWithinGraceWindow(
            now: now,
            slotStart: slotStart,
            graceBeforeMinutes: graceBefore,
            graceAfterMinutes: graceAfter,
          ),
          isFalse,
          reason: 'now is 1 min after window end',
        );
      },
    );

    // 11d: Boundary values — exactly at window start and end → succeeds.
    Glados3(
      any.slotStart,
      any.graceBefore,
      any.graceAfter,
      ExploreConfig(numRuns: 200),
    ).test(
      'boundary: exactly at window start succeeds',
      (slotStart, graceBefore, graceAfter) {
        final now = slotStart.subtract(Duration(minutes: graceBefore));
        expect(
          isWithinGraceWindow(
            now: now,
            slotStart: slotStart,
            graceBeforeMinutes: graceBefore,
            graceAfterMinutes: graceAfter,
          ),
          isTrue,
          reason: 'now == slotStart - $graceBefore should succeed',
        );
      },
    );

    Glados3(
      any.slotStart,
      any.graceBefore,
      any.graceAfter,
      ExploreConfig(numRuns: 200),
    ).test(
      'boundary: exactly at window end succeeds',
      (slotStart, graceBefore, graceAfter) {
        final now = slotStart.add(Duration(minutes: graceAfter));
        expect(
          isWithinGraceWindow(
            now: now,
            slotStart: slotStart,
            graceBeforeMinutes: graceBefore,
            graceAfterMinutes: graceAfter,
          ),
          isTrue,
          reason: 'now == slotStart + $graceAfter should succeed',
        );
      },
    );
  });
}
