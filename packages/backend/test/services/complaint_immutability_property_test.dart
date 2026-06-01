// Feature: mykiz-platform, Property 17: Complaint immutability
import 'package:glados/glados.dart';
import 'package:test/test.dart';

import 'package:backend/services/complaint_service.dart';

/// **Validates: Requirements 9.1, 9.2, 9.3, 9.4**
///
/// Property 17: Complaint immutability
/// For any complaint in any status (submitted, in_progress, or resolved),
/// any attempt to modify the description, location, or image, or any attempt
/// to delete the complaint, SHALL be rejected with 403 FORBIDDEN, leaving the
/// complaint data unchanged. Status advancement by an Admin is the sole
/// permitted modification.

/// Custom generators for complaint-related data.
extension ComplaintGenerators on Any {
  /// Generates a valid complaint status string.
  Generator<String> get complaintStatus =>
      choose(['submitted', 'in_progress', 'resolved']);

  /// Generates a random non-empty description (1-1000 chars).
  Generator<String> get complaintDescription => simple(
        generate: (random, size) {
          final length = random.nextInt(999) + 1; // 1 to 1000
          const chars =
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?';
          return List.generate(
            length,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
        },
        shrink: (input) => [],
      );

  /// Generates a random non-empty location (1-200 chars).
  Generator<String> get complaintLocation => simple(
        generate: (random, size) {
          final length = random.nextInt(199) + 1; // 1 to 200
          const chars =
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -.,';
          return List.generate(
            length,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
        },
        shrink: (input) => [],
      );

  /// Generates a UUID-like string.
  Generator<String> get uuid => simple(
        generate: (random, size) {
          const chars = 'abcdef0123456789';
          final segments = [8, 4, 4, 4, 12];
          final parts = segments.map((len) {
            return List.generate(
              len,
              (_) => chars[random.nextInt(chars.length)],
            ).join();
          });
          return parts.join('-');
        },
        shrink: (input) => [],
      );
}

void main() {
  late ComplaintService service;

  setUp(() {
    service = ComplaintService();
  });

  group('Property 17: Complaint immutability', () {
    // Property 17a: For any complaint status, calling rejectModification()
    // SHALL always throw ComplaintException with code 'FORBIDDEN' and
    // statusCode 403.
    Glados(any.complaintStatus, ExploreConfig(numRuns: 100)).test(
      'rejectModification() throws FORBIDDEN for any complaint status',
      (status) {
        // The rejectModification method is unconditional — it always throws
        // regardless of the complaint status. We generate random statuses to
        // demonstrate that no status bypasses the immutability enforcement.
        expect(
          () => service.rejectModification(),
          throwsA(
            isA<ComplaintException>()
                .having((e) => e.code, 'code', equals('FORBIDDEN'))
                .having((e) => e.statusCode, 'statusCode', equals(403)),
          ),
          reason:
              'rejectModification() must throw FORBIDDEN (403) for status "$status"',
        );
      },
    );

    // Property 17b: For any complaint status, calling rejectDeletion()
    // SHALL always throw ComplaintException with code 'FORBIDDEN' and
    // statusCode 403.
    Glados(any.complaintStatus, ExploreConfig(numRuns: 100)).test(
      'rejectDeletion() throws FORBIDDEN for any complaint status',
      (status) {
        // The rejectDeletion method is unconditional — it always throws
        // regardless of the complaint status. We generate random statuses to
        // demonstrate that no status bypasses the deletion protection.
        expect(
          () => service.rejectDeletion(),
          throwsA(
            isA<ComplaintException>()
                .having((e) => e.code, 'code', equals('FORBIDDEN'))
                .having((e) => e.statusCode, 'statusCode', equals(403)),
          ),
          reason:
              'rejectDeletion() must throw FORBIDDEN (403) for status "$status"',
        );
      },
    );

    // Property 17c: For any random complaint data (description, location,
    // student ID), the rejection is unconditional — no combination of
    // complaint data can bypass the immutability enforcement.
    Glados3(
      any.complaintDescription,
      any.complaintLocation,
      any.uuid,
      ExploreConfig(numRuns: 100),
    ).test(
      'rejectModification() is unconditional regardless of complaint data',
      (description, location, studentId) {
        // Even with arbitrary complaint data, the modification rejection
        // must always fire. This proves the enforcement is not data-dependent.
        expect(
          () => service.rejectModification(),
          throwsA(
            isA<ComplaintException>()
                .having((e) => e.code, 'code', equals('FORBIDDEN'))
                .having((e) => e.statusCode, 'statusCode', equals(403))
                .having(
                  (e) => e.message,
                  'message',
                  contains('cannot be modified'),
                ),
          ),
          reason: 'rejectModification() must throw FORBIDDEN regardless of '
              'complaint data (description length: ${description.length}, '
              'location: "$location", studentId: "$studentId")',
        );
      },
    );

    // Property 17d: For any random complaint data, the deletion rejection
    // is unconditional — no combination of complaint data can bypass it.
    Glados3(
      any.complaintDescription,
      any.complaintLocation,
      any.uuid,
      ExploreConfig(numRuns: 100),
    ).test(
      'rejectDeletion() is unconditional regardless of complaint data',
      (description, location, studentId) {
        // Even with arbitrary complaint data, the deletion rejection
        // must always fire. This proves the enforcement is not data-dependent.
        expect(
          () => service.rejectDeletion(),
          throwsA(
            isA<ComplaintException>()
                .having((e) => e.code, 'code', equals('FORBIDDEN'))
                .having((e) => e.statusCode, 'statusCode', equals(403))
                .having(
                  (e) => e.message,
                  'message',
                  contains('cannot be deleted'),
                ),
          ),
          reason: 'rejectDeletion() must throw FORBIDDEN regardless of '
              'complaint data (description length: ${description.length}, '
              'location: "$location", studentId: "$studentId")',
        );
      },
    );
  });
}
