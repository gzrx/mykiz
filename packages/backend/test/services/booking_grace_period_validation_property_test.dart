// Feature: booking-services, Property 14: Grace period validation
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 14.3, 14.4**
///
/// Property 14: Grace period validation
/// For any grace_before_minutes value, it SHALL be accepted if and only if it
/// is in [0, 60]. For any grace_after_minutes value, it SHALL be accepted if
/// and only if it is in [0, 120]. Values outside these ranges SHALL be rejected
/// with INVALID_GRACE_PERIOD.

extension GracePeriodGenerators on Any {
  /// Generates an invalid grace_before_minutes value (< 0 or > 60).
  Generator<int> get invalidGraceBefore => either(
        simple(
          generate: (random, size) => -(1 + random.nextInt(1000)),
          shrink: (input) => [if (input < -1) -1],
        ),
        simple(
          generate: (random, size) => 61 + random.nextInt(1000),
          shrink: (input) => [if (input > 61) 61],
        ),
      );

  /// Generates a valid grace_before_minutes value in [0, 60].
  Generator<int> get validGraceBefore => simple(
        generate: (random, size) => random.nextInt(61),
        shrink: (input) => [if (input > 0) 0],
      );

  /// Generates an invalid grace_after_minutes value (< 0 or > 120).
  Generator<int> get invalidGraceAfter => either(
        simple(
          generate: (random, size) => -(1 + random.nextInt(1000)),
          shrink: (input) => [if (input < -1) -1],
        ),
        simple(
          generate: (random, size) => 121 + random.nextInt(1000),
          shrink: (input) => [if (input > 121) 121],
        ),
      );

  /// Generates a valid grace_after_minutes value in [0, 120].
  Generator<int> get validGraceAfter => simple(
        generate: (random, size) => random.nextInt(121),
        shrink: (input) => [if (input > 0) 0],
      );
}

void main() {
  final service = BookingService();

  group('Property 14: Grace period validation', () {
    // 14a: Invalid grace_before_minutes SHALL be rejected with
    // INVALID_GRACE_PERIOD.
    Glados(any.invalidGraceBefore, ExploreConfig(numRuns: 100)).test(
      'rejects grace_before_minutes outside [0, 60]',
      (invalidBefore) {
        expect(
          () => service.updateFacility('any-id',
              graceBeforeMinutes: invalidBefore),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'INVALID_GRACE_PERIOD'),
          ),
          reason:
              'grace_before_minutes=$invalidBefore should be rejected',
        );
      },
    );

    // 14b: Invalid grace_after_minutes SHALL be rejected with
    // INVALID_GRACE_PERIOD.
    Glados(any.invalidGraceAfter, ExploreConfig(numRuns: 100)).test(
      'rejects grace_after_minutes outside [0, 120]',
      (invalidAfter) {
        expect(
          () => service.updateFacility('any-id',
              graceAfterMinutes: invalidAfter),
          throwsA(
            isA<BookingException>()
                .having((e) => e.code, 'code', 'INVALID_GRACE_PERIOD'),
          ),
          reason:
              'grace_after_minutes=$invalidAfter should be rejected',
        );
      },
    );

    // 14c: Valid grace_before_minutes SHALL NOT throw INVALID_GRACE_PERIOD.
    Glados(any.validGraceBefore, ExploreConfig(numRuns: 100)).test(
      'accepts grace_before_minutes in [0, 60]',
      (validBefore) async {
        try {
          await service
              .updateFacility('any-id', graceBeforeMinutes: validBefore)
              .timeout(const Duration(milliseconds: 50));
        } on BookingException catch (e) {
          if (e.code == 'INVALID_GRACE_PERIOD') {
            fail('grace_before_minutes=$validBefore should be accepted');
          }
          // Other BookingException codes (e.g. FACILITY_NOT_FOUND) are fine.
        } catch (_) {
          // DB errors expected — validation passed.
        }
      },
    );

    // 14d: Valid grace_after_minutes SHALL NOT throw INVALID_GRACE_PERIOD.
    Glados(any.validGraceAfter, ExploreConfig(numRuns: 100)).test(
      'accepts grace_after_minutes in [0, 120]',
      (validAfter) async {
        try {
          await service
              .updateFacility('any-id', graceAfterMinutes: validAfter)
              .timeout(const Duration(milliseconds: 50));
        } on BookingException catch (e) {
          if (e.code == 'INVALID_GRACE_PERIOD') {
            fail('grace_after_minutes=$validAfter should be accepted');
          }
        } catch (_) {
          // DB errors expected — validation passed.
        }
      },
    );
  });
}
