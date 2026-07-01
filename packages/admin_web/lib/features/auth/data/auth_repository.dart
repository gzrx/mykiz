import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_provider.dart';

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
      ref.read(authProvider.notifier).logout();
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
