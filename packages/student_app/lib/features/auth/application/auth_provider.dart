import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

/// Authentication state for the student app.
enum AuthStatus {
  /// User is authenticated with a valid token.
  authenticated,

  /// User is not authenticated.
  unauthenticated,

  /// Authentication is in progress (e.g. login request).
  loading,
}

/// Holds the current authentication state including token and user.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.token,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? token;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for the API client instance.
final apiClientProvider = Provider<MyKizApiClient>((ref) {
  return MyKizApiClient(baseUrl: 'http://localhost:8080');
});

/// Notifier that manages authentication state.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._apiClient) : super(const AuthState());

  final MyKizApiClient _apiClient;

  /// Attempts to log in with the given matric number and password.
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _apiClient.login(
        identifier: identifier,
        password: password,
      );

      // Store token in the API client for subsequent requests.
      _apiClient.setToken(response.token);

      state = AuthState(
        status: AuthStatus.authenticated,
        token: response.token,
        user: response.user,
      );
    } on ApiException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Logs out the current user.
  void logout() {
    _apiClient.clearToken();
    state = const AuthState();
  }
}

/// Provider for the auth state notifier.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
