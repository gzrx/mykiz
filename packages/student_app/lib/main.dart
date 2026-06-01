import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/kiz_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StudentApp(),
    ),
  );
}

/// MyKIZ Siswa - Student mobile application root widget.
class StudentApp extends ConsumerWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MyKIZ Siswa',
      theme: KizTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
