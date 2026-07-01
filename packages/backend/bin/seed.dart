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
/// - 3 Blocks (A, B, C) with rooms and beds:
///   - Block A: 3 single + 2 twin_sharing rooms
///   - Block B: 2 single + 3 twin_sharing rooms
///   - Block C: 2 single + 2 twin_sharing rooms
///   (single = 1 bed 'A', twin_sharing = 2 beds 'A'+'B')
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

  // --- Accommodation physical structure IDs ---
  const blockIds = [
    '00000000-0000-4000-d000-000000000001', // Block A
    '00000000-0000-4000-d000-000000000002', // Block B
    '00000000-0000-4000-d000-000000000003', // Block C
  ];

  // Rooms: Block A (A-101..A-105), Block B (B-101..B-105), Block C (C-101..C-104)
  const roomIds = [
    // Block A rooms
    '00000000-0000-4000-d100-000000000001', // A-101 single
    '00000000-0000-4000-d100-000000000002', // A-102 single
    '00000000-0000-4000-d100-000000000003', // A-103 single
    '00000000-0000-4000-d100-000000000004', // A-104 twin_sharing
    '00000000-0000-4000-d100-000000000005', // A-105 twin_sharing
    // Block B rooms
    '00000000-0000-4000-d100-000000000006', // B-101 single
    '00000000-0000-4000-d100-000000000007', // B-102 single
    '00000000-0000-4000-d100-000000000008', // B-103 twin_sharing
    '00000000-0000-4000-d100-000000000009', // B-104 twin_sharing
    '00000000-0000-4000-d100-00000000000a', // B-105 twin_sharing
    // Block C rooms
    '00000000-0000-4000-d100-00000000000b', // C-101 single
    '00000000-0000-4000-d100-00000000000c', // C-102 single
    '00000000-0000-4000-d100-00000000000d', // C-103 twin_sharing
    '00000000-0000-4000-d100-00000000000e', // C-104 twin_sharing
  ];

  // Beds: 1 per single room, 2 per twin_sharing room
  const bedIds = [
    // Block A single rooms (1 bed each)
    '00000000-0000-4000-d200-000000000001', // A-101 bed A
    '00000000-0000-4000-d200-000000000002', // A-102 bed A
    '00000000-0000-4000-d200-000000000003', // A-103 bed A
    // Block A twin_sharing rooms (2 beds each)
    '00000000-0000-4000-d200-000000000004', // A-104 bed A
    '00000000-0000-4000-d200-000000000005', // A-104 bed B
    '00000000-0000-4000-d200-000000000006', // A-105 bed A
    '00000000-0000-4000-d200-000000000007', // A-105 bed B
    // Block B single rooms (1 bed each)
    '00000000-0000-4000-d200-000000000008', // B-101 bed A
    '00000000-0000-4000-d200-000000000009', // B-102 bed A
    // Block B twin_sharing rooms (2 beds each)
    '00000000-0000-4000-d200-00000000000a', // B-103 bed A
    '00000000-0000-4000-d200-00000000000b', // B-103 bed B
    '00000000-0000-4000-d200-00000000000c', // B-104 bed A
    '00000000-0000-4000-d200-00000000000d', // B-104 bed B
    '00000000-0000-4000-d200-00000000000e', // B-105 bed A
    '00000000-0000-4000-d200-00000000000f', // B-105 bed B
    // Block C single rooms (1 bed each)
    '00000000-0000-4000-d200-000000000010', // C-101 bed A
    '00000000-0000-4000-d200-000000000011', // C-102 bed A
    // Block C twin_sharing rooms (2 beds each)
    '00000000-0000-4000-d200-000000000012', // C-103 bed A
    '00000000-0000-4000-d200-000000000013', // C-103 bed B
    '00000000-0000-4000-d200-000000000014', // C-104 bed A
    '00000000-0000-4000-d200-000000000015', // C-104 bed B
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

    // --- Seed Blocks ---
    print('  Creating accommodation blocks...');
    await connection.execute(
      Sql.named(
        'INSERT INTO blocks (id, name) VALUES '
        "(@id1, 'Block A'), "
        "(@id2, 'Block B'), "
        "(@id3, 'Block C') "
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id1': blockIds[0],
        'id2': blockIds[1],
        'id3': blockIds[2],
      },
    );

    // --- Seed Rooms ---
    print('  Creating rooms...');
    // Room data: [id, block_id, room_number, room_type]
    final rooms = [
      // Block A: 3 single + 2 twin_sharing
      [roomIds[0], blockIds[0], 'A-101', 'single'],
      [roomIds[1], blockIds[0], 'A-102', 'single'],
      [roomIds[2], blockIds[0], 'A-103', 'single'],
      [roomIds[3], blockIds[0], 'A-104', 'twin_sharing'],
      [roomIds[4], blockIds[0], 'A-105', 'twin_sharing'],
      // Block B: 2 single + 3 twin_sharing
      [roomIds[5], blockIds[1], 'B-101', 'single'],
      [roomIds[6], blockIds[1], 'B-102', 'single'],
      [roomIds[7], blockIds[1], 'B-103', 'twin_sharing'],
      [roomIds[8], blockIds[1], 'B-104', 'twin_sharing'],
      [roomIds[9], blockIds[1], 'B-105', 'twin_sharing'],
      // Block C: 2 single + 2 twin_sharing
      [roomIds[10], blockIds[2], 'C-101', 'single'],
      [roomIds[11], blockIds[2], 'C-102', 'single'],
      [roomIds[12], blockIds[2], 'C-103', 'twin_sharing'],
      [roomIds[13], blockIds[2], 'C-104', 'twin_sharing'],
    ];

    for (final room in rooms) {
      await connection.execute(
        Sql.named(
          'INSERT INTO rooms (id, block_id, room_number, room_type) '
          'VALUES (@id, @block_id, @room_number, @room_type) '
          'ON CONFLICT (id) DO NOTHING',
        ),
        parameters: {
          'id': room[0],
          'block_id': room[1],
          'room_number': room[2],
          'room_type': room[3],
        },
      );
    }

    // --- Seed Beds ---
    // Invariant: single rooms get 1 bed (label 'A'),
    //            twin_sharing rooms get 2 beds (labels 'A' and 'B')
    print('  Creating beds...');
    final beds = [
      // Block A single rooms — 1 bed each
      [bedIds[0], roomIds[0], 'A'],
      [bedIds[1], roomIds[1], 'A'],
      [bedIds[2], roomIds[2], 'A'],
      // Block A twin_sharing rooms — 2 beds each
      [bedIds[3], roomIds[3], 'A'],
      [bedIds[4], roomIds[3], 'B'],
      [bedIds[5], roomIds[4], 'A'],
      [bedIds[6], roomIds[4], 'B'],
      // Block B single rooms — 1 bed each
      [bedIds[7], roomIds[5], 'A'],
      [bedIds[8], roomIds[6], 'A'],
      // Block B twin_sharing rooms — 2 beds each
      [bedIds[9], roomIds[7], 'A'],
      [bedIds[10], roomIds[7], 'B'],
      [bedIds[11], roomIds[8], 'A'],
      [bedIds[12], roomIds[8], 'B'],
      [bedIds[13], roomIds[9], 'A'],
      [bedIds[14], roomIds[9], 'B'],
      // Block C single rooms — 1 bed each
      [bedIds[15], roomIds[10], 'A'],
      [bedIds[16], roomIds[11], 'A'],
      // Block C twin_sharing rooms — 2 beds each
      [bedIds[17], roomIds[12], 'A'],
      [bedIds[18], roomIds[12], 'B'],
      [bedIds[19], roomIds[13], 'A'],
      [bedIds[20], roomIds[13], 'B'],
    ];

    for (final bed in beds) {
      await connection.execute(
        Sql.named(
          'INSERT INTO beds (id, room_id, bed_label) '
          'VALUES (@id, @room_id, @bed_label) '
          'ON CONFLICT (id) DO NOTHING',
        ),
        parameters: {
          'id': bed[0],
          'room_id': bed[1],
          'bed_label': bed[2],
        },
      );
    }

    // --- Seed Facilities ---
    print('  Creating facilities...');
    const facilityIds = [
      '00000000-0000-4000-e000-000000000001', // Badminton (auto)
      '00000000-0000-4000-e000-000000000002', // Futsal (manual)
      '00000000-0000-4000-e000-000000000003', // Study Room (auto)
    ];
    await connection.execute(
      Sql.named(
        'INSERT INTO facilities (id, name, description, approval_mode, capacity) VALUES '
        "(@id1, 'Badminton Court', 'Indoor court', 'auto', 4), "
        "(@id2, 'Futsal Court', 'Outdoor futsal', 'manual', 10), "
        "(@id3, 'Study Room', 'Quiet study room', 'auto', 6) "
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id1': facilityIds[0],
        'id2': facilityIds[1],
        'id3': facilityIds[2],
      },
    );

    // --- Seed Slot Configs (2 per facility, non-overlapping) ---
    print('  Creating facility slot configs...');
    const slotIds = [
      '00000000-0000-4000-e100-000000000001',
      '00000000-0000-4000-e100-000000000002',
      '00000000-0000-4000-e100-000000000003',
      '00000000-0000-4000-e100-000000000004',
      '00000000-0000-4000-e100-000000000005',
      '00000000-0000-4000-e100-000000000006',
    ];
    final slots = [
      [slotIds[0], facilityIds[0], '08:00', '10:00'],
      [slotIds[1], facilityIds[0], '10:00', '12:00'],
      [slotIds[2], facilityIds[1], '16:00', '18:00'],
      [slotIds[3], facilityIds[1], '18:00', '20:00'],
      [slotIds[4], facilityIds[2], '09:00', '11:00'],
      [slotIds[5], facilityIds[2], '14:00', '16:00'],
    ];
    for (final s in slots) {
      await connection.execute(
        Sql.named(
          'INSERT INTO facility_slot_configs (id, facility_id, start_time, end_time) '
          'VALUES (@id, @fid, @st::time, @et::time) ON CONFLICT (id) DO NOTHING',
        ),
        parameters: {'id': s[0], 'fid': s[1], 'st': s[2], 'et': s[3]},
      );
    }

    // --- Seed Bookings (mixed statuses across facilities/dates) ---
    print('  Creating bookings...');
    const bookingIds = [
      '00000000-0000-4000-e200-000000000001',
      '00000000-0000-4000-e200-000000000002',
      '00000000-0000-4000-e200-000000000003',
      '00000000-0000-4000-e200-000000000004',
      '00000000-0000-4000-e200-000000000005',
    ];
    // [id, ref, student, facility, slot, dateOffsetDays, status]
    final bookings = [
      [bookingIds[0], 'BK-SEED-0001', studentIds[0], facilityIds[0], slotIds[0], 2, 'confirmed'],
      [bookingIds[1], 'BK-SEED-0002', studentIds[1], facilityIds[1], slotIds[2], 1, 'pending'],
      [bookingIds[2], 'BK-SEED-0003', studentIds[2], facilityIds[2], slotIds[4], -3, 'completed'],
      [bookingIds[3], 'BK-SEED-0004', studentIds[0], facilityIds[1], slotIds[3], -1, 'no_show'],
      [bookingIds[4], 'BK-SEED-0005', studentIds[1], facilityIds[2], slotIds[5], -5, 'cancelled'],
    ];
    for (final b in bookings) {
      await connection.execute(
        Sql.named(
          'INSERT INTO bookings '
          '(id, booking_reference, student_id, facility_id, slot_config_id, booking_date, status) '
          'VALUES (@id, @ref, @sid, @fid, @slot, CURRENT_DATE + @off, @status) '
          'ON CONFLICT (id) DO NOTHING',
        ),
        parameters: {
          'id': b[0], 'ref': b[1], 'sid': b[2], 'fid': b[3],
          'slot': b[4], 'off': b[5], 'status': b[6],
        },
      );
    }

    // --- Seed Accommodation Applications (mixed statuses) ---
    // status enum: submitted | approved | checked_in | checked_out | rejected
    print('  Creating accommodation applications...');
    const appIds = [
      '00000000-0000-4000-e300-000000000001',
      '00000000-0000-4000-e300-000000000002',
      '00000000-0000-4000-e300-000000000003',
    ];
    // Application 1: submitted (semester, no assignment)
    await connection.execute(
      Sql.named(
        'INSERT INTO accommodation_applications '
        '(id, student_id, application_type, status, room_type_preference, preferred_block_id, lifestyle_tags) '
        "VALUES (@id, @sid, 'semester', 'submitted', 'single', @block, ARRAY['non_smoker','early_sleeper']) "
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {'id': appIds[0], 'sid': studentIds[0], 'block': blockIds[0]},
    );
    // Application 2: approved with bed assignment (bed A-101 -> bedIds[0])
    await connection.execute(
      Sql.named(
        'INSERT INTO accommodation_applications '
        '(id, student_id, application_type, status, room_type_preference, '
        ' assigned_block_id, assigned_room_id, assigned_bed_id) '
        "VALUES (@id, @sid, 'semester', 'approved', 'single', @block, @room, @bed) "
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id': appIds[1],
        'sid': studentIds[1],
        'block': blockIds[0],
        'room': roomIds[0],
        'bed': bedIds[0],
      },
    );
    // Mark that bed occupied so occupancy shows 1/1 for A-101
    await connection.execute(
      Sql.named("UPDATE beds SET is_occupied = TRUE WHERE id = @bed"),
      parameters: {'bed': bedIds[0]},
    );
    // Application 3: rejected (out_of_semester)
    await connection.execute(
      Sql.named(
        'INSERT INTO accommodation_applications '
        '(id, student_id, application_type, status, check_in_date, check_out_date, '
        ' nightly_rate, total_cost, rejection_reason) '
        "VALUES (@id, @sid, 'out_of_semester', 'rejected', CURRENT_DATE + 5, CURRENT_DATE + 12, "
        ' 25.00, 175.00, @reason) '
        'ON CONFLICT (id) DO NOTHING',
      ),
      parameters: {
        'id': appIds[2],
        'sid': studentIds[2],
        'reason': 'Out-of-semester window is currently closed.',
      },
    );

    print('✅ Seed completed successfully!');
    print('   - 3 Students (A123456, A234567, A345678)');
    print('   - 2 Admins (S98765, S87654)');
    print('   - 5 Announcements');
    print('   - 4 Complaints (2 submitted, 1 in_progress, 1 resolved)');
    print('   - 3 Blocks (A, B, C) with 14 rooms and 21 beds');
    print('   - 3 Facilities, 6 slot configs, 5 bookings');
    print('   - 3 Accommodation applications (submitted/approved/rejected)');
    print('   Password for all accounts: password123');
  } catch (e, st) {
    print('❌ Seed failed: $e');
    print(st);
    exitCode = 1;
  } finally {
    await connection.close();
  }
}
