import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/kiz_card.dart';
import '../../../core/widgets/kiz_status.dart';
import '../application/complaints_provider.dart';

/// Screen displaying the student's own complaints with status indicators.
class ComplaintsListScreen extends ConsumerStatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  ConsumerState<ComplaintsListScreen> createState() =>
      _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends ConsumerState<ComplaintsListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch complaints on first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(complaintsListProvider.notifier).fetchComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complaintsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Complaints',
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.complaintSubmit),
        backgroundColor: KizColors.primary,
        child: const Icon(Icons.add, color: KizColors.onBackground),
      ),
    );
  }

  Widget _buildBody(ComplaintsListState state) {
    if (state.isLoading && state.complaints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.complaints.isEmpty) {
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
              const SizedBox(height: KizSpacing.base),
              ElevatedButton(
                onPressed: () {
                  ref.read(complaintsListProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.complaints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KizSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: KizColors.border,
              ),
              const SizedBox(height: KizSpacing.base),
              Text(
                'No complaints yet',
                style: KizFonts.display(fontSize: 22),
              ),
              const SizedBox(height: KizSpacing.sm),
              Text(
                'Tap + to submit a new complaint',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: KizColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(complaintsListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(KizSpacing.base),
        itemCount: state.complaints.length,
        separatorBuilder: (_, __) => const SizedBox(height: KizSpacing.md),
        itemBuilder: (context, index) {
          final complaint = state.complaints[index];
          return _ComplaintListTile(complaint: complaint);
        },
      ),
    );
  }
}

/// A single complaint list item showing description snippet, location,
/// status badge, and creation date.
class _ComplaintListTile extends StatelessWidget {
  const _ComplaintListTile({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final (kind, _) = KizStatusMapper.complaint(complaint.status);
    return KizCard(
      spineKind: kind,
      onTap: () => context.push('${AppRoutes.complaints}/${complaint.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: date (status is now shown via the card spine)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _formatDate(complaint.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: KizColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: KizSpacing.md),

          // Description snippet (max 2 lines)
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KizColors.onBackground,
            ),
          ),
          const SizedBox(height: KizSpacing.sm),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: KizColors.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: KizSpacing.xs),
              Expanded(
                child: Text(
                  complaint.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: KizColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
