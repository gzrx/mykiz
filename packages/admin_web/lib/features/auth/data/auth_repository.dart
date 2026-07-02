import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_provider.dart';

/// Whether a 401 response should trigger an automatic session teardown.
///
/// A 401 that occurs mid-[AuthNotifier.login] attempt (state still
/// `loading`) must NOT trigger logout: `logout()` is fire-and-forget and
/// races with `login()`'s catch block. If it wins the race, it overwrites
/// the freshly-set `errorMessage` with a blank `AuthState(status:
/// unauthenticated)`, so a wrong-password login silently shows no error.
/// Only auto-logout when a session was actually established.
bool shouldAutoLogoutOn401(AuthStatus status) =>
    status == AuthStatus.authenticated;

/// Provider for the [MyKizApiClient] instance.
///
/// Override this in tests or configure with the actual base URL.
final Provider<MyKizApiClient> apiClientProvider =
    Provider<MyKizApiClient>((ref) {
  return MyKizApiClient(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.isaacfurqan.dev',
    ),
    onUnauthorized: () {
      // Fire-and-forget logout; guards against loops (logout is idempotent).
      // Safe against circular init: this callback only runs later (at
      // 401 time), after both providers already exist.
      //
      // Guarded so a 401 during an in-flight login attempt doesn't clobber
      // the error message login() is about to set (see
      // shouldAutoLogoutOn401).
      if (shouldAutoLogoutOn401(ref.read(authProvider).status)) {
        ref.read(authProvider.notifier).logout();
      }
    },
  );
});

/// Repository that handles authentication API calls.
class AuthRepository {
  const AuthRepository(this._client);

  final MyKizApiClient _client;

  /// Authenticates a user with [identifier] and [password].
  ///
  /// Returns a [LoginResponse] containing the JWT token and user data.
  /// Throws [ApiException] subclasses on failure.
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) {
    return _client.login(identifier: identifier, password: password);
  }
}

/// Provider for the [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRepository(client);
});
