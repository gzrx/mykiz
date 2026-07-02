import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/occupancy_provider.dart';

/// Occupancy tab content — reuses the same provider and layout as OccupancyScreen
/// but without its own Scaffold/AppBar.
class OccupancyTab extends ConsumerStatefulWidget {
  const OccupancyTab({super.key});

  @override
  ConsumerState<OccupancyTab> createState() => _OccupancyTabState();
}

class _OccupancyTabState extends ConsumerState<OccupancyTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(occupancyProvider.notifier).fetchBlocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(occupancyProvider);
    final theme = Theme.of(context);

    if (state.isLoadingBlocks && state.blocks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: KizColors.error),
            const SizedBox(height: KizSpacing.base),
            Text(
              state.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: KizColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KizSpacing.base),
            ElevatedButton(
              onPressed: () =>
                  ref.read(occupancyProvider.notifier).fetchBlocks(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.blocks.isEmpty) {
      return Center(
        child: Text('No blocks found.', style: theme.textTheme.bodyLarge),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 240,
          child: ListView.builder(
            padding: const EdgeInsets.all(KizSpacing.sm),
            itemCount: state.blocks.length,
            itemBuilder: (context, index) {
              final block = state.blocks[index];
              final isSelected = block.id == state.selectedBlockId;
              return Card(
                color: isSelected
                    ? KizColors.primary.withValues(alpha: 0.15)
                    : null,
                child: ListTile(
                  title: Text(
                    block.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected ? KizColors.navigationBar : null,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () =>
                      ref.read(occupancyProvider.notifier).selectBlock(block.id),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _RoomsPanel(state: state, theme: theme)),
      ],
    );
  }
}

class _RoomsPanel extends StatelessWidget {
  const _RoomsPanel({required this.state, required this.theme});

  final OccupancyState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (state.selectedBlockId == null) {
      return Center(
        child: Text(
          'Select a block to view occupancy.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    if (state.isLoadingRooms) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Text(
          state.errorMessage!,
          style: theme.textTheme.bodyMedium?.copyWith(color: KizColors.error),
        ),
      );
    }

    if (state.rooms.isEmpty) {
      return Center(
        child: Text(
          'No rooms exist for this block.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KizSpacing.base),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Room')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Occupancy')),
        ],
        rows: [
          for (final room in state.rooms)
            DataRow(cells: [
              DataCell(KizCodeTag(room.roomNumber)),
              DataCell(Text(_formatRoomType(room.roomType))),
              DataCell(Text(
                '${room.occupied}/${room.total} beds filled',
                style: KizFonts.mono(),
              )),
            ]),
        ],
      ),
    );
  }

  String _formatRoomType(String type) => switch (type) {
        'single' => 'Single',
        'twin_sharing' => 'Twin Sharing',
        _ => type,
      };
}
