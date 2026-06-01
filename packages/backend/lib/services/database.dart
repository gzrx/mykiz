import 'dart:io';

import 'package:postgres/postgres.dart';

/// Provides a PostgreSQL connection pool for the backend.
///
/// Reads connection parameters from environment variables:
/// - DB_HOST (default: localhost)
/// - DB_PORT (default: 5432)
/// - DB_NAME (default: mykiz)
/// - DB_USER (default: mykiz)
/// - DB_PASSWORD (default: mykiz_secret)
class Database {
  Database._();

  static Pool<void>? _pool;

  /// Returns the shared connection pool, creating it on first access.
  static Pool<void> get pool {
    _pool ??= Pool.withEndpoints(
      [
        Endpoint(
          host: Platform.environment['DB_HOST'] ?? 'localhost',
          port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
          database: Platform.environment['DB_NAME'] ?? 'mykiz',
          username: Platform.environment['DB_USER'] ?? 'mykiz',
          password: Platform.environment['DB_PASSWORD'] ?? 'mykiz_secret',
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: 10,
      ),
    );
    return _pool!;
  }

  /// Executes a query using the connection pool and returns the result.
  static Future<Result> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final connection = await Connection.open(
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? 'localhost',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME'] ?? 'mykiz',
        username: Platform.environment['DB_USER'] ?? 'mykiz',
        password: Platform.environment['DB_PASSWORD'] ?? 'mykiz_secret',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    try {
      return await connection.execute(
        Sql.named(sql),
        parameters: parameters ?? {},
      );
    } finally {
      await connection.close();
    }
  }

  /// Closes the connection pool.
  static Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}
