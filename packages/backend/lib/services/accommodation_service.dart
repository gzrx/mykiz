import 'package:postgres/postgres.dart';
import 'package:shared_core/shared_core.dart';
import 'package:uuid/uuid.dart';

import 'accommodation_exception.dart';
import 'database.dart';

/// Service responsible for accommodation management operations.
class AccommodationService {
  AccommodationService();

  static final _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Returns the current accommodation settings as a Map.
  /// Keys: 'applications_open' (bool), 'window_id' (String?).
  Future<Map<String, dynamic>> getSettings() async {
    final result = await Database.query(
      'SELECT key, value FROM accommodation_settings '
      "WHERE key IN ('applications_open', 'window_id')",
    );

    final settings = <String, dynamic>{};
    for (final row in result) {
      final key = row[0] as String;
      final value = row[1] as String;
      if (key == 'applications_open') {
        settings['applications_open'] = value == 'true';
      } else {
        settings[key] = value;
      }
    }

    // Defaults if not present
    settings.putIfAbsent('applications_open', () => false);
    return settings;
  }

  /// Updates the application window toggle.
  /// When opening (open=true), generates and stores a new window_id.
  Future<Map<String, dynamic>> updateSettings({required bool open}) async {
    final now = DateTime.now().toUtc();

    await Database.query(
      'INSERT INTO accommodation_settings (key, value, updated_at) '
      "VALUES ('applications_open', @value, @now) "
      'ON CONFLICT (key) DO UPDATE SET value = @value, updated_at = @now',
      parameters: {
        'value': open.toString(),
        'now': now,
      },
    );

    // When opening, generate a new window_id
    if (open) {
      final windowId = _uuid.v4();
      await Database.query(
        'INSERT INTO accommodation_settings (key, value, updated_at) '
        "VALUES ('window_id', @windowId, @now) "
        'ON CONFLICT (key) DO UPDATE SET value = @windowId, updated_at = @now',
        parameters: {
          'windowId': windowId,
          'now': now,
        },
      );
    }

    return getSettings();
  }

  // ---------------------------------------------------------------------------
  // Structure: Blocks, Rooms, Occupancy
  // ---------------------------------------------------------------------------

  /// Returns all blocks with their rooms and beds nested.
  Future<List<Block>> listBlocks() async {
    final blockRows = await Database.query(
      'SELECT id, name FROM blocks ORDER BY name',
    );

    final blocks = <Block>[];
    for (final bRow in blockRows) {
      final blockId = bRow[0] as String;
      final blockName = bRow[1] as String;

      final roomRows = await Database.query(
        'SELECT r.id, r.block_id, r.room_number, r.room_type '
        'FROM rooms r WHERE r.block_id = @blockId ORDER BY r.room_number',
        parameters: {'blockId': blockId},
      );

      final rooms = <Room>[];
      for (final rRow in roomRows) {
        final roomId = rRow[0] as String;
        final bedRows = await Database.query(
          'SELECT id, room_id, bed_label, is_occupied '
          'FROM beds WHERE room_id = @roomId ORDER BY bed_label',
          parameters: {'roomId': roomId},
        );

        final beds = bedRows
            .map((bedRow) => Bed(
                  id: bedRow[0] as String,
                  roomId: bedRow[1] as String,
                  bedLabel: bedRow[2] as String,
                  isOccupied: bedRow[3] as bool,
                ))
            .toList();

        rooms.add(Room(
          id: roomId,
          blockId: rRow[1] as String,
          roomNumber: rRow[2] as String,
          roomType: rRow[3] as String,
          beds: beds,
        ));
      }

      blocks.add(Block(id: blockId, name: blockName, rooms: rooms));
    }

    return blocks;
  }

