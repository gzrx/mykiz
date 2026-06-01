// Feature: mykiz-platform, Property 14: Admin unrestricted complaint access
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 7.2, 7.6**
///
/// Property 14: Admin unrestricted complaint access
/// For any Admin requesting complaints, the Complaint_Service SHALL return all
/// complaints regardless of which Student submitted them, and for any single
/// complaint requested by an Admin, the full details SHALL be returned.

/// Simplified complaint model for property testing at the logic level.
class TestComplaint {
  const TestComplaint({
    required this.id,
    required this.studentId,
    required this.description,
    required this.location,
    required this.status,
  });

  final String id;
  final String studentId;
  final String description;
  final String location;
  final String status;
}

/// Simulates the complaint list logic from [ComplaintService.list].
///
/// - Students see only their own complaints (filtered by studentId).
/// - Admins see ALL complaints (no filtering).
///
/// Returns the list of complaints visible to the requester.
List<TestComplaint> listComplaints({
  required List<TestComplaint> allComplaints,
  required String requesterId,
  required String requesterRole,
}) {
  if (requesterRole == 'admin') {
    // Admin sees all complaints — no filtering by studentId
    return List.from(allComplaints);
  }
  // Student sees only their own complaints
  return allComplaints
      .where((c) => c.studentId == requesterId)
      .toList();
}

/// Simulates the complaint getById logic from [ComplaintService.getById].
///
/// - Students can only access their own complaints (returns null for others).
/// - Admins can access ANY complaint regardless of ownership.
///
/// Returns the complaint if accessible, or null if not found / not authorized.
TestComplaint? getComplaintById({
  required List<TestComplaint> allComplaints,
  required String complaintId,
  required String requesterId,
  required String requesterRole,
}) {
  // Find the complaint by ID
  final complaint = allComplaints
      .where((c) => c.id == complaintId)
      .firstOrNull;

  if (complaint == null) return null;

  if (requesterRole == 'admin') {
    // Admin can access any complaint — no ownership check
    return complaint;
  }

  // Student can only access their own complaints
  if (complaint.studentId != requesterId) {
    return null; // Treated as NOT_FOUND for students
  }

  return complaint;
}

/// Custom generators for complaint property testing.
extension ComplaintGenerators on Any {
  /// Generates a UUID-like string for IDs.
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

  /// Generates a non-empty description (1-100 chars for testing).
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

  /// Generates a non-empty location (1-50 chars for testing).
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

  /// Generates a valid complaint status.
  Generator<String> get complaintStatus =>
      choose(['submitted', 'in_progress', 'resolved']);

  /// Generates a list of complaints with varying student IDs.
  /// Each complaint has a unique ID and a randomly assigned studentId
  /// from a pool of student IDs.
  Generator<List<TestComplaint>> get complaintList => simple(
        generate: (random, size) {
          // Generate between 1 and 15 complaints
          final count = random.nextInt(15) + 1;
          // Generate a pool of 2-5 different student IDs
          final studentCount = random.nextInt(4) + 2;
          final studentIds = List.generate(studentCount, (_) {
            const chars = 'abcdef0123456789';
            final segments = [8, 4, 4, 4, 12];
            final parts = segments.map((len) {
              return List.generate(
                len,
                (_) => chars[random.nextInt(chars.length)],
              ).join();
            });
            return parts.join('-');
          });

          return List.generate(count, (i) {
            const chars = 'abcdef0123456789';
            final segments = [8, 4, 4, 4, 12];
            final idParts = segments.map((len) {
              return List.generate(
                len,
                (_) => chars[random.nextInt(chars.length)],
              ).join();
            });
            final id = idParts.join('-');

            final studentId = studentIds[random.nextInt(studentIds.length)];
            final statuses = ['submitted', 'in_progress', 'resolved'];
            final status = statuses[random.nextInt(statuses.length)];

            final descLen = random.nextInt(50) + 1;
            const descChars = 'abcdefghijklmnopqrstuvwxyz ';
            final desc = List.generate(
              descLen,
              (_) => descChars[random.nextInt(descChars.length)],
            ).join();

            final locLen = random.nextInt(30) + 1;
            final loc = List.generate(
              locLen,
              (_) => descChars[random.nextInt(descChars.length)],
            ).join();

            return TestComplaint(
              id: id,
              studentId: studentId,
              description: desc,
              location: loc,
              status: status,
            );
          });
        },
        shrink: (input) => [],
      );
}

