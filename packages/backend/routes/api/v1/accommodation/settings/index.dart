import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/accommodation_exception.dart';
import 'package:backend/services/accommodation_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/accommodation/settings route handler.
///
/// - GET: Returns current application window status (any authenticated user)
/// - PUT: Toggles the application window (admin only)
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getSettings(context);
    case HttpMethod.put:
      return _updateSettings(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only GET and PUT methods are allowed.',
          },
        },
      );
  }
}

/// GET /api/v1/accommodation/settings
Future<Response> _getSettings(RequestContext context) async {
  try {
    final service = AccommodationService();
    final settings = await service.getSettings();
    return ApiResponse.success(data: settings);
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

/// PUT /api/v1/accommodation/settings
///
/// Expects JSON body: { "open": true | false }
/// Admin only — returns 403 for non-admin users.
Future<Response> _updateSettings(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();

    if (!user.isAdmin) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can update accommodation settings.',
      );
    }

    final body = await parseJsonBody(context);
    final open = body['open'];

    if (open is! bool) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'VALIDATION_ERROR',
        message: 'The "open" field must be a boolean.',
      );
    }

    final service = AccommodationService();
    final settings = await service.updateSettings(open: open);
    return ApiResponse.success(data: settings);
  } on InvalidRequestException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
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
