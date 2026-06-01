import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

import 'package:admin_web/features/auth/application/auth_provider.dart';
import 'package:admin_web/features/auth/data/auth_repository.dart';

/// A fake [AuthRepository] for testing.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(MyKizApiClient(baseUrl: 'http://test'));

  bool shouldFail = false;
  String failCode = 'INVALID_CREDENTIALS';
  String failMessage = 'Invalid credentials';

  @override
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    if (shouldFail) {
      throw UnauthorizedException(code: failCode, message: failMessage);
    }
    return LoginResponse(
      token: 'test-jwt-token',
      user: User(
        id: 'user-uuid-123',
        identifier: identifier,
        name: 'Test Admin',
        role: 'admin',
        createdAt: DateTime(2024, 1, 1),
      ),
    );
  }
}

void main() {
  group('AuthNotifier', () {
    late ProviderContainer container;
    late FakeAuthRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          apiClientProvider.overrideWithValue(
            MyKizApiClient(baseUrl: 'http://test'),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is unauthenticated', () {
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.token, isNull);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('successful login sets authenticated state with token and user', () async {
      final notifier = container.read(authProvider.notifier);

      await notifier.login(identifier: 'S12345', password: 'password123');

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.token, 'test-jwt-token');
      expect(state.user, isNotNull);
      expect(state.user!.identifier, 'S12345');
      expect(state.user!.role, 'admin');
      expect(state.errorMessage, isNull);
    });

    test('failed login sets error message and remains unauthenticated', () async {
      fakeRepo.shouldFail = true;
      fakeRepo.failMessage = 'Invalid ID or password';

      final notifier = container.read(authProvider.notifier);

      await notifier.login(identifier: 'wrong', password: 'wrong');

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.token, isNull);
      expect(state.user, isNull);
      expect(state.errorMessage, 'Invalid ID or password');
    });

    test('logout clears auth state', () async {
      final notifier = container.read(authProvider.notifier);

      // First login
      await notifier.login(identifier: 'S12345', password: 'password123');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      // Then logout
      notifier.logout();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.token, isNull);
      expect(state.user, isNull);
    });

    test('isAuthenticated returns true only when authenticated', () async {
      final notifier = container.read(authProvider.notifier);

      expect(container.read(authProvider).isAuthenticated, isFalse);

      await notifier.login(identifier: 'S12345', password: 'password123');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      notifier.logout();
      expect(container.read(authProvider).isAuthenticated, isFalse);
    });
  });
}
