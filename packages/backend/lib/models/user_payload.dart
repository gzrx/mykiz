/// Represents the authenticated user extracted from a valid JWT.
///
/// Injected into the request context by the auth middleware.
class UserPayload {
  const UserPayload({
    required this.id,
    required this.role,
  });

  /// The user's UUID (from the JWT `sub` claim).
  final String id;

  /// The user's role: "student" or "admin".
  final String role;

  /// Whether this user has the admin role.
  bool get isAdmin => role == 'admin';

  /// Whether this user has the student role.
  bool get isStudent => role == 'student';
}
