import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/facilities/[id]/slots/[slotId] route handler.
///
/// - DELETE: Deactivate or delete a slot config (admin only).
///   Use ?action=delete to permanently delete; default is deactivate.
Future<Response> onRequest(
  RequestContext context,
  String id,
  String slotId,
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
        message: 'Only admins can manage slot configs.',
      );
    }

    final action = context.request.uri.queryParameters['action'];

    if (action == 'delete') {
      await const BookingService().deleteSlotConfig(slotId);
    } else {
      await const BookingService().deactivateSlotConfig(slotId);
    }

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
