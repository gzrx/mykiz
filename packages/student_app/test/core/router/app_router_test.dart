import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:student_app/core/router/app_router.dart';
import 'package:student_app/features/auth/application/auth_provider.dart';

void main() {
  group('computeRedirect', () {
    test('unknown status stays (no redirect, no flash)', () {
      expect(computeRedirect(AuthStatus.unknown, '/dashboard'), isNull);
    });
    test('unauthenticated on /dashboard -> /login', () {
      expect(
        computeRedirect(AuthStatus.unauthenticated, '/dashboard'),
        '/login',
      );
    });
    test('loading on /login stays', () {
      expect(computeRedirect(AuthStatus.loading, '/login'), isNull);
    });
    test('loading on /dashboard -> /login (no pre-token dashboard flash)', () {
      // Regression: during login the router rebuilds and resets to its
      // initialLocation (/dashboard). If `loading` passed through, the
      // dashboard would build before the token is set and its module tiles
      // would fire tokenless 401s (announcements/accommodation bugs).
      expect(computeRedirect(AuthStatus.loading, '/dashboard'), '/login');
    });
    test('authenticated on /login -> /dashboard', () {
      expect(
        computeRedirect(AuthStatus.authenticated, '/login'),
        '/dashboard',
      );
    });
  });

  group('Router integration - auth redirects', () {
    testWidgets('authenticated user lands on /dashboard', (tester) async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          (_) => _FakeAuthNotifier(_authenticatedState()),
        ),
      ]);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Should stay on /dashboard and render DashboardScreen content
      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
    });

    testWidgets('unauthenticated user on /dashboard redirects to /login',
        (tester) async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          (_) => _FakeAuthNotifier(const AuthState(
            status: AuthStatus.unauthenticated,
          )),
        ),
      ]);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Should redirect to /login
      expect(router.routeInformationProvider.value.uri.path, '/login');
    });

    testWidgets('authenticated user on /login redirects to /dashboard',
        (tester) async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          (_) => _FakeAuthNotifier(_authenticatedState()),
        ),
      ]);

      final router = container.read(appRouterProvider);
      // Navigate to /login programmatically
      router.go('/login');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Should redirect to /dashboard
      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
    });
  });
}

AuthState _authenticatedState() => AuthState(
      status: AuthStatus.authenticated,
      token: 'test-token',
      user: User(
        id: '1',
        identifier: 'test-student',
        name: 'Test User',
        role: 'student',
        createdAt: DateTime(2024, 1, 1),
      ),
    );

/// A fake AuthNotifier that immediately emits a fixed state.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState) : super(_FakeApiClient());

  final AuthState _initialState;

  @override
  AuthState get state => _initialState;

  @override
  set state(AuthState value) {
    // no-op for testing
  }
}

/// Minimal fake API client for AuthNotifier instantiation.
class _FakeApiClient extends Fake implements MyKizApiClient {}
