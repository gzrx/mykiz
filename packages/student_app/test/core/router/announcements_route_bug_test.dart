import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:student_app/core/router/app_router.dart';
import 'package:student_app/features/announcements/presentation/announcements_list_screen.dart';
import 'package:student_app/features/auth/application/auth_provider.dart';

/// Bug condition exploration test.
///
/// **Validates: Requirements 1.1, 1.2, 2.1, 2.2**
///
/// Bug condition: navigating to `/announcements` renders a placeholder
/// Scaffold(body: Center(child: Text('Announcements'))) instead of
/// AnnouncementsListScreen.
///
/// This test asserts the EXPECTED (correct) behavior. It will FAIL on
/// unfixed code, proving the bug exists.
void main() {
  group('Bug Condition: /announcements route', () {
    testWidgets(
      'navigating to /announcements renders AnnouncementsListScreen',
      (tester) async {
        final container = ProviderContainer(overrides: [
          authProvider.overrideWith(
            (_) => _FakeAuthNotifier(_authenticatedState()),
          ),
        ]);

        final router = container.read(appRouterProvider);
        router.go('/announcements');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Expected behavior: AnnouncementsListScreen is rendered
        expect(find.byType(AnnouncementsListScreen), findsOneWidget);
      },
    );
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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState) : super(_FakeApiClient());

  final AuthState _initialState;

  @override
  AuthState get state => _initialState;

  @override
  set state(AuthState value) {}
}

class _FakeApiClient extends Fake implements MyKizApiClient {}
