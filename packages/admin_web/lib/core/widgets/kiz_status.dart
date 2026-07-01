import 'package:flutter/material.dart';
import '../theme/kiz_theme.dart';

/// The four semantic buckets every status in the app collapses into.
///
/// Every complaint, booking, and accommodation status — however it's named
/// on the wire — maps to exactly one of these. One color system, one
/// meaning, everywhere: [fresh] = just landed and needs eyes, [active] =
/// in motion / in good standing, [done] = closed out normally, [blocked] =
/// stopped, rejected, or missed.
enum KizStatusKind { fresh, active, done, blocked }

extension KizStatusKindStyle on KizStatusKind {
  /// The spine/tab color for this status bucket.
  Color get color => switch (this) {
        KizStatusKind.fresh => KizColors.primary,
        KizStatusKind.active => KizColors.moss,
        KizStatusKind.done => KizColors.secondary,
        KizStatusKind.blocked => KizColors.error,
      };
}

/// Centralizes the raw-status-string → (bucket, label) mapping that used to
/// be reimplemented per-screen with inconsistent colors. One place per
/// domain, one source of truth.
abstract final class KizStatusMapper {
  static (KizStatusKind, String) complaint(String status) => switch (status) {
        'submitted' => (KizStatusKind.fresh, 'Submitted'),
        'in_progress' => (KizStatusKind.active, 'In Progress'),
        'resolved' => (KizStatusKind.done, 'Resolved'),
        _ => (KizStatusKind.fresh, status),
      };

  static (KizStatusKind, String) booking(String status) => switch (status) {
        'pending' => (KizStatusKind.fresh, 'Pending'),
        'confirmed' => (KizStatusKind.active, 'Confirmed'),
        'completed' => (KizStatusKind.done, 'Completed'),
        'cancelled' => (KizStatusKind.blocked, 'Cancelled'),
        'no_show' => (KizStatusKind.blocked, 'No Show'),
        'rejected' => (KizStatusKind.blocked, 'Rejected'),
        _ => (KizStatusKind.fresh, status),
      };

  static (KizStatusKind, String) accommodation(String status) =>
      switch (status) {
        'submitted' => (KizStatusKind.fresh, 'Submitted'),
        'approved' => (KizStatusKind.active, 'Approved'),
        'checked_in' => (KizStatusKind.active, 'Checked In'),
        'checked_out' => (KizStatusKind.done, 'Checked Out'),
        'rejected' => (KizStatusKind.blocked, 'Rejected'),
        _ => (KizStatusKind.fresh, status),
      };
}

/// Inline status indicator — a small colored tag with a mono label, styled
/// like a stamped ledger entry. Used inline with text: table cells, detail
/// headers. See [KizCard]'s `spineKind` for the card-list equivalent.
class KizStatusTab extends StatelessWidget {
  const KizStatusTab({super.key, required this.kind, required this.label});

  final KizStatusKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = kind.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: KizFonts.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: KizColors.onBackground,
        ),
      ),
    );
  }
}
