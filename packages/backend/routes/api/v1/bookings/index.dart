import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/services.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/bookings route handler.
///
/// - GET: List active bookings or history (via ?type=history)
/// - POST: Submit a new booking
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _listBookings(context);
    case HttpMethod.post:
      return _submitBooking(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only GET and POST methods are allowed.',
          },
        },
      );
  }
}

Future<Response> _listBookings(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();
    final type = context.request.uri.queryParameters['type'];
    final service = BookingService();

    if (type == 'history') {
      final pagination = parsePagination(context);
      final bookings = await service.listBookingHistory(
        studentId: user.id,
        page: pagination.page,
        limit: pagination.limit,
      );
      return ApiResponse.success(
        data: bookings.map((b) => b.toJson()).toList(),
      );
    }

    final bookings = await service.listActiveBookings(studentId: user.id);
    return ApiResponse.success(
      data: bookings.map((b) => b.toJson()).toList(),
    );
  } on InvalidRequestException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
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

Future<Response> _submitBooking(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();
    final body = await context.request.json() as Map<String, dynamic>;

    final facilityId = body['facilityId'] as String?;
    final slotConfigId = body['slotConfigId'] as String?;
    final dateStr = body['date'] as String?;

    if (facilityId == null || slotConfigId == null || dateStr == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: 'facilityId, slotConfigId, and date are required.',
      );
    }

    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: 'Invalid date format.',
      );
    }

    final service = BookingService();
    final booking = await service.submitBooking(
      studentId: user.id,
      facilityId: facilityId,
      slotConfigId: slotConfigId,
      date: date,
    );

    return ApiResponse.created(data: booking.toJson());
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
