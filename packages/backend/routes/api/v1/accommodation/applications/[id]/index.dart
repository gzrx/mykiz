import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/accommodation_exception.dart';
import 'package:backend/services/accommodation_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/accommodation/applications/:id route handler.
///
/// - GET: Retrieve a single application by ID (role-scoped).
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getApplication(context, id);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only GET method is allowed for this endpoint.',
          },
        },
      );
  }
}

/// GET /api/v1/accommodation/applications/:id
///
/// Any authenticated user can view, but students can only see their own.
Future<Response> _getApplication(RequestContext context, String id) async {
  try {
    final user = context.read<UserPayload>();
    final service = AccommodationService();

    final application = await service.getApplication(
      id,
      userId: user.id,
      role: user.role,
    );

    return ApiResponse.success(data: application.toJson());
  } on AccommodationException catch (e) {
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
