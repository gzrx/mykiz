import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDio extends Mock implements Dio {}
class MockBaseOptions extends Mock implements BaseOptions {}

void main() {
  late MockDio dio;
  late MyKizApiClient client;

  setUp(() {
    dio = MockDio();
    final opts = MockBaseOptions();
    when(() => dio.options).thenReturn(opts);
    when(() => opts.headers).thenReturn(<String, dynamic>{});
    client = MyKizApiClient(baseUrl: 'http://x', dio: dio);
  });

  Response<Map<String, dynamic>> resp(Map<String, dynamic> body) => Response(
        data: body,
        requestOptions: RequestOptions(path: '/'),
        statusCode: 200,
      );

  test('listBookings tolerates null meta', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/bookings',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => resp({'data': <dynamic>[], 'meta': null}));

    final result = await client.listBookings(type: 'active');
    expect(result.items, isEmpty);
    expect(result.meta.totalItems, 0);
    expect(result.meta.currentPage, 1);
  });

  test('listAllBookings tolerates null meta', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/admin/bookings',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => resp({'data': <dynamic>[], 'meta': null}));

    final result = await client.listAllBookings();
    expect(result.items, isEmpty);
    expect(result.meta.totalItems, 0);
  });

  test('listAnnouncements tolerates null meta', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/announcements',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => resp({'data': <dynamic>[], 'meta': null}));

    final result = await client.listAnnouncements();
    expect(result.items, isEmpty);
    expect(result.meta.totalItems, 0);
    expect(result.meta.currentPage, 1);
  });

  test('listComplaints tolerates null meta', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/complaints',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => resp({'data': <dynamic>[], 'meta': null}));

    final result = await client.listComplaints();
    expect(result.items, isEmpty);
    expect(result.meta.totalItems, 0);
    expect(result.meta.currentPage, 1);
  });

  test('getOccupancy parses RoomOccupancy list', () async {
    when(() => dio.get<Map<String, dynamic>>('/api/v1/accommodation/occupancy',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => resp({
              'data': [
                {
                  'roomId': 'r1',
                  'roomNumber': 'A-101',
                  'roomType': 'single',
                  'total': 1,
                  'occupied': 1,
                }
              ],
              'meta': null,
            }));

    final rooms = await client.getOccupancy('block-1');
    expect(rooms, hasLength(1));
    expect(rooms.first.occupied, 1);
    expect(rooms.first.roomNumber, 'A-101');
  });
}
