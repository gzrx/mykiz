import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:student_app/core/router/app_router.dart';
import 'package:student_app/features/auth/application/auth_provider.dart';
import 'package:student_app/features/auth/presentation/login_screen.dart';
import 'package:student_app/features/complaints/presentation/complaints_list_screen.dart';
import 'package:student_app/features/dashboard/presentation/dashboard_screen.dart';

/// Feature: announcement-display-fix, Property 2: Preservation
///
/// **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
///
/// Other routes remain unchanged: /dashboard, /complaints, /login all render
/// their correct screens, and computeRedirect truth table is stable.

void main() {
  // -- Widget tests: route → screen preservation --

  group('Property 2: Preservation – route renders correct screen', () {
    testWidgets('/dashboard renders DashboardScreen', (tester) async {
      // Validates: Requirements 3.1
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          (_) => _FakeAuthNotifier(_authenticatedState()),
        ),
      ]);

      final router = container.read(appRouterProvider);
      router.go('/dashboard');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('/complaints renders ComplaintsListScreen', (tester) async {
      // Validates: Requirements 3.2
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          (_) => _FakeAuthNotifier(_authenticatedState()),
        ),
      ]);

      final router = container.read(appRouterProvider);
      router.go('/complaints');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ComplaintsListScreen), findsOneWidget);
    });

    testWidgets('/login renders LoginScreen', (tester) async {
      // Validates: Requirements 3.3
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
          (_) => _FakeAuthNotifier(const AuthState(
            status: AuthStatus.unauthenticated,
          )),
        ),
      ]);

      final router = container.read(appRouterProvider);
      router.go('/login');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  // -- Unit test: computeRedirect truth table (exhaustive) --

  group('Property 2: Preservation – computeRedirect truth table', () {
    // Validates: Requirements 3.4
    // Exhaustive over finite domain: 3 AuthStatus × representative routes.

    const routes = [
      '/login',
      '/dashboard',
      '/announcements',
      '/complaints',
      '/complaints/new',
      '/complaints/123',
    ];

    test('exhaustive truth table matches expected redirects', () {
      for (final status in AuthStatus.values) {
        for (final route in routes) {
          final result = computeRedirect(status, route);

          // Compute expected per the defined redirect logic
          final String? expected;
          if (status == AuthStatus.unknown) {
            expected = null;
          } else if (status == AuthStatus.loading) {
            expected = null;
          } else if (status == AuthStatus.authenticated &&
              route == '/login') {
            expected = '/dashboard';
          } else if (status == AuthStatus.authenticated) {
            expected = null;
          } else if (status == AuthStatus.unauthenticated &&
              route == '/login') {
            expected = null;
          } else {
            // unauthenticated + non-login
            expected = '/login';
          }

          expect(result, expected,
              reason:
                  'computeRedirect($status, "$route") = $result, expected $expected');
        }
      }
    });
  });
}

// -- Test helpers (mirrored from existing app_router_test.dart) --

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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState) : super(_FakeApiClient());

  final AuthState _initialState;

  @override
  AuthState get state => _initialState;

  @override
  set state(AuthState value) {}
}

class _FakeApiClient extends Fake implements MyKizApiClient {}