  /// Returns rooms filtered by blockId (if provided), with nested beds.
  Future<List<Room>> listRooms({String? blockId}) async {
    final sql = StringBuffer(
      'SELECT r.id, r.block_id, r.room_number, r.room_type '
      'FROM rooms r',
    );
    final params = <String, dynamic>{};

    if (blockId != null) {
      sql.write(' WHERE r.block_id = @blockId');
      params['blockId'] = blockId;
    }
    sql.write(' ORDER BY r.room_number');

    final roomRows = await Database.query(sql.toString(), parameters: params);

    final rooms = <Room>[];
    for (final rRow in roomRows) {
      final roomId = rRow[0] as String;
      final bedRows = await Database.query(
        'SELECT id, room_id, bed_label, is_occupied '
        'FROM beds WHERE room_id = @roomId ORDER BY bed_label',
        parameters: {'roomId': roomId},
      );

      final beds = bedRows
          .map((bedRow) => Bed(
                id: bedRow[0] as String,
                roomId: bedRow[1] as String,
                bedLabel: bedRow[2] as String,
                isOccupied: bedRow[3] as bool,
              ))
          .toList();

      rooms.add(Room(
        id: roomId,
        blockId: rRow[1] as String,
        roomNumber: rRow[2] as String,
        roomType: rRow[3] as String,
        beds: beds,
      ));
    }

    return rooms;
  }

