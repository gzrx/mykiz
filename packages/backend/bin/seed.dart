import 'dart:io';

import 'package:backend/services/seed_data.dart';
import 'package:postgres/postgres.dart';

/// Seed script for populating the database with test data.
///
/// Idempotent: uses INSERT ... ON CONFLICT DO NOTHING so re-running is safe.
///
/// Run via: melos run seed
void main() async {
  final connection = await Connection.open(
    Endpoint(
      host: Platform.environment['DB_HOST'] ?? 'localhost',
      port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
      database: Platform.environment['DB_NAME'] ?? 'mykiz',
      username: Platform.environment['DB_USER'] ?? 'mykiz',
      password: Platform.environment['DB_PASSWORD'] ?? 'mykiz_secret',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    await runSeed(connection);
  } catch (e, st) {
    print('❌ Seed failed: $e');
    print(st);
    exitCode = 1;
  } finally {
    await connection.close();
  }
}
