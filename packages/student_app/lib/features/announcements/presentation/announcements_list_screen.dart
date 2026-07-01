import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/kiz_card.dart';
import '../application/announcements_provider.dart';

/// Announcements list screen for the Student App.
///
/// Displays a paginated list of announcements with pull-to-refresh.
/// Tapping an item navigates to the announcement detail screen.
class AnnouncementsListScreen extends ConsumerStatefulWidget {
  const AnnouncementsListScreen({super.key});

  @override
  ConsumerState<AnnouncementsListScreen> createState() =>
      _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState
    extends ConsumerState<AnnouncementsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(announcementsListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(announcementsListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AnnouncementsListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.announcements.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.announcements.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(KizSpacing.base),
        itemCount: state.announcements.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: KizSpacing.sm),
        itemBuilder: (context, index) {
          if (index == state.announcements.length) {
            return _buildLoadingIndicator();
          }
          return _AnnouncementListItem(
            announcement: state.announcements[index],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: KizColors.onSurface),
            ),
            const SizedBox(height: KizSpacing.base),
            ElevatedButton(
              onPressed: () {
                ref.read(announcementsListProvider.notifier).loadAnnouncements();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KizSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: KizColors.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: KizSpacing.base),
            Text(
              'No announcements yet',
              style: KizFonts.display(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: KizColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: KizSpacing.base),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// A single announcement item in the list.
class _AnnouncementListItem extends StatelessWidget {
  const _AnnouncementListItem({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/announcements/${announcement.id}');
      },
      child: KizCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: KizColors.onBackground,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: KizSpacing.xs),
            Text(
              _formatDate(announcement.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KizColors.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: KizSpacing.sm),
            Text(
              announcement.body,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
