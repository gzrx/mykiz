import 'package:flutter/material.dart';
import '../theme/kiz_theme.dart';

/// A card widget styled per the KIZ design system.
///
/// Uses 20px padding, 8px border radius, and 1px border #E5E7EB.
class KizCard extends StatelessWidget {
  const KizCard({
    super.key,
    required this.child,
    this.padding,
  });

  /// The content of the card.
  final Widget child;

  /// Optional custom padding. Defaults to 20px all sides.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(KizSpacing.lg),
      decoration: BoxDecoration(
        color: KizColors.surface,
        borderRadius: BorderRadius.circular(KizRadius.card),
        border: Border.all(color: KizColors.cardBorder),
      ),
      child: child,
    );
  }
}