  /// Returns beds filtered by roomId (if provided).
  Future<List<Bed>> listBeds({String? roomId}) async {
    final sql = StringBuffer('SELECT id, room_id, bed_label, is_occupied FROM beds');
    final params = <String, dynamic>{};

    if (roomId != null) {
      sql.write(' WHERE room_id = @roomId');
      params['roomId'] = roomId;
    }
    sql.write(' ORDER BY bed_label');

    final rows = await Database.query(sql.toString(), parameters: params);

    return rows
        .map((row) => Bed(
              id: row[0] as String,
              roomId: row[1] as String,
              bedLabel: row[2] as String,
              isOccupied: row[3] as bool,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Application Submission
  // ---------------------------------------------------------------------------

  /// Submits a new accommodation application after validating all constraints.
  ///
  /// Checks (in order):
  /// 1. Application window must be open.
  /// 2. No active application of the same type for this student.
  /// 3. Re-application limit (max 2 per type per window).
  /// 4. Lifestyle tag validation (semester only, 1-10 valid tags).
  /// 5. Date validation (out_of_semester only).
  /// 6. Cost calculation (out_of_semester only).
  Future<AccommodationApplication> submitApplication({
    required String studentId,
    required String applicationType,
    String? roomTypePreference,
    String? preferredBlockId,
    List<String>? lifestyleTags,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) async {
    // 1. Check window is open
    final settingsRows = await Database.query(
      "SELECT value FROM accommodation_settings WHERE key = 'applications_open'",
    );
    final isOpen = settingsRows.isNotEmpty && settingsRows.first[0] == 'true';
    if (!isOpen) {
      throw const AccommodationException.windowClosed();
    }

    // Get current window_id
    final windowRows = await Database.query(
      "SELECT value FROM accommodation_settings WHERE key = 'window_id'",
    );
    final windowId =
        windowRows.isNotEmpty ? windowRows.first[0] as String : null;

    // 2. Check active constraint (same student + same type)
    final activeRows = await Database.query(
      'SELECT id FROM accommodation_applications '
      'WHERE student_id = @studentId '
      'AND application_type = @type '
      "AND status IN ('submitted', 'approved', 'checked_in') "
      'LIMIT 1',
      parameters: {'studentId': studentId, 'type': applicationType},
    );
    if (activeRows.isNotEmpty) {
      throw const AccommodationException.activeApplicationExists();
    }

    // 3. Check re-application limit (max 2 per type per window)
    if (windowId != null) {
      final countRows = await Database.query(
        'SELECT COUNT(*) FROM accommodation_applications '
        'WHERE student_id = @studentId '
        'AND application_type = @type '
        'AND window_id = @windowId',
        parameters: {
          'studentId': studentId,
          'type': applicationType,
          'windowId': windowId,
        },
      );
      final count = countRows.first[0] as int;
      if (count >= 2) {
        throw const AccommodationException.reapplicationLimit();
      }
    }

    // Type-specific validation
    double? nightlyRate;
    double? totalCost;

    if (applicationType == 'semester') {
      // 4. Validate lifestyle tags (1-10, all valid enum values)
      final tags = lifestyleTags ?? [];
      if (tags.isEmpty || tags.length > 10) {
        throw const AccommodationException.validationError(
          message:
              'Lifestyle tags must contain between 1 and 10 tags.',
        );
      }
      for (final tag in tags) {
        if (LifestyleTag.fromDbValue(tag) == null) {
          throw AccommodationException.validationError(
            message: 'Invalid lifestyle tag: $tag',
          );
        }
      }
    } else if (applicationType == 'out_of_semester') {
      // 5. Validate dates
      if (checkInDate == null || checkOutDate == null) {
        throw const AccommodationException.validationError(
          message: 'Check-in and check-out dates are required.',
        );
      }
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final checkIn =
          DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
      final checkOut =
          DateTime(checkOutDate.year, checkOutDate.month, checkOutDate.day);

      if (checkIn.isBefore(todayDate)) {
        throw const AccommodationException.validationError(
          message: 'Check-in date must be today or a future date.',
        );
      }
      if (!checkOut.isAfter(checkIn)) {
        throw const AccommodationException.validationError(
          message: 'Check-out date must be after check-in date.',
        );
      }
      final nights = checkOut.difference(checkIn).inDays;
      if (nights < 1 || nights > 90) {
        throw const AccommodationException.validationError(
          message: 'Stay duration must be between 1 and 90 nights.',
        );
      }

      // 6. Calculate cost
      nightlyRate = 49.00;
      totalCost = nights * 49.00;
    }

    // 7. Insert the application
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();

    await Database.query(
      'INSERT INTO accommodation_applications '
      '(id, student_id, application_type, status, '
      'room_type_preference, preferred_block_id, lifestyle_tags, '
      'check_in_date, check_out_date, nightly_rate, total_cost, '
      'window_id, created_at, updated_at) '
      'VALUES (@id, @studentId, @type, @status, '
      '@roomType, @blockId, @tags, '
      '@checkIn, @checkOut, @nightlyRate, @totalCost, '
      '@windowId, @now, @now)',
      parameters: {
        'id': id,
        'studentId': studentId,
        'type': applicationType,
        'status': 'submitted',
        'roomType': roomTypePreference,
        'blockId': preferredBlockId,
        'tags': lifestyleTags ?? <String>[],
        'checkIn': checkInDate,
        'checkOut': checkOutDate,
        'nightlyRate': nightlyRate,
        'totalCost': totalCost,
        'windowId': windowId,
        'now': now,
      },
    );

    return AccommodationApplication(
      id: id,
      studentId: studentId,
      applicationType: applicationType,
      status: 'submitted',
      roomTypePreference: roomTypePreference,
      preferredBlockId: preferredBlockId,
      lifestyleTags: lifestyleTags ?? [],
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      nightlyRate: nightlyRate,
      totalCost: totalCost,
      windowId: windowId,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ---------------------------------------------------------------------------
  // Application Listing (Admin)
  // ---------------------------------------------------------------------------

  /// Returns a paginated, filterable list of applications for admin use.
  ///
  /// Filters:
  /// - [status]: filter by application status
  /// - [applicationType]: filter by 'semester' or 'out_of_semester'
  /// - [tags]: AND filter — only applications whose lifestyle_tags contain ALL
  ///   specified tags are returned
  ///
  /// Returns a map with 'applications' (list) and 'meta' (pagination info).
  Future<Map<String, dynamic>> listApplications({
    required int page,
    required int limit,
    String? status,
    String? applicationType,
    List<String>? tags,
  }) async {
    final where = <String>[];
    final params = <String, dynamic>{};

    if (status != null && status.isNotEmpty) {
      where.add('a.status = @status');
      params['status'] = status;
    }

    if (applicationType != null && applicationType.isNotEmpty) {
      where.add('a.application_type = @applicationType');
      params['applicationType'] = applicationType;
    }

    if (tags != null && tags.isNotEmpty) {
      // AND logic: lifestyle_tags must contain ALL provided tags
      where.add('a.lifestyle_tags @> @tags');
      params['tags'] = tags;
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    // Count query
    final countResult = await Database.query(
      'SELECT COUNT(*) FROM accommodation_applications a $whereClause',
      parameters: params,
    );
    final totalItems = countResult.first[0] as int;

    // Data query with pagination
    final offset = (page - 1) * limit;
    final dataParams = Map<String, dynamic>.from(params)
      ..['limit'] = limit
      ..['offset'] = offset;

    final rows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      '$whereClause '
      'ORDER BY a.created_at DESC '
      'LIMIT @limit OFFSET @offset',
      parameters: dataParams,
    );

    final applications = rows.map(_rowToApplication).toList();

    final totalPages = totalItems == 0 ? 1 : (totalItems / limit).ceil();

    return {
      'applications': applications,
      'meta': {
        'currentPage': page,
        'limit': limit,
        'totalItems': totalItems,
        'totalPages': totalPages,
      },
    };
  }

  // ---------------------------------------------------------------------------
  // Approval / Rejection
  // ---------------------------------------------------------------------------

  /// Approves a submitted application and atomically assigns a bed.
  ///
  /// Uses a conditional UPDATE to handle race conditions: if the bed was
  /// taken between selection and confirmation, throws BED_UNAVAILABLE.
  Future<AccommodationApplication> approveApplication(
    String id, {
    required String bedId,
  }) async {
    // 1. Fetch application
    final rows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      'WHERE a.id = @id',
      parameters: {'id': id},
    );

    if (rows.isEmpty) {
      throw const AccommodationException.notFound(
        message: 'Application not found.',
      );
    }

    final application = _rowToApplication(rows.first);

    // 2. Verify status is 'submitted'
    if (application.status != 'submitted') {
      throw AccommodationException.invalidTransition(
        message:
            'Cannot approve: application status is "${application.status}".',
      );
    }

    // 3. Fetch bed to get room_id and block_id
    final bedRows = await Database.query(
      'SELECT bed.id, bed.room_id, r.block_id '
      'FROM beds bed '
      'JOIN rooms r ON r.id = bed.room_id '
      'WHERE bed.id = @bedId',
      parameters: {'bedId': bedId},
    );

    if (bedRows.isEmpty) {
      throw const AccommodationException.notFound(
        message: 'Bed not found.',
      );
    }

    final roomId = bedRows.first[1] as String;
    final blockId = bedRows.first[2] as String;

    // 4. Transaction: conditional bed claim + application update
    final now = DateTime.now().toUtc();
    await Database.transaction((session) async {
      // 4a. Attempt to mark bed occupied (only if still free)
      final bedUpdate = await session.execute(
        Sql.named(
          'UPDATE beds SET is_occupied = TRUE '
          'WHERE id = @bedId AND is_occupied = FALSE',
        ),
        parameters: {'bedId': bedId},
      );

      // 4b. If no rows affected, bed was taken
      if (bedUpdate.affectedRows == 0) {
        throw const AccommodationException.bedUnavailable();
      }

      // 4c. Update application status and assignment fields
      await session.execute(
        Sql.named(
          'UPDATE accommodation_applications '
          "SET status = 'approved', "
          'assigned_block_id = @blockId, '
          'assigned_room_id = @roomId, '
          'assigned_bed_id = @bedId, '
          'updated_at = @now '
          'WHERE id = @id',
        ),
        parameters: {
          'blockId': blockId,
          'roomId': roomId,
          'bedId': bedId,
          'now': now,
          'id': id,
        },
      );
    });

    // 5. Return updated application with joined fields
    // Re-fetch to get joined block/room/bed names
    final updatedRows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      'WHERE a.id = @id',
      parameters: {'id': id},
    );

    return _rowToApplication(updatedRows.first);
  }

  /// Rejects a submitted application with a mandatory reason.
  ///
  /// Reason must be 1-500 non-whitespace-only characters after trimming.
  Future<AccommodationApplication> rejectApplication(
    String id, {
    required String reason,
  }) async {
    // 1. Validate reason
    final trimmed = reason.trim();
    if (trimmed.isEmpty || trimmed.length > 500) {
      throw const AccommodationException.validationError(
        message:
            'Rejection reason must be between 1 and 500 characters.',
      );
    }

    // 2. Fetch application
    final rows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      'WHERE a.id = @id',
      parameters: {'id': id},
    );

    if (rows.isEmpty) {
      throw const AccommodationException.notFound(
        message: 'Application not found.',
      );
    }

    final application = _rowToApplication(rows.first);

    // 3. Verify status is 'submitted'
    if (application.status != 'submitted') {
      throw AccommodationException.invalidTransition(
        message:
            'Cannot reject: application status is "${application.status}".',
      );
    }

    // 4. Update status and store reason
    final now = DateTime.now().toUtc();
    await Database.query(
      'UPDATE accommodation_applications '
      "SET status = 'rejected', rejection_reason = @reason, updated_at = @now "
      'WHERE id = @id',
      parameters: {'id': id, 'reason': reason, 'now': now},
    );

    // 5. Return updated application
    return application.copyWith(
      status: 'rejected',
      rejectionReason: reason,
      updatedAt: now,
    );
  }

  // ---------------------------------------------------------------------------
  // Structure: Blocks, Rooms, Occupancy
  // ---------------------------------------------------------------------------

  /// Returns rooms in a block with occupied/total bed counts.
  /// Each entry: { 'roomId', 'roomNumber', 'roomType', 'occupied', 'total' }
  Future<List<Map<String, dynamic>>> getOccupancy(String blockId) async {
    // Verify block exists
    final blockCheck = await Database.query(
      'SELECT id FROM blocks WHERE id = @blockId',
      parameters: {'blockId': blockId},
    );
    if (blockCheck.isEmpty) {
      throw const AccommodationException.notFound(
        message: 'Block not found.',
      );
    }

    final result = await Database.query(
      'SELECT r.id, r.room_number, r.room_type, '
      'COUNT(b.id) AS total_beds, '
      'COUNT(b.id) FILTER (WHERE b.is_occupied = TRUE) AS occupied_beds '
      'FROM rooms r '
      'LEFT JOIN beds b ON b.room_id = r.id '
      'WHERE r.block_id = @blockId '
      'GROUP BY r.id, r.room_number, r.room_type '
      'ORDER BY r.room_number',
      parameters: {'blockId': blockId},
    );

    return result
        .map((row) => <String, dynamic>{
              'roomId': row[0] as String,
              'roomNumber': row[1] as String,
              'roomType': row[2] as String,
              'total': row[3] as int,
              'occupied': row[4] as int,
            })
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Student Queries
  // ---------------------------------------------------------------------------

  /// Returns active applications and history for a student.
  /// Active: status in ('submitted', 'approved', 'checked_in').
  /// History: status in ('checked_out', 'rejected'), ordered by created_at DESC.
  Future<Map<String, List<AccommodationApplication>>> getStudentApplications(
    String studentId,
  ) async {
    final activeRows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      "WHERE a.student_id = @studentId AND a.status IN ('submitted', 'approved', 'checked_in')",
      parameters: {'studentId': studentId},
    );

    final historyRows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      "WHERE a.student_id = @studentId AND a.status IN ('checked_out', 'rejected') "
      'ORDER BY a.created_at DESC',
      parameters: {'studentId': studentId},
    );

    return {
      'active': activeRows.map(_rowToApplication).toList(),
      'history': historyRows.map(_rowToApplication).toList(),
    };
  }

  /// Returns a single application by id with role-scoping.
  /// Students can only view their own applications; admins can view any.
  Future<AccommodationApplication> getApplication(
    String id, {
    required String userId,
    required String role,
  }) async {
    final rows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      'WHERE a.id = @id',
      parameters: {'id': id},
    );

    if (rows.isEmpty) {
      throw const AccommodationException.notFound(
        message: 'Application not found.',
      );
    }

    final application = _rowToApplication(rows.first);

    if (role == 'student' && application.studentId != userId) {
      throw const AccommodationException.forbidden();
    }

    return application;
  }

  // ---------------------------------------------------------------------------
  // Check-In / Check-Out
  // ---------------------------------------------------------------------------

  /// UUID format regex for validation.
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Transitions an approved application to checked_in.
  ///
  /// Throws [AccommodationException] with:
  /// - NOT_FOUND if the application doesn't exist or id is invalid UUID format.
  /// - INVALID_TRANSITION if the application is not in 'approved' status.
  Future<AccommodationApplication> checkIn(String applicationId) async {
    if (!_uuidRegex.hasMatch(applicationId)) {
      throw const AccommodationException.notFound(
        message: 'Application not found.',
      );
    }

    // Fetch application with joined fields
    final rows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      'WHERE a.id = @id',
      parameters: {'id': applicationId},
    );

    if (rows.isEmpty) {
      throw const AccommodationException.notFound(
        message: 'Application not found.',
      );
    }

    final application = _rowToApplication(rows.first);

    if (application.status != 'approved') {
      throw AccommodationException.invalidTransition(
        message:
            'Cannot check in: application status is "${application.status}".',
      );
    }

    final now = DateTime.now().toUtc();
    await Database.query(
      'UPDATE accommodation_applications '
      "SET status = 'checked_in', updated_at = @now "
      'WHERE id = @id',
      parameters: {'id': applicationId, 'now': now},
    );

    return application.copyWith(status: 'checked_in', updatedAt: now);
  }

