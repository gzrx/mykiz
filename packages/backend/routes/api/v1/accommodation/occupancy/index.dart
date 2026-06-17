import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/middleware/role_guard.dart';
import 'package:backend/services/accommodation_exception.dart';
import 'package:backend/services/accommodation_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /api/v1/accommodation/occupancy?blockId=...
///
/// Admin only. Returns rooms with occupied/total bed counts for a block.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return ApiResponse.error(
      statusCode: HttpStatus.methodNotAllowed,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Only GET is allowed.',
    );
  }

  final forbidden = requireAdmin(context);
  if (forbidden != null) return forbidden;

  try {
    final blockId = context.request.uri.queryParameters['blockId'];
    if (blockId == null || blockId.isEmpty) {
      return ApiResponse.error(
        statusCode: HttpStatus.badRequest,
        code: 'VALIDATION_ERROR',
        message: 'Query parameter "blockId" is required.',
      );
    }

    final service = AccommodationService();
    final occupancy = await service.getOccupancy(blockId);
    return ApiResponse.success(data: occupancy);
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
