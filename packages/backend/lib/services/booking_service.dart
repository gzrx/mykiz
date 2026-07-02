import 'package:postgres/postgres.dart' show Time;
import 'package:shared_core/shared_core.dart';

import 'booking_exception.dart';
import 'database.dart';

/// Per-slot availability snapshot for a facility on a given date.
class SlotAvailability {
  const SlotAvailability({
    required this.slotConfigId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.booked,
    required this.available,
    required this.isBlocked,
    required this.isPast,
  });

  final String slotConfigId;
  final String startTime;
  final String endTime;
  final int capacity;
  final int booked;
  final int available;
  final bool isBlocked;
  final bool isPast;

  Map<String, dynamic> toJson() => {
        'slotConfigId': slotConfigId,
        'startTime': startTime,
        'endTime': endTime,
        'capacity': capacity,
        'booked': booked,
        'available': available,
        'isBlocked': isBlocked,
        'isPast': isPast,
      };
}

/// Summary of booking counts by status and facility for a date range.
class BookingSummary {
  const BookingSummary({required this.byStatus, required this.byFacility, required this.total});
  final Map<String, int> byStatus;
  final Map<String, int> byFacility;
  final int total;
  Map<String, dynamic> toJson() => {'byStatus': byStatus, 'byFacility': byFacility, 'total': total};
}

/// Daily utilization per facility: booked vs total capacity.
class FacilityUtilization {
  const FacilityUtilization({required this.facilityId, required this.facilityName, required this.totalCapacity, required this.booked, required this.utilizationPercent});
  final String facilityId;
  final String facilityName;
  final int totalCapacity;
  final int booked;
  final double utilizationPercent;
  Map<String, dynamic> toJson() => {'facilityId': facilityId, 'facilityName': facilityName, 'totalCapacity': totalCapacity, 'booked': booked, 'utilizationPercent': utilizationPercent};
}

/// Two time slots overlap if one starts before the other ends and vice versa.
/// Expects HH:MM strings (lexicographic comparison works for zero-padded time).
bool slotsOverlap(String startA, String endA, String startB, String endB) {
  return startA.compareTo(endB) < 0 && startB.compareTo(endA) < 0;
}

/// Service responsible for the Booking & Services module.
///
/// Follows the same static-[Database] pattern used by [ComplaintService].
class BookingService {
  const BookingService();

  // ─── Facility Management (Admin) ───────────────────────────────────────

  /// Returns all facilities ordered by name.
  Future<List<Facility>> listFacilities() async {
    final result = await Database.query(
      'SELECT id, name, description, approval_mode, is_active, capacity, '
      'grace_before_minutes, grace_after_minutes, created_at, updated_at '
      'FROM facilities ORDER BY name',
    );

    return result.map(_rowToFacility).toList();
  }

  /// Updates a facility's settings. Only non-null parameters are applied.
  ///
  /// Throws [BookingException] with:
  /// - `INVALID_GRACE_PERIOD` if grace values are out of range
  /// - `FACILITY_NOT_FOUND` (404) if the facility doesn't exist
  Future<Facility> updateFacility(
    String id, {
    bool? isActive,
    String? approvalMode,
    int? graceBeforeMinutes,
    int? graceAfterMinutes,
  }) async {
    // Validate grace periods
    if (graceBeforeMinutes != null &&
        (graceBeforeMinutes < 0 || graceBeforeMinutes > 60)) {
      throw const BookingException(
        code: 'INVALID_GRACE_PERIOD',
        message:
            'grace_before_minutes must be between 0 and 60.',
      );
    }
    if (graceAfterMinutes != null &&
        (graceAfterMinutes < 0 || graceAfterMinutes > 120)) {
      throw const BookingException(
        code: 'INVALID_GRACE_PERIOD',
        message:
            'grace_after_minutes must be between 0 and 120.',
      );
    }

    // Build dynamic SET clause
    final setClauses = <String>[];
    final params = <String, dynamic>{'id': id};

    if (isActive != null) {
      setClauses.add('is_active = @isActive');
      params['isActive'] = isActive;
    }
    if (approvalMode != null) {
      setClauses.add('approval_mode = @approvalMode');
      params['approvalMode'] = approvalMode;
    }
    if (graceBeforeMinutes != null) {
      setClauses.add('grace_before_minutes = @graceBeforeMinutes');
      params['graceBeforeMinutes'] = graceBeforeMinutes;
    }
    if (graceAfterMinutes != null) {
      setClauses.add('grace_after_minutes = @graceAfterMinutes');
      params['graceAfterMinutes'] = graceAfterMinutes;
    }

    // Always bump updated_at
    setClauses.add('updated_at = @updatedAt');
    final now = DateTime.now().toUtc();
    params['updatedAt'] = now;

    final result = await Database.query(
      'UPDATE facilities SET ${setClauses.join(', ')} '
      'WHERE id = @id '
      'RETURNING id, name, description, approval_mode, is_active, capacity, '
      'grace_before_minutes, grace_after_minutes, created_at, updated_at',
      parameters: params,
    );

    if (result.isEmpty) {
      throw const BookingException(
        code: 'FACILITY_NOT_FOUND',
        message: 'Facility not found.',
        statusCode: 404,
      );
    }

    return _rowToFacility(result.first);
  }

