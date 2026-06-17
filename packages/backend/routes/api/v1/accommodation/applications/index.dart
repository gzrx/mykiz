import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/accommodation_exception.dart';
import 'package:backend/services/accommodation_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// /api/v1/accommodation/applications route handler.
///
/// - POST (student only): Submit a new application
/// - GET (admin only): List applications with pagination and filters
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.post:
      return _submitApplication(context);
    case HttpMethod.get:
      return _listApplications(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only GET and POST methods are allowed.',
          },
        },
      );
  }
}

/// POST /api/v1/accommodation/applications
///
/// Student submits a new accommodation application.
/// Body fields: applicationType, roomTypePreference, preferredBlockId,
/// lifestyleTags, checkInDate, checkOutDate.
Future<Response> _submitApplication(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();

    if (!user.isStudent) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only students can submit applications.',
      );
    }

    final body = await parseJsonBody(context);
    final applicationType = body['applicationType'] as String?;

    if (applicationType == null ||
        (applicationType != 'semester' &&
            applicationType != 'out_of_semester')) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'VALIDATION_ERROR',
        message:
            'applicationType must be "semester" or "out_of_semester".',
      );
    }

    final roomTypePreference = body['roomTypePreference'] as String?;
    final preferredBlockId = body['preferredBlockId'] as String?;
    final lifestyleTags = (body['lifestyleTags'] as List?)?.cast<String>();

    DateTime? checkInDate;
    DateTime? checkOutDate;
    if (body['checkInDate'] != null) {
      checkInDate = DateTime.tryParse(body['checkInDate'] as String);
    }
    if (body['checkOutDate'] != null) {
      checkOutDate = DateTime.tryParse(body['checkOutDate'] as String);
    }

    final service = AccommodationService();
    final application = await service.submitApplication(
      studentId: user.id,
      applicationType: applicationType,
      roomTypePreference: roomTypePreference,
      preferredBlockId: preferredBlockId,
      lifestyleTags: lifestyleTags,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
    );

    return ApiResponse.created(data: application.toJson());
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

/// GET /api/v1/accommodation/applications
///
/// Admin-only listing with pagination and optional filters:
/// - ?status=submitted|approved|...
/// - ?type=semester|out_of_semester
/// - ?tags=tag1,tag2 (AND filter)
/// - ?page=1&limit=20
Future<Response> _listApplications(RequestContext context) async {
  try {
    final user = context.read<UserPayload>();

    if (!user.isAdmin) {
      return ApiResponse.error(
        statusCode: HttpStatus.forbidden,
        code: 'FORBIDDEN',
        message: 'Only admins can list applications.',
      );
    }

    final pagination = parsePagination(context);
    final queryParams = context.request.uri.queryParameters;

    final status = queryParams['status'];
    final type = queryParams['type'];
    final tagsParam = queryParams['tags'];
    final tags = tagsParam != null && tagsParam.isNotEmpty
        ? tagsParam.split(',').map((t) => t.trim()).toList()
        : null;

    final service = AccommodationService();
    final result = await service.listApplications(
      page: pagination.page,
      limit: pagination.limit,
      status: status,
      applicationType: type,
      tags: tags,
    );

    final applications = (result['applications']! as List)
        .map((a) => (a as dynamic).toJson())
        .toList();
    final meta = result['meta']! as Map<String, dynamic>;

    return ApiResponse.success(data: applications, meta: meta);
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
