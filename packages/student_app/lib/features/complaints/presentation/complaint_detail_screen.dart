import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/complaints_provider.dart';

/// Read-only detail screen for a single complaint.
///
/// Displays full description, location, status, creation date,
/// and attached image (if present).
class ComplaintDetailScreen extends ConsumerStatefulWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});

  /// The UUID of the complaint to display.
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complaint Details',
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ComplaintDetailState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
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
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: KizColors.error,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final complaint = state.complaint;
    if (complaint == null) {
      return const Center(child: Text('Complaint not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KizSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and date header
          Container(
            padding: const EdgeInsets.all(KizSpacing.base),
            decoration: BoxDecoration(
              color: KizColors.surface,
              borderRadius: BorderRadius.circular(KizRadius.card),
              border: Border.all(color: KizColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(status: complaint.status),
                Text(
                  _formatDateTime(complaint.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: KizColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KizSpacing.xl),

          // Description section
          Text(
            'Description',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KizColors.onBackground,
            ),
          ),
          const SizedBox(height: KizSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KizSpacing.base),
            decoration: BoxDecoration(
              color: KizColors.surface,
              borderRadius: BorderRadius.circular(KizRadius.card),
              border: Border.all(color: KizColors.cardBorder),
            ),
            child: Text(
              complaint.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: KizColors.onSurface,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: KizSpacing.xl),

          // Location section
          Text(
            'Location',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KizColors.onBackground,
            ),
          ),
          const SizedBox(height: KizSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KizSpacing.base),
            decoration: BoxDecoration(
              color: KizColors.surface,
              borderRadius: BorderRadius.circular(KizRadius.card),
              border: Border.all(color: KizColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: KizColors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: KizSpacing.sm),
                Expanded(
                  child: Text(
                    complaint.location,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: KizColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KizSpacing.xl),

          // Image section (if present)
          if (complaint.imageKey != null) ...[
            Text(
              'Attached Photo',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KizColors.onBackground,
              ),
            ),
            const SizedBox(height: KizSpacing.sm),
            _ComplaintImage(imageKey: complaint.imageKey!),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

/// Widget that loads and displays a complaint image from the backend.
class _ComplaintImage extends ConsumerWidget {
  const _ComplaintImage({required this.imageKey});

  final String imageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(complaintImageProvider(imageKey));

    return imageAsync.when(
      data: (bytes) => ClipRRect(
        borderRadius: BorderRadius.circular(KizRadius.card),
        child: Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: KizColors.surface,
          borderRadius: BorderRadius.circular(KizRadius.card),
          border: Border.all(color: KizColors.cardBorder),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: KizColors.surface,
          borderRadius: BorderRadius.circular(KizRadius.card),
          border: Border.all(color: KizColors.cardBorder),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: KizColors.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: KizSpacing.sm),
              Text(
                'Failed to load image',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: KizColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color-coded status badge widget.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KizSpacing.md,
        vertical: KizSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KizRadius.button),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, String) _statusConfig(String status) {
    return switch (status) {
      'submitted' => (Colors.orange, 'Submitted'),
      'in_progress' => (KizColors.secondary, 'In Progress'),
      'resolved' => (Colors.green, 'Resolved'),
      _ => (KizColors.onSurface, status),
    };
  }
}
