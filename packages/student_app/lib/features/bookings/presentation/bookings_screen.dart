import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/bookings_provider.dart';

/// Main bookings screen with Facilities and My Bookings tabs.
class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).fetchFacilities();
      ref.read(bookingsProvider.notifier).fetchActiveBookings();
      ref.read(bookingsProvider.notifier).fetchHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookings',
          style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Facilities'),
            Tab(text: 'My Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FacilitiesTab(),
          _MyBookingsTab(),
        ],
      ),
    );
  }
}

class _FacilitiesTab extends ConsumerWidget {
  const _FacilitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);

    if (state.isLoading && state.facilities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.facilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: KizColors.error),
            const SizedBox(height: KizSpacing.base),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: KizColors.error),
            ),
            const SizedBox(height: KizSpacing.base),
            ElevatedButton(
              onPressed: () =>
                  ref.read(bookingsProvider.notifier).fetchFacilities(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.facilities.isEmpty) {
      return Center(
        child: Text(
          'No facilities available',
          style: GoogleFonts.poppins(color: KizColors.onSurface),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookingsProvider.notifier).fetchFacilities(),
      child: ListView.separated(
        padding: const EdgeInsets.all(KizSpacing.base),
        itemCount: state.facilities.length,
        separatorBuilder: (_, __) => const SizedBox(height: KizSpacing.md),
        itemBuilder: (context, index) {
          final facility = state.facilities[index];
          return _FacilityCard(facility: facility);
        },
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.facility});

  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/bookings/facility/${facility.id}'),
      child: Container(
        padding: const EdgeInsets.all(KizSpacing.lg),
        decoration: BoxDecoration(
          color: KizColors.surface,
          borderRadius: BorderRadius.circular(KizRadius.card),
          border: Border.all(color: KizColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              facility.name,
              style: GoogleFonts.leagueSpartan(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: KizColors.onBackground,
              ),
            ),
            if (facility.description != null) ...[
              const SizedBox(height: KizSpacing.sm),
              Text(
                facility.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: KizColors.onSurface,
                ),
              ),
            ],
            const SizedBox(height: KizSpacing.md),
            Row(
              children: [
                Icon(Icons.people_outline,
                    size: 16, color: KizColors.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: KizSpacing.xs),
                Text(
                  'Capacity: ${facility.capacity}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: KizColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: KizSpacing.base),
                Icon(Icons.schedule,
                    size: 16, color: KizColors.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: KizSpacing.xs),
                Text(
                  facility.approvalMode == 'auto'
                      ? 'Auto-confirm'
                      : 'Requires approval',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: KizColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyBookingsTab extends ConsumerWidget {
  const _MyBookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);

    if (state.isLoading &&
        state.activeBookings.isEmpty &&
        state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.activeBookings.isEmpty && state.history.isEmpty) {
      return Center(
        child: Text(
          'No bookings yet',
          style: GoogleFonts.poppins(color: KizColors.onSurface),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(bookingsProvider.notifier).fetchActiveBookings();
        await ref.read(bookingsProvider.notifier).fetchHistory();
      },
      child: ListView(
        padding: const EdgeInsets.all(KizSpacing.base),
        children: [
          if (state.activeBookings.isNotEmpty) ...[
            Text(
              'Active',
              style: GoogleFonts.leagueSpartan(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: KizColors.onBackground,
              ),
            ),
            const SizedBox(height: KizSpacing.sm),
            ...state.activeBookings.map((b) => _BookingTile(booking: b)),
          ],
          if (state.history.isNotEmpty) ...[
            const SizedBox(height: KizSpacing.xl),
            Text(
              'History',
              style: GoogleFonts.leagueSpartan(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: KizColors.onBackground,
              ),
            ),
            const SizedBox(height: KizSpacing.sm),
            ...state.history.map((b) => _BookingTile(booking: b)),
          ],
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/bookings/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: KizSpacing.md),
        padding: const EdgeInsets.all(KizSpacing.lg),
        decoration: BoxDecoration(
          color: KizColors.surface,
          borderRadius: BorderRadius.circular(KizRadius.card),
          border: Border.all(color: KizColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.bookingReference,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KizColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: KizSpacing.xs),
                  Text(
                    _formatDate(booking.bookingDate),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: KizColors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: booking.status),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KizSpacing.sm,
        vertical: KizSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KizRadius.button),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, String) _statusConfig(String status) {
    return switch (status) {
      'pending' => (Colors.orange, 'Pending'),
      'confirmed' => (Colors.green, 'Confirmed'),
      'cancelled' => (Colors.grey, 'Cancelled'),
      'completed' => (const Color(0xFF3B82F6), 'Completed'),
      'no_show' => (Colors.red, 'No Show'),
      'rejected' => (Colors.red, 'Rejected'),
      _ => (KizColors.onSurface, status),
    };
  }
}
