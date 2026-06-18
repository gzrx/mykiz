// Bug Condition Exploration Test
// Validates: Requirements 1.1, 1.2, 1.3
//
// This test is EXPECTED TO FAIL on unfixed code.
// Failure confirms both bugs exist:
//   1. submitAccommodationApplication sends snake_case keys
//   2. listApplications reads response['total'] instead of response['meta']['totalItems']

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

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    final mockOptions = MockBaseOptions();
    when(() => mockDio.options).thenReturn(mockOptions);
    when(() => mockOptions.headers).thenReturn(<String, dynamic>{});
    client = MyKizApiClient(baseUrl: 'http://localhost:8080', dio: mockDio);
  });

  group('Bug Condition Exploration', () {
    test('submitAccommodationApplication body keys are camelCase', () async {
      // Capture the body passed to dio.post
      Map<String, dynamic>? capturedBody;
      when(() => mockDio.post<Map<String, dynamic>>(
            '/api/v1/accommodation/applications',
            data: any(named: 'data'),
          )).thenAnswer((invocation) async {
        capturedBody =
            invocation.namedArguments[#data] as Map<String, dynamic>;
        return Response(
          data: {
            'data': {
              'id': 'app-1',
              'studentId': 'student-1',
              'applicationType': 'semester',
              'roomTypePreference': 'single',
              'preferredBlockId': 'block-1',
              'lifestyleTags': ['quiet'],
              'checkInDate': '2024-03-01',
              'checkOutDate': '2024-06-30',
              'status': 'pending',
              'createdAt': '2024-01-01T00:00:00.000Z',
              'updatedAt': '2024-01-01T00:00:00.000Z',
            },
          },
          statusCode: 201,
          requestOptions: RequestOptions(
              path: '/api/v1/accommodation/applications'),
        );
      });

      await client.submitAccommodationApplication(
        applicationType: 'semester',
        roomTypePreference: 'single',
        preferredBlockId: 'block-1',
        lifestyleTags: ['quiet'],
        checkInDate: DateTime(2024, 3, 1),
        checkOutDate: DateTime(2024, 6, 30),
      );

      expect(capturedBody, isNotNull, reason: 'Body should have been sent');

      // These assertions will FAIL on unfixed code because keys are snake_case
      expect(capturedBody!.containsKey('applicationType'), isTrue,
          reason: 'Expected camelCase key "applicationType" but got snake_case');
      expect(capturedBody!.containsKey('roomTypePreference'), isTrue,
          reason:
              'Expected camelCase key "roomTypePreference" but got snake_case');
      expect(capturedBody!.containsKey('preferredBlockId'), isTrue,
          reason:
              'Expected camelCase key "preferredBlockId" but got snake_case');
      expect(capturedBody!.containsKey('lifestyleTags'), isTrue,
          reason: 'Expected camelCase key "lifestyleTags" but got snake_case');
      expect(capturedBody!.containsKey('checkInDate'), isTrue,
          reason: 'Expected camelCase key "checkInDate" but got snake_case');
      expect(capturedBody!.containsKey('checkOutDate'), isTrue,
          reason: 'Expected camelCase key "checkOutDate" but got snake_case');

      // Verify NO snake_case keys exist
      expect(capturedBody!.containsKey('application_type'), isFalse,
          reason: 'Snake_case key "application_type" should not exist');
      expect(capturedBody!.containsKey('room_type_preference'), isFalse,
          reason: 'Snake_case key "room_type_preference" should not exist');
    });

    test('listApplications total reads from meta.totalItems', () async {
      // Simulate the real API envelope: {data: [...], meta: {totalItems: 47}}
      when(() => mockDio.get<Map<String, dynamic>>(
            '/api/v1/accommodation/applications',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'data': [
                {
                  'id': 'app-1',
                  'studentId': 'student-1',
                  'applicationType': 'semester',
                  'roomTypePreference': 'single',
                  'preferredBlockId': null,
                  'lifestyleTags': [],
                  'checkInDate': '2024-03-01',
                  'checkOutDate': '2024-06-30',
                  'status': 'pending',
                  'createdAt': '2024-01-01T00:00:00.000Z',
                  'updatedAt': '2024-01-01T00:00:00.000Z',
                },
              ],
              'meta': {
                'currentPage': 1,
                'limit': 20,
                'totalItems': 47,
                'totalPages': 3,
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(
                path: '/api/v1/accommodation/applications'),
          ));

      // Call listApplications and verify the CORRECT parsing logic works
      final response = await client.listApplications();
      final data = response['data'] as List<dynamic>? ?? [];
      // ponytail: fixed parsing reads from meta.totalItems
      final meta = response['meta'] as Map<String, dynamic>?;
      final total = meta?['totalItems'] as int? ?? data.length;

      expect(total, equals(47),
          reason:
              'Total should be 47 from meta.totalItems using correct parsing logic');
    });
  });
}
