import 'package:dart_frog/dart_frog.dart';

import 'api_exceptions.dart';

/// Default page number when not specified.
const int defaultPage = 1;

/// Default limit when not specified.
const int defaultLimit = 20;

/// Maximum allowed limit value.
const int maxLimit = 100;

/// Validated pagination parameters extracted from query string.
class PaginationParams {
  const PaginationParams({
    required this.page,
    required this.limit,
  });

  /// The requested page number (1-based).
  final int page;

  /// The number of items per page.
  final int limit;

  /// Calculates the SQL OFFSET for this page.
  int get offset => (page - 1) * limit;
}

/// Parses and validates pagination query parameters from the request.
///
/// Extracts `page` and `limit` from the query string.
/// - If not provided, defaults to page=1, limit=20.
/// - Rejects non-numeric values with [InvalidRequestException].
/// - Rejects page < 1 with [InvalidRequestException].
/// - Rejects limit < 1 or limit > 100 with [InvalidRequestException].
///
/// Throws [InvalidRequestException] if validation fails.
PaginationParams parsePagination(RequestContext context) {
  final queryParams = context.request.uri.queryParameters;

  final pageStr = queryParams['page'];
  final limitStr = queryParams['limit'];

  int page = defaultPage;
  int limit = defaultLimit;

  // Parse page parameter
  if (pageStr != null) {
    final parsed = int.tryParse(pageStr);
    if (parsed == null) {
      throw const InvalidRequestException(
        'Query parameter "page" must be a valid integer.',
      );
    }
    if (parsed < 1) {
      throw const InvalidRequestException(
        'Query parameter "page" must be at least 1.',
      );
    }
    page = parsed;
  }

  // Parse limit parameter
  if (limitStr != null) {
    final parsed = int.tryParse(limitStr);
    if (parsed == null) {
      throw const InvalidRequestException(
        'Query parameter "limit" must be a valid integer.',
      );
    }
    if (parsed < 1) {
      throw const InvalidRequestException(
        'Query parameter "limit" must be at least 1.',
      );
    }
    if (parsed > maxLimit) {
      throw const InvalidRequestException(
        'Query parameter "limit" must not exceed $maxLimit.',
      );
    }
    limit = parsed;
  }

  return PaginationParams(page: page, limit: limit);
}

/// Builds the pagination meta object for a list response.
///
/// [currentPage] is the current page number.
/// [limit] is the items per page.
/// [totalItems] is the total count of items matching the query.
Map<String, dynamic> buildPaginationMeta({
  required int currentPage,
  required int limit,
  required int totalItems,
}) {
  final totalPages = totalItems == 0 ? 1 : (totalItems / limit).ceil();
  return {
    'currentPage': currentPage,
    'limit': limit,
    'totalItems': totalItems,
    'totalPages': totalPages,
  };
}
