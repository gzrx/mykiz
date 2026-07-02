import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

import 'package:admin_web/features/auth/application/auth_provider.dart';
import 'package:admin_web/features/auth/data/auth_repository.dart';
import 'package:admin_web/features/auth/data/auth_storage.dart';

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

/// A spy [MyKizApiClient] that records the last token set on it, so tests
/// can assert `setToken` was called without reaching into Dio internals.
class SpyApiClient extends MyKizApiClient {
  SpyApiClient() : super(baseUrl: 'http://test');

  String? lastSetToken;

  @override
  void setToken(String token) {
    lastSetToken = token;
    super.setToken(token);
  }
}

/// A fake [AuthStorage] for testing that keeps the "persisted" session in
/// memory instead of touching real local storage.
class FakeAuthStorage extends AuthStorage {
  ({String token, User user})? savedSession;
  bool cleared = false;
  final List<({String token, User user})> saveCalls = [];

  @override
  Future<void> save(String token, User user) async {
    saveCalls.add((token: token, user: user));
    savedSession = (token: token, user: user);
  }

  @override
  Future<({String token, User user})?> read() async => savedSession;

  @override
  Future<void> clear() async {
    cleared = true;
    savedSession = null;
  }
}

void main() {
  group('AuthNotifier', () {
    late ProviderContainer container;
    late FakeAuthRepository fakeRepo;
    late FakeAuthStorage fakeStorage;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      fakeStorage = FakeAuthStorage();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          apiClientProvider.overrideWithValue(
            MyKizApiClient(baseUrl: 'http://test'),
          ),
          authStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is unknown', () {
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unknown);
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

    test('successful login persists the session to storage', () async {
      final notifier = container.read(authProvider.notifier);

      await notifier.login(identifier: 'S12345', password: 'password123');

      expect(fakeStorage.saveCalls, hasLength(1));
      expect(fakeStorage.saveCalls.single.token, 'test-jwt-token');
      expect(fakeStorage.saveCalls.single.user.identifier, 'S12345');
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

    test('logout clears auth state and storage', () async {
      final notifier = container.read(authProvider.notifier);

      // First login
      await notifier.login(identifier: 'S12345', password: 'password123');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      // Then logout
      await notifier.logout();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.token, isNull);
      expect(state.user, isNull);
      expect(fakeStorage.cleared, isTrue);
    });

    test('isAuthenticated returns true only when authenticated', () async {
      final notifier = container.read(authProvider.notifier);

      expect(container.read(authProvider).isAuthenticated, isFalse);

      await notifier.login(identifier: 'S12345', password: 'password123');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      await notifier.logout();
      expect(container.read(authProvider).isAuthenticated, isFalse);
    });

    test('bootstrap restores persisted session and sets token on client', () async {
      final spyApiClient = SpyApiClient();
      fakeStorage.savedSession = (
        token: 'persisted-token',
        user: User(
          id: 'user-uuid-999',
          identifier: 'S99999',
          name: 'Persisted User',
          role: 'admin',
          createdAt: DateTime(2024, 1, 1),
        ),
      );

      final bootstrapContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          apiClientProvider.overrideWithValue(spyApiClient),
          authStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(bootstrapContainer.dispose);

      await bootstrapContainer.read(authProvider.notifier).bootstrap();

      final state = bootstrapContainer.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.token, 'persisted-token');
      expect(state.user!.identifier, 'S99999');
      expect(spyApiClient.lastSetToken, 'persisted-token');
    });

    test('bootstrap with no persisted session ends unauthenticated', () async {
      fakeStorage.savedSession = null;

      final bootstrapContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          apiClientProvider.overrideWithValue(
            MyKizApiClient(baseUrl: 'http://test'),
          ),
          authStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(bootstrapContainer.dispose);

      await bootstrapContainer.read(authProvider.notifier).bootstrap();

      final state = bootstrapContainer.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.token, isNull);
      expect(state.user, isNull);
    });
  });
}
