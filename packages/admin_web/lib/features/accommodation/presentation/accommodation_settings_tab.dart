import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../application/accommodation_settings_provider.dart';

/// Settings tab content with the application window toggle.
///
/// Fetches current setting on load, performs optimistic update on toggle,
/// and reverts with error message on failure.
class AccommodationSettingsTab extends ConsumerStatefulWidget {
  const AccommodationSettingsTab({super.key});

  @override
  ConsumerState<AccommodationSettingsTab> createState() =>
      _AccommodationSettingsTabState();
}

class _AccommodationSettingsTabState
    extends ConsumerState<AccommodationSettingsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(accommodationSettingsProvider.notifier).fetch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accommodationSettingsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                state.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          KizCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Application Window'),
              subtitle: Text(
                state.isOpen
                    ? 'Students can submit applications'
                    : 'Applications are closed',
              ),
              value: state.isOpen,
              onChanged: (_) {
                ref.read(accommodationSettingsProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
    );
  }
}
