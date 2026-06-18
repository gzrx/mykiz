import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:backend/services/database.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/facilities/[id] route handler.
///
/// - GET: Single facility details (any authenticated user)
/// - PUT: Update facility settings (admin only)
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getFacility(context, id);
    case HttpMethod.put:
      return _updateFacility(context, id);
    default:
      return ApiResponse.error(
        statusCode: HttpStatus.methodNotAllowed,
        code: 'METHOD_NOT_ALLOWED',
        message: 'Only GET and PUT methods are allowed.',
      );
  }
}

Future<Response> _getFacility(RequestContext context, String id) async {
  try {
    final result = await Database.query(
      'SELECT id, name, description, approval_mode, is_active, capacity, '
      'grace_before_minutes, grace_after_minutes, created_at, updated_at '
      'FROM facilities WHERE id = @id',
      parameters: {'id': id},
    );

    if (result.isEmpty) {
      return ApiResponse.error(
        statusCode: HttpStatus.notFound,
        code: 'FACILITY_NOT_FOUND',
        message: 'Facility not found.',
      );
    }

    final row = result.first;
    final facility = {
      'id': row[0] as String,
      'name': row[1] as String,
      'description': row[2] as String?,
      'approvalMode': row[3] as String,
      'isActive': row[4] as bool,
      'capacity': row[5] as int,
      'graceBeforeMinutes': row[6] as int,
      'graceAfterMinutes': row[7] as int,
      'createdAt': (row[8] as DateTime).toIso8601String(),
      'updatedAt': (row[9] as DateTime).toIso8601String(),
    };

    return ApiResponse.success(data: facility);
  } catch (_) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}

Future<Response> _updateFacility(RequestContext context, String id) async {
  try {
    final user = context.read<UserPayload>();
    if (!user.isAdmin) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can update facility settings.',
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;

    final facility = await const BookingService().updateFacility(
      id,
      isActive: body['isActive'] as bool?,
      approvalMode: body['approvalMode'] as String?,
      graceBeforeMinutes: body['graceBeforeMinutes'] as int?,
      graceAfterMinutes: body['graceAfterMinutes'] as int?,
    );

    return ApiResponse.success(data: facility.toJson());
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