  // ─── Slot Config Management (Admin) ─────────────────────────────────────

  /// Adds a new time slot config for a facility.
  ///
  /// Throws [BookingException] with:
  /// - `INVALID_TIME_RANGE` if start >= end
  /// - `SLOT_OVERLAP` if new slot overlaps an existing active slot
  Future<FacilitySlotConfig> addSlotConfig({
    required String facilityId,
    required String startTime,
    required String endTime,
  }) async {
    // Validate time order
    if (startTime.compareTo(endTime) >= 0) {
      throw const BookingException(
        code: 'INVALID_TIME_RANGE',
        message: 'Start time must be before end time.',
      );
    }

    // Check overlap with existing active slots for this facility
    final existing = await Database.query(
      'SELECT start_time, end_time FROM facility_slot_configs '
      'WHERE facility_id = @facilityId AND is_active = true',
      parameters: {'facilityId': facilityId},
    );

    for (final row in existing) {
      final existStart = _formatSlotTime(row[0] as Object); // HH:MM
      final existEnd = _formatSlotTime(row[1] as Object);
      if (slotsOverlap(startTime, endTime, existStart, existEnd)) {
        throw const BookingException(
          code: 'SLOT_OVERLAP',
          message:
              'The new slot overlaps with an existing active slot for this facility.',
        );
      }
    }

    final result = await Database.query(
      'INSERT INTO facility_slot_configs (facility_id, start_time, end_time) '
      'VALUES (@facilityId, @startTime::time, @endTime::time) '
      'RETURNING id, facility_id, start_time, end_time, is_active, created_at',
      parameters: {
        'facilityId': facilityId,
        'startTime': startTime,
        'endTime': endTime,
      },
    );

    return _rowToSlotConfig(result.first);
  }

  /// Deactivates a slot config (sets is_active = false).
  ///
  /// Throws [BookingException] with `SLOT_CONFIG_NOT_FOUND` (404) if not found.
  Future<void> deactivateSlotConfig(String id) async {
    final result = await Database.query(
      'UPDATE facility_slot_configs SET is_active = false '
      'WHERE id = @id RETURNING id',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      throw const BookingException(
        code: 'SLOT_CONFIG_NOT_FOUND',
        message: 'Slot config not found.',
        statusCode: 404,
      );
    }
  }

  /// Deletes a slot config if no future confirmed bookings reference it.
  ///
  /// Throws [BookingException] with:
  /// - `SLOT_CONFIG_NOT_FOUND` (404) if not found
  /// - `SLOT_HAS_BOOKINGS` (409) if future confirmed bookings exist
  Future<void> deleteSlotConfig(String id) async {
    // Check existence
    final exists = await Database.query(
      'SELECT id FROM facility_slot_configs WHERE id = @id',
      parameters: {'id': id},
    );
    if (exists.isEmpty) {
      throw const BookingException(
        code: 'SLOT_CONFIG_NOT_FOUND',
        message: 'Slot config not found.',
        statusCode: 404,
      );
    }

    // Check for future confirmed bookings
    final bookings = await Database.query(
      'SELECT COUNT(*) FROM bookings '
      'WHERE slot_config_id = @id AND status = \'confirmed\' '
      'AND booking_date >= CURRENT_DATE',
      parameters: {'id': id},
    );
    final count = bookings.first[0] as int;
    if (count > 0) {
      throw const BookingException(
        code: 'SLOT_HAS_BOOKINGS',
        message: 'Cannot delete slot config with future confirmed bookings.',
        statusCode: 409,
      );
    }

    await Database.query(
      'DELETE FROM facility_slot_configs WHERE id = @id',
      parameters: {'id': id},
    );
  }

  // ─── Blocked Slots (Admin) ───────────────────────────────────────────────

  /// Blocks a date-slot combination.
  /// Cancels any confirmed bookings for that facility+slot_config+date.
  Future<BlockedSlot> blockSlot({
    required String facilityId,
    required String slotConfigId,
    required DateTime date,
    String? reason,
  }) async {
    // Insert blocked slot record
    final result = await Database.query(
      'INSERT INTO blocked_slots (facility_id, slot_config_id, blocked_date, reason) '
      'VALUES (@facilityId, @slotConfigId, @date, @reason) '
      'RETURNING id, facility_id, slot_config_id, blocked_date, reason, created_at',
      parameters: {
        'facilityId': facilityId,
        'slotConfigId': slotConfigId,
        'date': date,
        'reason': reason,
      },
    );

    // Cancel all confirmed bookings for that facility+slot+date
    await Database.query(
      "UPDATE bookings SET status = 'cancelled', updated_at = NOW() "
      "WHERE facility_id = @facilityId AND slot_config_id = @slotConfigId "
      "AND booking_date = @date AND status = 'confirmed'",
      parameters: {
        'facilityId': facilityId,
        'slotConfigId': slotConfigId,
        'date': date,
      },
    );

    return _rowToBlockedSlot(result.first);
  }

