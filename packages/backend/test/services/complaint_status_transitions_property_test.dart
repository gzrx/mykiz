// Feature: mykiz-platform, Property 15: Valid status transitions succeed
// Feature: mykiz-platform, Property 16: Invalid status transitions rejected
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 8.1, 8.2, 8.3**
///
/// Property 15: Valid status transitions succeed
/// For any complaint in status "submitted", advancing to "in_progress" SHALL
/// succeed. For any complaint in status "in_progress", advancing to "resolved"
/// SHALL succeed.
///
/// Property 16: Invalid status transitions rejected
/// For any complaint and any target status that is not the next step in the
/// linear sequence (submitted → in_progress → resolved), including backward
/// transitions, same-status transitions, and skipping steps, the
/// Complaint_Service SHALL reject with 400 and code "INVALID_TRANSITION".

/// All valid transitions in the linear state machine.
const _validTransitions = [
  (ComplaintStatus.submitted, ComplaintStatus.inProgress),
  (ComplaintStatus.inProgress, ComplaintStatus.resolved),
];

/// All possible status pairs that are NOT valid transitions.
final _invalidTransitions = [
  for (final current in ComplaintStatus.values)
    for (final target in ComplaintStatus.values)
      if (!_validTransitions.contains((current, target))) (current, target),
];

/// Custom generators for complaint status testing.
extension ComplaintStatusGenerators on Any {
  /// Generates a random [ComplaintStatus] value.
  Generator<ComplaintStatus> get complaintStatus =>
      choose(ComplaintStatus.values);

  /// Generates a valid transition pair (current, target) from the state machine.
  Generator<(ComplaintStatus, ComplaintStatus)> get validTransitionPair =>
      choose(_validTransitions);

  /// Generates an invalid transition pair (current, target).
  Generator<(ComplaintStatus, ComplaintStatus)> get invalidTransitionPair =>
      choose(_invalidTransitions);
}

void main() {
  group('Property 15: Valid status transitions succeed', () {
    // Property 15a: For any complaint in status "submitted", advancing to
    // "in_progress" SHALL succeed (canTransitionTo returns true).
    Glados(any.validTransitionPair, ExploreConfig(numRuns: 100)).test(
      'canTransitionTo returns true for all valid forward transitions',
      (pair) {
        final (current, target) = pair;

        expect(
          current.canTransitionTo(target),
          isTrue,
          reason:
              'Transition from ${current.name} to ${target.name} should be valid',
        );
      },
    );

    // Property 15b: For status "submitted", the next getter returns inProgress.
    Glados(any.complaintStatus, ExploreConfig(numRuns: 100)).test(
      'next getter returns the correct next status for non-terminal statuses',
      (status) {
        switch (status) {
          case ComplaintStatus.submitted:
            expect(
              status.next,
              equals(ComplaintStatus.inProgress),
              reason: 'submitted.next should be inProgress',
            );
          case ComplaintStatus.inProgress:
            expect(
              status.next,
              equals(ComplaintStatus.resolved),
              reason: 'inProgress.next should be resolved',
            );
          case ComplaintStatus.resolved:
            expect(
              status.next,
              isNull,
              reason: 'resolved.next should be null (terminal state)',
            );
        }
      },
    );

    // Property 15c: For any valid transition, the target equals current.next.
    Glados(any.validTransitionPair, ExploreConfig(numRuns: 100)).test(
      'valid transition target always equals current.next',
      (pair) {
        final (current, target) = pair;

        expect(
          current.next,
          equals(target),
          reason:
              'For valid transition ${current.name} → ${target.name}, '
              'target should equal current.next',
        );
      },
    );
  });

  group('Property 16: Invalid status transitions rejected', () {
    // Property 16a: For any invalid transition pair, canTransitionTo returns
    // false (the state machine rejects it).
    Glados(any.invalidTransitionPair, ExploreConfig(numRuns: 100)).test(
      'canTransitionTo returns false for all invalid transitions',
      (pair) {
        final (current, target) = pair;

        expect(
          current.canTransitionTo(target),
          isFalse,
          reason:
              'Transition from ${current.name} to ${target.name} should be '
              'rejected as invalid',
        );
      },
    );

    // Property 16b: Same-status transitions are always rejected.
    Glados(any.complaintStatus, ExploreConfig(numRuns: 100)).test(
      'same-status transitions are always rejected',
      (status) {
        expect(
          status.canTransitionTo(status),
          isFalse,
          reason:
              'Transitioning from ${status.name} to itself should be rejected',
        );
      },
    );

    // Property 16c: Backward transitions are always rejected.
    Glados2(any.complaintStatus, any.complaintStatus,
            ExploreConfig(numRuns: 100))
        .test(
      'backward transitions are always rejected',
      (current, target) {
        // A backward transition is when target.index < current.index
        if (target.index < current.index) {
          expect(
            current.canTransitionTo(target),
            isFalse,
            reason:
                'Backward transition from ${current.name} to ${target.name} '
                'should be rejected',
          );
        }
      },
    );

    // Property 16d: Skipping steps is always rejected (submitted → resolved).
    Glados2(any.complaintStatus, any.complaintStatus,
            ExploreConfig(numRuns: 100))
        .test(
      'skipping steps in the sequence is rejected',
      (current, target) {
        // A skip is when target.index - current.index > 1
        if (target.index - current.index > 1) {
          expect(
            current.canTransitionTo(target),
            isFalse,
            reason:
                'Skipping from ${current.name} to ${target.name} should be '
                'rejected',
          );
        }
      },
    );

    // Property 16e: The terminal state (resolved) cannot transition to anything.
    Glados(any.complaintStatus, ExploreConfig(numRuns: 100)).test(
      'resolved status cannot transition to any status',
      (target) {
        expect(
          ComplaintStatus.resolved.canTransitionTo(target),
          isFalse,
          reason:
              'Resolved (terminal state) should not transition to ${target.name}',
        );
      },
    );
  });
}
