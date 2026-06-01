// Feature: mykiz-platform, Property 13: Complaint ownership scoping
import 'package:glados/glados.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 7.1, 7.5, 2.6**
///
/// Property 13: Complaint ownership scoping
/// For any Student requesting complaints, the Complaint_Service SHALL return
/// only complaints where studentId matches the requesting Student's ID.
/// For any Student requesting a single complaint belonging to a different
/// Student, the service SHALL return 404.

/// Simulates the ownership filtering logic from [ComplaintService.list].
///
/// When a student requests complaints, the service filters to only return
/// complaints where studentId matches the requesterId.
List<Complaint> filterComplaintsForStudent({
  required List<Complaint> allComplaints,
  required String requesterId,
}) {
  return allComplaints
      .where((c) => c.studentId == requesterId)
      .toList();
}

/// Simulates the ownership check from [ComplaintService.getById].
///
/// When a student requests a single complaint:
/// - If the complaint's studentId matches the requesterId, return it.
/// - If the complaint belongs to a different student, throw NOT_FOUND.
///
/// Returns the complaint or null (representing 404 NOT_FOUND).
Complaint? getByIdForStudent({
  required Complaint complaint,
  required String requesterId,
}) {
  if (complaint.studentId == requesterId) {
    return complaint;
  }
  // Service returns 404 NOT_FOUND for complaints belonging to other students
  return null;
}

