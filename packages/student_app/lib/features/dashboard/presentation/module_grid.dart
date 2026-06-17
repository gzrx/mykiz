import 'package:flutter/material.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/dashboard_utils.dart';
import '../data/module_registry.dart';
import 'module_tile.dart';

/// Responsive grid of dashboard module tiles.
/// ponytail: single stateless widget, delegates column math to pure function.
class ModuleGrid extends StatelessWidget {
  const ModuleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = computeColumnCount(width);
    final validEntries = moduleRegistry.where((e) => e.isValid).toList();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // parent scrolls
      crossAxisCount: columns,
      crossAxisSpacing: KizSpacing.base,
      mainAxisSpacing: KizSpacing.base,
      childAspectRatio: 0.85, // between 1:1 (1.0) and 4:5 (0.8)
      children: validEntries.map((e) => ModuleTile(entry: e)).toList(),
    );
  }
}
