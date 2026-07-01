import 'package:flutter/material.dart';
import '../theme/kiz_theme.dart';
import 'kiz_status.dart';

/// A card widget styled per the KIZ design system.
///
/// Reads as a piece of paper lifted slightly off the page — soft shadow,
/// warm surface, cork-tinted border. Pass [spineKind] to give the card a
/// colored edge (like a mailbox tag or library index card) instead of a
/// separate status pill — see [KizStatusKind].
class KizCard extends StatelessWidget {
  const KizCard({
    super.key,
    required this.child,
    this.padding,
    this.spineKind,
    this.onTap,
  });

  /// The content of the card.
  final Widget child;

  /// Optional custom padding. Defaults to 20px all sides.
  final EdgeInsetsGeometry? padding;

  /// If set, draws a colored spine on the card's leading edge encoding the
  /// item's status — the card-list equivalent of [KizStatusTab].
  final KizStatusKind? spineKind;

  /// Optional tap handler; wraps the card in an [InkWell] when provided.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(KizSpacing.lg),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: KizColors.surface,
        borderRadius: BorderRadius.circular(KizRadius.card),
        border: Border.all(color: KizColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: KizColors.onBackground.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: spineKind == null
              ? content
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: spineKind!.color),
                      Expanded(child: content),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
