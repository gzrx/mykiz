import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/complaint_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/complaints/:id route handler.
///
/// - GET: Retrieve a single complaint by ID with ownership check.
/// - PUT/PATCH (without /status): Reject modification (immutability).
/// - DELETE: Reject deletion (immutability).
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getComplaint(context, id);
    case HttpMethod.put:
    case HttpMethod.patch:
      return _rejectModification();
    case HttpMethod.delete:
      return _rejectDeletion();
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

/// GET /api/v1/complaints/:id
///
/// Retrieves a complaint by ID. Students can only see their own complaints;
/// Admins can see all complaints.
Future<Response> _getComplaint(RequestContext context, String id) async {
  try {
    final user = context.read<UserPayload>();

    final service = ComplaintService();
    final complaint = await service.getById(
      id,
      requesterId: user.id,
      requesterRole: user.role,
    );

    return ApiResponse.success(data: complaint.toJson());
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

/// Rejects any modification attempt to a complaint (immutability rule).
Response _rejectModification() {
  try {
    ComplaintService().rejectModification();
  } on ComplaintException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  }
}

/// Rejects any deletion attempt on a complaint (immutability rule).
Response _rejectDeletion() {
  try {
    ComplaintService().rejectDeletion();
  } on ComplaintException catch (e) {
    return ApiResponse.error(
      statusCode: e.statusCode,
      code: e.code,
      message: e.message,
    );
  }
}
