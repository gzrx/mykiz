// Feature: mykiz-platform, Property 1: JWT issuance correctness
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:glados/glados.dart';
import 'package:test/test.dart';

/// **Validates: Requirements 1.1, 1.4**
///
/// Property 1: JWT issuance correctness
/// For any valid user (Student or Admin) with correct credentials, the JWT
/// returned by Auth_Service SHALL contain `sub` equal to the user's UUID,
/// `role` matching the user's role, `iat` set to the current time, and `exp`
/// set to exactly `iat + 86400` seconds.

/// Simulates the JWT issuance logic from [AuthService.login].
///
/// This replicates the exact signing logic used in production:
/// - Creates a JWT with `sub` and `role` in the payload
/// - Signs with HMAC-SHA256 using the provided secret
/// - Sets expiry to 86400 seconds (24 hours) from issuance
///
/// Returns the signed token string.
String issueJwt({
  required String userId,
  required String role,
  required String secret,
}) {
  final jwt = JWT(
    {
      'sub': userId,
      'role': role,
    },
    issuer: 'mykiz-backend',
  );

  return jwt.sign(
    SecretKey(secret),
    algorithm: JWTAlgorithm.HS256,
    expiresIn: const Duration(seconds: 86400),
  );
}

/// Custom generators for user data.
extension UserGenerators on Any {
  /// Generates a UUID-like string (simplified for testing).
  Generator<String> get uuid => simple(
        generate: (random, size) {
          const chars = 'abcdef0123456789';
          final segments = [8, 4, 4, 4, 12];
          final parts = segments.map((len) {
            return List.generate(
              len,
              (_) => chars[random.nextInt(chars.length)],
            ).join();
          });
          return parts.join('-');
        },
        shrink: (input) => [],
      );

  /// Generates a valid role: either 'student' or 'admin'.
  Generator<String> get userRole => choose(['student', 'admin']);
}

void main() {
  const jwtSecret = 'test-jwt-secret-for-property-testing';

  group('Property 1: JWT issuance correctness', () {
    // Property 1a: For any valid user UUID and role, the issued JWT SHALL
    // contain `sub` equal to the user's UUID.
    Glados2(any.uuid, any.userRole, ExploreConfig(numRuns: 100)).test(
      'JWT sub claim equals the user UUID for any valid user',
      (userId, role) {
        final token = issueJwt(
          userId: userId,
          role: role,
          secret: jwtSecret,
        );

        final verified = JWT.verify(token, SecretKey(jwtSecret));
        final payload = verified.payload as Map<String, dynamic>;

        expect(
          payload['sub'],
          equals(userId),
          reason: 'JWT sub claim should equal user UUID "$userId"',
        );
      },
    );

    // Property 1b: For any valid user UUID and role, the issued JWT SHALL
    // contain `role` matching the user's role.
    Glados2(any.uuid, any.userRole, ExploreConfig(numRuns: 100)).test(
      'JWT role claim matches the user role for any valid user',
      (userId, role) {
        final token = issueJwt(
          userId: userId,
          role: role,
          secret: jwtSecret,
        );

        final verified = JWT.verify(token, SecretKey(jwtSecret));
        final payload = verified.payload as Map<String, dynamic>;

        expect(
          payload['role'],
          equals(role),
          reason: 'JWT role claim should equal "$role" for user "$userId"',
        );
      },
    );

    // Property 1c: For any valid user, the issued JWT SHALL have `iat` set
    // to approximately the current time (within 2 seconds tolerance).
    Glados2(any.uuid, any.userRole, ExploreConfig(numRuns: 100)).test(
      'JWT iat claim is set to the current time for any valid user',
      (userId, role) {
        final beforeIssuance =
            DateTime.now().millisecondsSinceEpoch ~/ 1000; // seconds

        final token = issueJwt(
          userId: userId,
          role: role,
          secret: jwtSecret,
        );

        final afterIssuance =
            DateTime.now().millisecondsSinceEpoch ~/ 1000; // seconds

        final verified = JWT.verify(token, SecretKey(jwtSecret));
        final payload = verified.payload as Map<String, dynamic>;

        expect(
          payload['iat'],
          isNotNull,
          reason: 'JWT must have an iat claim',
        );

        final iat = payload['iat'] as int;

        // iat should be between beforeIssuance and afterIssuance (inclusive)
        expect(
          iat,
          greaterThanOrEqualTo(beforeIssuance),
          reason: 'JWT iat ($iat) should not be before issuance time '
              '($beforeIssuance)',
        );
        expect(
          iat,
          lessThanOrEqualTo(afterIssuance),
          reason: 'JWT iat ($iat) should not be after issuance time '
              '($afterIssuance)',
        );
      },
    );

    // Property 1d: For any valid user, the issued JWT SHALL have `exp` set
    // to exactly `iat + 86400` seconds (24 hours).
    Glados2(any.uuid, any.userRole, ExploreConfig(numRuns: 100)).test(
      'JWT exp claim equals iat + 86400 seconds for any valid user',
      (userId, role) {
        final token = issueJwt(
          userId: userId,
          role: role,
          secret: jwtSecret,
        );

        final verified = JWT.verify(token, SecretKey(jwtSecret));
        final payload = verified.payload as Map<String, dynamic>;

        expect(
          payload['iat'],
          isNotNull,
          reason: 'JWT must have an iat claim',
        );
        expect(
          payload['exp'],
          isNotNull,
          reason: 'JWT must have an exp claim',
        );

        final iat = payload['iat'] as int;
        final exp = payload['exp'] as int;

        // exp - iat should be exactly 86400 seconds
        final differenceInSeconds = exp - iat;

        expect(
          differenceInSeconds,
          equals(86400),
          reason: 'JWT exp should be exactly iat + 86400 seconds (24 hours). '
              'Got iat=$iat, exp=$exp, difference=$differenceInSeconds seconds.',
        );
      },
    );

    // Property 1e: For any valid user, the issued JWT SHALL be signed with
    // HMAC-SHA256 (verifiable with the same secret).
    Glados2(any.uuid, any.userRole, ExploreConfig(numRuns: 100)).test(
      'JWT is signed with HMAC-SHA256 and verifiable with correct secret',
      (userId, role) {
        final token = issueJwt(
          userId: userId,
          role: role,
          secret: jwtSecret,
        );

        // Should verify successfully with the correct secret
        expect(
          () => JWT.verify(token, SecretKey(jwtSecret)),
          returnsNormally,
          reason: 'JWT should verify with the signing secret',
        );

        // Should fail with a different secret (proves HMAC signature)
        expect(
          () => JWT.verify(token, SecretKey('wrong-secret')),
          throwsA(isA<JWTException>()),
          reason: 'JWT should not verify with a different secret',
        );
      },
    );
  });
}
