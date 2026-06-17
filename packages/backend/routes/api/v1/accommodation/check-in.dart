import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/accommodation_exception.dart';
import 'package:backend/services/accommodation_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// POST /api/v1/accommodation/check-in
///
/// Admin-only. Accepts `{ "applicationId": "uuid-string" }` from QR scan.
/// Transitions an approved application to checked_in.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
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

  try {
    final user = context.read<UserPayload>();

    if (!user.isAdmin) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can perform check-in.',
      );
    }

    final body = await parseJsonBody(context);
    final applicationId = body['applicationId'];

    if (applicationId is! String || applicationId.trim().isEmpty) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'VALIDATION_ERROR',
        message: 'The "applicationId" field is required and must be a string.',
      );
    }

    final service = AccommodationService();
    final application = await service.checkIn(applicationId);

    return ApiResponse.success(data: application.toJson());
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
