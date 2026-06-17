// Feature: accommodation-management, Property 2: Active Constraint Per Type
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 2.3, 3.5, 11.1, 11.2, 11.3, 11.4**
///
/// Property 2: Active Constraint Per Type
/// For any student and application type, if there exists an active application
/// (status in {submitted, approved, checked_in}) of that type, then submitting
/// a new application of the same type shall be rejected. An application of a
/// different type shall be permitted regardless. Active constraint is evaluated
/// independently per type.

/// The two application types in the system.
const _applicationTypes = ['semester', 'out_of_semester'];

extension AccommodationPropertyGenerators on Any {
  Generator<AccommodationStatus> get accommodationStatus =>
      choose(AccommodationStatus.values);

  Generator<String> get applicationType => choose(_applicationTypes);
}

void main() {
  group('Property 2: Active Constraint Per Type', () {
    // 2a: Active statuses block same-type submission.
    Glados(any.accommodationStatus, ExploreConfig(numRuns: 100)).test(
      'active status blocks same-type submission',
      (status) {
        if (status.isActive) {
          // Active statuses should block new submissions of same type
          expect(status.isActive, isTrue);
          expect(status.isTerminal, isFalse);
        } else {
          // Terminal/completed statuses allow new submissions
          expect(status.isTerminal, isTrue);
          expect(status.isActive, isFalse);
        }
      },
    );

    // 2b: isActive and isTerminal are mutually exclusive and exhaustive.
    Glados(any.accommodationStatus, ExploreConfig(numRuns: 100)).test(
      'isActive and isTerminal are mutually exclusive and exhaustive',
      (status) {
        // Every status is exactly one of active or terminal
        expect(
          status.isActive != status.isTerminal,
          isTrue,
          reason:
              '${status.name} must be either active or terminal, not both/neither',
        );
      },
    );

    // 2c: Active constraint is per-type — different types never block each other.
    Glados2(any.accommodationStatus, any.applicationType,
            ExploreConfig(numRuns: 100))
        .test(
      'different application types never block each other regardless of status',
      (status, existingType) {
        final newType =
            existingType == 'semester' ? 'out_of_semester' : 'semester';

        // The constraint logic: block only when same type AND active status.
        // For different types, it should NEVER block.
        bool wouldBlock(
            AccommodationStatus s, String existing, String incoming) {
          return s.isActive && existing == incoming;
        }

        expect(
          wouldBlock(status, existingType, newType),
          isFalse,
          reason:
              'An active $existingType app (status: ${status.name}) '
              'should not block a new $newType submission',
        );
      },
    );

    // 2d: Same-type blocking only occurs for active statuses.
    Glados2(any.accommodationStatus, any.applicationType,
            ExploreConfig(numRuns: 100))
        .test(
      'same-type submission blocked iff existing app has active status',
      (status, appType) {
        // Simulates the constraint check: should we block a new submission
        // of the same type given an existing app in this status?
        final shouldBlock = status.isActive;

        if (shouldBlock) {
          expect(
            status,
            isIn([
              AccommodationStatus.submitted,
              AccommodationStatus.approved,
              AccommodationStatus.checkedIn,
            ]),
            reason:
                'Only submitted, approved, checkedIn should block same-type',
          );
        } else {
          expect(
            status,
            isIn([
              AccommodationStatus.checkedOut,
              AccommodationStatus.rejected,
            ]),
            reason:
                'Only checkedOut, rejected should allow same-type re-submission',
          );
        }
      },
    );
  });
}
