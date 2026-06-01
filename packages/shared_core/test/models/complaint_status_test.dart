import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';

/// Custom generator for ComplaintStatus enum values.
extension AnyComplaintStatus on Any {
  Generator<ComplaintStatus> get complaintStatus =>
      choose(ComplaintStatus.values);
}

void main() {
  // Feature: mykiz-platform, Property 15: Valid status transitions succeed
  // **Validates: Requirements 8.1, 8.2**
  Glados(any.complaintStatus, ExploreConfig(numRuns: 100)).test(
    'Property 15: Valid status transitions succeed - '
    'submitted→inProgress and inProgress→resolved always succeed',
    (status) {
      final nextStatus = status.next;
      if (nextStatus != null) {
        // If there is a valid next status, canTransitionTo must return true
        expect(status.canTransitionTo(nextStatus), isTrue);
      }
      // Verify the specific transitions per requirements 8.1 and 8.2
      expect(
        ComplaintStatus.submitted.canTransitionTo(ComplaintStatus.inProgress),
        isTrue,
      );
      expect(
        ComplaintStatus.inProgress.canTransitionTo(ComplaintStatus.resolved),
        isTrue,
      );
    },
  );

  // Feature: mykiz-platform, Property 16: Invalid status transitions rejected
  // **Validates: Requirements 8.3**
  Glados2(any.complaintStatus, any.complaintStatus,
          ExploreConfig(numRuns: 100))
      .test(
    'Property 16: Invalid status transitions rejected - '
    'any transition that is not the next step returns false',
    (source, target) {
      if (target != source.next) {
        // Any target that is NOT the next valid step must be rejected
        expect(source.canTransitionTo(target), isFalse);
      }
    },
  );

  // Feature: mykiz-platform, Property 15: Valid status transitions succeed
  // Additional: resolved status has no valid next transition
  // **Validates: Requirements 8.1, 8.2, 8.3**
  Glados(any.complaintStatus, ExploreConfig(numRuns: 100)).test(
    'Property 15/16: resolved status has no valid next transition',
    (status) {
      if (status == ComplaintStatus.resolved) {
        expect(status.next, isNull);
        // All transitions from resolved must be rejected
        for (final target in ComplaintStatus.values) {
          expect(status.canTransitionTo(target), isFalse);
        }
      }
    },
  );
}
