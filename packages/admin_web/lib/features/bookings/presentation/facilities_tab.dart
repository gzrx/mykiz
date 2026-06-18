import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/bookings_provider.dart';
import '../data/bookings_repository.dart';

/// Tab for managing facilities: toggle active, change approval mode, manage slots.
class FacilitiesTab extends ConsumerStatefulWidget {
  const FacilitiesTab({super.key});

  @override
  ConsumerState<FacilitiesTab> createState() => _FacilitiesTabState();
}

class _FacilitiesTabState extends ConsumerState<FacilitiesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facilitiesProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facilitiesProvider);
    final theme = Theme.of(context);

    if (state.isLoading && state.facilities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.facilities.isEmpty) {
      return Center(
        child: Text(
          state.errorMessage!,
          style: theme.textTheme.bodyMedium?.copyWith(color: KizColors.error),
        ),
      );
    }

    if (state.facilities.isEmpty) {
      return const Center(child: Text('No facilities configured'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KizSpacing.base),
      itemCount: state.facilities.length,
      separatorBuilder: (_, __) => const SizedBox(height: KizSpacing.md),
      itemBuilder: (context, index) {
        final facility = state.facilities[index];
        return _FacilityCard(facility: facility);
      },
    );
  }
}

class _FacilityCard extends ConsumerWidget {
  const _FacilityCard({required this.facility});

  final Facility facility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        title: Text(
          facility.name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          'Capacity: ${facility.capacity} • ${facility.approvalMode}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Switch(
          value: facility.isActive,
          onChanged: (v) => ref
              .read(facilitiesProvider.notifier)
              .toggleActive(facility.id, isActive: v),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(KizSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Approval mode toggle
                Row(
                  children: [
                    const Text('Approval Mode: '),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'auto', label: Text('Auto')),
                        ButtonSegment(value: 'manual', label: Text('Manual')),
                      ],
                      selected: {facility.approvalMode},
                      onSelectionChanged: (v) => ref
                          .read(facilitiesProvider.notifier)
                          .updateApprovalMode(facility.id, v.first),
                    ),
                  ],
                ),
                const SizedBox(height: KizSpacing.base),
                // Slot configs
                Text('Slot Configs',
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: KizSpacing.sm),
                _SlotConfigsList(facilityId: facility.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotConfigsList extends ConsumerStatefulWidget {
  const _SlotConfigsList({required this.facilityId});

  final String facilityId;

  @override
  ConsumerState<_SlotConfigsList> createState() => _SlotConfigsListState();
}

class _SlotConfigsListState extends ConsumerState<_SlotConfigsList> {
  List<FacilitySlotConfig>? _slots;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final slots = await repo.getFacilitySlots(widget.facilityId);
      if (mounted) setState(() { _slots = slots; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();

    return Column(
      children: [
        if (_slots != null && _slots!.isNotEmpty)
          ..._slots!.map((slot) => ListTile(
                dense: true,
                title: Text('${slot.startTime} – ${slot.endTime}'),
                subtitle: Text(slot.isActive ? 'Active' : 'Inactive'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    final repo = ref.read(bookingsRepositoryProvider);
                    await repo.deleteSlotConfig(widget.facilityId, slot.id);
                    _loadSlots();
                  },
                ),
              )),
        if (_slots == null || _slots!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: KizSpacing.sm),
            child: Text('No slots configured'),
          ),
        TextButton.icon(
          onPressed: () => _showAddSlotDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Slot'),
        ),
      ],
    );
  }

  void _showAddSlotDialog(BuildContext context) {
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: 'Start Time',
                hintText: 'HH:MM',
              ),
            ),
            const SizedBox(height: KizSpacing.base),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'End Time',
                hintText: 'HH:MM',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final start = startController.text.trim();
              final end = endController.text.trim();
              if (start.isEmpty || end.isEmpty) return;
              final repo = ref.read(bookingsRepositoryProvider);
              await repo.addSlotConfig(
                widget.facilityId,
                startTime: start,
                endTime: end,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _loadSlots();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
