import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/kiz_theme.dart';
import '../application/announcements_provider.dart';

/// Announcement detail screen showing full content with edit/delete actions.
///
/// Displays the full announcement title, body, and timestamps.
/// Provides actions to edit or soft-delete the announcement.
class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  final String announcementId;

  @override
  ConsumerState<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends ConsumerState<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(announcementDetailProvider.notifier)
          .fetchAnnouncement(widget.announcementId);
    });
  }

  Future<void> _showDeleteDialog() async {
    final state = ref.read(announcementDetailProvider);
    final announcement = state.announcement;
    if (announcement == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
          'Are you sure you want to delete "${announcement.title}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KizColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(announcementsListProvider.notifier)
          .deleteAnnouncement(announcement.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted successfully.'),
              backgroundColor: KizColors.navigationBar,
            ),
          );
          context.go(AppRoutes.announcements);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete announcement.'),
              backgroundColor: KizColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementDetailProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.announcements),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Announcement'),
        actions: [
          if (state.announcement != null) ...[
            IconButton(
              onPressed: () => context.go(
                AppRoutes.announcementEdit(widget.announcementId),
              ),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: _showDeleteDialog,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
            const SizedBox(width: KizSpacing.sm),
          ],
        ],
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(AnnouncementDetailState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: KizColors.error),
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
              onPressed: () => ref
                  .read(announcementDetailProvider.notifier)
                  .fetchAnnouncement(widget.announcementId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final announcement = state.announcement;
    if (announcement == null) {
      return const Center(child: Text('Announcement not found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KizSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              announcement.title,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: KizSpacing.base),

            // Metadata
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: KizColors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: KizSpacing.xs),
                Text(
                  'Created: ${_formatDate(announcement.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: KizColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: KizSpacing.lg),
                Icon(
                  Icons.update_outlined,
                  size: 16,
                  color: KizColors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: KizSpacing.xs),
                Text(
                  'Updated: ${_formatDate(announcement.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: KizColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KizSpacing.xl),
            const Divider(),
            const SizedBox(height: KizSpacing.xl),

            // Body
            Text(
              announcement.body,
              style: theme.textTheme.bodyLarge,
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
    return '$day/$month/$year at $hour:$minute';
  }
}
