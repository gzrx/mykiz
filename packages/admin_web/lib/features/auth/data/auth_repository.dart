import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [MyKizApiClient] instance.
///
/// Override this in tests or configure with the actual base URL.
final apiClientProvider = Provider<MyKizApiClient>((ref) {
  return MyKizApiClient(baseUrl: 'http://localhost:8080');
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
