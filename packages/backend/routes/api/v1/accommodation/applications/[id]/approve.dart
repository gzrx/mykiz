import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/accommodation_exception.dart';
import 'package:backend/services/accommodation_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/accommodation/applications/:id/approve route handler.
///
/// - POST: Approve a submitted application with bed assignment (admin only).
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.post:
      return _approve(context, id);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only POST method is allowed for this endpoint.',
          },
        },
      );
  }
}

/// POST /api/v1/accommodation/applications/:id/approve
///
/// Admin only. Expects JSON body: { "bedId": "..." }
Future<Response> _approve(RequestContext context, String id) async {
  try {
    final user = context.read<UserPayload>();

    if (!user.isAdmin) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can approve applications.',
      );
    }

    final body = await parseJsonBody(context);
    final bedId = body['bedId'] as String?;

    if (bedId == null || bedId.trim().isEmpty) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'VALIDATION_ERROR',
        message: 'The "bedId" field is required.',
      );
    }

    final service = AccommodationService();
    final application = await service.approveApplication(id, bedId: bedId);

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
