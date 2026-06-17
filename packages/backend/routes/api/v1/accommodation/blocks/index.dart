import 'dart:io';

import 'package:backend/helpers/helpers.dart';
import 'package:backend/services/accommodation_exception.dart';
import 'package:backend/services/accommodation_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /api/v1/accommodation/blocks
///
/// Returns all blocks with nested rooms and beds.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return ApiResponse.error(
      statusCode: HttpStatus.methodNotAllowed,
      code: 'METHOD_NOT_ALLOWED',
      message: 'Only GET is allowed.',
    );
  }

  try {
    final service = AccommodationService();
    final blocks = await service.listBlocks();
    return ApiResponse.success(
      data: blocks.map((b) => b.toJson()).toList(),
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
