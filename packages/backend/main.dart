import 'dart:io';

import 'package:backend/services/database.dart';
import 'package:dart_frog/dart_frog.dart';

/// Custom Dart Frog entrypoint: run migrations + seed-if-empty before serving.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  try {
    await Database.migrate();
    await Database.seedIfEmpty();
  } catch (e) {
    stderr.writeln('Startup migrate/seed failed (continuing): $e');
  }
  return serve(handler, ip, port);
}
