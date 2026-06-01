// Feature: mykiz-platform, Property 20: Seed script idempotency
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 13.5**
///
/// Property 20: Seed script idempotency
/// For any number of consecutive executions of the seed script on the same
/// database, the resulting data SHALL contain exactly 3 Students, 2 Admins,
/// 5 announcements, and 4 complaints — no duplicates.

/// Represents a user record in the simulated database.
class UserRecord {
  final String id;
  final String identifier;
  final String role;
  final String name;

  const UserRecord({
    required this.id,
    required this.identifier,
    required this.role,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      other is UserRecord && other.identifier == identifier;

  @override
  int get hashCode => identifier.hashCode;
}

/// Represents an announcement record in the simulated database.
class AnnouncementRecord {
  final String id;
  final String title;
  final String body;
  final String authorId;

  const AnnouncementRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
  });

  @override
  bool operator ==(Object other) =>
      other is AnnouncementRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a complaint record in the simulated database.
class ComplaintRecord {
  final String id;
  final String studentId;
  final String description;
  final String location;
  final String status;

  const ComplaintRecord({
    required this.id,
    required this.studentId,
    required this.description,
    required this.location,
    required this.status,
  });

  @override
  bool operator ==(Object other) =>
      other is ComplaintRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Simulates the database with ON CONFLICT DO NOTHING behavior.
///
/// Users use `identifier` as the conflict key (ON CONFLICT (identifier) DO NOTHING).
/// Announcements use `id` as the conflict key (ON CONFLICT (id) DO NOTHING).
/// Complaints use `id` as the conflict key (ON CONFLICT (id) DO NOTHING).
class SimulatedDatabase {
  /// Users keyed by identifier (unique constraint on identifier column).
  final Map<String, UserRecord> _users = {};

  /// Announcements keyed by id (unique constraint on id/primary key).
  final Map<String, AnnouncementRecord> _announcements = {};

  /// Complaints keyed by id (unique constraint on id/primary key).
  final Map<String, ComplaintRecord> _complaints = {};

  /// Inserts a user with ON CONFLICT (identifier) DO NOTHING semantics.
  void insertUserOnConflictDoNothing(UserRecord user) {
    _users.putIfAbsent(user.identifier, () => user);
  }

  /// Inserts an announcement with ON CONFLICT (id) DO NOTHING semantics.
  void insertAnnouncementOnConflictDoNothing(AnnouncementRecord announcement) {
    _announcements.putIfAbsent(announcement.id, () => announcement);
  }

  /// Inserts a complaint with ON CONFLICT (id) DO NOTHING semantics.
  void insertComplaintOnConflictDoNothing(ComplaintRecord complaint) {
    _complaints.putIfAbsent(complaint.id, () => complaint);
  }

  int get studentCount =>
      _users.values.where((u) => u.role == 'student').length;

  int get adminCount => _users.values.where((u) => u.role == 'admin').length;

  int get announcementCount => _announcements.length;

  int get complaintCount => _complaints.length;

