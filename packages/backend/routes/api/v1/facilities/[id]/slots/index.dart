import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:backend/services/database.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/facilities/[id]/slots route handler.
///
/// - GET: List active slot configs for a facility (any authenticated user)
/// - POST: Add a new slot config (admin only)
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _listSlots(context, id);
    case HttpMethod.post:
      return _addSlot(context, id);
    default:
      return ApiResponse.error(
        statusCode: HttpStatus.methodNotAllowed,
        code: 'METHOD_NOT_ALLOWED',
        message: 'Only GET and POST methods are allowed.',
      );
  }
}

Future<Response> _listSlots(RequestContext context, String id) async {
  try {
    final result = await Database.query(
      'SELECT id, facility_id, start_time, end_time, is_active, created_at '
      'FROM facility_slot_configs '
      'WHERE facility_id = @facilityId AND is_active = true '
      'ORDER BY start_time',
      parameters: {'facilityId': id},
    );

    final slots = result
        .map((row) => {
              'id': row[0] as String,
              'facilityId': row[1] as String,
              'startTime': (row[2] as String).substring(0, 5),
              'endTime': (row[3] as String).substring(0, 5),
              'isActive': row[4] as bool,
              'createdAt': (row[5] as DateTime).toIso8601String(),
            })
        .toList();

    return ApiResponse.success(data: slots);
  } catch (_) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}

Future<Response> _addSlot(RequestContext context, String id) async {
  try {
    final user = context.read<UserPayload>();
    if (!user.isAdmin) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can add slot configs.',
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final startTime = body['startTime'] as String?;
    final endTime = body['endTime'] as String?;

    if (startTime == null || endTime == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: 'Both "startTime" and "endTime" (HH:MM) are required.',
      );
    }

    final slot = await const BookingService().addSlotConfig(
      facilityId: id,
      startTime: startTime,
      endTime: endTime,
    );

    return ApiResponse.created(data: slot.toJson());
  } on BookingException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  } catch (_) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}