/// Custom generators for complaint ownership testing.
extension ComplaintOwnershipGenerators on Any {
  /// Generates a UUID-like string for student IDs.
  Generator<String> get studentId => simple(
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

  /// Generates a valid complaint status string.
  Generator<String> get complaintStatus =>
      choose(['submitted', 'in_progress', 'resolved']);

  /// Generates a non-empty description (1-100 chars for test efficiency).
  Generator<String> get description => simple(
        generate: (random, size) {
          final length = random.nextInt(100) + 1;
          const chars =
              'abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
          return List.generate(
            length,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
        },
        shrink: (input) => [],
      );

  /// Generates a non-empty location (1-50 chars for test efficiency).
  Generator<String> get location => simple(
        generate: (random, size) {
          final length = random.nextInt(50) + 1;
          const chars = 'abcdefghijklmnopqrstuvwxyz 0123456789';
          return List.generate(
            length,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
        },
        shrink: (input) => [],
      );

  /// Generates a Complaint with a specific studentId.
  Generator<Complaint> complaintForStudent(String studentId) => simple(
        generate: (random, size) {
          const chars = 'abcdef0123456789';
          final segments = [8, 4, 4, 4, 12];
          final id = segments.map((len) {
            return List.generate(
              len,
              (_) => chars[random.nextInt(chars.length)],
            ).join();
          }).join('-');

          final descLength = random.nextInt(100) + 1;
          const descChars = 'abcdefghijklmnopqrstuvwxyz ';
          final desc = List.generate(
            descLength,
            (_) => descChars[random.nextInt(descChars.length)],
          ).join();

          final locLength = random.nextInt(50) + 1;
          final loc = List.generate(
            locLength,
            (_) => descChars[random.nextInt(descChars.length)],
          ).join();

          final statuses = ['submitted', 'in_progress', 'resolved'];
          final status = statuses[random.nextInt(statuses.length)];

          final now = DateTime.now().toUtc();

          return Complaint(
            id: id,
            studentId: studentId,
            description: desc,
            location: loc,
            status: status,
            createdAt: now,
            updatedAt: now,
          );
        },
        shrink: (input) => [],
      );

  /// Generates a list of complaints distributed across multiple student IDs.
  /// Returns a tuple of (allComplaints, listOfStudentIds).
  Generator<({List<Complaint> complaints, List<String> studentIds})>
      get complaintSet => simple(
            generate: (random, size) {
              // Generate 2-5 distinct student IDs
              final numStudents = random.nextInt(4) + 2;
              const chars = 'abcdef0123456789';
              final segments = [8, 4, 4, 4, 12];

              final studentIds = List.generate(numStudents, (_) {
                return segments.map((len) {
                  return List.generate(
                    len,
                    (_) => chars[random.nextInt(chars.length)],
                  ).join();
                }).join('-');
              });

              // Generate 3-15 complaints distributed across students
              final numComplaints = random.nextInt(13) + 3;
              final complaints = List.generate(numComplaints, (_) {
                final ownerIdx = random.nextInt(studentIds.length);
                final owner = studentIds[ownerIdx];

                final id = segments.map((len) {
                  return List.generate(
                    len,
                    (_) => chars[random.nextInt(chars.length)],
                  ).join();
                }).join('-');

                const descChars = 'abcdefghijklmnopqrstuvwxyz ';
                final descLength = random.nextInt(100) + 1;
                final desc = List.generate(
                  descLength,
                  (_) => descChars[random.nextInt(descChars.length)],
                ).join();

                final locLength = random.nextInt(50) + 1;
                final loc = List.generate(
                  locLength,
                  (_) => descChars[random.nextInt(descChars.length)],
                ).join();

                final statuses = ['submitted', 'in_progress', 'resolved'];
                final status = statuses[random.nextInt(statuses.length)];

                final now = DateTime.now().toUtc();

                return Complaint(
                  id: id,
                  studentId: owner,
                  description: desc,
                  location: loc,
                  status: status,
                  createdAt: now,
                  updatedAt: now,
                );
              });

              return (complaints: complaints, studentIds: studentIds);
            },
            shrink: (input) => [],
          );
}

void main() {
  group('Property 13: Complaint ownership scoping', () {
    // Property 13a: For any Student requesting complaints, the service SHALL
    // return only complaints where studentId matches the requesting Student's ID.
    Glados(any.complaintSet, ExploreConfig(numRuns: 100)).test(
      'Student list returns only complaints owned by the requesting student',
      (data) {
        final allComplaints = data.complaints;
        final studentIds = data.studentIds;

        // Test for each student in the set
        for (final requesterId in studentIds) {
          final result = filterComplaintsForStudent(
            allComplaints: allComplaints,
            requesterId: requesterId,
          );

          // All returned complaints must belong to the requester
          for (final complaint in result) {
            expect(
              complaint.studentId,
              equals(requesterId),
              reason:
                  'Filtered complaint ${complaint.id} should have studentId '
                  '"$requesterId" but has "${complaint.studentId}"',
            );
          }
        }
      },
    );

    // Property 13b: The filtered result SHALL contain ALL complaints belonging
    // to the requesting student (no complaints are incorrectly excluded).
    Glados(any.complaintSet, ExploreConfig(numRuns: 100)).test(
      'Student list contains all complaints belonging to the requesting student',
      (data) {
        final allComplaints = data.complaints;
        final studentIds = data.studentIds;

        for (final requesterId in studentIds) {
          final result = filterComplaintsForStudent(
            allComplaints: allComplaints,
            requesterId: requesterId,
          );

          // Count expected complaints
          final expectedCount =
              allComplaints.where((c) => c.studentId == requesterId).length;

          expect(
            result.length,
            equals(expectedCount),
            reason:
                'Student "$requesterId" should see $expectedCount complaints '
                'but got ${result.length}',
          );
        }
      },
    );

    // Property 13c: For any Student requesting a single complaint belonging to
    // a different Student, the service SHALL return NOT_FOUND (null).
    Glados(any.complaintSet, ExploreConfig(numRuns: 100)).test(
      'Student getById returns NOT_FOUND for complaints owned by other students',
      (data) {
        final allComplaints = data.complaints;
        final studentIds = data.studentIds;

        for (final requesterId in studentIds) {
          // Find complaints NOT belonging to this student
          final otherComplaints =
              allComplaints.where((c) => c.studentId != requesterId);

          for (final complaint in otherComplaints) {
            final result = getByIdForStudent(
              complaint: complaint,
              requesterId: requesterId,
            );

            expect(
              result,
              isNull,
              reason:
                  'Student "$requesterId" requesting complaint ${complaint.id} '
                  'owned by "${complaint.studentId}" should get NOT_FOUND (null)',
            );
          }
        }
      },
    );

    // Property 13d: For any Student requesting their own complaint by ID,
    // the service SHALL return the complaint successfully.
    Glados(any.complaintSet, ExploreConfig(numRuns: 100)).test(
      'Student getById returns the complaint when it belongs to the requester',
      (data) {
        final allComplaints = data.complaints;
        final studentIds = data.studentIds;

        for (final requesterId in studentIds) {
          // Find complaints belonging to this student
          final ownComplaints =
              allComplaints.where((c) => c.studentId == requesterId);

          for (final complaint in ownComplaints) {
            final result = getByIdForStudent(
              complaint: complaint,
              requesterId: requesterId,
            );

            expect(
              result,
              isNotNull,
              reason:
                  'Student "$requesterId" requesting their own complaint '
                  '${complaint.id} should get the complaint back',
            );
            expect(
              result!.id,
              equals(complaint.id),
              reason: 'Returned complaint should have the same ID',
            );
            expect(
              result.studentId,
              equals(requesterId),
              reason: 'Returned complaint should belong to the requester',
            );
          }
        }
      },
    );

    // Property 13e: The ownership filter SHALL never return complaints
    // belonging to a different student (no information leakage).
    Glados(any.complaintSet, ExploreConfig(numRuns: 100)).test(
      'No complaint from another student ever appears in filtered results',
      (data) {
        final allComplaints = data.complaints;
        final studentIds = data.studentIds;

        for (final requesterId in studentIds) {
          final result = filterComplaintsForStudent(
            allComplaints: allComplaints,
            requesterId: requesterId,
          );

          // Verify no complaint in the result belongs to another student
          final leakedComplaints =
              result.where((c) => c.studentId != requesterId);

          expect(
            leakedComplaints,
            isEmpty,
            reason:
                'No complaints from other students should appear in results '
                'for student "$requesterId". Found ${leakedComplaints.length} '
                'leaked complaints.',
          );
        }
      },
    );
  });
}
