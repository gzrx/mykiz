import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

import 'package:admin_web/core/router/app_router.dart';
import 'package:admin_web/features/auth/application/auth_provider.dart';
import 'package:admin_web/features/auth/data/auth_repository.dart';

/// A fake [AuthRepository] for testing router redirects.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(MyKizApiClient(baseUrl: 'http://test'));

  @override
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    return LoginResponse(
      token: 'test-token',
      user: User(
        id: 'user-1',
        identifier: identifier,
        name: 'Admin',
        role: 'admin',
        createdAt: DateTime(2024, 1, 1),
      ),
    );
  }
}

void main() {
  group('AppRouter redirect guard', () {
    testWidgets('unauthenticated user is shown login screen', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          apiClientProvider.overrideWithValue(
            MyKizApiClient(baseUrl: 'http://test'),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show login screen (contains Staff ID field)
      expect(find.text('Staff ID'), findsOneWidget);
      expect(find.text('MyKIZ Admin'), findsOneWidget);

      container.dispose();
    });

    testWidgets('authenticated user on /login is redirected to announcements',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          apiClientProvider.overrideWithValue(
            MyKizApiClient(baseUrl: 'http://test'),
          ),
        ],
      );

      // Login first
      await container.read(authProvider.notifier).login(
            identifier: 'S12345',
            password: 'password123',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should be redirected away from login to announcements
      expect(find.text('Staff ID'), findsNothing);
      expect(find.text('Announcements'), findsOneWidget);

      container.dispose();
    });
  });
}
