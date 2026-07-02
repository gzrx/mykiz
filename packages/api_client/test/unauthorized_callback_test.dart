import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDio extends Mock implements Dio {}

class MockBaseOptions extends Mock implements BaseOptions {}

void main() {
  test('onUnauthorized fires on 401', () async {
    final dio = MockDio();
    final opts = MockBaseOptions();
    when(() => dio.options).thenReturn(opts);
    when(() => opts.headers).thenReturn(<String, dynamic>{});
    var fired = false;
    final client = MyKizApiClient(
      baseUrl: 'http://x',
      dio: dio,
      onUnauthorized: () => fired = true,
    );
    when(() => dio.get<Map<String, dynamic>>(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: '/'),
      response: Response(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 401,
        data: {
          'error': {'code': 'UNAUTHORIZED', 'message': 'nope'}
        },
      ),
    ));

    await expectLater(
      client.listFacilities(),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(fired, isTrue);
  });
}
