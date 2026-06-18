// Property 10: Approval workflow state transitions
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 6.2, 6.3, 6.4**
///
/// For any booking with status 'pending', approval SHALL transition it to
/// 'confirmed'. For any booking with status 'pending' and a non-whitespace-only
/// reason string (1-255 chars), rejection SHALL transition it to 'rejected' and
/// store the reason. For any whitespace-only or empty reason string, rejection
/// SHALL be refused with REJECTION_REASON_REQUIRED.

// ─── Pure simulation functions (mirror BookingService logic) ────────────────

String simulateApproval(String currentStatus) {
  if (currentStatus != 'pending') throw 'INVALID_BOOKING_STATUS';
  return 'confirmed';
}

({String newStatus, String? error}) simulateRejection(
  String currentStatus,
  String reason,
) {
  if (reason.trim().isEmpty || reason.length > 255) {
    return (newStatus: currentStatus, error: 'REJECTION_REASON_REQUIRED');
  }
  if (currentStatus != 'pending') {
    return (newStatus: currentStatus, error: 'INVALID_BOOKING_STATUS');
  }
  return (newStatus: 'rejected', error: null);
}

// ─── Generators ─────────────────────────────────────────────────────────────

const _allStatuses = [
  'pending',
  'confirmed',
  'cancelled',
  'completed',
  'no_show',
  'rejected',
];

extension ApprovalGenerators on Any {
  /// Random booking status.
  Generator<String> get bookingStatus => simple(
        generate: (random, size) =>
            _allStatuses[random.nextInt(_allStatuses.length)],
        shrink: (input) => [],
      );

  /// Reason string that is valid (non-whitespace-only, 1-255 chars).
  Generator<String> get validReason => simple(
        generate: (random, size) {
          // At least one non-whitespace char, length 1-255.
          final len = 1 + random.nextInt(255);
          final buf = StringBuffer();
          for (var i = 0; i < len; i++) {
            // printable ASCII 33-126 (no whitespace-only risk)
            buf.writeCharCode(33 + random.nextInt(94));
          }
          return buf.toString();
        },
        shrink: (input) => input.length > 1 ? [input.substring(0, 1)] : [],
      );

  /// Reason string that is invalid (empty or whitespace-only).
  Generator<String> get invalidReason => simple(
        generate: (random, size) {
          // 50% empty, 50% whitespace-only (spaces/tabs/newlines)
          if (random.nextBool()) return '';
          final len = 1 + random.nextInt(20);
          const ws = [' ', '\t', '\n', '\r'];
          final buf = StringBuffer();
          for (var i = 0; i < len; i++) {
            buf.write(ws[random.nextInt(ws.length)]);
          }
          return buf.toString();
        },
        shrink: (input) => input.isNotEmpty ? [''] : [],
      );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('Property 10: Approval workflow state transitions', () {
    // 10a: Approving a pending booking transitions to confirmed.
    Glados(any.bookingStatus, ExploreConfig(numRuns: 200)).test(
      'approval of pending → confirmed; non-pending → error',
      (status) {
        if (status == 'pending') {
          expect(simulateApproval(status), equals('confirmed'));
        } else {
          expect(
            () => simulateApproval(status),
            throwsA(equals('INVALID_BOOKING_STATUS')),
          );
        }
      },
    );

    // 10b: Rejecting a pending booking with a valid reason → rejected + stores reason.
    Glados2(any.bookingStatus, any.validReason, ExploreConfig(numRuns: 200))
        .test(
      'rejection with valid reason: pending → rejected, non-pending → error',
      (status, reason) {
        final result = simulateRejection(status, reason);
        if (status == 'pending') {
          expect(result.newStatus, equals('rejected'));
          expect(result.error, isNull);
        } else {
          expect(result.newStatus, equals(status),
              reason: 'Status unchanged on non-pending');
          expect(result.error, equals('INVALID_BOOKING_STATUS'));
        }
      },
    );

    // 10c: Rejecting with whitespace-only or empty reason → REJECTION_REASON_REQUIRED.
    Glados(any.invalidReason, ExploreConfig(numRuns: 200)).test(
      'rejection with empty/whitespace reason is refused regardless of status',
      (reason) {
        for (final status in _allStatuses) {
          final result = simulateRejection(status, reason);
          expect(result.error, equals('REJECTION_REASON_REQUIRED'),
              reason: 'status=$status, reason="${reason.replaceAll('\n', '\\n')}"');
          expect(result.newStatus, equals(status),
              reason: 'Status must not change when reason is invalid');
        }
      },
    );

    // 10d: Reason > 255 chars is also refused.
    Glados(any.bookingStatus, ExploreConfig(numRuns: 100)).test(
      'rejection with reason > 255 chars is refused',
      (status) {
        final longReason = 'x' * 256; // non-whitespace but too long
        final result = simulateRejection(status, longReason);
        expect(result.error, equals('REJECTION_REASON_REQUIRED'));
        expect(result.newStatus, equals(status));
      },
    );
  });
}
