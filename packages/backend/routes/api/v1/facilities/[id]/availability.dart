import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/facilities/[id]/availability route handler.
///
/// - GET: Slot availability for a facility on a given date.
///   Requires query param: ?date=YYYY-MM-DD
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return ApiResponse.error(
      statusCode: HttpStatus.methodNotAllowed,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Only GET is allowed.',
    );
  }

  try {
    final dateStr = context.request.uri.queryParameters['date'];
    if (dateStr == null || dateStr.isEmpty) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: 'Query parameter "date" (YYYY-MM-DD) is required.',
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

    final availability = await const BookingService().getAvailability(
      facilityId: id,
      date: date,
    );

    return ApiResponse.success(
      data: availability.map((s) => s.toJson()).toList(),
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
