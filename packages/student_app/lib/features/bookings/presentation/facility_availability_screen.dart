import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/bookings_provider.dart';

/// Screen showing slot availability for a facility with date picker.
class FacilityAvailabilityScreen extends ConsumerStatefulWidget {
  const FacilityAvailabilityScreen({super.key, required this.facilityId});

  final String facilityId;

  @override
  ConsumerState<FacilityAvailabilityScreen> createState() =>
      _FacilityAvailabilityScreenState();
}

class _FacilityAvailabilityScreenState
    extends ConsumerState<FacilityAvailabilityScreen> {
  late DateTime _selectedDate;
  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).selectFacility(widget.facilityId);
      ref
          .read(bookingsProvider.notifier)
          .fetchAvailability(widget.facilityId, _selectedDate);
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    ref
        .read(bookingsProvider.notifier)
        .fetchAvailability(widget.facilityId, date);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsProvider);
    final facility = state.selectedFacility;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          facility?.name ?? 'Availability',
          style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Date selector: next 14 days
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: KizSpacing.base, vertical: KizSpacing.sm),
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = _today.add(Duration(days: index));
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;
                return GestureDetector(
                  onTap: () => _onDateSelected(date),
                  child: Container(
                    width: 56,
                    margin: const EdgeInsets.only(right: KizSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? KizColors.primary
                          : KizColors.surface,
                      borderRadius: BorderRadius.circular(KizRadius.card),
                      border: Border.all(
                        color: isSelected
                            ? KizColors.primary
                            : KizColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekday(date),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isSelected
                                ? KizColors.onBackground
                                : KizColors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: KizColors.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Slots
          Expanded(
            child: _buildSlotsList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsList(BookingsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Text(
          state.errorMessage!,
          style: GoogleFonts.poppins(color: KizColors.error),
        ),
      );
    }

    if (state.availability.isEmpty) {
      return Center(
        child: Text(
          'No slots available for this date',
          style: GoogleFonts.poppins(color: KizColors.onSurface),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KizSpacing.base),
      itemCount: state.availability.length,
      separatorBuilder: (_, __) => const SizedBox(height: KizSpacing.md),
      itemBuilder: (context, index) {
        final slot = state.availability[index];
        return _SlotTile(
          slot: slot,
          onBook: () => _confirmBooking(slot),
        );
      },
    );
  }

  Future<void> _confirmBooking(Map<String, dynamic> slot) async {
    final available = (slot['available'] as num?)?.toInt() ?? 0;
    if (available <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
          'Book ${slot['startTime']} – ${slot['endTime']} on '
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Book'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final success = await ref.read(bookingsProvider.notifier).submitBooking(
          facilityId: widget.facilityId,
          slotConfigId: slot['slotConfigId'] as String,
          date: dateStr,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted!')),
      );
      // Refresh availability
      ref
          .read(bookingsProvider.notifier)
          .fetchAvailability(widget.facilityId, _selectedDate);
    } else {
      final error = ref.read(bookingsProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Booking failed')),
      );
    }
  }

  String _weekday(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.onBook});

  final Map<String, dynamic> slot;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final available = (slot['available'] as num?)?.toInt() ?? 0;
    final isBlocked = slot['blocked'] == true;
    final isPast = slot['past'] == true;

    final Color statusColor;
    final String statusText;

    if (isBlocked) {
      statusColor = Colors.red;
      statusText = 'Blocked';
    } else if (isPast) {
      statusColor = Colors.grey;
      statusText = 'Past';
    } else if (available <= 0) {
      statusColor = Colors.red;
      statusText = 'Full';
    } else {
      statusColor = Colors.green;
      statusText = '$available available';
    }

    final canBook = !isBlocked && !isPast && available > 0;

    return Container(
      padding: const EdgeInsets.all(KizSpacing.lg),
      decoration: BoxDecoration(
        color: KizColors.surface,
        borderRadius: BorderRadius.circular(KizRadius.card),
        border: Border.all(color: KizColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: KizSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot['startTime']} – ${slot['endTime']}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: KizColors.onBackground,
                  ),
                ),
                const SizedBox(height: KizSpacing.xs),
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (canBook)
            ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: KizSpacing.base,
                  vertical: KizSpacing.sm,
                ),
              ),
              child: const Text('Book'),
            ),
        ],
      ),
    );
  }
}
