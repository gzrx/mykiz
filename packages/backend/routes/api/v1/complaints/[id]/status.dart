import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/complaint_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/complaints/:id/status route handler.
///
/// - PATCH: Advance complaint status (admin only).
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.patch:
      return _advanceStatus(context, id);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only PATCH method is allowed for this endpoint.',
          },
        },
      );
  }
}

/// PATCH /api/v1/complaints/:id/status
///
/// Advances the complaint status. Admin only — returns 403 for students.
/// Expects JSON body: { "status": "in_progress" | "resolved" }
Future<Response> _advanceStatus(RequestContext context, String id) async {
  try {
    final user = context.read<UserPayload>();

    // Only admins can advance complaint status
    if (user.role != 'admin') {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can advance complaint status.',
      );
    }

    // Parse JSON body
    final body = await parseJsonBody(context);

    final newStatus = body['status'] as String?;
    if (newStatus == null || newStatus.isEmpty) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'VALIDATION_ERROR',
        message: 'The "status" field is required.',
      );
    }

    final service = ComplaintService();
    final complaint = await service.advanceStatus(id, newStatus: newStatus);

    return ApiResponse.success(data: complaint.toJson());
  } on InvalidRequestException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  } on ComplaintException catch (e) {
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
