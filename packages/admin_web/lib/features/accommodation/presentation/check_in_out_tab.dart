import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/widgets.dart';
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
              style: KizFonts.mono(),
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
              color: KizColors.error.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: KizColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: KizColors.error),
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
      color: KizColors.moss.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCheckIn ? Icons.check_circle : Icons.logout,
                  color: KizColors.moss,
                ),
                const SizedBox(width: 12),
                Text(
                  isCheckIn
                      ? 'Check-In Successful'
                      : 'Check-Out Successful',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: KizColors.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (app.studentName != null)
              _infoRow('Student', Text(app.studentName!)),
            if (app.assignedBlockName != null)
              _infoRow('Block', KizCodeTag(app.assignedBlockName!)),
            if (app.assignedRoomNumber != null)
              _infoRow('Room', KizCodeTag(app.assignedRoomNumber!)),
            if (app.assignedBedLabel != null)
              _infoRow('Bed', KizCodeTag(app.assignedBedLabel!)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          value,
        ],
      ),
    );
  }
}