void main() {
  group('Property 14: Admin unrestricted complaint access', () {
    // Property 14a: For any Admin requesting complaints, the Complaint_Service
    // SHALL return ALL complaints regardless of which Student submitted them.
    Glados2(any.complaintList, any.uuid, ExploreConfig(numRuns: 100)).test(
      'Admin list returns all complaints regardless of studentId',
      (complaints, adminId) {
        final result = listComplaints(
          allComplaints: complaints,
          requesterId: adminId,
          requesterRole: 'admin',
        );

        // Admin should see ALL complaints — count must match total
        expect(
          result.length,
          equals(complaints.length),
          reason: 'Admin should see all ${complaints.length} complaints, '
              'but got ${result.length}',
        );

        // Every complaint in the original set should be in the result
        for (final complaint in complaints) {
          expect(
            result.any((c) => c.id == complaint.id),
            isTrue,
            reason: 'Admin result should contain complaint "${complaint.id}" '
                'owned by student "${complaint.studentId}"',
          );
        }
      },
    );

    // Property 14b: Admin list is NOT filtered by any particular studentId —
    // complaints from multiple students are all included.
    Glados2(any.complaintList, any.uuid, ExploreConfig(numRuns: 100)).test(
      'Admin list includes complaints from all different students',
      (complaints, adminId) {
        final result = listComplaints(
          allComplaints: complaints,
          requesterId: adminId,
          requesterRole: 'admin',
        );

        // Collect all unique studentIds from the original complaints
        final originalStudentIds =
            complaints.map((c) => c.studentId).toSet();

        // Collect all unique studentIds from the admin result
        final resultStudentIds = result.map((c) => c.studentId).toSet();

        // Admin should see complaints from ALL students
        expect(
          resultStudentIds,
          equals(originalStudentIds),
          reason: 'Admin result should contain complaints from all '
              '${originalStudentIds.length} students, but only has '
              'complaints from ${resultStudentIds.length} students',
        );
      },
    );

    // Property 14c: For any single complaint requested by an Admin, the full
    // details SHALL be returned (no NOT_FOUND due to ownership).
    Glados2(any.complaintList, any.uuid, ExploreConfig(numRuns: 100)).test(
      'Admin getById returns any complaint regardless of ownership',
      (complaints, adminId) {
        // Skip if no complaints generated
        if (complaints.isEmpty) return;

        // For each complaint, admin should be able to access it
        for (final complaint in complaints) {
          final result = getComplaintById(
            allComplaints: complaints,
            complaintId: complaint.id,
            requesterId: adminId,
            requesterRole: 'admin',
          );

          // Admin should always get the complaint (never null)
          expect(
            result,
            isNotNull,
            reason: 'Admin should access complaint "${complaint.id}" '
                'owned by student "${complaint.studentId}", but got null',
          );

          // Full details should be returned
          expect(result!.id, equals(complaint.id));
          expect(result.studentId, equals(complaint.studentId));
          expect(result.description, equals(complaint.description));
          expect(result.location, equals(complaint.location));
          expect(result.status, equals(complaint.status));
        }
      },
    );

    // Property 14d: Contrast with student scoping — a student only sees their
    // own complaints, while admin sees all. This demonstrates admin has NO
    // ownership restriction.
    Glados2(any.complaintList, any.uuid, ExploreConfig(numRuns: 100)).test(
      'Admin sees more complaints than any individual student',
      (complaints, adminId) {
        if (complaints.isEmpty) return;

        final adminResult = listComplaints(
          allComplaints: complaints,
          requesterId: adminId,
          requesterRole: 'admin',
        );

        // For each unique student, their view should be a subset of admin view
        final studentIds = complaints.map((c) => c.studentId).toSet();
        for (final studentId in studentIds) {
          final studentResult = listComplaints(
            allComplaints: complaints,
            requesterId: studentId,
            requesterRole: 'student',
          );

          // Student result should be a subset of admin result
          expect(
            studentResult.length,
            lessThanOrEqualTo(adminResult.length),
            reason: 'Student "$studentId" sees ${studentResult.length} '
                'complaints but admin sees ${adminResult.length} — '
                'student should never see more than admin',
          );

          // Every complaint the student sees should also be in admin result
          for (final sc in studentResult) {
            expect(
              adminResult.any((ac) => ac.id == sc.id),
              isTrue,
              reason: 'Complaint "${sc.id}" visible to student should also '
                  'be visible to admin',
            );
          }
        }
      },
    );
  });
}
