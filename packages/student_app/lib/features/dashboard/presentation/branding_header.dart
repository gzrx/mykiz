import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/kiz_theme.dart';
import '../../auth/application/auth_provider.dart';
import '../application/dashboard_utils.dart';

/// Dashboard branding header showing a personalized greeting and the MyKIZ logo.
class BrandingHeader extends ConsumerWidget {
  const BrandingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final greeting = formatGreeting(authState.user?.name);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KizSpacing.base,
        vertical: KizSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          // ponytail: text-based logo fallback — no asset file exists yet.
          // Upgrade path: replace with Image.asset('assets/logo.png', semanticLabel: 'MyKIZ logo')
          // once a logo asset is added to the project.
          Semantics(
            label: 'MyKIZ logo',
            child: ExcludeSemantics(
              child: Text(
                'MyKIZ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: KizColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
