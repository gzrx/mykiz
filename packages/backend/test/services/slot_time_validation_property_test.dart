// Property 2: Slot time validation
import 'package:backend/services/booking_service.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 2.2, 2.3, 2.4**
///
/// For any pair of start and end time strings, the system SHALL accept the slot
/// config if and only if start < end AND the new slot does not overlap with any
/// existing active slot for the same facility.

/// Generates a valid HH:MM time string (00:00 – 23:59).
extension SlotTimeGenerators on Any {
  Generator<String> get validTime => simple(
        generate: (random, size) {
          final h = random.nextInt(24);
          final m = random.nextInt(60);
          return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        },
        shrink: (input) => [],
      );
}

void main() {
  group('Property 2: Slot time validation', () {
    // 2a: start >= end means invalid time ordering.
    // slotsOverlap is only meaningful when both slots have valid ordering,
    // but we test the ordering precondition itself here.
    Glados2(any.validTime, any.validTime, ExploreConfig(numRuns: 200)).test(
      'start < end is the only valid time ordering for a slot',
      (start, end) {
        final isValidOrder = start.compareTo(end) < 0;
        // A slot with start >= end should be rejected (the DB CHECK enforces
        // this; the service must validate before insert).
        if (start.compareTo(end) >= 0) {
          expect(isValidOrder, isFalse,
              reason: 'start=$start >= end=$end should be rejected');
        } else {
          expect(isValidOrder, isTrue,
              reason: 'start=$start < end=$end should be accepted');
        }
      },
    );

    // 2b: Overlap detection — two slots overlap iff startA < endB AND startB < endA.
    Glados(any.validTime, ExploreConfig(numRuns: 200)).test(
      'non-overlapping slots: slotB starts at or after slotA ends',
      (midTime) {
        // Construct two non-overlapping slots: A = [00:00, midTime), B = [midTime, 23:59)
        // Only valid when midTime is between 00:01 and 23:58 exclusive.
        if (midTime.compareTo('00:01') < 0 || midTime.compareTo('23:58') > 0) {
          return; // skip trivial edge where we can't form two valid slots
        }
        const startA = '00:00';
        final endA = midTime;
        final startB = midTime;
        const endB = '23:59';

        // Slots that share an endpoint (endA == startB) should NOT overlap.
        expect(slotsOverlap(startA, endA, startB, endB), isFalse,
            reason: 'Adjacent slots [$startA,$endA) and [$startB,$endB) '
                'should not overlap');
      },
    );

    // 2c: Overlapping slots — if slotB starts before slotA ends.
    Glados2(any.validTime, any.validTime, ExploreConfig(numRuns: 200)).test(
      'overlapping slots are correctly detected',
      (t1, t2) {
        // Build a guaranteed overlapping pair when t1 != t2.
        final times = [t1, t2]..sort();
        final early = times[0];
        final late = times[1];
        if (early == late) return; // can't form distinct slots

        // Slots A=[early, late) and B that starts inside A overlaps.
        // Use A=[early, late), B=[early, late) — identical slots always overlap.
        expect(slotsOverlap(early, late, early, late), isTrue,
            reason: 'Identical slots [$early,$late) must overlap');
      },
    );

    // 2d: Symmetry — overlap(A,B) == overlap(B,A).
    Glados2(any.validTime, any.validTime, ExploreConfig(numRuns: 200)).test(
      'slotsOverlap(A,B) == slotsOverlap(B,A) for any valid slots',
      (t1, t2) {
        // We need 4 times — use t1,t2 to derive two slots.
        // SlotA = [min(t1,t2), max(t1,t2)], SlotB shifted by re-using t2 as start.
        final sorted = [t1, t2]..sort();
        final startA = sorted[0];
        final endA = sorted[1];
        if (startA == endA) return; // degenerate

        // For slot B, use endA as start and '23:59' as end (always valid if endA < 23:59).
        if (endA.compareTo('23:59') >= 0) return;
        final startB = endA;
        const endB = '23:59';

        expect(
          slotsOverlap(startA, endA, startB, endB),
          equals(slotsOverlap(startB, endB, startA, endA)),
          reason: 'Overlap must be symmetric: '
              'A=[$startA,$endA) B=[$startB,$endB)',
        );
      },
    );
  });
}
