import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/bookings_provider.dart';

/// Tab displaying all bookings with filters and approve/reject actions.
class BookingsTab extends ConsumerStatefulWidget {
  const BookingsTab({super.key});

  @override
  ConsumerState<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<BookingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsListProvider.notifier).fetch();
      ref.read(facilitiesProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsListProvider);
    final facilitiesState = ref.watch(facilitiesProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filters row
        Padding(
          padding: const EdgeInsets.all(KizSpacing.base),
          child: Row(
            children: [
              // Facility filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: state.facilityFilter,
                  decoration: const InputDecoration(
                    labelText: 'Facility',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...facilitiesState.facilities.map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                    ),
                  ],
                  onChanged: (v) =>
                      ref.read(bookingsListProvider.notifier).setFacilityFilter(v),
                ),
              ),
              const SizedBox(width: KizSpacing.base),
              // Status filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: state.statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(
                        value: 'cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(
                        value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'no_show', child: Text('No Show')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (v) =>
                      ref.read(bookingsListProvider.notifier).setStatusFilter(v),
                ),
              ),
              const SizedBox(width: KizSpacing.base),
              // Date range button
              OutlinedButton.icon(
                onPressed: () => _pickDateRange(context),
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  state.fromDate != null
                      ? '${state.fromDate} → ${state.toDate}'
                      : 'Date Range',
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Table
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null
                  ? Center(
                      child: Text(
                        state.errorMessage!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: KizColors.error),
                      ),
                    )
                  : state.bookings.isEmpty
                      ? const Center(child: Text('No bookings found'))
                      : _buildTable(state, theme),
        ),
        // Pagination
        if (state.totalPages > 1)
          Container(
            padding: const EdgeInsets.all(KizSpacing.base),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: KizColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: state.page > 1
                      ? () => ref
                          .read(bookingsListProvider.notifier)
                          .goToPage(state.page - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${state.page} of ${state.totalPages}'),
                IconButton(
                  onPressed: state.page < state.totalPages
                      ? () => ref
                          .read(bookingsListProvider.notifier)
                          .goToPage(state.page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTable(BookingsListState state, ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Reference')),
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: state.bookings.map((booking) {
            return DataRow(cells: [
              DataCell(Text(booking.bookingReference)),
              DataCell(Text(booking.studentId)),
              DataCell(Text(_formatDate(booking.bookingDate))),
              DataCell(_StatusChip(status: booking.status)),
              DataCell(_ActionButtons(booking: booking)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (range == null) return;
    final from = _toIso(range.start);
    final to = _toIso(range.end);
    ref.read(bookingsListProvider.notifier).setDateRange(from, to);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _toIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending' => (Colors.orange, 'Pending'),
      'confirmed' => (Colors.green, 'Confirmed'),
      'cancelled' => (Colors.grey, 'Cancelled'),
      'completed' => (const Color(0xFF3B82F6), 'Completed'),
      'no_show' => (Colors.red, 'No Show'),
      'rejected' => (Colors.red, 'Rejected'),
      _ => (KizColors.onSurface, status),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (booking.status != 'pending') return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () =>
              ref.read(bookingsListProvider.notifier).approveBooking(booking.id),
          child: const Text('Approve'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: KizColors.error),
          onPressed: () => _showRejectDialog(context, ref),
          child: const Text('Reject'),
        ),
      ],
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Enter rejection reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KizColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              ref
                  .read(bookingsListProvider.notifier)
                  .rejectBooking(booking.id, reason: reason);
              Navigator.pop(ctx);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
