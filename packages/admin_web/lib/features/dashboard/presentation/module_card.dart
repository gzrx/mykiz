import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/kiz_theme.dart';
import '../data/module_entry.dart';

/// A card widget representing a single module on the Dashboard.
/// Displays the module icon and name, navigates to the module's route on tap.
class ModuleCard extends StatelessWidget {
  const ModuleCard({super.key, required this.entry});

  final ModuleEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.go(entry.route),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: KizTheme.minTouchTarget,
            minHeight: KizTheme.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.all(KizSpacing.base),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(entry.icon, size: 32, color: KizColors.secondary),
                const SizedBox(height: KizSpacing.sm),
                Text(
                  entry.name,
                  style: theme.textTheme.labelMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
