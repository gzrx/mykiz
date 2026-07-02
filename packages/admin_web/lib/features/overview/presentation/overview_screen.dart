import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/kiz_theme.dart';
import '../application/overview_providers.dart';

/// Admin landing page: actionable count cards linking to each module.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(overviewCountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: KizColors.error, size: 40),
            const SizedBox(height: KizSpacing.sm),
            const Text('Could not load overview.'),
            const SizedBox(height: KizSpacing.sm),
            ElevatedButton(
              onPressed: () => ref.invalidate(overviewCountsProvider),
              child: const Text('Retry'),
            ),
          ]),
        ),
        data: (c) => GridView.count(
          padding: const EdgeInsets.all(KizSpacing.base),
          crossAxisCount: 3,
          mainAxisSpacing: KizSpacing.base,
          crossAxisSpacing: KizSpacing.base,
          childAspectRatio: 1.6,
          children: [
            _OverviewCard(
              label: 'Submitted complaints',
              count: c.submittedComplaints,
              icon: Icons.report_problem_outlined,
              onTap: () => context.go(AppRoutes.complaints),
            ),
            _OverviewCard(
              label: 'Pending bookings',
              count: c.pendingBookings,
              icon: Icons.event_available_outlined,
              onTap: () => context.go(AppRoutes.bookings),
            ),
            _OverviewCard(
              label: 'New applications',
              count: c.submittedApplications,
              icon: Icons.assignment_outlined,
              onTap: () => context.go(AppRoutes.accommodation),
            ),
            _OverviewCard(
              label: 'Pending check-ins',
              count: c.pendingCheckIns,
              icon: Icons.login_outlined,
              onTap: () => context.go(AppRoutes.accommodation),
            ),
            _OverviewCard(
              label: 'Near-full blocks',
              count: c.nearFullBlocks,
              icon: Icons.apartment_outlined,
              onTap: () => context.go(AppRoutes.accommodation),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(KizSpacing.base),
          // FittedBox shrinks the content to fit whatever space the grid
          // cell ends up with, so this never overflows regardless of
          // viewport size or the number of cards in the row.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: KizColors.primary),
                Text('$count', style: theme.textTheme.headlineMedium),
                Text(label, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
