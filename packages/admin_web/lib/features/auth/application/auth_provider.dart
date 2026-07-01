import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../data/auth_repository.dart';
import '../data/auth_storage.dart';

/// Authentication state enum.
enum AuthStatus {
  /// Auth state has not yet been determined (bootstrap in progress).
  unknown,

  /// User is not authenticated.
  unauthenticated,

  /// Authentication is in progress.
  loading,

  /// User is authenticated.
  authenticated,
}

/// Holds the current authentication state including token and user.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.token,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? token;
  final User? user;
  final String? errorMessage;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => status == AuthStatus.authenticated;

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

/// Notifier that manages authentication state.
///
/// Handles login, logout, token storage (in-memory for PoC),
/// and auth state transitions.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository, this._apiClient, this._storage)
      : super(const AuthState());

  final AuthRepository _repository;
  final MyKizApiClient _apiClient;
  final AuthStorage _storage;

  /// Attempts to log in with the given [identifier] and [password].
  ///
  /// On success, stores the token and user, sets auth state to authenticated.
  /// On failure, sets the error message for display.
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _repository.login(
        identifier: identifier,
        password: password,
      );

      // Store token in the API client for subsequent requests
      _apiClient.setToken(response.token);

      // Persist the session so it survives a browser reload.
      await _storage.save(response.token, response.user);

      state = AuthState(
        status: AuthStatus.authenticated,
        token: response.token,
        user: response.user,
      );
    } on UnauthorizedException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } on ApiTimeoutException {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Connection timed out. Please try again.',
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

  /// Logs out the current user and clears stored credentials.
  Future<void> logout() async {
    await _storage.clear();
    _apiClient.clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Restores a persisted session (if any) on app startup.
  ///
  /// Resolves the initial [AuthStatus.unknown] state to either
  /// [AuthStatus.authenticated] (with the token applied to the API client)
  /// or [AuthStatus.unauthenticated] when no session was persisted.
  Future<void> bootstrap() async {
    final saved = await _storage.read();
    if (saved == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    _apiClient.setToken(saved.token);
    state = AuthState(
      status: AuthStatus.authenticated,
      token: saved.token,
      user: saved.user,
    );
  }
}

/// Provider for the [AuthNotifier] and its [AuthState].
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(authStorageProvider);
  return AuthNotifier(repository, apiClient, storage);
});
