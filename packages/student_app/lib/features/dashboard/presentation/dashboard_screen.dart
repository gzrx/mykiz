import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/kiz_theme.dart';
import 'branding_header.dart';
import 'module_grid.dart';

/// Root dashboard screen — no AppBar, no back button.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KizSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              BrandingHeader(),
              SizedBox(height: KizSpacing.base),
              ModuleGrid(),
            ],
          ),
        ),
      ),
    );
  }
}
