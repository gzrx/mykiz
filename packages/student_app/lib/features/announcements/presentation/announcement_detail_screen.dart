import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/kiz_card.dart';
import '../application/announcements_provider.dart';

/// Announcement detail screen (read-only).
///
/// Displays the full title, body, createdAt, and updatedAt of an announcement.
class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  /// The UUID of the announcement to display.
  final String announcementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(
      announcementDetailProvider(announcementId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
      ),
      body: announcementAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, ref, error),
        data: (announcement) => SingleChildScrollView(
          padding: const EdgeInsets.all(KizSpacing.base),
          child: KizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: KizColors.onBackground,
                      ),
                ),
                const SizedBox(height: KizSpacing.sm),
                _buildDateRow(
                  context,
                  label: 'Published',
                  date: announcement.createdAt,
                ),
                if (announcement.updatedAt != announcement.createdAt) ...[
                  const SizedBox(height: KizSpacing.xs),
                  _buildDateRow(
                    context,
                    label: 'Updated',
                    date: announcement.updatedAt,
                  ),
                ],
                const SizedBox(height: KizSpacing.base),
                const Divider(),
                const SizedBox(height: KizSpacing.base),
                Text(
                  announcement.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context, {
    required String label,
    required DateTime date,
  }) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: KizColors.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: KizSpacing.xs),
        Text(
          '$label: ${_formatDate(date)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: KizColors.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KizSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: KizColors.error,
            ),
            const SizedBox(height: KizSpacing.base),
            Text(
              'Failed to load announcement',
              textAlign: TextAlign.center,
              style: TextStyle(color: KizColors.onSurface),
            ),
            const SizedBox(height: KizSpacing.base),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(announcementDetailProvider(announcementId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
