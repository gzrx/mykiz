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
///
/// The "wired through real login/logout state" tests below assert the
/// guard's effect directly on a spy standing in for the real `logout()`
/// call, in addition to the observable state. This is deliberate: in the
/// mocked synchronous-throw setup used here, `logout()`'s continuation
/// (after its `await _storage.clear()` gap) happens to be scheduled as a
/// microtask *before* `login()`'s own catch-block continuation, so
/// `login()`'s state write always runs last and wins regardless of
/// whether the guard exists. Asserting only on the final `errorMessage`
/// would therefore pass even with the guard removed. Verifying the spy
/// call count makes the guard itself the thing under test.
class MockDio extends Mock implements Dio {}

class MockBaseOptions extends Mock implements BaseOptions {}

/// Spy standing in for the real (fire-and-forget) `logout()` call so tests
/// can assert whether the guard let it through, independent of the
/// microtask-ordering coincidence described above.
class MockLogoutSpy extends Mock {
  void call();
}

/// In-memory [AuthStorage] fake so tests don't touch real local storage.
class FakeAuthStorage extends AuthStorage {
  @override
  Future<void> save(String token, User user) async {}

  @override
  Future<({String token, User user})?> read() async => null;

  @override
  Future<void> clear() async {}
}

/// In-memory [AuthStorage] fake that reports an already-persisted session,
/// so `bootstrap()` resolves straight to `AuthStatus.authenticated` without
/// ever passing through `AuthStatus.loading` (unlike `login()`).
class FakeAuthStorageWithSession extends AuthStorage {
  static final _user = User(
    id: 'u1',
    identifier: 'S12345',
    name: 'Test Student',
    role: 'student',
    createdAt: DateTime(2024),
  );

  @override
  Future<void> save(String token, User user) async {}

  @override
  Future<({String token, User user})?> read() async =>
      (token: 'existing-token', user: _user);

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
    late MockLogoutSpy logoutSpy;

    setUp(() {
      dio = MockDio();
      final opts = MockBaseOptions();
      when(() => dio.options).thenReturn(opts);
      when(() => opts.headers).thenReturn(<String, dynamic>{});
      logoutSpy = MockLogoutSpy();
    });

    /// Builds a container whose `apiClientProvider` is overridden with a
    /// [MyKizApiClient] backed by a mock [Dio], wired with the SAME guard
    /// (`shouldAutoLogoutOn401`) that the real `apiClientProvider` uses.
    /// `login()` therefore runs through the real `AuthNotifier` and
    /// `AuthRepository` production code; only the transport is mocked.
    ///
    /// [logoutSpy] is invoked exactly when the guard would let the real
    /// `logout()` call through, mirroring the production wiring's
    /// conditional one-for-one.
    ProviderContainer buildContainer({AuthStorage? storage}) {
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
                  logoutSpy();
                  container.read(authProvider.notifier).logout();
                }
              },
            ),
          ),
          authStorageProvider.overrideWithValue(storage ?? FakeAuthStorage()),
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

        // The guard must have suppressed the auto-logout call entirely: a
        // 401 that occurs while `login()` is still `loading` must never
        // reach `logout()`. This is what actually fails if the guard is
        // removed (the errorMessage assertions above do not, because of
        // the microtask-ordering coincidence documented at the top of this
        // file).
        verifyNever(() => logoutSpy());
      },
    );

    test(
      '401 on a request made while a session is already authenticated '
      'DOES trigger auto-logout',
      () async {
        // Bootstrap (not login()) resolves straight to `authenticated`
        // without ever visiting `loading`, so the guard sees the status
        // this scenario is meant to exercise.
        final container = buildContainer(storage: FakeAuthStorageWithSession());
        addTearDown(container.dispose);

        await container.read(authProvider.notifier).bootstrap();
        expect(container.read(authProvider).status, AuthStatus.authenticated);

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
                'code': 'SESSION_EXPIRED',
                'message': 'Session expired',
              },
            },
          ),
        ));

        // Call the API client directly (bypassing AuthNotifier.login(),
        // which would otherwise force status back to `loading`) so the
        // guard observes the already-authenticated status, just like a
        // stale-token request made from any authenticated screen would.
        await expectLater(
          container
              .read(apiClientProvider)
              .login(identifier: 'S12345', password: 'whatever'),
          throwsA(isA<UnauthorizedException>()),
        );

        // Let the fire-and-forget logout()'s `await storage.clear()`
        // continuation run.
        await pumpEventQueue();

        verify(() => logoutSpy()).called(1);
        expect(container.read(authProvider).status, AuthStatus.unauthenticated);
      },
    );
  });
}
