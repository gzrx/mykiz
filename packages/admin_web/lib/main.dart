import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/kiz_theme.dart';
import 'features/auth/application/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: AdminWebApp()));
}

/// MyKIZ Admin Web application root widget.
class AdminWebApp extends ConsumerStatefulWidget {
  const AdminWebApp({super.key});

  @override
  ConsumerState<AdminWebApp> createState() => _AdminWebAppState();
}

class _AdminWebAppState extends ConsumerState<AdminWebApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider).status;
    final router = ref.watch(appRouterProvider);

    if (status == AuthStatus.unknown) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp.router(
      title: 'MyKIZ Admin',
      theme: KizTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
