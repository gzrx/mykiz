import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/middleware/role_guard.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/accommodation_exception.dart';
import 'package:backend/services/accommodation_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /api/v1/accommodation/my-applications
///
/// Student only. Returns the authenticated student's active and history applications.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return ApiResponse.error(
      statusCode: HttpStatus.methodNotAllowed,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Only GET is allowed.',
    );
  }

  final forbidden = requireRole(context, 'student');
  if (forbidden != null) return forbidden;

  try {
    final user = context.read<UserPayload>();
    final service = AccommodationService();
    final result = await service.getStudentApplications(user.id);

    return ApiResponse.success(
      data: {
        'active': result['active']!.map((a) => a.toJson()).toList(),
        'history': result['history']!.map((a) => a.toJson()).toList(),
      },
    );
  } on AccommodationException catch (e) {
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
