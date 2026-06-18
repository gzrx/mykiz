import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/facilities/[id]/slots/[slotId]/block route handler.
///
/// - POST: Block a date-slot combination (admin only).
///   JSON body: { "date": "YYYY-MM-DD", "reason": "optional" }
Future<Response> onRequest(
  RequestContext context,
  String id,
  String slotId,
) async {
  if (context.request.method != HttpMethod.post) {
    return ApiResponse.error(
      statusCode: HttpStatus.methodNotAllowed,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Only POST is allowed.',
    );
  }

  try {
    final user = context.read<UserPayload>();
    if (!user.isAdmin) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can block slots.',
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final dateStr = body['date'] as String?;
    if (dateStr == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: '"date" (YYYY-MM-DD) is required.',
      );
    }

    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: 'Invalid date format. Use YYYY-MM-DD.',
      );
    }

    final reason = body['reason'] as String?;

    final blocked = await const BookingService().blockSlot(
      facilityId: id,
      slotConfigId: slotId,
      date: date,
      reason: reason,
    );

    return ApiResponse.created(data: blocked.toJson());
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
