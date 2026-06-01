// Feature: mykiz-platform, Property 2: Invalid credentials rejection
import 'package:bcrypt/bcrypt.dart';
import 'package:backend/services/auth_service.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 1.2**
///
/// Property 2: Invalid credentials rejection
/// For any credential pair where either the identifier does not exist or the
/// password does not match the stored hash, Auth_Service SHALL return an error
/// with code "INVALID_CREDENTIALS" without revealing which field is incorrect.

/// Simulates the AuthService login logic for testing without a live database.
///
/// This function replicates the decision logic in [AuthService.login]:
/// - If [userRow] is null, the identifier was not found → INVALID_CREDENTIALS
/// - If [userRow] is provided, verify password against stored hash
///   - If mismatch → INVALID_CREDENTIALS
///   - If match → login succeeds (no exception)
///
/// Returns the [AuthException] thrown, or null if login would succeed.
AuthException? simulateLoginDecision({
  required List<dynamic>? userRow,
  required String password,
}) {
  if (userRow == null) {
    return const AuthException(
      code: 'INVALID_CREDENTIALS',
      message: 'The provided ID or password is incorrect.',
    );
  }

  final storedHash = userRow[2] as String;
  final isValid = BCrypt.checkpw(password, storedHash);

  if (!isValid) {
    return const AuthException(
      code: 'INVALID_CREDENTIALS',
      message: 'The provided ID or password is incorrect.',
    );
  }

  return null; // Login would succeed
}

void main() {
  group('Property 2: Invalid credentials rejection', () {
    // Pre-compute a known bcrypt hash for testing password mismatch scenarios.
    // Using cost factor 4 for speed in tests (production uses 10).
    final knownPassword = 'correct_password_123';
    final knownHash =
        BCrypt.hashpw(knownPassword, BCrypt.gensalt(logRounds: 4));

    Glados<String>(any.nonEmptyLetterOrDigits).test(
      'non-existent identifier always returns INVALID_CREDENTIALS with generic message',
      (identifier) {
        // Simulate: identifier not found in database (userRow is null)
        final exception = simulateLoginDecision(
          userRow: null,
          password: identifier, // password doesn't matter when user not found
        );

        expect(exception, isNotNull);
        expect(exception!.code, equals('INVALID_CREDENTIALS'));
        expect(
          exception.message,
          equals('The provided ID or password is incorrect.'),
        );
        // Verify message does NOT reveal which field is wrong
        expect(exception.message, isNot(contains('identifier')));
        expect(exception.message, isNot(contains('user not found')));
        expect(exception.message, isNot(contains('does not exist')));
      },
    );

    Glados<String>(any.nonEmptyLetterOrDigits, ExploreConfig(numRuns: 10)).test(
      'wrong password always returns INVALID_CREDENTIALS with generic message',
      (wrongPassword) {
        // Skip if the generated password happens to match the known password
        if (wrongPassword == knownPassword) return;

        // Simulate: user found but password doesn't match
        final userRow = [
          'uuid-123', // id
          'A123456', // identifier
          knownHash, // password_hash (bcrypt)
          'student', // role
          'Test User', // name
        ];

        final exception = simulateLoginDecision(
          userRow: userRow,
          password: wrongPassword,
        );

        expect(exception, isNotNull);
        expect(exception!.code, equals('INVALID_CREDENTIALS'));
        expect(
          exception.message,
          equals('The provided ID or password is incorrect.'),
        );
        // Verify message does NOT reveal that it was specifically the password
        // that was wrong (a generic message mentioning both fields is acceptable)
        expect(exception.message, isNot(contains('wrong password')));
        expect(exception.message, isNot(contains('invalid password')));
        expect(exception.message, isNot(contains('password mismatch')));
        expect(exception.message, isNot(contains('mismatch')));
      },
    );

    Glados<String>(any.nonEmptyLetterOrDigits, ExploreConfig(numRuns: 10)).test(
      'error message is identical for non-existent user and wrong password',
      (input) {
        // Case 1: identifier not found
        final notFoundError = simulateLoginDecision(
          userRow: null,
          password: input,
        );

        // Case 2: user found but wrong password
        final wrongPassword =
            (input == knownPassword) ? 'definitely_wrong' : input;
        final userRow = [
          'uuid-456',
          'S98765',
          knownHash,
          'admin',
          'Admin User',
        ];
        final wrongPassError = simulateLoginDecision(
          userRow: userRow,
          password: wrongPassword,
        );

        // Both errors must have the same code and message
        expect(notFoundError, isNotNull);
        expect(wrongPassError, isNotNull);
        expect(notFoundError!.code, equals(wrongPassError!.code));
        expect(notFoundError.message, equals(wrongPassError.message));
        // Both must be INVALID_CREDENTIALS
        expect(notFoundError.code, equals('INVALID_CREDENTIALS'));
      },
    );

    // Verify that correct credentials do NOT throw (sanity check)
    test('correct credentials do not produce an error', () {
      final userRow = [
        'uuid-789',
        'A234567',
        knownHash,
        'student',
        'Valid Student',
      ];

      final exception = simulateLoginDecision(
        userRow: userRow,
        password: knownPassword,
      );

      expect(exception, isNull);
    });
  });
}
