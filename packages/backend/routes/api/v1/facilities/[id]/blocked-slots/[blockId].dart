import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/facilities/[id]/blocked-slots/[blockId] route handler.
///
/// - DELETE: Remove a blocked slot record (admin only).
Future<Response> onRequest(
  RequestContext context,
  String id,
  String blockId,
) async {
  if (context.request.method != HttpMethod.delete) {
    return ApiResponse.error(
      statusCode: HttpStatus.methodNotAllowed,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Only DELETE is allowed.',
    );
  }

  try {
    final user = context.read<UserPayload>();
    if (!user.isAdmin) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can unblock slots.',
      );
    }

    await const BookingService().unblockSlot(blockId);

    return ApiResponse.noContent();
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
