import 'dart:io';

import 'package:backend/services/seed_data.dart';
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

  /// Runs a callback inside a database transaction.
  /// The callback receives a [TxSession] that must be used for all queries
  /// within the transaction.
  static Future<T> transaction<T>(
    Future<T> Function(TxSession session) callback,
  ) async {
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
      return await connection.runTx(callback);
    } finally {
      await connection.close();
    }
  }

  /// Closes the connection pool.
  static Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }

  /// Applies any migration files not yet recorded in `schema_migrations`.
  /// Idempotent: safe to call on every boot.
  static Future<void> migrate({String migrationsDir = 'migrations'}) async {
    await query(
      'CREATE TABLE IF NOT EXISTS schema_migrations ('
      'filename TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW())',
    );
    final dir = Directory(migrationsDir);
    if (!dir.existsSync()) return; // build output may not bundle migrations
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final done = await query(
        'SELECT 1 FROM schema_migrations WHERE filename = @n',
        parameters: {'n': name},
      );
      if (done.isNotEmpty) continue;
      await transaction((tx) async {
        await tx.execute(file.readAsStringSync(), queryMode: QueryMode.simple);
        await tx.execute(
          Sql.named('INSERT INTO schema_migrations (filename) VALUES (@n)'),
          parameters: {'n': name},
        );
      });
    }
  }

  /// Runs the seed only if the users table is empty.
  static Future<void> seedIfEmpty() async {
    final rows = await query('SELECT COUNT(*)::int AS c FROM users');
    if ((rows.first[0] as int) > 0) return;
    final conn = await Connection.open(
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
      await runSeed(conn);
    } finally {
      await conn.close();
    }
  }
}
