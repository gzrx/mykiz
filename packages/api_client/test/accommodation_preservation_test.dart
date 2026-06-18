// Preservation Property Tests (Task 2)
// Validates: Requirements 3.1, 3.2, 3.3, 3.4
//
// These tests MUST PASS on unfixed code.
// They confirm baseline behavior that must not regress after the fix:
//   - getAccommodationSettings parses applications_open correctly
//   - getMyApplications returns active and history lists
//   - listApplications data array parsing produces correct application objects

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

class MockDio extends mocktail.Mock implements Dio {}

class MockBaseOptions extends mocktail.Mock implements BaseOptions {}

class FakeRequestOptions extends mocktail.Fake implements RequestOptions {}

/// Generators for preservation property tests.
extension PreservationGenerators on Any {
  /// Generates a random bool for applications_open setting.
  Generator<bool> get applicationOpen => simple(
        generate: (random, size) => random.nextBool(),
        shrink: (input) => [],
      );

  /// Generates a list of 0..5 valid application JSON maps.
  Generator<List<Map<String, dynamic>>> get applicationJsonList => simple(
        generate: (random, size) {
          final count = random.nextInt(6);
          return List.generate(count, (i) => _randomApplicationJson(random, i));
        },
        shrink: (input) => input.isEmpty ? [] : [input.sublist(0, input.length - 1)],
      );
}

Map<String, dynamic> _randomApplicationJson(Object random, int index) {
  // ponytail: minimal valid JSON that AccommodationApplication.fromJson accepts
  final r = random as dynamic;
  final types = ['semester', 'out_of_semester'];
  final statuses = ['pending', 'approved', 'rejected', 'checked_in', 'checked_out'];
  return {
    'id': 'app-$index',
    'studentId': 'student-$index',
    'applicationType': types[index % types.length],
    'status': statuses[index % statuses.length],
    'lifestyleTags': <String>[],
    'createdAt': '2024-01-0${(index % 9) + 1}T00:00:00.000Z',
    'updatedAt': '2024-01-0${(index % 9) + 1}T00:00:00.000Z',
  };
}

void main() {
  late MockDio mockDio;
  late MyKizApiClient client;

  setUpAll(() {
    mocktail.registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    final mockOptions = MockBaseOptions();
    mocktail.when(() => mockDio.options).thenReturn(mockOptions);
    mocktail.when(() => mockOptions.headers).thenReturn(<String, dynamic>{});
    client = MyKizApiClient(baseUrl: 'http://localhost:8080', dio: mockDio);
  });

  group('Property 2: Preservation - Other Accommodation Endpoints Unchanged', () {
    // **Validates: Requirements 3.1**
    Glados(any.applicationOpen, ExploreConfig(numRuns: 50)).test(
      'getAccommodationSettings parses applications_open correctly for any bool value',
      (openValue) async {
        mocktail
            .when(() => mockDio.get<Map<String, dynamic>>(
                  '/api/v1/accommodation/settings',
                ))
            .thenAnswer((_) async => Response(
                  data: {
                    'data': {'applications_open': openValue},
                  },
                  statusCode: 200,
                  requestOptions:
                      RequestOptions(path: '/api/v1/accommodation/settings'),
                ));

        final settings = await client.getAccommodationSettings();
        expect(settings['applications_open'], equals(openValue));
      },
    );

    // **Validates: Requirements 3.2**
    Glados2(any.applicationJsonList, any.applicationJsonList,
            ExploreConfig(numRuns: 50))
        .test(
      'getMyApplications parses active and history lists correctly for any valid applications',
      (activeApps, historyApps) async {
        mocktail
            .when(() => mockDio.get<Map<String, dynamic>>(
                  '/api/v1/accommodation/my-applications',
                ))
            .thenAnswer((_) async => Response(
                  data: {
                    'data': {
                      'active': activeApps,
                      'history': historyApps,
                    },
                  },
                  statusCode: 200,
                  requestOptions: RequestOptions(
                      path: '/api/v1/accommodation/my-applications'),
                ));

        final result = await client.getMyApplications();
        expect(result.active.length, equals(activeApps.length));
        expect(result.history.length, equals(historyApps.length));

        // Verify each application's id is preserved
        for (var i = 0; i < activeApps.length; i++) {
          expect(result.active[i].id, equals(activeApps[i]['id']));
          expect(result.active[i].applicationType,
              equals(activeApps[i]['applicationType']));
        }
        for (var i = 0; i < historyApps.length; i++) {
          expect(result.history[i].id, equals(historyApps[i]['id']));
          expect(result.history[i].status, equals(historyApps[i]['status']));
        }
      },
    );

    // **Validates: Requirements 3.3, 3.4**
    Glados(any.applicationJsonList, ExploreConfig(numRuns: 50)).test(
      'listApplications data array parsing produces correct application objects',
      (apps) async {
        mocktail
            .when(() => mockDio.get<Map<String, dynamic>>(
                  '/api/v1/accommodation/applications',
                  queryParameters:
                      mocktail.any(named: 'queryParameters'),
                ))
            .thenAnswer((_) async => Response(
                  data: {
                    'data': apps,
                    'meta': {
                      'currentPage': 1,
                      'limit': 20,
                      'totalItems': apps.length + 10,
                      'totalPages': 2,
                    },
                  },
                  statusCode: 200,
                  requestOptions: RequestOptions(
                      path: '/api/v1/accommodation/applications'),
                ));

        // listApplications returns raw response Map
        final response = await client.listApplications();
        final data = response['data'] as List<dynamic>? ?? [];

        // Verify data array parsing (this is the part that works correctly now)
        final items = data
            .map((e) => AccommodationApplication.fromJson(
                e as Map<String, dynamic>))
            .toList();

        expect(items.length, equals(apps.length));
        for (var i = 0; i < apps.length; i++) {
          expect(items[i].id, equals(apps[i]['id']));
          expect(items[i].studentId, equals(apps[i]['studentId']));
          expect(items[i].applicationType, equals(apps[i]['applicationType']));
          expect(items[i].status, equals(apps[i]['status']));
        }
      },
    );
  });
}
