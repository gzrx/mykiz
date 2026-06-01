import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

/// Seed script for populating the database with test data.
///
/// Creates:
/// - 3 Student accounts (Matric Numbers: A123456, A234567, A345678)
/// - 2 Admin accounts (Staff IDs: S98765, S87654)
/// - 5 announcements authored by seeded Admins
/// - 4 complaints owned by seeded Students with mixed statuses
///
/// Idempotent: uses INSERT ... ON CONFLICT DO NOTHING so re-running is safe.
///
/// Run via: melos run seed
void main() async {
  print('🌱 Starting database seed...');

  // Hash password once (bcrypt cost factor 10)
  final salt = BCrypt.gensalt(logRounds: 10);
  final passwordHash = BCrypt.hashpw('password123', salt);

  // Fixed UUIDs for deterministic seeding and idempotency
  const studentIds = [
    '00000000-0000-4000-a000-000000000001',
    '00000000-0000-4000-a000-000000000002',
    '00000000-0000-4000-a000-000000000003',
  ];
  const adminIds = [
    '00000000-0000-4000-a000-000000000004',
    '00000000-0000-4000-a000-000000000005',
  ];
  const announcementIds = [
    '00000000-0000-4000-b000-000000000001',
    '00000000-0000-4000-b000-000000000002',
    '00000000-0000-4000-b000-000000000003',
    '00000000-0000-4000-b000-000000000004',
    '00000000-0000-4000-b000-000000000005',
  ];
  const complaintIds = [
    '00000000-0000-4000-c000-000000000001',
    '00000000-0000-4000-c000-000000000002',
    '00000000-0000-4000-c000-000000000003',
    '00000000-0000-4000-c000-000000000004',
  ];

  final connection = await Connection.open(
    Endpoint(
      host: Platform.environment['DB_HOST'] ?? 'localhost',
      port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
      database: Platform.environment['DB_NAME'] ?? 'mykiz',
      username: Platform.environment['DB_USER'] ?? 'mykiz',
      password: Platform.environment['DB_PASSWORD'] ?? 'mykiz_secret',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    // --- Seed Students ---
    print('  Creating student accounts...');
    await connection.execute(
      Sql.named(
        'INSERT INTO users (id, identifier, password_hash, role, name) VALUES '
        "(@id1, @ident1, @hash, 'student', @name1), "
        "(@id2, @ident2, @hash, 'student', @name2), "
        "(@id3, @ident3, @hash, 'student', @name3) "
        'ON CONFLICT (identifier) DO NOTHING',
      ),
      parameters: {
        'id1': studentIds[0],
        'ident1': 'A123456',
        'name1': 'Ahmad',
        'id2': studentIds[1],
        'ident2': 'A234567',
        'name2': 'Siti',
        'id3': studentIds[2],
        'ident3': 'A345678',
        'name3': 'Farah',
        'hash': passwordHash,
      },
    );

    // --- Seed Admins ---
    print('  Creating admin accounts...');
    await connection.execute(
      Sql.named(
        'INSERT INTO users (id, identifier, password_hash, role, name) VALUES '
        "(@id1, @ident1, @hash, 'admin', @name1), "
        "(@id2, @ident2, @hash, 'admin', @name2) "
        'ON CONFLICT (identifier) DO NOTHING',
      ),
      parameters: {
        'id1': adminIds[0],
        'ident1': 'S98765',
        'name1': 'Dr. Aminah',
        'id2': adminIds[1],
        'ident2': 'S87654',
        'name2': 'Encik Razak',
        'hash': passwordHash,
      },
    );

    // --- Seed Announcements ---
    print('  Creating announcements...');
    final announcements = [
      {
        'id': announcementIds[0],
        'title': 'Welcome to KIZ Semester 2 2024/2025',
        'body':
            'Welcome all residents to the new semester. Please ensure your '
            'room registration is complete by the end of this week.',
        'author_id': adminIds[0],
      },
      {
        'id': announcementIds[1],
        'title': 'Water Supply Interruption Notice',
        'body':
            'There will be a scheduled water supply interruption on 15 March '
            '2025 from 9:00 AM to 5:00 PM for maintenance work. Please store '
            'sufficient water beforehand.',
        'author_id': adminIds[0],
      },
      {
        'id': announcementIds[2],
        'title': 'KIZ Sports Day Registration Open',
        'body':
            'Registration for the annual KIZ Sports Day is now open. Events '
            'include badminton, futsal, and volleyball. Sign up at the office '
            'before 20 March 2025.',
        'author_id': adminIds[1],
      },
      {
        'id': announcementIds[3],
        'title': 'WiFi Upgrade Scheduled',
        'body':
            'The campus WiFi infrastructure will be upgraded next week. '
            'Expect intermittent connectivity on Monday and Tuesday. The new '
            'system will provide faster speeds across all blocks.',
        'author_id': adminIds[1],
      },
      {
        'id': announcementIds[4],
        'title': 'Quiet Hours Reminder',
        'body':
            'Please be reminded that quiet hours are from 11:00 PM to 7:00 AM '
            'daily. Residents are expected to keep noise levels low during '
            'these hours to ensure a conducive study environment.',
        'author_id': adminIds[0],
      },
    ];

    for (final ann in announcements) {
      await connection.execute(
        Sql.named(
          'INSERT INTO announcements (id, title, body, author_id) VALUES '
          '(@id, @title, @body, @author_id) '
          'ON CONFLICT (id) DO NOTHING',
        ),
        parameters: ann,
      );
    }

    // --- Seed Complaints ---
    print('  Creating complaints...');
    final complaints = [
      {
        'id': complaintIds[0],
        'student_id': studentIds[0],
        'description': 'The ceiling fan in room B-204 is making loud '
            'rattling noises and vibrates excessively when turned on.',
        'location': 'Block B, Room 204',
        'status': 'submitted',
      },
      {
        'id': complaintIds[1],
        'student_id': studentIds[1],
        'description': 'Water is leaking from the bathroom pipe under the '
            'sink. The floor gets wet and slippery.',
        'location': 'Block A, Room 112, Bathroom',
        'status': 'in_progress',
      },
      {
        'id': complaintIds[2],
        'student_id': studentIds[2],
        'description': 'The corridor light on the third floor has been '
            'flickering for two weeks and sometimes goes off completely.',
        'location': 'Block C, Level 3 Corridor',
        'status': 'resolved',
      },
      {
        'id': complaintIds[3],
        'student_id': studentIds[0],
        'description': 'The washing machine number 3 in the laundry room '
            'does not spin properly. Clothes come out still soaking wet.',
        'location': 'Laundry Room, Ground Floor',
        'status': 'submitted',
      },
    ];

    for (final complaint in complaints) {
      await connection.execute(
        Sql.named(
          'INSERT INTO complaints (id, student_id, description, location, status) '
          'VALUES (@id, @student_id, @description, @location, @status) '
          'ON CONFLICT (id) DO NOTHING',
        ),
        parameters: complaint,
      );
    }

    print('✅ Seed completed successfully!');
    print('   - 3 Students (A123456, A234567, A345678)');
    print('   - 2 Admins (S98765, S87654)');
    print('   - 5 Announcements');
    print('   - 4 Complaints (2 submitted, 1 in_progress, 1 resolved)');
    print('   Password for all accounts: password123');
  } catch (e, st) {
    print('❌ Seed failed: $e');
    print(st);
    exitCode = 1;
  } finally {
    await connection.close();
  }
}
