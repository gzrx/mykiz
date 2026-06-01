import 'dart:io';

import 'package:backend/helpers/request_helpers.dart';
import 'package:backend/helpers/response_helpers.dart';
import 'package:backend/middleware/role_guard.dart';
import 'package:backend/services/announcement_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Handles requests to /api/v1/announcements/:id
///
/// - GET: Get announcement by ID (any authenticated user)
/// - PATCH: Partial update (admin only)
/// - DELETE: Soft delete (admin only)
Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _handleGet(context, id);
    case HttpMethod.patch:
      return _handlePatch(context, id);
    case HttpMethod.delete:
      return _handleDelete(context, id);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {
          'error': {
            'code': 'METHOD_NOT_ALLOWED',
            'message': 'Only GET, PATCH, and DELETE methods are allowed.',
          },
        },
      );
  }
}

/// GET /api/v1/announcements/:id
///
/// Retrieves a single announcement by ID. Available to any authenticated user.
Future<Response> _handleGet(RequestContext context, String id) async {
  try {
    final service = AnnouncementService();
    final announcement = await service.getById(id);

    return ApiResponse.success(
      data: {
        'id': announcement.id,
        'title': announcement.title,
        'body': announcement.body,
        'authorId': announcement.authorId,
        'createdAt': announcement.createdAt.toIso8601String(),
        'updatedAt': announcement.updatedAt.toIso8601String(),
      },
    );
  } on NotFoundException catch (e) {
    return ApiResponse.error(
      statusCode: HttpStatus.notFound,
      code: e.code,
      message: e.message,
    );
  }
}

/// PATCH /api/v1/announcements/:id
///
/// Partially updates an announcement. Admin only.
Future<Response> _handlePatch(RequestContext context, String id) async {
  // Check admin role
  final forbidden = requireAdmin(context);
  if (forbidden != null) return forbidden;

  final body = await parseJsonBody(context);
  final title = body['title'] as String?;
  final bodyText = body['body'] as String?;

  try {
    final service = AnnouncementService();
    final announcement = await service.update(
      id,
      title: title,
      body: bodyText,
    );

    return ApiResponse.success(
      data: {
        'id': announcement.id,
        'title': announcement.title,
        'body': announcement.body,
        'authorId': announcement.authorId,
        'createdAt': announcement.createdAt.toIso8601String(),
        'updatedAt': announcement.updatedAt.toIso8601String(),
      },
    );
  } on ValidationException catch (e) {
    return ApiResponse.error(
      statusCode: HttpStatus.badRequest,
      code: e.code,
      message: e.message,
    );
  } on NotFoundException catch (e) {
    return ApiResponse.error(
      statusCode: HttpStatus.notFound,
      code: e.code,
      message: e.message,
    );
  }
}

/// DELETE /api/v1/announcements/:id
///
/// Soft-deletes an announcement. Admin only.
Future<Response> _handleDelete(RequestContext context, String id) async {
  // Check admin role
  final forbidden = requireAdmin(context);
  if (forbidden != null) return forbidden;

  try {
    final service = AnnouncementService();
    await service.softDelete(id);

    return ApiResponse.noContent();
  } on NotFoundException catch (e) {
    return ApiResponse.error(
      statusCode: HttpStatus.notFound,
      code: e.code,
      message: e.message,
    );
  }
}
