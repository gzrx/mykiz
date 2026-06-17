import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/check_in_out_provider.dart';

/// Tab for scanning/entering application UUIDs to check in or check out.
class CheckInOutTab extends ConsumerStatefulWidget {
  const CheckInOutTab({super.key});

  @override
  ConsumerState<CheckInOutTab> createState() => _CheckInOutTabState();
}

class _CheckInOutTabState extends ConsumerState<CheckInOutTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCheckIn() {
    final uuid = _controller.text.trim();
    if (uuid.isEmpty) return;
    ref.read(checkInOutProvider.notifier).checkIn(uuid);
  }

  void _handleCheckOut() {
    final uuid = _controller.text.trim();
    if (uuid.isEmpty) return;
    ref.read(checkInOutProvider.notifier).checkOut(uuid);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkInOutProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check-In / Check-Out', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: _controller,
              maxLength: 36,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: const InputDecoration(
                hintText: 'Enter or scan application UUID',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (_) {
                // Clear previous results when user types
                if (state.result != null || state.errorMessage != null) {
                  ref.read(checkInOutProvider.notifier).clear();
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: state.isLoading ? null : _handleCheckIn,
                icon: const Icon(Icons.login),
                label: const Text('Check In'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: state.isLoading ? null : _handleCheckOut,
                icon: const Icon(Icons.logout),
                label: const Text('Check Out'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (state.isLoading) const CircularProgressIndicator(),
          if (state.errorMessage != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.result != null) _buildSuccessCard(state.result!, theme),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(dynamic app, ThemeData theme) {
    // ponytail: accessing fields directly from AccommodationApplication
    final status = app.status as String;
    final isCheckIn = status == 'checked_in';

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCheckIn ? Icons.check_circle : Icons.logout,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  isCheckIn
                      ? 'Check-In Successful'
                      : 'Check-Out Successful',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (app.studentName != null)
              _infoRow('Student', app.studentName!),
            if (app.assignedBlockName != null)
              _infoRow('Block', app.assignedBlockName!),
            if (app.assignedRoomNumber != null)
              _infoRow('Room', app.assignedRoomNumber!),
            if (app.assignedBedLabel != null)
              _infoRow('Bed', app.assignedBedLabel!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(value),
        ],
      ),
    );
  }
}
