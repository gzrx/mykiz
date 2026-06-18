import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/admin/bookings — GET (list all), POST (manual booking).
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _listAll(context);
    case HttpMethod.post:
      return _createManual(context);
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

Future<Response> _listAll(RequestContext context) async {
  try {
    final params = context.request.uri.queryParameters;
    final pagination = parsePagination(context);

    final facilityId = params['facilityId'];
    final status = params['status'];
    final fromDate =
        params['fromDate'] != null ? DateTime.tryParse(params['fromDate']!) : null;
    final toDate =
        params['toDate'] != null ? DateTime.tryParse(params['toDate']!) : null;

    final service = BookingService();
    final bookings = await service.listAllBookings(
      facilityId: facilityId,
      status: status,
      fromDate: fromDate,
      toDate: toDate,
      page: pagination.page,
      limit: pagination.limit,
    );

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
  } catch (_) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}

Future<Response> _createManual(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();
    final body = await context.request.json() as Map<String, dynamic>;

    final studentId = body['studentId'] as String?;
    final facilityId = body['facilityId'] as String?;
    final slotConfigId = body['slotConfigId'] as String?;
    final dateStr = body['date'] as String?;

    if (studentId == null ||
        facilityId == null ||
        slotConfigId == null ||
        dateStr == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message:
            'Fields studentId, facilityId, slotConfigId, and date are required.',
      );
    }

    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: 'Field "date" must be a valid ISO date string.',
      );
    }

    final service = BookingService();
    final booking = await service.createManualBooking(
      adminId: user.id,
      studentId: studentId,
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
  } catch (_) {
    return ApiResponse.error(
      statusCode: HttpStatus.internalServerError,
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred.',
    );
  }
}
