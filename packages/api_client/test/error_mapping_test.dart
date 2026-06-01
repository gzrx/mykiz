import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDio extends Mock implements Dio {}

class MockBaseOptions extends Mock implements BaseOptions {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockDio mockDio;
  late MyKizApiClient client;
  late MockBaseOptions mockOptions;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    mockOptions = MockBaseOptions();
    when(() => mockDio.options).thenReturn(mockOptions);
    when(() => mockOptions.headers).thenReturn(<String, dynamic>{});
    client = MyKizApiClient(baseUrl: 'http://localhost:8080', dio: mockDio);
  });

  group('API client error mapping', () {
    // -------------------------------------------------------------------------
    // HTTP status code → exception type mapping
    // Validates: Requirements 12.3
    // -------------------------------------------------------------------------

    group('HTTP status code mapping', () {
      test('400 maps to ValidationException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 400,
            data: {
              'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Title is required',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('401 maps to UnauthorizedException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 401,
            data: {
              'error': {
                'code': 'UNAUTHORIZED',
                'message': 'Missing or invalid token',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('403 maps to ForbiddenException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 403,
            data: {
              'error': {
                'code': 'FORBIDDEN',
                'message': 'Admin access required',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ForbiddenException>()),
        );
      });

      test('404 maps to NotFoundException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 404,
            data: {
              'error': {
                'code': 'NOT_FOUND',
                'message': 'Announcement not found',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('500 maps to ServerException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 500,
            data: {
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Something went wrong',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ServerException>()),
        );
      });

      test('unknown status code maps to ServerException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 502,
            data: {
              'error': {
                'code': 'BAD_GATEWAY',
                'message': 'Bad gateway',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Error code and message preservation
    // Validates: Requirements 12.3
    // -------------------------------------------------------------------------

    group('error code and message preservation', () {
      test('preserves error code from response body', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 400,
            data: {
              'error': {
                'code': 'INVALID_REQUEST',
                'message': 'Malformed JSON body',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'INVALID_REQUEST',
          )),
        );
      });

      test('preserves error message from response body', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 401,
            data: {
              'error': {
                'code': 'TOKEN_EXPIRED',
                'message': 'Your session has expired',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<UnauthorizedException>()
              .having((e) => e.code, 'code', 'TOKEN_EXPIRED')
              .having(
                  (e) => e.message, 'message', 'Your session has expired')),
        );
      });

      test('uses defaults when response body has no error envelope', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          response: Response(
            statusCode: 500,
            data: 'Internal Server Error',
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/test-id'),
          ),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ServerException>()
              .having((e) => e.code, 'code', 'UNKNOWN')
              .having((e) => e.message, 'message',
                  'An unexpected error occurred')),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Timeout behavior → ApiTimeoutException
    // Validates: Requirements 12.9
    // -------------------------------------------------------------------------

    group('timeout behavior', () {
      test('connectionTimeout throws ApiTimeoutException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ApiTimeoutException>()),
        );
      });

      test('receiveTimeout throws ApiTimeoutException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ApiTimeoutException>()),
        );
      });

      test('sendTimeout throws ApiTimeoutException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ApiTimeoutException>()),
        );
      });

      test('ApiTimeoutException has default code TIMEOUT', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ApiTimeoutException>()
              .having((e) => e.code, 'code', 'TIMEOUT')
              .having((e) => e.message, 'message', 'Request timed out')),
        );
      });
    });

    // -------------------------------------------------------------------------
    // Connection error → ServerException with CONNECTION_ERROR
    // Validates: Requirements 12.3
    // -------------------------------------------------------------------------

    group('connection error', () {
      test('connection error maps to ServerException with CONNECTION_ERROR',
          () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
          message: 'Connection refused',
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ServerException>()
              .having((e) => e.code, 'code', 'CONNECTION_ERROR')
              .having((e) => e.message, 'message', 'Connection refused')),
        );
      });

      test('connection error with null message uses fallback message',
          () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/test-id',
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/api/v1/announcements/test-id'),
        ));

        expect(
          () => client.getAnnouncement('test-id'),
          throwsA(isA<ServerException>()
              .having((e) => e.code, 'code', 'CONNECTION_ERROR')
              .having(
                  (e) => e.message, 'message', 'Failed to connect to server')),
        );
      });
    });
  });
}
