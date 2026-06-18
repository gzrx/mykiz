import 'package:dart_frog/dart_frog.dart';

/// Middleware for /api/v1/facilities/* routes.
///
/// Auth is handled by the parent /api/v1/ middleware.
/// Admin role checks for mutation endpoints (PUT/POST/DELETE) are performed
/// inline in each route handler since students can still GET these routes.
// ponytail: pass-through; admin guard lives in handlers because routes are shared
Handler middleware(Handler handler) {
  return handler;
}
