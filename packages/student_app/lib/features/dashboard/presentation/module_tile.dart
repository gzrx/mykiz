import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/kiz_theme.dart';
import '../data/module_registry.dart';

/// A single tappable tile in the dashboard grid.
/// Renders icon + label with optional async badge.
class ModuleTile extends ConsumerStatefulWidget {
  const ModuleTile({super.key, required this.entry});

  final ModuleRegistryEntry entry;

  @override
  ConsumerState<ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends ConsumerState<ModuleTile> {
  String? _badgeText;

  @override
  void initState() {
    super.initState();
    _loadBadge();
  }

  Future<void> _loadBadge() async {
    final provider = widget.entry.badgeProvider;
    if (provider == null) return;
    try {
      final text = await provider(ref);
      if (mounted) setState(() => _badgeText = text);
    } catch (_) {
      // ponytail: badge provider failure → no badge, per spec.
    }
  }

  void _onTap() {
    try {
      context.push(widget.entry.routePath);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Module unavailable')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(KizRadius.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinTouchTarget,
              minHeight: kMinTouchTarget,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.entry.icon, size: 32),
                const SizedBox(height: KizSpacing.xs),
                Text(
                  widget.entry.label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (_badgeText != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KizSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: KizColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
