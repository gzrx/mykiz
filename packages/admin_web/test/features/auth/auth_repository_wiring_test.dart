import 'package:admin_web/features/auth/application/auth_provider.dart';
import 'package:admin_web/features/auth/data/auth_repository.dart';
import 'package:admin_web/features/auth/data/auth_storage.dart';
import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';

/// This suite covers the CRITICAL finding: a wrong-password login used to
/// show NO error message. The real `apiClientProvider` wires
/// `onUnauthorized` to a fire-and-forget `logout()`. On a 401 during
/// `login()`, `_mapDioException` invokes `onUnauthorized` synchronously
/// *before* `login()`'s catch block finishes setting its `errorMessage`.
/// The resulting `logout()` call then races in and overwrites the state
/// with a bare `AuthState(status: unauthenticated)` (no error message).
///
/// The fix guards the callback with [shouldAutoLogoutOn401] so it only
/// fires when a session actually existed (status `authenticated`); during
/// an in-flight login attempt (`loading`) it must no-op.

class MockDio extends Mock implements Dio {}

class MockBaseOptions extends Mock implements BaseOptions {}

/// In-memory [AuthStorage] fake so tests don't touch real local storage.
class FakeAuthStorage extends AuthStorage {
  @override
  Future<void> save(String token, User user) async {}

  @override
  Future<({String token, User user})?> read() async => null;

  @override
  Future<void> clear() async {}
}

void main() {
  group('shouldAutoLogoutOn401 (guard used by apiClientProvider)', () {
    test('does not auto-logout while a login attempt is in flight', () {
      expect(shouldAutoLogoutOn401(AuthStatus.loading), isFalse);
    });

    test('does not auto-logout when already unauthenticated', () {
      expect(shouldAutoLogoutOn401(AuthStatus.unauthenticated), isFalse);
    });

    test('does not auto-logout while bootstrap status is unresolved', () {
      expect(shouldAutoLogoutOn401(AuthStatus.unknown), isFalse);
    });

    test('auto-logs out when a session was actually established', () {
      expect(shouldAutoLogoutOn401(AuthStatus.authenticated), isTrue);
    });
  });

  group('401 auto-logout guard wired through real login/logout state', () {
    late MockDio dio;

    setUp(() {
      dio = MockDio();
      final opts = MockBaseOptions();
      when(() => dio.options).thenReturn(opts);
      when(() => opts.headers).thenReturn(<String, dynamic>{});
    });

    /// Builds a container whose `apiClientProvider` is overridden with a
    /// [MyKizApiClient] backed by a mock [Dio], wired with the SAME guard
    /// (`shouldAutoLogoutOn401`) that the real `apiClientProvider` uses.
    /// `login()` therefore runs through the real `AuthNotifier` and
    /// `AuthRepository` production code; only the transport is mocked.
    ProviderContainer buildContainer() {
      late ProviderContainer container;
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            MyKizApiClient(
              baseUrl: 'http://test',
              dio: dio,
              onUnauthorized: () {
                if (shouldAutoLogoutOn401(
                    container.read(authProvider).status)) {
                  container.read(authProvider.notifier).logout();
                }
              },
            ),
          ),
          authStorageProvider.overrideWithValue(FakeAuthStorage()),
        ],
      );
      return container;
    }

    test(
      'wrong-password login surfaces the error message; the 401 '
      'auto-logout must not clobber it',
      () async {
        when(() => dio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          response: Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 401,
            data: {
              'error': {
                'code': 'INVALID_CREDENTIALS',
                'message': 'Invalid credentials',
              },
            },
          ),
        ));

        final container = buildContainer();
        addTearDown(container.dispose);

        await container
            .read(authProvider.notifier)
            .login(identifier: 'S12345', password: 'wrongpassword');

        final state = container.read(authProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(state.errorMessage, 'Invalid credentials');
      },
    );
  });
}