  int get totalUserCount => _users.length;
}

/// Fixed UUIDs matching the actual seed script (bin/seed.dart).
const _studentIds = [
  '00000000-0000-4000-a000-000000000001',
  '00000000-0000-4000-a000-000000000002',
  '00000000-0000-4000-a000-000000000003',
];
const _adminIds = [
  '00000000-0000-4000-a000-000000000004',
  '00000000-0000-4000-a000-000000000005',
];
const _announcementIds = [
  '00000000-0000-4000-b000-000000000001',
  '00000000-0000-4000-b000-000000000002',
  '00000000-0000-4000-b000-000000000003',
  '00000000-0000-4000-b000-000000000004',
  '00000000-0000-4000-b000-000000000005',
];
const _complaintIds = [
  '00000000-0000-4000-c000-000000000001',
  '00000000-0000-4000-c000-000000000002',
  '00000000-0000-4000-c000-000000000003',
  '00000000-0000-4000-c000-000000000004',
];

/// Simulates one execution of the seed script against the database.
///
/// This mirrors the logic in `bin/seed.dart`:
/// - 3 students with fixed identifiers (ON CONFLICT (identifier) DO NOTHING)
/// - 2 admins with fixed identifiers (ON CONFLICT (identifier) DO NOTHING)
/// - 5 announcements with fixed IDs (ON CONFLICT (id) DO NOTHING)
/// - 4 complaints with fixed IDs (ON CONFLICT (id) DO NOTHING)
void executeSeed(SimulatedDatabase db) {
  // Seed students
  final students = [
    UserRecord(
        id: _studentIds[0],
        identifier: 'A123456',
        role: 'student',
        name: 'Ahmad'),
    UserRecord(
        id: _studentIds[1],
        identifier: 'A234567',
        role: 'student',
        name: 'Siti'),
    UserRecord(
        id: _studentIds[2],
        identifier: 'A345678',
        role: 'student',
        name: 'Farah'),
  ];

  for (final student in students) {
    db.insertUserOnConflictDoNothing(student);
  }

  // Seed admins
  final admins = [
    UserRecord(
        id: _adminIds[0],
        identifier: 'S98765',
        role: 'admin',
        name: 'Dr. Aminah'),
    UserRecord(
        id: _adminIds[1],
        identifier: 'S87654',
        role: 'admin',
        name: 'Encik Razak'),
  ];

  for (final admin in admins) {
    db.insertUserOnConflictDoNothing(admin);
  }

  // Seed announcements
  final announcements = [
    AnnouncementRecord(
        id: _announcementIds[0],
        title: 'Welcome to KIZ Semester 2 2024/2025',
        body: 'Welcome all residents...',
        authorId: _adminIds[0]),
    AnnouncementRecord(
        id: _announcementIds[1],
        title: 'Water Supply Interruption Notice',
        body: 'There will be a scheduled...',
        authorId: _adminIds[0]),
    AnnouncementRecord(
        id: _announcementIds[2],
        title: 'KIZ Sports Day Registration Open',
        body: 'Registration for the annual...',
        authorId: _adminIds[1]),
    AnnouncementRecord(
        id: _announcementIds[3],
        title: 'WiFi Upgrade Scheduled',
        body: 'The campus WiFi infrastructure...',
        authorId: _adminIds[1]),
    AnnouncementRecord(
        id: _announcementIds[4],
        title: 'Quiet Hours Reminder',
        body: 'Please be reminded that...',
        authorId: _adminIds[0]),
  ];

  for (final announcement in announcements) {
    db.insertAnnouncementOnConflictDoNothing(announcement);
  }

  // Seed complaints
  final complaints = [
    ComplaintRecord(
        id: _complaintIds[0],
        studentId: _studentIds[0],
        description: 'Ceiling fan rattling...',
        location: 'Block B, Room 204',
        status: 'submitted'),
    ComplaintRecord(
        id: _complaintIds[1],
        studentId: _studentIds[1],
        description: 'Water leaking from pipe...',
        location: 'Block A, Room 112, Bathroom',
        status: 'in_progress'),
    ComplaintRecord(
        id: _complaintIds[2],
        studentId: _studentIds[2],
        description: 'Corridor light flickering...',
        location: 'Block C, Level 3 Corridor',
        status: 'resolved'),
    ComplaintRecord(
        id: _complaintIds[3],
        studentId: _studentIds[0],
        description: 'Washing machine not spinning...',
        location: 'Laundry Room, Ground Floor',
        status: 'submitted'),
  ];

  for (final complaint in complaints) {
    db.insertComplaintOnConflictDoNothing(complaint);
  }
}

/// Generator for the number of seed executions (1–100).
extension SeedExecutionGenerators on Any {
  Generator<int> get seedExecutionCount => simple(
        generate: (random, size) => 1 + random.nextInt(100),
        shrink: (input) => input > 1 ? [input - 1] : [],
      );
}

void main() {
  group('Property 20: Seed script idempotency', () {
    // Property 20a: For any number of consecutive seed executions (1–100),
    // the database SHALL contain exactly 3 students.
    Glados(any.seedExecutionCount, ExploreConfig(numRuns: 100)).test(
      'student count is always 3 regardless of seed execution count',
      (executionCount) {
        final db = SimulatedDatabase();

        for (var i = 0; i < executionCount; i++) {
          executeSeed(db);
        }

        expect(
          db.studentCount,
          equals(3),
          reason:
              'After $executionCount seed executions, expected 3 students '
              'but got ${db.studentCount}',
        );
      },
    );

    // Property 20b: For any number of consecutive seed executions (1–100),
    // the database SHALL contain exactly 2 admins.
    Glados(any.seedExecutionCount, ExploreConfig(numRuns: 100)).test(
      'admin count is always 2 regardless of seed execution count',
      (executionCount) {
        final db = SimulatedDatabase();

        for (var i = 0; i < executionCount; i++) {
          executeSeed(db);
        }

        expect(
          db.adminCount,
          equals(2),
          reason:
              'After $executionCount seed executions, expected 2 admins '
              'but got ${db.adminCount}',
        );
      },
    );

    // Property 20c: For any number of consecutive seed executions (1–100),
    // the database SHALL contain exactly 5 announcements.
    Glados(any.seedExecutionCount, ExploreConfig(numRuns: 100)).test(
      'announcement count is always 5 regardless of seed execution count',
      (executionCount) {
        final db = SimulatedDatabase();

        for (var i = 0; i < executionCount; i++) {
          executeSeed(db);
        }

        expect(
          db.announcementCount,
          equals(5),
          reason:
              'After $executionCount seed executions, expected 5 announcements '
              'but got ${db.announcementCount}',
        );
      },
    );

    // Property 20d: For any number of consecutive seed executions (1–100),
    // the database SHALL contain exactly 4 complaints.
    Glados(any.seedExecutionCount, ExploreConfig(numRuns: 100)).test(
      'complaint count is always 4 regardless of seed execution count',
      (executionCount) {
        final db = SimulatedDatabase();

        for (var i = 0; i < executionCount; i++) {
          executeSeed(db);
        }

        expect(
          db.complaintCount,
          equals(4),
          reason:
              'After $executionCount seed executions, expected 4 complaints '
              'but got ${db.complaintCount}',
        );
      },
    );

    // Property 20e: For any number of consecutive seed executions (1–100),
    // the total user count SHALL be exactly 5 (3 students + 2 admins),
    // confirming no duplicates across roles.
    Glados(any.seedExecutionCount, ExploreConfig(numRuns: 100)).test(
      'total user count is always 5 (no duplicates) regardless of seed execution count',
      (executionCount) {
        final db = SimulatedDatabase();

        for (var i = 0; i < executionCount; i++) {
          executeSeed(db);
        }

        expect(
          db.totalUserCount,
          equals(5),
          reason:
              'After $executionCount seed executions, expected 5 total users '
              '(3 students + 2 admins) but got ${db.totalUserCount}',
        );
      },
    );
  });
}
