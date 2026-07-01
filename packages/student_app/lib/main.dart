import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/kiz_theme.dart';
import 'features/auth/application/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StudentApp(),
    ),
  );
}

/// MyKIZ Siswa - Student mobile application root widget.
class StudentApp extends ConsumerStatefulWidget {
  const StudentApp({super.key});

  @override
  ConsumerState<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends ConsumerState<StudentApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).resolveInitial();
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
      title: 'MyKIZ Siswa',
      theme: KizTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
