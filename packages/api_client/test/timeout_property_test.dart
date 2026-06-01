// Feature: mykiz-platform, Property 21: API client timeout

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:test/test.dart';

class MockDio extends mocktail.Mock implements Dio {}

class MockBaseOptions extends mocktail.Mock implements BaseOptions {}

class FakeRequestOptions extends mocktail.Fake implements RequestOptions {}

/// **Validates: Requirements 12.9**
///
/// Property 21: API client timeout
/// For any backend request that receives no response within 30 seconds,
/// the api_client SHALL throw a timeout error that calling code can catch
/// without crashing the application.

/// Custom generators for timeout type testing.
extension TimeoutGenerators on Any {
  /// Generates a random DioExceptionType timeout variant:
  /// connectionTimeout, receiveTimeout, or sendTimeout.
  Generator<DioExceptionType> get timeoutType => simple(
        generate: (random, size) {
          final types = [
            DioExceptionType.connectionTimeout,
            DioExceptionType.receiveTimeout,
            DioExceptionType.sendTimeout,
          ];
          return types[random.nextInt(types.length)];
        },
        shrink: (input) => [],
      );
}

void main() {
  late MockDio mockDio;
  late MyKizApiClient client;
  late MockBaseOptions mockOptions;

  setUpAll(() {
    mocktail.registerFallbackValue(FakeRequestOptions());
    mocktail.registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = MockDio();
    mockOptions = MockBaseOptions();
    mocktail.when(() => mockDio.options).thenReturn(mockOptions);
    mocktail.when(() => mockOptions.headers).thenReturn(<String, dynamic>{});
    client = MyKizApiClient(baseUrl: 'http://localhost:8080', dio: mockDio);
  });

  group('Property 21: API client timeout', () {
    // For any timeout type (connectionTimeout, receiveTimeout, sendTimeout),
    // when Dio throws a timeout DioException, the client SHALL throw
    // ApiTimeoutException that is catchable as both ApiTimeoutException
    // and ApiException without crashing the application.

    Glados(any.timeoutType, ExploreConfig(numRuns: 100)).test(
      'listAnnouncements throws ApiTimeoutException for any timeout type',
      (timeoutType) async {
        mocktail
            .when(() => mockDio.get<Map<String, dynamic>>(
                  '/api/v1/announcements',
                  queryParameters:
                      mocktail.any(named: 'queryParameters'),
                ))
            .thenThrow(DioException(
          type: timeoutType,
          requestOptions: RequestOptions(path: '/api/v1/announcements'),
        ));

        // The exception must be catchable without crashing
        ApiException? caughtException;
        try {
          await client.listAnnouncements();
        } on ApiTimeoutException catch (e) {
          caughtException = e;
        }

        expect(caughtException, isNotNull,
            reason: 'Timeout type $timeoutType should throw ApiTimeoutException');
        expect(caughtException, isA<ApiTimeoutException>());
        expect(caughtException!.code, equals('TIMEOUT'));
        expect(caughtException.message, equals('Request timed out'));
      },
    );

    Glados(any.timeoutType, ExploreConfig(numRuns: 100)).test(
      'login throws ApiTimeoutException for any timeout type',
      (timeoutType) async {
        mocktail
            .when(() => mockDio.post<Map<String, dynamic>>(
                  '/api/v1/auth/login',
                  data: mocktail.any(named: 'data'),
                ))
            .thenThrow(DioException(
          type: timeoutType,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ));

        ApiException? caughtException;
        try {
          await client.login(identifier: 'test', password: 'test');
        } on ApiTimeoutException catch (e) {
          caughtException = e;
        }

        expect(caughtException, isNotNull,
            reason: 'Timeout type $timeoutType should throw ApiTimeoutException');
        expect(caughtException, isA<ApiTimeoutException>());
        expect(caughtException!.code, equals('TIMEOUT'));
      },
    );

    Glados(any.timeoutType, ExploreConfig(numRuns: 100)).test(
      'getAnnouncement throws ApiTimeoutException for any timeout type',
      (timeoutType) async {
        mocktail
            .when(() => mockDio.get<Map<String, dynamic>>(
                  '/api/v1/announcements/test-id',
                ))
            .thenThrow(DioException(
          type: timeoutType,
          requestOptions:
              RequestOptions(path: '/api/v1/announcements/test-id'),
        ));

        ApiException? caughtException;
        try {
          await client.getAnnouncement('test-id');
        } on ApiTimeoutException catch (e) {
          caughtException = e;
        }

        expect(caughtException, isNotNull,
            reason: 'Timeout type $timeoutType should throw ApiTimeoutException');
        expect(caughtException, isA<ApiTimeoutException>());
        expect(caughtException!.code, equals('TIMEOUT'));
      },
    );

    Glados(any.timeoutType, ExploreConfig(numRuns: 100)).test(
      'submitComplaint throws ApiTimeoutException for any timeout type',
      (timeoutType) async {
        mocktail
            .when(() => mockDio.post<Map<String, dynamic>>(
                  '/api/v1/complaints',
                  data: mocktail.any(named: 'data'),
                ))
            .thenThrow(DioException(
          type: timeoutType,
          requestOptions: RequestOptions(path: '/api/v1/complaints'),
        ));

        ApiException? caughtException;
        try {
          await client.submitComplaint(
            description: 'test',
            location: 'test',
          );
        } on ApiTimeoutException catch (e) {
          caughtException = e;
        }

        expect(caughtException, isNotNull,
            reason: 'Timeout type $timeoutType should throw ApiTimeoutException');
        expect(caughtException, isA<ApiTimeoutException>());
        expect(caughtException!.code, equals('TIMEOUT'));
      },
    );

    Glados(any.timeoutType, ExploreConfig(numRuns: 100)).test(
      'ApiTimeoutException is catchable as both ApiTimeoutException and ApiException',
      (timeoutType) async {
        mocktail
            .when(() => mockDio.get<Map<String, dynamic>>(
                  '/api/v1/announcements',
                  queryParameters:
                      mocktail.any(named: 'queryParameters'),
                ))
            .thenThrow(DioException(
          type: timeoutType,
          requestOptions: RequestOptions(path: '/api/v1/announcements'),
        ));

        // Test catchable as ApiTimeoutException
        bool caughtAsTimeout = false;
        try {
          await client.listAnnouncements();
        } on ApiTimeoutException {
          caughtAsTimeout = true;
        }
        expect(caughtAsTimeout, isTrue,
            reason: 'Should be catchable as ApiTimeoutException');

        // Test catchable as ApiException (parent sealed class)
        bool caughtAsApiException = false;
        try {
          await client.listAnnouncements();
        } on ApiException {
          caughtAsApiException = true;
        }
        expect(caughtAsApiException, isTrue,
            reason: 'Should be catchable as ApiException');

        // Test does not crash - catchable as Exception
        bool caughtAsException = false;
        try {
          await client.listAnnouncements();
        } on Exception {
          caughtAsException = true;
        }
        expect(caughtAsException, isTrue,
            reason: 'Should be catchable as Exception without crashing');
      },
    );

    Glados(any.timeoutType, ExploreConfig(numRuns: 100)).test(
      'getImage throws ApiTimeoutException for any timeout type',
      (timeoutType) async {
        mocktail
            .when(() => mockDio.get<List<int>>(
                  '/api/v1/images/test-key',
                  options: mocktail.any(named: 'options'),
                ))
            .thenThrow(DioException(
          type: timeoutType,
          requestOptions: RequestOptions(path: '/api/v1/images/test-key'),
        ));

        ApiException? caughtException;
        try {
          await client.getImage('test-key');
        } on ApiTimeoutException catch (e) {
          caughtException = e;
        }

        expect(caughtException, isNotNull,
            reason: 'Timeout type $timeoutType should throw ApiTimeoutException');
        expect(caughtException, isA<ApiTimeoutException>());
        expect(caughtException!.code, equals('TIMEOUT'));
      },
    );

    Glados(any.timeoutType, ExploreConfig(numRuns: 100)).test(
      'advanceComplaintStatus throws ApiTimeoutException for any timeout type',
      (timeoutType) async {
        mocktail
            .when(() => mockDio.patch<Map<String, dynamic>>(
                  '/api/v1/complaints/test-id/status',
                  data: mocktail.any(named: 'data'),
                ))
            .thenThrow(DioException(
          type: timeoutType,
          requestOptions:
              RequestOptions(path: '/api/v1/complaints/test-id/status'),
        ));

        ApiException? caughtException;
        try {
          await client.advanceComplaintStatus('test-id',
              status: 'in_progress');
        } on ApiTimeoutException catch (e) {
          caughtException = e;
        }

        expect(caughtException, isNotNull,
            reason: 'Timeout type $timeoutType should throw ApiTimeoutException');
        expect(caughtException, isA<ApiTimeoutException>());
        expect(caughtException!.code, equals('TIMEOUT'));
      },
    );
  });
}
