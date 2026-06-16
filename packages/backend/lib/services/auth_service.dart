import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'database.dart';

/// Result of a successful login operation.
class LoginResult {
  const LoginResult({
    required this.token,
    required this.user,
  });

  /// The signed JWT token string.
  final String token;

  /// User data to include in the response.
  final Map<String, dynamic> user;
}

/// Error thrown when authentication fails.
class AuthException implements Exception {
  const AuthException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

/// Service responsible for user authentication, JWT issuance, and password
/// hashing.
class AuthService {
  /// Authenticates a user by identifier and password.
  ///
  /// Looks up the user by identifier (Matric Number or Staff ID), verifies
  /// the password against the stored bcrypt hash, and issues a JWT on success.
  ///
  /// Throws [AuthException] with code "INVALID_CREDENTIALS" if the user is
  /// not found or the password does not match. The error message is generic
  /// to avoid revealing which field is wrong.
  Future<LoginResult> login(String identifier, String password) async {
    // Query user by identifier
    final result = await Database.query(
      'SELECT id, identifier, password_hash, role, name, created_at FROM users '
      'WHERE identifier = @identifier',
      parameters: {'identifier': identifier},
    );

    if (result.isEmpty) {
      throw const AuthException(
        code: 'INVALID_CREDENTIALS',
        message: 'The provided ID or password is incorrect.',
      );
    }

    final row = result.first;
    final storedHash = row[2] as String; // password_hash

    // Verify password against stored bcrypt hash
    final isValid = BCrypt.checkpw(password, storedHash);

    if (!isValid) {
      throw const AuthException(
        code: 'INVALID_CREDENTIALS',
        message: 'The provided ID or password is incorrect.',
      );
    }

    final userId = row[0] as String; // id (UUID)
    final userIdentifier = row[1] as String; // identifier
    final role = row[3] as String; // role
    final name = row[4] as String; // name
    final createdAt = row[5] as DateTime; // created_at

    // Issue JWT with HMAC-SHA256
    final jwtSecret =
        Platform.environment['JWT_SECRET'] ?? 'change-me-to-a-secure-random-string';

    final now = DateTime.now();
    final jwt = JWT(
      {
        'sub': userId,
        'role': role,
      },
      issuer: 'mykiz-backend',
    );

    final token = jwt.sign(
      SecretKey(jwtSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: const Duration(seconds: 86400),
    );

    return LoginResult(
      token: token,
      user: {
        'id': userId,
        'identifier': userIdentifier,
        'name': name,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
      },
    );
  }

  /// Hashes a password using bcrypt with a minimum cost factor of 10.
  ///
  /// Used for creating new user accounts or updating passwords.
  String hashPassword(String password) {
    final salt = BCrypt.gensalt(logRounds: 10);
    return BCrypt.hashpw(password, salt);
  }
}
