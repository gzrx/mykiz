import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/complaints_provider.dart';

/// Detail screen for a single complaint.
///
/// Shows full description, location, image (if present), status badge,
/// and status advancement button for valid transitions.
class ComplaintDetailScreen extends ConsumerStatefulWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  ConsumerState<ComplaintDetailScreen> createState() =>
      _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(complaintDetailProvider.notifier)
          .fetchComplaint(widget.complaintId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complaintDetailProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(ComplaintDetailState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.complaint == null) {
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
                ref
                    .read(complaintDetailProvider.notifier)
                    .fetchComplaint(widget.complaintId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final complaint = state.complaint;
    if (complaint == null) {
      return const Center(child: Text('Complaint not found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KizSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSection(complaint, state, theme),
            const SizedBox(height: KizSpacing.xl),
            _buildInfoSection('Location', complaint.location, theme),
            const SizedBox(height: KizSpacing.base),
            _buildInfoSection('Description', complaint.description, theme),
            const SizedBox(height: KizSpacing.base),
            _buildDateSection(complaint, theme),
            if (complaint.imageKey != null) ...[
              const SizedBox(height: KizSpacing.xl),
              _buildImageSection(complaint.imageKey!, theme),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: KizSpacing.base),
              Text(
                state.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: KizColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    Complaint complaint,
    ComplaintDetailState state,
    ThemeData theme,
  ) {
    final (kind, label) = KizStatusMapper.complaint(complaint.status);
    final nextStatus = _getNextStatus(complaint.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KizSpacing.base),
        child: Row(
          children: [
            KizStatusTab(kind: kind, label: label),
            const Spacer(),
            if (nextStatus != null)
              ElevatedButton(
                onPressed: state.isAdvancing
                    ? null
                    : () => _advanceStatus(nextStatus),
                child: state.isAdvancing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_advanceButtonLabel(complaint.status)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: KizSpacing.xs),
        Text(
          content,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDateSection(Complaint complaint, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submitted',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: KizSpacing.xs),
        Text(
          _formatDate(complaint.createdAt),
          style: theme.textTheme.bodySmall,
        ),
        if (complaint.updatedAt != complaint.createdAt) ...[
          const SizedBox(height: KizSpacing.sm),
          Text(
            'Last Updated',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: KizSpacing.xs),
          Text(
            _formatDate(complaint.updatedAt),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildImageSection(String imageKey, ThemeData theme) {
    final imageAsync = ref.watch(complaintImageProvider(imageKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached Image',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: KizSpacing.sm),
        imageAsync.when(
          data: (bytes) {
            if (bytes == null) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: KizColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KizColors.cardBorder),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, size: 40, color: KizColors.border),
                      SizedBox(height: KizSpacing.sm),
                      Text('Image could not be loaded'),
                    ],
                  ),
                ),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                width: double.infinity,
                height: 300,
              ),
            );
          },
          loading: () => Container(
            height: 200,
            decoration: BoxDecoration(
              color: KizColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: KizColors.cardBorder),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            height: 200,
            decoration: BoxDecoration(
              color: KizColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: KizColors.cardBorder),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 40, color: KizColors.border),
                  SizedBox(height: KizSpacing.sm),
                  Text('Failed to load image'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _advanceStatus(String newStatus) {
    ref.read(complaintDetailProvider.notifier).advanceStatus(newStatus);
  }

  /// Returns the next valid status string, or null if terminal.
  String? _getNextStatus(String currentStatus) {
    return switch (currentStatus) {
      'submitted' => 'in_progress',
      'in_progress' => 'resolved',
      _ => null,
    };
  }

  /// Returns the button label for advancing from the current status.
  String _advanceButtonLabel(String currentStatus) {
    return switch (currentStatus) {
      'submitted' => 'Mark In Progress',
      'in_progress' => 'Mark Resolved',
      _ => '',
    };
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
