import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/services/booking_exception.dart';
import 'package:backend/services/booking_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/facilities route handler.
///
/// - GET: List active facilities (any authenticated user)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return ApiResponse.error(
      statusCode: HttpStatus.methodNotAllowed,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Only GET is allowed.',
    );
  }

  try {
    final facilities = await const BookingService().listFacilities();
    // Return only active facilities for student view
    final active = facilities.where((f) => f.isActive).toList();
    return ApiResponse.success(
      data: active.map((f) => f.toJson()).toList(),
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
