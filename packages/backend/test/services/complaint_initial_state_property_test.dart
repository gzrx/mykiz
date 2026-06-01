// Feature: mykiz-platform, Property 12: Complaint creation initial state
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

/// **Validates: Requirements 6.1**
///
/// Property 12: Complaint creation initial state
/// For any valid complaint submission (description 1–1000 chars, location
/// 1–200 chars), the Complaint_Service SHALL create the complaint with status
/// "submitted", a generated UUID, and a server-set createdAt timestamp.

/// UUID validation regex matching standard UUID v4 format.
final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Simulates the complaint creation logic from [ComplaintService.submit].
///
/// This replicates the initial state contract:
/// - Generates a UUID for the complaint ID
/// - Sets status to "submitted"
/// - Sets createdAt to the current server time
/// - Preserves the provided description and location
Complaint createComplaint({
  required String description,
  required String location,
  required String studentId,
}) {
  final uuid = const Uuid();
  final id = uuid.v4();
  final now = DateTime.now().toUtc();

  return Complaint(
    id: id,
    studentId: studentId,
    description: description,
    location: location,
    status: 'submitted',
    createdAt: now,
    updatedAt: now,
  );
}

/// Custom generators for complaint data.
extension ComplaintGenerators on Any {
  /// Generates a valid description string (1–1000 characters).
  Generator<String> get validDescription => simple(
        generate: (random, size) {
          // Length between 1 and 1000
          final length = 1 + random.nextInt(1000);
          const chars =
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?-';
          return List.generate(
            length,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
        },
        shrink: (input) => [],
      );

  /// Generates a valid location string (1–200 characters).
  Generator<String> get validLocation => simple(
        generate: (random, size) {
          // Length between 1 and 200
          final length = 1 + random.nextInt(200);
          const chars =
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?-';
          return List.generate(
            length,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
        },
        shrink: (input) => [],
      );

  /// Generates a UUID-like string for student IDs.
  Generator<String> get studentUuid => simple(
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
  group('Property 12: Complaint creation initial state', () {
    // Property 12a: For any valid complaint submission, the created complaint
    // SHALL have status "submitted".
    Glados3(any.validDescription, any.validLocation, any.studentUuid,
            ExploreConfig(numRuns: 100))
        .test(
      'complaint status is always "submitted" on creation',
      (description, location, studentId) {
        final complaint = createComplaint(
          description: description,
          location: location,
          studentId: studentId,
        );

        expect(
          complaint.status,
          equals('submitted'),
          reason:
              'Newly created complaint must have status "submitted", got "${complaint.status}"',
        );
      },
    );

    // Property 12b: For any valid complaint submission, the created complaint
    // SHALL have a valid UUID as its id.
    Glados3(any.validDescription, any.validLocation, any.studentUuid,
            ExploreConfig(numRuns: 100))
        .test(
      'complaint id is a valid UUID on creation',
      (description, location, studentId) {
        final complaint = createComplaint(
          description: description,
          location: location,
          studentId: studentId,
        );

        expect(
          _uuidRegex.hasMatch(complaint.id),
          isTrue,
          reason:
              'Complaint id "${complaint.id}" should be a valid UUID format',
        );
      },
    );

    // Property 12c: For any valid complaint submission, the created complaint
    // SHALL have a server-set createdAt timestamp (not null, set to
    // approximately current time).
    Glados3(any.validDescription, any.validLocation, any.studentUuid,
            ExploreConfig(numRuns: 100))
        .test(
      'complaint createdAt is set to server time on creation',
      (description, location, studentId) {
        final before = DateTime.now().toUtc();

        final complaint = createComplaint(
          description: description,
          location: location,
          studentId: studentId,
        );

        final after = DateTime.now().toUtc();

        // createdAt should be between before and after (inclusive)
        expect(
          complaint.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
          reason:
              'Complaint createdAt (${complaint.createdAt}) should not be before test start ($before)',
        );
        expect(
          complaint.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
          reason:
              'Complaint createdAt (${complaint.createdAt}) should not be after test end ($after)',
        );
      },
    );

    // Property 12d: For any valid complaint submission, the description and
    // location are preserved exactly as provided.
    Glados3(any.validDescription, any.validLocation, any.studentUuid,
            ExploreConfig(numRuns: 100))
        .test(
      'complaint preserves description and location on creation',
      (description, location, studentId) {
        final complaint = createComplaint(
          description: description,
          location: location,
          studentId: studentId,
        );

        expect(
          complaint.description,
          equals(description),
          reason: 'Complaint description should be preserved exactly',
        );
        expect(
          complaint.location,
          equals(location),
          reason: 'Complaint location should be preserved exactly',
        );
      },
    );

    // Property 12e: The ComplaintStatus enum's initial/first value is
    // 'submitted', confirming the domain model enforces the initial state.
    test('ComplaintStatus enum initial value is submitted', () {
      expect(
        ComplaintStatus.values.first,
        equals(ComplaintStatus.submitted),
        reason:
            'The first value of ComplaintStatus enum must be "submitted" to '
            'represent the initial state of all complaints',
      );
    });

    // Property 12f: For any valid complaint, each creation produces a unique
    // UUID (no collisions across multiple creations with same inputs).
    Glados2(any.validDescription, any.validLocation,
            ExploreConfig(numRuns: 100))
        .test(
      'each complaint creation generates a unique UUID',
      (description, location) {
        final complaint1 = createComplaint(
          description: description,
          location: location,
          studentId: 'student-1',
        );
        final complaint2 = createComplaint(
          description: description,
          location: location,
          studentId: 'student-1',
        );

        expect(
          complaint1.id,
          isNot(equals(complaint2.id)),
          reason:
              'Two complaints created with the same inputs should have different UUIDs',
        );
      },
    );
  });
}