  /// Transitions a checked_in application to checked_out and releases the bed
  /// atomically in a single transaction.
  ///
  /// Throws [AccommodationException] with:
  /// - NOT_FOUND if the application doesn't exist or id is invalid UUID format.
  /// - INVALID_TRANSITION if the application is not in 'checked_in' status.
  Future<AccommodationApplication> checkOut(String applicationId) async {
    if (!_uuidRegex.hasMatch(applicationId)) {
      throw const AccommodationException.notFound(
        message: 'Application not found.',
      );
    }

    // Fetch application with joined fields
    final rows = await Database.query(
      'SELECT a.id, a.student_id, a.application_type, a.status, '
      'a.room_type_preference, a.preferred_block_id, a.lifestyle_tags, '
      'a.check_in_date, a.check_out_date, a.nightly_rate, a.total_cost, '
      'a.assigned_block_id, a.assigned_room_id, a.assigned_bed_id, '
      'a.rejection_reason, a.window_id, a.created_at, a.updated_at, '
      'b.name AS assigned_block_name, r.room_number AS assigned_room_number, '
      'bed.bed_label AS assigned_bed_label, u.name AS student_name '
      'FROM accommodation_applications a '
      'LEFT JOIN blocks b ON b.id = a.assigned_block_id '
      'LEFT JOIN rooms r ON r.id = a.assigned_room_id '
      'LEFT JOIN beds bed ON bed.id = a.assigned_bed_id '
      'LEFT JOIN users u ON u.id = a.student_id '
      'WHERE a.id = @id',
      parameters: {'id': applicationId},
    );

    if (rows.isEmpty) {
      throw const AccommodationException.notFound(
        message: 'Application not found.',
      );
    }

    final application = _rowToApplication(rows.first);

    if (application.status != 'checked_in') {
      throw AccommodationException.invalidTransition(
        message:
            'Cannot check out: application status is "${application.status}".',
      );
    }

    // Atomic: update status + release bed in one transaction
    final now = DateTime.now().toUtc();
    await Database.transaction((session) async {
      await session.execute(
        Sql.named(
          'UPDATE accommodation_applications '
          "SET status = 'checked_out', updated_at = @now "
          'WHERE id = @id',
        ),
        parameters: {'id': applicationId, 'now': now},
      );
      await session.execute(
        Sql.named(
          'UPDATE beds SET is_occupied = FALSE WHERE id = @bedId',
        ),
        parameters: {'bedId': application.assignedBedId},
      );
    });

    return application.copyWith(status: 'checked_out', updatedAt: now);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps a raw DB row (from the joined application query) to an
  /// [AccommodationApplication] instance.
  AccommodationApplication _rowToApplication(List<dynamic> row) {
    return AccommodationApplication(
      id: row[0] as String,
      studentId: row[1] as String,
      applicationType: row[2] as String,
      status: row[3] as String,
      roomTypePreference: row[4] as String?,
      preferredBlockId: row[5] as String?,
      lifestyleTags: (row[6] as List?)?.cast<String>() ?? [],
      checkInDate: row[7] != null ? row[7] as DateTime : null,
      checkOutDate: row[8] != null ? row[8] as DateTime : null,
      nightlyRate: row[9] != null ? (row[9] as num).toDouble() : null,
      totalCost: row[10] != null ? (row[10] as num).toDouble() : null,
      assignedBlockId: row[11] as String?,
      assignedRoomId: row[12] as String?,
      assignedBedId: row[13] as String?,
      rejectionReason: row[14] as String?,
      windowId: row[15] as String?,
      createdAt: row[16] as DateTime,
      updatedAt: row[17] as DateTime,
      assignedBlockName: row[18] as String?,
      assignedRoomNumber: row[19] as String?,
      assignedBedLabel: row[20] as String?,
      studentName: row[21] as String?,
    );
  }
}
