import 'package:api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';
import 'package:student_app/features/auth/application/auth_provider.dart';

class MockMyKizApiClient extends Mock implements MyKizApiClient {}

void main() {
  late MockMyKizApiClient mockApiClient;
  late AuthNotifier authNotifier;

  setUp(() {
    mockApiClient = MockMyKizApiClient();
    authNotifier = AuthNotifier(mockApiClient);
  });

  group('AuthNotifier', () {
    test('initial state is unauthenticated', () {
      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.token, isNull);
      expect(authNotifier.state.user, isNull);
      expect(authNotifier.state.errorMessage, isNull);
    });

    test('login sets state to loading then authenticated on success',
        () async {
      final user = User(
        id: 'user-123',
        identifier: 'A123456',
        name: 'Test Student',
        role: 'student',
        createdAt: DateTime(2024, 1, 1),
      );
      final loginResponse = LoginResponse(token: 'jwt-token', user: user);

      when(() => mockApiClient.login(
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => loginResponse);

      when(() => mockApiClient.setToken(any())).thenReturn(null);

      final states = <AuthState>[];
      authNotifier.addListener((state) {
        states.add(state);
      });

      await authNotifier.login(
        identifier: 'A123456',
        password: 'password123',
      );

      // Should have gone through loading → authenticated
      expect(states.any((s) => s.status == AuthStatus.loading), isTrue);
      expect(authNotifier.state.status, AuthStatus.authenticated);
      expect(authNotifier.state.token, 'jwt-token');
      expect(authNotifier.state.user, user);
      expect(authNotifier.state.errorMessage, isNull);

      verify(() => mockApiClient.setToken('jwt-token')).called(1);
    });

    test('login sets error message on invalid credentials', () async {
      when(() => mockApiClient.login(
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
          )).thenThrow(const UnauthorizedException(
        code: 'INVALID_CREDENTIALS',
        message: 'The provided ID or password is incorrect',
      ));

      await authNotifier.login(
        identifier: 'A123456',
        password: 'wrong-password',
      );

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.errorMessage,
          'The provided ID or password is incorrect');
      expect(authNotifier.state.token, isNull);
      expect(authNotifier.state.user, isNull);
    });

    test('login sets generic error message on unexpected exception', () async {
      when(() => mockApiClient.login(
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
          )).thenThrow(Exception('network error'));

      await authNotifier.login(
        identifier: 'A123456',
        password: 'password123',
      );

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.errorMessage,
          'An unexpected error occurred. Please try again.');
    });

    test('logout clears state and token', () async {
      // First login
      final user = User(
        id: 'user-123',
        identifier: 'A123456',
        name: 'Test Student',
        role: 'student',
        createdAt: DateTime(2024, 1, 1),
      );
      final loginResponse = LoginResponse(token: 'jwt-token', user: user);

      when(() => mockApiClient.login(
            identifier: any(named: 'identifier'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => loginResponse);
      when(() => mockApiClient.setToken(any())).thenReturn(null);
      when(() => mockApiClient.clearToken()).thenReturn(null);

      await authNotifier.login(
        identifier: 'A123456',
        password: 'password123',
      );
      expect(authNotifier.state.status, AuthStatus.authenticated);

      // Now logout
      authNotifier.logout();

      expect(authNotifier.state.status, AuthStatus.unauthenticated);
      expect(authNotifier.state.token, isNull);
      expect(authNotifier.state.user, isNull);
      verify(() => mockApiClient.clearToken()).called(1);
    });
  });
}
