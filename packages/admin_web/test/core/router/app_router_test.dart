import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';

import 'package:admin_web/core/router/app_router.dart';
import 'package:admin_web/features/auth/application/auth_provider.dart';
import 'package:admin_web/features/auth/data/auth_repository.dart';
import 'package:admin_web/features/auth/data/auth_storage.dart';

/// Fake repository that always succeeds login.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(MyKizApiClient(baseUrl: 'http://test'));

  @override
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    return LoginResponse(
      token: 'tok',
      user: User(
        id: '1',
        identifier: identifier,
        name: 'Test',
        role: 'admin',
        createdAt: DateTime(2024),
      ),
    );
  }
}

/// Fake [AuthStorage] that never has a persisted session, so `bootstrap()`
/// resolves straight to `unauthenticated` in tests.
class FakeAuthStorage extends AuthStorage {
  @override
  Future<void> save(String token, User user) async {}

  @override
  Future<({String token, User user})?> read() async => null;

  @override
  Future<void> clear() async {}
}

/// Creates a [ProviderContainer] with standard test overrides.
ProviderContainer _container() => ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        apiClientProvider.overrideWithValue(
          MyKizApiClient(baseUrl: 'http://test'),
        ),
        authStorageProvider.overrideWithValue(FakeAuthStorage()),
      ],
    );

/// Pumps a [MaterialApp.router] wired to [appRouterProvider].
Future<void> _pumpRouter(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    ),
  );
}

void main() {
  group('AppRouter redirect guard', () {
    // Requirement 1.2: Unauthenticated on /dashboard → /login
    testWidgets('unauthenticated user on /dashboard redirects to /login',
        (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      // Resolve the initial `unknown` status to `unauthenticated` (no
      // persisted session), mirroring what happens at real app startup.
      await container.read(authProvider.notifier).bootstrap();

      // Router initial location is /login, but redirect logic should guard
      // /dashboard → /login for unauthenticated users. Verify via router
      // redirect function directly.
      final router = container.read(appRouterProvider);
      // Navigate to /dashboard
      router.go('/dashboard');
      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      // Should show login (Staff ID field) since user is unauthenticated
      expect(find.text('Staff ID'), findsOneWidget);
    });

    // Requirement 1.1: Authenticated on /login → /overview
    testWidgets('authenticated user on /login redirects to /overview',
        (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      // Authenticate
      await container
          .read(authProvider.notifier)
          .login(identifier: 'S1', password: 'p');

      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      // Initial location is /login → should redirect to /overview
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Staff ID'), findsNothing);
    });

    // Requirement 1.3: Authenticated on / → /overview
    testWidgets('authenticated user on / redirects to /overview',
        (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await container
          .read(authProvider.notifier)
          .login(identifier: 'S1', password: 'p');

      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      final router = container.read(appRouterProvider);
      router.go('/');
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsWidgets);
    });

    // Requirement 1.4: Authenticated user accessing /login directly → /overview
    testWidgets(
        'authenticated user accessing /login directly redirects to /overview',
        (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await container
          .read(authProvider.notifier)
          .login(identifier: 'S1', password: 'p');

      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      // Explicitly navigate to /login while authenticated
      final router = container.read(appRouterProvider);
      router.go('/login');
      await tester.pumpAndSettle();

      // Should still be on overview
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Staff ID'), findsNothing);
    });

    // Legacy /dashboard path redirects authenticated users to /overview.
    testWidgets('authenticated user on /dashboard redirects to /overview',
        (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await container
          .read(authProvider.notifier)
          .login(identifier: 'S1', password: 'p');

      await _pumpRouter(tester, container);
      await tester.pumpAndSettle();

      final router = container.read(appRouterProvider);
      router.go('/dashboard');
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsWidgets);
    });
  });
}