  /// Removes a blocked slot record, restoring availability.
  Future<void> unblockSlot(String id) async {
    final result = await Database.query(
      'DELETE FROM blocked_slots WHERE id = @id RETURNING id',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      throw const BookingException(
        code: 'SLOT_CONFIG_NOT_FOUND',
        message: 'Blocked slot not found.',
        statusCode: 404,
      );
    }
  }

  // ─── Availability ────────────────────────────────────────────────────────

  /// Returns per-slot availability for a facility on a given date.
  ///
  /// For each active slot config:
  /// - booked = count of bookings with status IN ('pending', 'confirmed')
  /// - isBlocked = blocked_slot record exists for that facility+slot+date
  /// - isPast = date < today, or (date == today AND slot startTime <= now)
  /// - available = (isBlocked || isPast) ? 0 : capacity - booked
  Future<List<SlotAvailability>> getAvailability({
    required String facilityId,
    required DateTime date,
  }) async {
    // 1. Get facility capacity
    final facResult = await Database.query(
      'SELECT capacity FROM facilities WHERE id = @id AND is_active = true',
      parameters: {'id': facilityId},
    );
    if (facResult.isEmpty) {
      throw const BookingException(
        code: 'FACILITY_NOT_FOUND',
        message: 'Facility not found or is closed.',
        statusCode: 404,
      );
    }
    final capacity = facResult.first[0] as int;

    // 2. Get active slot configs
    final slots = await Database.query(
      'SELECT id, start_time, end_time FROM facility_slot_configs '
      'WHERE facility_id = @facilityId AND is_active = true '
      'ORDER BY start_time',
      parameters: {'facilityId': facilityId},
    );

    // 3. Get booking counts per slot for this date
    final bookingCounts = await Database.query(
      'SELECT slot_config_id, COUNT(*) FROM bookings '
      'WHERE facility_id = @facilityId AND booking_date = @date '
      "AND status IN ('pending', 'confirmed') "
      'GROUP BY slot_config_id',
      parameters: {'facilityId': facilityId, 'date': date},
    );
    final countMap = <String, int>{
      for (final row in bookingCounts)
        (row[0] as String): (row[1] as int),
    };

    // 4. Get blocked slots for this date
    final blocked = await Database.query(
      'SELECT slot_config_id FROM blocked_slots '
      'WHERE facility_id = @facilityId AND blocked_date = @date',
      parameters: {'facilityId': facilityId, 'date': date},
    );
    final blockedSet = <String>{
      for (final row in blocked) row[0] as String,
    };

    // 5. Determine "now" for past-checking
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final results = <SlotAvailability>[];
    for (final row in slots) {
      final slotId = row[0] as String;
      final startTime = _formatSlotTime(row[1] as Object);
      final endTime = _formatSlotTime(row[2] as Object);

      final booked = countMap[slotId] ?? 0;
      final isBlocked = blockedSet.contains(slotId);

      // Past if date is before today, or date is today and slot start has passed
      final bool isPast;
      if (dateOnly.isBefore(today)) {
        isPast = true;
      } else if (dateOnly.isAtSameMomentAs(today)) {
        // Compare HH:MM to current time
        final parts = startTime.split(':');
        final slotStart = DateTime(
          now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]),
        );
        isPast = now.isAfter(slotStart);
      } else {
        isPast = false;
      }

      final available = (isBlocked || isPast) ? 0 : capacity - booked;

