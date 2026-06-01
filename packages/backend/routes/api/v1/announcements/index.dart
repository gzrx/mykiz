import 'dart:io';

import 'package:backend/helpers/pagination_helpers.dart';
import 'package:backend/helpers/request_helpers.dart';
import 'package:backend/helpers/response_helpers.dart';
import 'package:backend/middleware/role_guard.dart';
import 'package:backend/models/user_payload.dart';
import 'package:backend/services/announcement_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Handles requests to /api/v1/announcements
///
/// - GET: List announcements with pagination (any authenticated user)
/// - POST: Create a new announcement (admin only)
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _handleGet(context);
    case HttpMethod.post:
      return _handlePost(context);
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

/// GET /api/v1/announcements
///
/// Lists announcements with pagination. Available to any authenticated user.
Future<Response> _handleGet(RequestContext context) async {
  final pagination = parsePagination(context);

  try {
    final service = AnnouncementService();
    final result = await service.list(
      page: pagination.page,
      limit: pagination.limit,
    );

    final items = result.items
        .map(
          (a) => {
            'id': a.id,
            'title': a.title,
            'body': a.body,
            'authorId': a.authorId,
            'createdAt': a.createdAt.toIso8601String(),
            'updatedAt': a.updatedAt.toIso8601String(),
          },
        )
        .toList();

    final meta = buildPaginationMeta(
      currentPage: result.meta.currentPage,
      limit: result.meta.limit,
      totalItems: result.meta.totalItems,
    );

    return ApiResponse.success(data: items, meta: meta);
  } on ValidationException catch (e) {
    return ApiResponse.error(
      statusCode: HttpStatus.badRequest,
      code: e.code,
      message: e.message,
    );
  }
}

/// POST /api/v1/announcements
///
/// Creates a new announcement. Admin only.
Future<Response> _handlePost(RequestContext context) async {
  // Check admin role
  final forbidden = requireAdmin(context);
  if (forbidden != null) return forbidden;

  final body = await parseJsonBody(context);
  final title = body['title'] as String? ?? '';
  final bodyText = body['body'] as String? ?? '';

  final user = context.read<UserPayload>();

  try {
    final service = AnnouncementService();
    final announcement = await service.create(
      title: title,
      body: bodyText,
      authorId: user.id,
    );

    return ApiResponse.created(
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
  }
}
