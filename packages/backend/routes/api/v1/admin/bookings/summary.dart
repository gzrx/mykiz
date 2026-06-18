import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /api/v1/admin/bookings/summary?fromDate=...&toDate=...
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {
        'error': {
          'code': 'METHOD_NOT_ALLOWED',
          'message': 'Only GET method is allowed.',
        },
      },
    );
  }

  try {
    final params = context.request.uri.queryParameters;
    final fromStr = params['fromDate'];
    final toStr = params['toDate'];

    if (fromStr == null || toStr == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: 'Query parameters "fromDate" and "toDate" are required.',
      );
    }

    final fromDate = DateTime.tryParse(fromStr);
    final toDate = DateTime.tryParse(toStr);
    if (fromDate == null || toDate == null) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'INVALID_REQUEST',
        message: 'fromDate and toDate must be valid ISO date strings.',
      );
    }

    final service = BookingService();
    final summary = await service.getSummary(fromDate: fromDate, toDate: toDate);
    return ApiResponse.success(data: summary.toJson());
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
