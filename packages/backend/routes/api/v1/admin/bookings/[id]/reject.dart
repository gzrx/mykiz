import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// PUT /api/v1/admin/bookings/:id/reject
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.put) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {
        'error': {
          'code': 'METHOD_NOT_ALLOWED',
          'message': 'Only PUT method is allowed.',
        },
      },
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final reason = body['reason'] as String? ?? '';

    final service = BookingService();
    final booking = await service.rejectBooking(id, reason: reason);
    return ApiResponse.success(data: booking.toJson());
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
