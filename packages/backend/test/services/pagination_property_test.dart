// Feature: mykiz-platform, Property 9: Pagination correctness
import 'package:backend/helpers/helpers.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' hide any;
import 'package:test/test.dart';

/// **Validates: Requirements 4.2, 4.5, 7.3, 10.4, 10.6**
///
/// Property 9: Pagination correctness
/// For any list endpoint, valid page number p (≥ 1), valid limit l (1–100),
/// and total item count n, the response SHALL return at most l items,
/// totalItems equal to n, totalPages equal to ceil(n / l), and currentPage
/// equal to p. If p or l is non-numeric, less than 1, or l exceeds 100, the
/// Backend SHALL return 400.

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

/// Creates a mock RequestContext with the given query parameters.
RequestContext _createContext(Map<String, String> queryParams) {
  final context = _MockRequestContext();
  final request = _MockRequest();
  final uri = Uri(
    scheme: 'http',
    host: 'localhost',
    path: '/api/v1/announcements',
    queryParameters: queryParams.isEmpty ? null : queryParams,
  );
  when(() => request.uri).thenReturn(uri);
  when(() => context.request).thenReturn(request);
  return context;
}

/// Custom generators for pagination parameters.
extension PaginationGenerators on Any {
  /// Generates a valid page number (1 to 10000).
  Generator<int> get validPage => simple(
        generate: (random, size) => 1 + random.nextInt(10000),
        shrink: (input) => input > 1 ? [1] : [],
      );

  /// Generates a valid limit (1 to 100).
  Generator<int> get validLimit => simple(
        generate: (random, size) => 1 + random.nextInt(100),
        shrink: (input) => input > 1 ? [1] : [],
      );

  /// Generates a valid totalItems count (0 to 100000).
  Generator<int> get validTotalItems => simple(
        generate: (random, size) => random.nextInt(100001),
        shrink: (input) => input > 0 ? [0] : [],
      );

  /// Generates an invalid page value (0, negative, or non-numeric string).
  Generator<String> get invalidPageString => simple(
        generate: (random, size) {
          final options = [
            '0',
            '-1',
            '-${1 + random.nextInt(100)}',
            'abc',
            '1.5',
            '',
            'null',
            'true',
            '!@#',
          ];
          return options[random.nextInt(options.length)];
        },
        shrink: (input) => [],
      );

  /// Generates an invalid limit value (0, negative, >100, or non-numeric).
  Generator<String> get invalidLimitString => simple(
        generate: (random, size) {
          final options = [
            '0',
            '-1',
            '-${1 + random.nextInt(100)}',
            '${101 + random.nextInt(1000)}',
            'abc',
            '20.5',
            '',
            'null',
            'true',
            '!@#',
          ];
          return options[random.nextInt(options.length)];
        },
        shrink: (input) => [],
      );
}

void main() {
  group('Property 9: Pagination correctness', () {
    // Property 9a: For any valid page (≥1), valid limit (1-100), and
    // totalItems (≥0), buildPaginationMeta SHALL return:
    // - totalPages == ceil(totalItems / limit) (or 1 when totalItems == 0)
    // - currentPage == page
    // - limit == limit
    // - totalItems == totalItems
    Glados3(any.validPage, any.validLimit, any.validTotalItems,
            ExploreConfig(numRuns: 100))
        .test(
      'buildPaginationMeta returns correct metadata for any valid inputs',
      (page, limit, totalItems) {
        final meta = buildPaginationMeta(
          currentPage: page,
          limit: limit,
          totalItems: totalItems,
        );

        final expectedTotalPages =
            totalItems == 0 ? 1 : (totalItems / limit).ceil();

        expect(meta['currentPage'], equals(page));
        expect(meta['limit'], equals(limit));
        expect(meta['totalItems'], equals(totalItems));
        expect(meta['totalPages'], equals(expectedTotalPages));
      },
    );

    // Property 9b: Mathematical bound — totalPages * limit >= totalItems
    // (there are enough pages to hold all items).
    Glados3(any.validPage, any.validLimit, any.validTotalItems,
            ExploreConfig(numRuns: 100))
        .test(
      'totalPages * limit >= totalItems (pages can hold all items)',
      (page, limit, totalItems) {
        final meta = buildPaginationMeta(
          currentPage: page,
          limit: limit,
          totalItems: totalItems,
        );

        final totalPages = meta['totalPages'] as int;
        expect(totalPages * limit, greaterThanOrEqualTo(totalItems));
      },
    );

    // Property 9c: Mathematical bound — (totalPages - 1) * limit < totalItems
    // when totalItems > 0 (no unnecessary extra pages).
    Glados2(any.validLimit, any.validTotalItems, ExploreConfig(numRuns: 100))
        .test(
      '(totalPages - 1) * limit < totalItems when totalItems > 0 (minimal pages)',
      (limit, totalItems) {
        // Only test when totalItems > 0 to avoid trivial case
        if (totalItems == 0) return;

        final meta = buildPaginationMeta(
          currentPage: 1,
          limit: limit,
          totalItems: totalItems,
        );

        final totalPages = meta['totalPages'] as int;
        expect((totalPages - 1) * limit, lessThan(totalItems));
      },
    );

    // Property 9d: parsePagination SHALL throw InvalidRequestException for
    // any invalid page parameter (non-numeric, < 1).
    Glados(any.invalidPageString, ExploreConfig(numRuns: 100)).test(
      'parsePagination throws InvalidRequestException for invalid page values',
      (invalidPage) {
        final context = _createContext({'page': invalidPage});

        expect(
          () => parsePagination(context),
          throwsA(isA<InvalidRequestException>()),
        );
      },
    );

    // Property 9e: parsePagination SHALL throw InvalidRequestException for
    // any invalid limit parameter (non-numeric, < 1, > 100).
    Glados(any.invalidLimitString, ExploreConfig(numRuns: 100)).test(
      'parsePagination throws InvalidRequestException for invalid limit values',
      (invalidLimit) {
        final context = _createContext({'limit': invalidLimit});

        expect(
          () => parsePagination(context),
          throwsA(isA<InvalidRequestException>()),
        );
      },
    );

    // Property 9f: parsePagination SHALL correctly parse any valid page and
    // limit combination.
    Glados2(any.validPage, any.validLimit, ExploreConfig(numRuns: 100)).test(
      'parsePagination correctly parses any valid page and limit',
      (page, limit) {
        final context = _createContext({
          'page': page.toString(),
          'limit': limit.toString(),
        });

        final params = parsePagination(context);

        expect(params.page, equals(page));
        expect(params.limit, equals(limit));
        expect(params.offset, equals((page - 1) * limit));
      },
    );
  });
}
