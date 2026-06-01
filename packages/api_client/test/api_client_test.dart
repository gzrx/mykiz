import 'dart:typed_data';

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

  group('MyKizApiClient', () {
    group('setToken / clearToken', () {
      test('setToken sets Authorization header', () {
        final headers = <String, dynamic>{};
        when(() => mockOptions.headers).thenReturn(headers);

        client.setToken('test-token');

        expect(headers['Authorization'], equals('Bearer test-token'));
      });

      test('clearToken removes Authorization header', () {
        final headers = <String, dynamic>{'Authorization': 'Bearer old'};
        when(() => mockOptions.headers).thenReturn(headers);

        client.clearToken();

        expect(headers.containsKey('Authorization'), isFalse);
      });
    });

    group('login', () {
      test('returns LoginResponse on success', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              '/api/v1/auth/login',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'data': {
                  'token': 'jwt-token-123',
                  'user': {
                    'id': 'uuid-1',
                    'identifier': 'A123456',
                    'name': 'Test Student',
                    'role': 'student',
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  },
                },
                'meta': null,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/auth/login'),
            ));

        final result = await client.login(
          identifier: 'A123456',
          password: 'password123',
        );

        expect(result.token, equals('jwt-token-123'));
        expect(result.user.id, equals('uuid-1'));
        expect(result.user.role, equals('student'));
      });

      test('throws UnauthorizedException on 401', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              '/api/v1/auth/login',
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          response: Response(
            statusCode: 401,
            data: {
              'error': {
                'code': 'INVALID_CREDENTIALS',
                'message': 'Invalid identifier or password',
              },
            },
            requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          ),
        ));

        expect(
          () => client.login(identifier: 'bad', password: 'bad'),
          throwsA(isA<UnauthorizedException>().having(
            (e) => e.code,
            'code',
            'INVALID_CREDENTIALS',
          )),
        );
      });
    });

    group('announcements', () {
      test('listAnnouncements returns paginated response', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'data': [
                  {
                    'id': 'ann-1',
                    'title': 'Test',
                    'body': 'Body text',
                    'authorId': 'admin-1',
                    'createdAt': '2024-01-01T00:00:00.000Z',
                    'updatedAt': '2024-01-01T00:00:00.000Z',
                  },
                ],
                'meta': {
                  'currentPage': 1,
                  'limit': 20,
                  'totalItems': 1,
                  'totalPages': 1,
                },
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/announcements'),
            ));

        final result = await client.listAnnouncements();

        expect(result.items.length, equals(1));
        expect(result.items.first.title, equals('Test'));
        expect(result.meta.totalItems, equals(1));
      });

      test('getAnnouncement returns single announcement', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/ann-1',
            )).thenAnswer((_) async => Response(
              data: {
                'data': {
                  'id': 'ann-1',
                  'title': 'Test',
                  'body': 'Body text',
                  'authorId': 'admin-1',
                  'createdAt': '2024-01-01T00:00:00.000Z',
                  'updatedAt': '2024-01-01T00:00:00.000Z',
                },
                'meta': null,
              },
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: '/api/v1/announcements/ann-1'),
            ));

        final result = await client.getAnnouncement('ann-1');

        expect(result.id, equals('ann-1'));
        expect(result.title, equals('Test'));
      });

      test('createAnnouncement returns created announcement', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              '/api/v1/announcements',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'data': {
                  'id': 'ann-new',
                  'title': 'New Title',
                  'body': 'New Body',
                  'authorId': 'admin-1',
                  'createdAt': '2024-01-01T00:00:00.000Z',
                  'updatedAt': '2024-01-01T00:00:00.000Z',
                },
                'meta': null,
              },
              statusCode: 201,
              requestOptions: RequestOptions(path: '/api/v1/announcements'),
            ));

        final result = await client.createAnnouncement(
          title: 'New Title',
          body: 'New Body',
        );

        expect(result.id, equals('ann-new'));
        expect(result.title, equals('New Title'));
      });

      test('deleteAnnouncement completes without error', () async {
        when(() => mockDio.delete<Map<String, dynamic>>(
              '/api/v1/announcements/ann-1',
            )).thenAnswer((_) async => Response(
              data: {'data': null, 'meta': null},
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: '/api/v1/announcements/ann-1'),
            ));

        await expectLater(
          client.deleteAnnouncement('ann-1'),
          completes,
        );
      });

      test('throws NotFoundException on 404', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements/missing',
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions:
              RequestOptions(path: '/api/v1/announcements/missing'),
          response: Response(
            statusCode: 404,
            data: {
              'error': {
                'code': 'NOT_FOUND',
                'message': 'Announcement not found',
              },
            },
            requestOptions:
                RequestOptions(path: '/api/v1/announcements/missing'),
          ),
        ));

        expect(
          () => client.getAnnouncement('missing'),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('complaints', () {
      test('listComplaints returns paginated response', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/complaints',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'data': [
                  {
                    'id': 'cmp-1',
                    'studentId': 'student-1',
                    'description': 'Broken pipe',
                    'location': 'Room 101',
                    'imageKey': null,
                    'status': 'submitted',
                    'createdAt': '2024-01-01T00:00:00.000Z',
                    'updatedAt': '2024-01-01T00:00:00.000Z',
                  },
                ],
                'meta': {
                  'currentPage': 1,
                  'limit': 20,
                  'totalItems': 1,
                  'totalPages': 1,
                },
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/complaints'),
            ));

        final result = await client.listComplaints();

        expect(result.items.length, equals(1));
        expect(result.items.first.description, equals('Broken pipe'));
      });

      test('advanceComplaintStatus returns updated complaint', () async {
        when(() => mockDio.patch<Map<String, dynamic>>(
              '/api/v1/complaints/cmp-1/status',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'data': {
                  'id': 'cmp-1',
                  'studentId': 'student-1',
                  'description': 'Broken pipe',
                  'location': 'Room 101',
                  'imageKey': null,
                  'status': 'in_progress',
                  'createdAt': '2024-01-01T00:00:00.000Z',
                  'updatedAt': '2024-01-02T00:00:00.000Z',
                },
                'meta': null,
              },
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: '/api/v1/complaints/cmp-1/status'),
            ));

        final result = await client.advanceComplaintStatus(
          'cmp-1',
          status: 'in_progress',
        );

        expect(result.status, equals('in_progress'));
      });
    });

    group('images', () {
      test('getImage returns bytes', () async {
        final imageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
        when(() => mockDio.get<List<int>>(
              '/api/v1/images/test-key',
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response(
              data: imageBytes.toList(),
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/images/test-key'),
            ));

        final result = await client.getImage('test-key');

        expect(result, equals(imageBytes));
      });
    });

    group('error mapping', () {
      test('maps timeout to ApiTimeoutException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements',
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/api/v1/announcements'),
        ));

        expect(
          () => client.listAnnouncements(),
          throwsA(isA<ApiTimeoutException>()),
        );
      });

      test('maps 403 to ForbiddenException', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              '/api/v1/announcements',
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements'),
          response: Response(
            statusCode: 403,
            data: {
              'error': {
                'code': 'FORBIDDEN',
                'message': 'Admin access required',
              },
            },
            requestOptions: RequestOptions(path: '/api/v1/announcements'),
          ),
        ));

        expect(
          () => client.createAnnouncement(title: 'T', body: 'B'),
          throwsA(isA<ForbiddenException>().having(
            (e) => e.code,
            'code',
            'FORBIDDEN',
          )),
        );
      });

      test('maps 400 to ValidationException', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              '/api/v1/announcements',
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements'),
          response: Response(
            statusCode: 400,
            data: {
              'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'Title is required',
              },
            },
            requestOptions: RequestOptions(path: '/api/v1/announcements'),
          ),
        ));

        expect(
          () => client.createAnnouncement(title: '', body: 'B'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('maps 500 to ServerException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements',
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/api/v1/announcements'),
          response: Response(
            statusCode: 500,
            data: {
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Something went wrong',
              },
            },
            requestOptions: RequestOptions(path: '/api/v1/announcements'),
          ),
        ));

        expect(
          () => client.listAnnouncements(),
          throwsA(isA<ServerException>()),
        );
      });

      test('maps connection error to ServerException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              '/api/v1/announcements',
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/api/v1/announcements'),
          message: 'Connection refused',
        ));

        expect(
          () => client.listAnnouncements(),
          throwsA(isA<ServerException>().having(
            (e) => e.code,
            'code',
            'CONNECTION_ERROR',
          )),
        );
      });
    });
  });
}
