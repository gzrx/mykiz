import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/services.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/bookings/:id route handler.
///
/// - DELETE: Cancel a booking
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.delete:
      return _cancelBooking(context, id);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only DELETE method is allowed.',
          },
        },
      );
  }
}

Future<Response> _cancelBooking(RequestContext context, String id) async {
  try {
    final user = context.read<UserPayload>();
    final service = BookingService();

    final booking = await service.cancelBooking(id, studentId: user.id);
    return ApiResponse.success(data: booking.toJson());
  } on BookingException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  } catch (e) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}
