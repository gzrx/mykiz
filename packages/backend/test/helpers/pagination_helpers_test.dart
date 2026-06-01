import 'package:backend/helpers/helpers.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('parsePagination', () {
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

    test('returns defaults when no params provided', () {
      final context = _createContext({});
      final params = parsePagination(context);

      expect(params.page, equals(defaultPage));
      expect(params.limit, equals(defaultLimit));
    });

    test('parses valid page and limit', () {
      final context = _createContext({'page': '3', 'limit': '50'});
      final params = parsePagination(context);

      expect(params.page, equals(3));
      expect(params.limit, equals(50));
    });

    test('parses page only, uses default limit', () {
      final context = _createContext({'page': '2'});
      final params = parsePagination(context);

      expect(params.page, equals(2));
      expect(params.limit, equals(defaultLimit));
    });

    test('parses limit only, uses default page', () {
      final context = _createContext({'limit': '10'});
      final params = parsePagination(context);

      expect(params.page, equals(defaultPage));
      expect(params.limit, equals(10));
    });

    test('accepts limit=100 (max)', () {
      final context = _createContext({'limit': '100'});
      final params = parsePagination(context);

      expect(params.limit, equals(100));
    });

    test('accepts limit=1 (min)', () {
      final context = _createContext({'limit': '1'});
      final params = parsePagination(context);

      expect(params.limit, equals(1));
    });

    test('rejects non-numeric page', () {
      final context = _createContext({'page': 'abc'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>().having(
          (e) => e.message,
          'message',
          contains('page'),
        )),
      );
    });

    test('rejects non-numeric limit', () {
      final context = _createContext({'limit': 'xyz'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>().having(
          (e) => e.message,
          'message',
          contains('limit'),
        )),
      );
    });

    test('rejects page < 1', () {
      final context = _createContext({'page': '0'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>().having(
          (e) => e.message,
          'message',
          contains('page'),
        )),
      );
    });

    test('rejects negative page', () {
      final context = _createContext({'page': '-1'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>().having(
          (e) => e.message,
          'message',
          contains('page'),
        )),
      );
    });

    test('rejects limit < 1', () {
      final context = _createContext({'limit': '0'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>().having(
          (e) => e.message,
          'message',
          contains('limit'),
        )),
      );
    });

    test('rejects negative limit', () {
      final context = _createContext({'limit': '-5'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>().having(
          (e) => e.message,
          'message',
          contains('limit'),
        )),
      );
    });

    test('rejects limit > 100', () {
      final context = _createContext({'limit': '101'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>().having(
          (e) => e.message,
          'message',
          contains('limit'),
        )),
      );
    });

    test('rejects floating point page', () {
      final context = _createContext({'page': '1.5'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>()),
      );
    });

    test('rejects floating point limit', () {
      final context = _createContext({'limit': '20.5'});

      expect(
        () => parsePagination(context),
        throwsA(isA<InvalidRequestException>()),
      );
    });
  });
}
