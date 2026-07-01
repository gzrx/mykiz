import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/complaints_provider.dart';

/// Complaints list screen for Admin Web.
///
/// Displays all complaints with status badges, description snippets,
/// location, and creation date. Supports pagination.
class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch complaints on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(complaintsListProvider.notifier).fetchComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complaintsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(ComplaintsListState state, ThemeData theme) {
    if (state.isLoading && state.complaints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              onPressed: () {
                ref.read(complaintsListProvider.notifier).fetchComplaints();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.complaints.isEmpty) {
      return Center(
        child: Text(
          'No complaints found.',
          style: KizFonts.display(fontSize: 20),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(KizSpacing.base),
            itemCount: state.complaints.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: KizSpacing.sm),
            itemBuilder: (context, index) {
              final complaint = state.complaints[index];
              return _ComplaintCard(
                complaint: complaint,
                onTap: () => _navigateToDetail(complaint.id),
              );
            },
          ),
        ),
        if (state.meta != null) _buildPaginationBar(state),
      ],
    );
  }

  Widget _buildPaginationBar(ComplaintsListState state) {
    final meta = state.meta!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KizSpacing.base,
        vertical: KizSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KizColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${meta.currentPage} of ${meta.totalPages} '
            '(${meta.totalItems} total)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.currentPage > 1
                    ? () => ref
                        .read(complaintsListProvider.notifier)
                        .previousPage()
                    : null,
                tooltip: 'Previous page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.currentPage < meta.totalPages
                    ? () =>
                        ref.read(complaintsListProvider.notifier).nextPage()
                    : null,
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(String complaintId) {
    context.go(AppRoutes.complaintDetailPath(complaintId));
  }
}

/// A card displaying a complaint summary in the list.
class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({
    required this.complaint,
    required this.onTap,
  });

  final Complaint complaint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (kind, label) = KizStatusMapper.complaint(complaint.status);

    return KizCard(
      spineKind: kind,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint.location,
                  style: theme.textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: KizSpacing.sm),
              KizStatusTab(kind: kind, label: label),
            ],
          ),
          const SizedBox(height: KizSpacing.sm),
          Text(
            complaint.description,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: KizSpacing.sm),
          Text(
            _formatDate(complaint.createdAt),
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
    return '$day/$month/$year $hour:$minute';
  }
}
