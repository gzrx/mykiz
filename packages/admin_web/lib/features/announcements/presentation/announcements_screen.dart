import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/announcements_provider.dart';

/// Announcements list screen for Admin Web.
///
/// Displays a paginated list of announcements with title, creation date,
/// and a body snippet. Provides navigation to create, view, and edit.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch announcements on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementsListProvider.notifier).fetchAnnouncements();
    });
  }

  Future<void> _showDeleteDialog(Announcement announcement) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Announcement deleted successfully.'
                  : 'Failed to delete announcement.',
            ),
            backgroundColor: success ? KizColors.navigationBar : KizColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: KizSpacing.base),
            child: ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.announcementCreate),
              icon: const Icon(Icons.add),
              label: const Text('New'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Content area
          Expanded(
            child: _buildContent(state, theme),
          ),
          // Pagination controls
          if (state.meta != null) _buildPaginationControls(state, theme),
        ],
      ),
    );
  }

  Widget _buildContent(AnnouncementsListState state, ThemeData theme) {
    if (state.isLoading && state.announcements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.announcements.isEmpty) {
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
                  .read(announcementsListProvider.notifier)
                  .fetchAnnouncements(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: KizColors.border,
            ),
            const SizedBox(height: KizSpacing.base),
            Text(
              'No announcements yet',
              style: KizFonts.display(fontSize: 22),
            ),
            const SizedBox(height: KizSpacing.sm),
            Text(
              'Create your first announcement to get started.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(announcementsListProvider.notifier)
          .fetchAnnouncements(),
      child: ListView.separated(
        padding: const EdgeInsets.all(KizSpacing.lg),
        itemCount: state.announcements.length,
        separatorBuilder: (_, __) => const SizedBox(height: KizSpacing.md),
        itemBuilder: (context, index) {
          final announcement = state.announcements[index];
          return _AnnouncementCard(
            announcement: announcement,
            onTap: () => context.go(
              AppRoutes.announcementDetail(announcement.id),
            ),
            onDelete: () => _showDeleteDialog(announcement),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(
    AnnouncementsListState state,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KizSpacing.lg,
        vertical: KizSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KizColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${state.totalItems} total announcements',
            style: theme.textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.currentPage > 1
                    ? () => ref
                        .read(announcementsListProvider.notifier)
                        .previousPage()
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: KizSpacing.sm),
                child: Text(
                  'Page ${state.currentPage} of ${state.totalPages}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: state.currentPage < state.totalPages
                    ? () => ref
                        .read(announcementsListProvider.notifier)
                        .nextPage()
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card widget displaying a single announcement in the list.
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
    required this.onDelete,
  });

  final Announcement announcement;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snippet = announcement.body.length > 120
        ? '${announcement.body.substring(0, 120)}...'
        : announcement.body;

    return KizCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  style: theme.textTheme.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: KizColors.error,
                tooltip: 'Delete announcement',
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: KizSpacing.sm),
          Text(
            snippet,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: KizSpacing.md),
          Text(
            _formatDate(announcement.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: KizColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
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
