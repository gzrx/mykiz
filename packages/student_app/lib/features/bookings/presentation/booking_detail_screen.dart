import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/kiz_code_tag.dart';
import '../../../core/widgets/kiz_status.dart';
import '../application/bookings_provider.dart';

/// Screen showing full booking details with cancel action.
class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);
    // Find booking in active or history
    final booking = _findBooking(state);

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final canCancel = _canCancel(booking);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Details',
          style: KizFonts.display(fontSize: 20, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(KizSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reference
            _DetailRow(
              label: 'Reference',
              valueWidget: KizCodeTag(booking.bookingReference),
            ),
            _DetailRow(
              label: 'Status',
              valueWidget: Builder(builder: (context) {
                final (kind, label) = KizStatusMapper.booking(booking.status);
                return KizStatusTab(kind: kind, label: label);
              }),
            ),
            _DetailRow(label: 'Date', value: _formatDate(booking.bookingDate)),
            _DetailRow(
              label: 'Facility ID',
              valueWidget: KizCodeTag(booking.facilityId),
            ),
            _DetailRow(
              label: 'Slot ID',
              valueWidget: KizCodeTag(booking.slotConfigId),
            ),
            if (booking.rejectionReason != null)
              _DetailRow(label: 'Rejection Reason', value: booking.rejectionReason!),
            const Spacer(),
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context, ref, booking),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KizColors.error,
                    side: BorderSide(color: KizColors.error),
                  ),
                  child: const Text('Cancel Booking'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Booking? _findBooking(BookingsState state) {
    for (final b in state.activeBookings) {
      if (b.id == bookingId) return b;
    }
    for (final b in state.history) {
      if (b.id == bookingId) return b;
    }
    return null;
  }

  bool _canCancel(Booking booking) {
    // Can cancel if confirmed and booking date is in the future (simplified 2h rule
    // ponytail: exact 2h check needs slot start time; simplified to just confirmed/pending status
    return booking.status == 'confirmed' || booking.status == 'pending';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KizColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(bookingsProvider.notifier).cancelBooking(booking.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
      Navigator.pop(context);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.valueWidget})
      : assert(
          value != null || valueWidget != null,
          'Either value or valueWidget must be provided',
        );

  final String label;
  final String? value;

  /// Optional widget to render in place of a plain [value] string — used
  /// for codes ([KizCodeTag]) and status ([KizStatusTab]).
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KizSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: KizColors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KizColors.onBackground,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
