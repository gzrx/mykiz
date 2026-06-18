import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/services.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/bookings/check-in route handler.
///
/// - POST: QR check-in
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.post:
      return _checkIn(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only POST method is allowed.',
          },
        },
      );
  }
}

Future<Response> _checkIn(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();
    final body = await context.request.json() as Map<String, dynamic>;

    final facilityId = body['facilityId'] as String?;
    final slotConfigId = body['slotConfigId'] as String?;
    final dateStr = body['date'] as String?;

    if (facilityId == null || slotConfigId == null || dateStr == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_QR_PAYLOAD',
        message: 'facilityId, slotConfigId, and date are required.',
      );
    }

    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_QR_PAYLOAD',
        message: 'Invalid date format.',
      );
    }

    final service = BookingService();
    final booking = await service.checkIn(
      studentId: user.id,
      facilityId: facilityId,
      slotConfigId: slotConfigId,
      date: date,
    );

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
