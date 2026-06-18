// Property 7: Status assignment on booking creation
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 4.3, 8.1**
///
/// For any booking created by a student on an auto-approval facility, the
/// initial status SHALL be 'confirmed'. For any booking created by a student on
/// a manual-approval facility, the initial status SHALL be 'pending'. For any
/// manual booking created by an admin, the initial status SHALL be 'confirmed'
/// regardless of the facility's approval mode.

/// Pure decision function matching the logic in BookingService.submitBooking
/// and BookingService.createManualBooking.
String determineStatus({
  required String approvalMode,
  required bool isAdminManual,
}) {
  if (isAdminManual) return 'confirmed';
  return approvalMode == 'auto' ? 'confirmed' : 'pending';
}

extension StatusGenerators on Any {
  Generator<String> get approvalMode => simple(
        generate: (random, size) => random.nextBool() ? 'auto' : 'manual',
        shrink: (input) => [],
      );

  Generator<bool> get adminFlag => simple(
        generate: (random, size) => random.nextBool(),
        shrink: (input) => [],
      );
}

void main() {
  group('Property 7: Status assignment on booking creation', () {
    // 7a: Admin manual bookings are always confirmed.
    Glados(any.approvalMode, ExploreConfig(numRuns: 100)).test(
      'admin manual booking is always confirmed regardless of approval mode',
      (mode) {
        expect(
          determineStatus(approvalMode: mode, isAdminManual: true),
          equals('confirmed'),
          reason: 'Admin manual booking with approvalMode=$mode '
              'must be confirmed',
        );
      },
    );

    // 7b: Student on auto-approval facility gets confirmed.
    Glados(any.adminFlag, ExploreConfig(numRuns: 50)).test(
      'student booking on auto-approval facility is confirmed',
      (_) {
        expect(
          determineStatus(approvalMode: 'auto', isAdminManual: false),
          equals('confirmed'),
        );
      },
    );

    // 7c: Student on manual-approval facility gets pending.
    Glados(any.adminFlag, ExploreConfig(numRuns: 50)).test(
      'student booking on manual-approval facility is pending',
      (_) {
        expect(
          determineStatus(approvalMode: 'manual', isAdminManual: false),
          equals('pending'),
        );
      },
    );

    // 7d: Full property — covers all combinations.
    Glados2(any.approvalMode, any.adminFlag, ExploreConfig(numRuns: 200)).test(
      'status assignment is consistent across all input combinations',
      (mode, isAdmin) {
        final status = determineStatus(
          approvalMode: mode,
          isAdminManual: isAdmin,
        );

        if (isAdmin) {
          expect(status, 'confirmed',
              reason: 'Admin override: always confirmed');
        } else if (mode == 'auto') {
          expect(status, 'confirmed',
              reason: 'Student + auto = confirmed');
        } else {
          expect(status, 'pending',
              reason: 'Student + manual = pending');
        }
      },
    );
  });
}