      results.add(SlotAvailability(
        slotConfigId: slotId,
        startTime: startTime,
        endTime: endTime,
        capacity: capacity,
        booked: booked,
        available: available < 0 ? 0 : available, // ponytail: clamp to 0
        isBlocked: isBlocked,
        isPast: isPast,
      ));
    }
    return results;
  }

  // ─── Student Bookings ──────────────────────────────────────────────────

  /// Submits a new booking for a student.
  ///
  /// Validates all preconditions, auto-assigns status based on facility
  /// approval_mode, generates a reference, and inserts the booking.
  Future<Booking> submitBooking({
    required String studentId,
    required String facilityId,
    required String slotConfigId,
    required DateTime date,
  }) async {
    // 1. Fetch facility
    final facResult = await Database.query(
      'SELECT id, name, description, approval_mode, is_active, capacity, '
      'grace_before_minutes, grace_after_minutes, created_at, updated_at '
      'FROM facilities WHERE id = @id',
      parameters: {'id': facilityId},
    );
    if (facResult.isEmpty) {
      throw const BookingException(
        code: 'FACILITY_NOT_FOUND',
        message: 'Facility not found.',
        statusCode: 404,
      );
    }
    final facility = _rowToFacility(facResult.first);
    if (!facility.isActive) {
      throw const BookingException(
        code: 'FACILITY_CLOSED',
        message: 'Facility is currently closed.',
      );
    }

    // 2. Verify slot config exists and belongs to this facility
    final slotResult = await Database.query(
      'SELECT id, start_time, end_time FROM facility_slot_configs '
      'WHERE id = @id AND facility_id = @facilityId AND is_active = true',
      parameters: {'id': slotConfigId, 'facilityId': facilityId},
    );
    if (slotResult.isEmpty) {
      throw const BookingException(
        code: 'SLOT_CONFIG_NOT_FOUND',
        message: 'Slot config not found for this facility.',
        statusCode: 404,
      );
    }
    final slotStartTime = _formatSlotTime(slotResult.first[1] as Object);

    // 3. Check date is not past and slot start hasn't passed today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isBefore(today)) {
      throw const BookingException(
        code: 'SLOT_IN_PAST',
        message: 'Cannot book a slot in the past.',
      );
    }
    if (dateOnly.isAtSameMomentAs(today)) {
      final parts = slotStartTime.split(':');
      final slotStart = DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      if (now.isAfter(slotStart)) {
        throw const BookingException(
          code: 'SLOT_IN_PAST',
          message: 'The slot start time has already passed today.',
        );
      }
    }

    // 4. Check date is within 14 days
    final maxDate = today.add(const Duration(days: 14));
    if (dateOnly.isAfter(maxDate)) {
      throw const BookingException(
        code: 'DATE_OUT_OF_RANGE',
        message: 'Booking date must be within 14 days from today.',
      );
    }

    // 5. Check no blocked slot
    final blockedResult = await Database.query(
      'SELECT id FROM blocked_slots '
      'WHERE facility_id = @facilityId AND slot_config_id = @slotConfigId '
      'AND blocked_date = @date',
      parameters: {
        'facilityId': facilityId,
        'slotConfigId': slotConfigId,
        'date': dateOnly,
      },
    );
    if (blockedResult.isNotEmpty) {
      throw const BookingException(
        code: 'SLOT_BLOCKED',
        message: 'This slot is blocked and unavailable.',
      );
    }

    // 6. Check capacity
    final countResult = await Database.query(
      'SELECT COUNT(*) FROM bookings '
      'WHERE facility_id = @facilityId AND slot_config_id = @slotConfigId '
      "AND booking_date = @date AND status IN ('pending', 'confirmed')",
      parameters: {
        'facilityId': facilityId,
        'slotConfigId': slotConfigId,
        'date': dateOnly,
      },
    );
    final bookedCount = countResult.first[0] as int;
    if (bookedCount >= facility.capacity) {
      throw const BookingException(
        code: 'SLOT_FULL',
        message: 'The selected time slot has reached maximum capacity.',
      );
    }

    // 7. Check no active booking for this student + facility
    final activeResult = await Database.query(
      'SELECT id FROM bookings '
      'WHERE student_id = @studentId AND facility_id = @facilityId '
      "AND status IN ('pending', 'confirmed') LIMIT 1",
      parameters: {'studentId': studentId, 'facilityId': facilityId},
    );
    if (activeResult.isNotEmpty) {
      throw const BookingException(
        code: 'ACTIVE_BOOKING_EXISTS',
        message: 'Student already has an active booking for this facility.',
        statusCode: 409,
      );
    }

    // 8. Determine status
    final status = facility.approvalMode == 'auto' ? 'confirmed' : 'pending';

    // 9. Generate reference
    final refResult = await Database.query('SELECT next_booking_reference()');
    final reference = refResult.first[0] as String;

    // 10. Insert booking
    final insertResult = await Database.query(
      'INSERT INTO bookings '
      '(booking_reference, student_id, facility_id, slot_config_id, booking_date, status) '
      'VALUES (@ref, @studentId, @facilityId, @slotConfigId, @date, @status) '
      'RETURNING id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at',
      parameters: {
        'ref': reference,
        'studentId': studentId,
        'facilityId': facilityId,
        'slotConfigId': slotConfigId,
        'date': dateOnly,
        'status': status,
      },
    );

    return _rowToBooking(insertResult.first);
  }

  /// Cancels a booking owned by the given student.
  ///
  /// Pending bookings: always cancellable.
  /// Confirmed bookings: only if > 2h before slot start.
  /// Other statuses: rejected with INVALID_BOOKING_STATUS.
  Future<Booking> cancelBooking(String bookingId, {required String studentId}) async {
    // Fetch booking + slot start_time in one query
    final result = await Database.query(
      'SELECT b.id, b.booking_reference, b.student_id, b.facility_id, '
      'b.slot_config_id, b.booking_date, b.status, b.rejection_reason, '
      'b.created_by, b.created_at, b.updated_at, s.start_time '
      'FROM bookings b '
      'JOIN facility_slot_configs s ON s.id = b.slot_config_id '
      'WHERE b.id = @id',
      parameters: {'id': bookingId},
    );

    if (result.isEmpty) {
      throw const BookingException(
        code: 'BOOKING_NOT_FOUND',
        message: 'Booking not found.',
        statusCode: 404,
      );
    }

    final row = result.first;
    final ownerStudentId = row[2] as String;
    if (ownerStudentId != studentId) {
      throw const BookingException(
        code: 'BOOKING_NOT_FOUND',
        message: 'Booking not found.',
        statusCode: 404,
      );
    }

    final status = row[6] as String;

    if (status == 'pending') {
      // Always cancellable — no time check
    } else if (status == 'confirmed') {
      // Check > 2h before slot start
      final bookingDate = row[5] as DateTime;
      final slotStartStr = _formatSlotTime(row[11] as Object); // HH:MM
      final parts = slotStartStr.split(':');
      final slotStart = DateTime(
        bookingDate.year, bookingDate.month, bookingDate.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      final now = DateTime.now();
      if (slotStart.difference(now) <= const Duration(hours: 2)) {
        throw const BookingException(
          code: 'CANCELLATION_WINDOW_PASSED',
          message: 'Cancellation must be more than 2 hours before slot start.',
        );
      }
    } else {
      throw const BookingException(
        code: 'INVALID_BOOKING_STATUS',
        message: 'Booking cannot be cancelled in its current status.',
      );
    }

    // Update status
    final updated = await Database.query(
      "UPDATE bookings SET status = 'cancelled', updated_at = NOW() "
      'WHERE id = @id '
      'RETURNING id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at',
      parameters: {'id': bookingId},
    );

    return _rowToBooking(updated.first);
  }

  // ─── Student Query Methods ────────────────────────────────────────────────

  /// Returns active bookings (pending/confirmed) for a student, ordered by date asc.
  Future<List<Booking>> listActiveBookings({required String studentId}) async {
    final result = await Database.query(
      'SELECT id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at '
      "FROM bookings WHERE student_id = @studentId AND status IN ('pending', 'confirmed') "
      'ORDER BY booking_date ASC',
      parameters: {'studentId': studentId},
    );
    return result.map(_rowToBooking).toList();
  }

  /// Returns booking history (terminal statuses) for a student, ordered by date desc, paginated.
  Future<List<Booking>> listBookingHistory({
    required String studentId,
    int page = 1,
    int limit = 20,
  }) async {
    final offset = (page - 1) * limit;
    final result = await Database.query(
      'SELECT id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at '
      "FROM bookings WHERE student_id = @studentId AND status IN ('cancelled', 'completed', 'no_show', 'rejected') "
      'ORDER BY booking_date DESC LIMIT @limit OFFSET @offset',
      parameters: {'studentId': studentId, 'limit': limit, 'offset': offset},
    );
    return result.map(_rowToBooking).toList();
  }

  // ─── Admin Bookings ─────────────────────────────────────────────────────

  /// Approves a pending booking (transitions to confirmed).
  ///
  /// If the slot has since been blocked, cancels the booking and throws
  /// [BookingException] with `SLOT_BLOCKED`.
  ///
  /// Throws:
  /// - `BOOKING_NOT_FOUND` (404) if missing
  /// - `INVALID_BOOKING_STATUS` if not pending
  /// - `SLOT_BLOCKED` if slot now blocked (also cancels the booking)
  Future<Booking> approveBooking(String bookingId) async {
    // 1. Fetch booking
    final rows = await Database.query(
      'SELECT id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at '
      'FROM bookings WHERE id = @id',
      parameters: {'id': bookingId},
    );
    if (rows.isEmpty) {
      throw const BookingException(
        code: 'BOOKING_NOT_FOUND',
        message: 'Booking not found.',
        statusCode: 404,
      );
    }
    final booking = _rowToBooking(rows.first);

    // 2. Must be pending
    if (booking.status != 'pending') {
      throw const BookingException(
        code: 'INVALID_BOOKING_STATUS',
        message: 'Only pending bookings can be approved.',
      );
    }

    // 3. Check if slot is now blocked
    final blocked = await Database.query(
      'SELECT id FROM blocked_slots '
      'WHERE facility_id = @facilityId AND slot_config_id = @slotConfigId '
      'AND blocked_date = @date',
      parameters: {
        'facilityId': booking.facilityId,
        'slotConfigId': booking.slotConfigId,
        'date': booking.bookingDate,
      },
    );
    if (blocked.isNotEmpty) {
      // Cancel the booking and throw
      await Database.query(
        "UPDATE bookings SET status = 'cancelled', updated_at = NOW() "
        'WHERE id = @id',
        parameters: {'id': bookingId},
      );
      throw const BookingException(
        code: 'SLOT_BLOCKED',
        message: 'The slot has been blocked; booking has been cancelled.',
      );
    }

    // 4. Approve
    final updated = await Database.query(
      "UPDATE bookings SET status = 'confirmed', updated_at = NOW() "
      'WHERE id = @id '
      'RETURNING id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at',
      parameters: {'id': bookingId},
    );
    return _rowToBooking(updated.first);
  }

  /// Rejects a pending booking with a reason.
  ///
  /// Throws:
  /// - `BOOKING_NOT_FOUND` (404) if missing
  /// - `INVALID_BOOKING_STATUS` if not pending
  /// - `REJECTION_REASON_REQUIRED` if reason is empty, whitespace-only, or >255 chars
  Future<Booking> rejectBooking(String bookingId, {required String reason}) async {
    // 1. Validate reason upfront
    if (reason.trim().isEmpty || reason.length > 255) {
      throw const BookingException(
        code: 'REJECTION_REASON_REQUIRED',
        message: 'A non-empty rejection reason (1-255 characters) is required.',
      );
    }

    // 2. Fetch booking
    final rows = await Database.query(
      'SELECT id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at '
      'FROM bookings WHERE id = @id',
      parameters: {'id': bookingId},
    );
    if (rows.isEmpty) {
      throw const BookingException(
        code: 'BOOKING_NOT_FOUND',
        message: 'Booking not found.',
        statusCode: 404,
      );
    }
    final booking = _rowToBooking(rows.first);

    // 3. Must be pending
    if (booking.status != 'pending') {
      throw const BookingException(
        code: 'INVALID_BOOKING_STATUS',
        message: 'Only pending bookings can be rejected.',
      );
    }

    // 4. Reject with reason
    final updated = await Database.query(
      "UPDATE bookings SET status = 'rejected', rejection_reason = @reason, "
      'updated_at = NOW() WHERE id = @id '
      'RETURNING id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at',
      parameters: {'id': bookingId, 'reason': reason},
    );
    return _rowToBooking(updated.first);
  }

  // ─── Admin Bookings ──────────────────────────────────────────────────────

  /// Creates a booking on behalf of a student (admin action).
  ///
  /// Always status = 'confirmed', bypasses approval_mode.
  /// Same capacity & active-booking-limit constraints as [submitBooking].
  Future<Booking> createManualBooking({
    required String adminId,
    required String studentId,
    required String facilityId,
    required String slotConfigId,
    required DateTime date,
  }) async {
    // 1. Verify student exists
    final studentResult = await Database.query(
      'SELECT id FROM users WHERE id = @id',
      parameters: {'id': studentId},
    );
    if (studentResult.isEmpty) {
      throw const BookingException(
        code: 'STUDENT_NOT_FOUND',
        message: 'Student not found.',
        statusCode: 404,
      );
    }

    // 2. Fetch facility
    final facResult = await Database.query(
      'SELECT id, name, description, approval_mode, is_active, capacity, '
      'grace_before_minutes, grace_after_minutes, created_at, updated_at '
      'FROM facilities WHERE id = @id',
      parameters: {'id': facilityId},
    );
    if (facResult.isEmpty) {
      throw const BookingException(
        code: 'FACILITY_NOT_FOUND',
        message: 'Facility not found.',
        statusCode: 404,
      );
    }
    final facility = _rowToFacility(facResult.first);

    // 3. Verify slot config exists and belongs to this facility
    final slotResult = await Database.query(
      'SELECT id FROM facility_slot_configs '
      'WHERE id = @id AND facility_id = @facilityId AND is_active = true',
      parameters: {'id': slotConfigId, 'facilityId': facilityId},
    );
    if (slotResult.isEmpty) {
      throw const BookingException(
        code: 'SLOT_CONFIG_NOT_FOUND',
        message: 'Slot config not found for this facility.',
        statusCode: 404,
      );
    }

    // 4. Check capacity
    final dateOnly = DateTime(date.year, date.month, date.day);
    final countResult = await Database.query(
      'SELECT COUNT(*) FROM bookings '
      'WHERE facility_id = @facilityId AND slot_config_id = @slotConfigId '
      "AND booking_date = @date AND status IN ('pending', 'confirmed')",
      parameters: {
        'facilityId': facilityId,
        'slotConfigId': slotConfigId,
        'date': dateOnly,
      },
    );
    final bookedCount = countResult.first[0] as int;
    if (bookedCount >= facility.capacity) {
      throw const BookingException(
        code: 'SLOT_FULL',
        message: 'The selected time slot has reached maximum capacity.',
      );
    }

    // 5. Check no active booking for this student + facility
    final activeResult = await Database.query(
      'SELECT id FROM bookings '
      'WHERE student_id = @studentId AND facility_id = @facilityId '
      "AND status IN ('pending', 'confirmed') LIMIT 1",
      parameters: {'studentId': studentId, 'facilityId': facilityId},
    );
    if (activeResult.isNotEmpty) {
      throw const BookingException(
        code: 'ACTIVE_BOOKING_EXISTS',
        message: 'Student already has an active booking for this facility.',
        statusCode: 409,
      );
    }

    // 6. Generate reference
    final refResult = await Database.query('SELECT next_booking_reference()');
    final reference = refResult.first[0] as String;

    // 7. Insert with status = 'confirmed', created_by = adminId
    final insertResult = await Database.query(
      'INSERT INTO bookings '
      '(booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, created_by) '
      "VALUES (@ref, @studentId, @facilityId, @slotConfigId, @date, 'confirmed', @adminId) "
      'RETURNING id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at',
      parameters: {
        'ref': reference,
        'studentId': studentId,
        'facilityId': facilityId,
        'slotConfigId': slotConfigId,
        'date': dateOnly,
        'adminId': adminId,
      },
    );

    return _rowToBooking(insertResult.first);
  }

  // ─── No-Show Processing ──────────────────────────────────────────────────

  /// Finds confirmed bookings for today whose grace window has elapsed
  /// (slot_start + facility.grace_after_minutes < now) and transitions them
  /// to `no_show`. Returns the count of updated bookings.
  Future<int> processNoShows() async {
    // Single query: find + update in one shot using a CTE.
    final result = await Database.query(
      "WITH expired AS ( "
      "  SELECT b.id FROM bookings b "
      "  JOIN facility_slot_configs fsc ON b.slot_config_id = fsc.id "
      "  JOIN facilities f ON b.facility_id = f.id "
      "  WHERE b.status = 'confirmed' "
      "    AND b.booking_date = CURRENT_DATE "
      "    AND (CURRENT_DATE + fsc.start_time + (f.grace_after_minutes || ' minutes')::interval) < NOW() "
      ") "
      "UPDATE bookings SET status = 'no_show', updated_at = NOW() "
      "FROM expired WHERE bookings.id = expired.id "
      "RETURNING bookings.id",
    );
    return result.length;
  }

  // ─── QR Check-In ──────────────────────────────────────────────────────

  /// Checks in a student by matching their confirmed booking for the
  /// given facility+date+slot, validating the grace window.
  ///
  /// Throws:
  /// - `CHECKIN_WINDOW_CLOSED` if date != today or now is outside grace window
  /// - `FACILITY_NOT_FOUND` (404) if facility missing
  /// - `SLOT_CONFIG_NOT_FOUND` (404) if slot config missing
  /// - `NO_MATCHING_BOOKING` (404) if no confirmed booking found
  Future<Booking> checkIn({
    required String studentId,
    required String facilityId,
    required String slotConfigId,
    required DateTime date,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    // 1. Date must be today
    if (!dateOnly.isAtSameMomentAs(today)) {
      throw const BookingException(
        code: 'CHECKIN_WINDOW_CLOSED',
        message: 'Check-in is only available on the booking date.',
      );
    }

    // 2. Fetch facility for grace period values
    final facResult = await Database.query(
      'SELECT id, name, description, approval_mode, is_active, capacity, '
      'grace_before_minutes, grace_after_minutes, created_at, updated_at '
      'FROM facilities WHERE id = @id',
      parameters: {'id': facilityId},
    );
    if (facResult.isEmpty) {
      throw const BookingException(
        code: 'FACILITY_NOT_FOUND',
        message: 'Facility not found.',
        statusCode: 404,
      );
    }
    final facility = _rowToFacility(facResult.first);

    // 3. Fetch slot config for start_time
    final slotResult = await Database.query(
      'SELECT id, start_time FROM facility_slot_configs '
      'WHERE id = @id AND facility_id = @facilityId',
      parameters: {'id': slotConfigId, 'facilityId': facilityId},
    );
    if (slotResult.isEmpty) {
      throw const BookingException(
        code: 'SLOT_CONFIG_NOT_FOUND',
        message: 'Slot config not found.',
        statusCode: 404,
      );
    }
    final startTimeStr = _formatSlotTime(slotResult.first[1] as Object);
    final parts = startTimeStr.split(':');
    final slotStart = DateTime(
      today.year, today.month, today.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );

    // 4. Validate grace window
    final windowStart =
        slotStart.subtract(Duration(minutes: facility.graceBeforeMinutes));
    final windowEnd =
        slotStart.add(Duration(minutes: facility.graceAfterMinutes));

    if (now.isBefore(windowStart) || now.isAfter(windowEnd)) {
      throw const BookingException(
        code: 'CHECKIN_WINDOW_CLOSED',
        message: 'Check-in is only available within the grace period window.',
      );
    }

    // 5. Find confirmed booking for student+facility+date+slot
    final bookingResult = await Database.query(
      'SELECT id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at '
      'FROM bookings '
      "WHERE student_id = @studentId AND facility_id = @facilityId "
      "AND slot_config_id = @slotConfigId AND booking_date = @date "
      "AND status = 'confirmed' LIMIT 1",
      parameters: {
        'studentId': studentId,
        'facilityId': facilityId,
        'slotConfigId': slotConfigId,
        'date': dateOnly,
      },
    );
    if (bookingResult.isEmpty) {
      throw const BookingException(
        code: 'NO_MATCHING_BOOKING',
        message: 'No confirmed booking found for this facility, date, and slot.',
        statusCode: 404,
      );
    }

    final bookingId = bookingResult.first[0] as String;

    // 6. Transition to completed
    final updated = await Database.query(
      "UPDATE bookings SET status = 'completed', updated_at = @now "
      'WHERE id = @id '
      'RETURNING id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at',
      parameters: {'id': bookingId, 'now': now.toUtc()},
    );

    return _rowToBooking(updated.first);
  }

  // ─── Admin Reports & Queries ──────────────────────────────────────────

  /// All bookings with optional filters, paginated.
  Future<List<Booking>> listAllBookings({
    String? facilityId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    final where = <String>[];
    final params = <String, dynamic>{};

    if (facilityId != null) {
      where.add('facility_id = @facilityId');
      params['facilityId'] = facilityId;
    }
    if (status != null) {
      where.add('status = @status');
      params['status'] = status;
    }
    if (fromDate != null) {
      where.add('booking_date >= @fromDate');
      params['fromDate'] = DateTime(fromDate.year, fromDate.month, fromDate.day);
    }
    if (toDate != null) {
      where.add('booking_date <= @toDate');
      params['toDate'] = DateTime(toDate.year, toDate.month, toDate.day);
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final offset = (page - 1) * limit;
    params['lim'] = limit;
    params['off'] = offset;

    final result = await Database.query(
      'SELECT id, booking_reference, student_id, facility_id, slot_config_id, '
      'booking_date, status, rejection_reason, created_by, created_at, updated_at '
      'FROM bookings $whereClause '
      'ORDER BY booking_date DESC, created_at DESC '
      'LIMIT @lim OFFSET @off',
      parameters: params,
    );

    return result.map(_rowToBooking).toList();
  }

  /// Summary of booking counts by status for a date range.
  Future<BookingSummary> getSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final to = DateTime(toDate.year, toDate.month, toDate.day);

    // By status
    final statusResult = await Database.query(
      'SELECT status, COUNT(*)::int FROM bookings '
      'WHERE booking_date >= @from AND booking_date <= @to '
      'GROUP BY status',
      parameters: {'from': from, 'to': to},
    );
    final byStatus = <String, int>{
      for (final row in statusResult) (row[0] as String): (row[1] as int),
    };

    // By facility
    final facilityResult = await Database.query(
      'SELECT facility_id, COUNT(*)::int FROM bookings '
      'WHERE booking_date >= @from AND booking_date <= @to '
      'GROUP BY facility_id',
      parameters: {'from': from, 'to': to},
    );
    final byFacility = <String, int>{
      for (final row in facilityResult) (row[0] as String): (row[1] as int),
    };

    final total = byStatus.values.fold<int>(0, (a, b) => a + b);

    return BookingSummary(byStatus: byStatus, byFacility: byFacility, total: total);
  }

  /// Daily utilization per facility: booked capacity vs total capacity.
  Future<List<FacilityUtilization>> getDailyUtilization({required DateTime date}) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    // For each facility: total_capacity = capacity * active_slot_count
    // booked = count of active bookings for that date
    final result = await Database.query(
      'SELECT f.id, f.name, f.capacity, '
      '  (SELECT COUNT(*)::int FROM facility_slot_configs fsc '
      '   WHERE fsc.facility_id = f.id AND fsc.is_active = true) AS slot_count, '
      '  (SELECT COUNT(*)::int FROM bookings b '
      "   WHERE b.facility_id = f.id AND b.booking_date = @date AND b.status IN ('pending', 'confirmed')) AS booked "
      'FROM facilities f '
      'WHERE f.is_active = true '
      'ORDER BY f.name',
      parameters: {'date': dateOnly},
    );

    return result.map((row) {
      final capacity = row[2] as int;
      final slotCount = row[3] as int;
      final booked = row[4] as int;
      final totalCapacity = capacity * slotCount;
      // ponytail: avoid division by zero
      final pct = totalCapacity > 0 ? (booked / totalCapacity) * 100 : 0.0;
      return FacilityUtilization(
        facilityId: row[0] as String,
        facilityName: row[1] as String,
        totalCapacity: totalCapacity,
        booked: booked,
        utilizationPercent: pct,
      );
    }).toList();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  /// Formats a PostgreSQL `TIME` column value to an `HH:MM` string.
  ///
  /// The postgres driver decodes `time` columns to a [Time] object (whose
  /// `toString()` is `Time(HH:MM:SS.ffffff)`), not a `String`. Casting the
  /// value directly to `String` throws and 500s the request, so accept the
  /// driver's [Time] type and fall back to raw-string handling defensively.
  static String _formatSlotTime(Object value) {
    if (value is Time) {
      final h = value.hour.toString().padLeft(2, '0');
      final m = value.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final s = value.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  Facility _rowToFacility(dynamic row) {
    return Facility(
      id: row[0] as String,
      name: row[1] as String,
      description: row[2] as String?,
      approvalMode: row[3] as String,
      isActive: row[4] as bool,
      capacity: row[5] as int,
      graceBeforeMinutes: row[6] as int,
      graceAfterMinutes: row[7] as int,
      createdAt: row[8] as DateTime,
      updatedAt: row[9] as DateTime,
    );
  }

  FacilitySlotConfig _rowToSlotConfig(dynamic row) {
    return FacilitySlotConfig(
      id: row[0] as String,
      facilityId: row[1] as String,
      startTime: _formatSlotTime(row[2] as Object), // HH:MM
      endTime: _formatSlotTime(row[3] as Object),
      isActive: row[4] as bool,
      createdAt: row[5] as DateTime,
    );
  }

  BlockedSlot _rowToBlockedSlot(dynamic row) {
    return BlockedSlot(
      id: row[0] as String,
      facilityId: row[1] as String,
      slotConfigId: row[2] as String,
      blockedDate: row[3] as DateTime,
      reason: row[4] as String?,
      createdAt: row[5] as DateTime,
    );
  }

  Booking _rowToBooking(dynamic row) {
    return Booking(
      id: row[0] as String,
      bookingReference: row[1] as String,
      studentId: row[2] as String,
      facilityId: row[3] as String,
      slotConfigId: row[4] as String,
      bookingDate: row[5] as DateTime,
      status: row[6] as String,
      rejectionReason: row[7] as String?,
      createdBy: row[8] as String?,
      createdAt: row[9] as DateTime,
      updatedAt: row[10] as DateTime,
    );
  }
}
