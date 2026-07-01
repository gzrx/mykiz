import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/theme/kiz_theme.dart';
import '../../../core/widgets/kiz_card.dart';
import '../../../core/widgets/kiz_code_tag.dart';
import '../../../core/widgets/kiz_status.dart';
import '../application/accommodation_provider.dart';

/// Main accommodation screen showing application form + status cards + history.
class AccommodationScreen extends ConsumerWidget {
  const AccommodationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowAsync = ref.watch(accommodationWindowProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Accommodation',
            style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.w600)),
      ),
      body: windowAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _StatusMessage(
            icon: Icons.wifi_off_rounded,
            message: 'Status could not be loaded. Please try again later.'),
        data: (isOpen) => _AccommodationBody(windowOpen: isOpen),
      ),
    );
  }
}

class _AccommodationBody extends ConsumerWidget {
  const _AccommodationBody({required this.windowOpen});
  final bool windowOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(myAccommodationAppsProvider);
    return appsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _StatusMessage(
          icon: Icons.error_outline,
          message: 'Could not load applications.'),
      data: (apps) => _buildContent(context, ref, apps),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, MyApplicationsResponse apps) {
    final active = apps.active;
    final history = apps.history;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myAccommodationAppsProvider);
        ref.invalidate(accommodationWindowProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(KizSpacing.base),
        children: [
          if (active.isNotEmpty) ...[
            _buildSectionHeader('Active Applications'),
            const SizedBox(height: KizSpacing.md),
            ...active.map((app) => Padding(
                  padding: const EdgeInsets.only(bottom: KizSpacing.md),
                  child: _ApplicationStatusCard(application: app),
                )),
            const SizedBox(height: KizSpacing.xl),
          ],
          if (windowOpen) ...[
            if (!active.any((a) => a.applicationType == 'semester')) ...[
              _buildSectionHeader('Semester Application'),
              const SizedBox(height: KizSpacing.md),
              const _SemesterForm(),
              const SizedBox(height: KizSpacing.xl),
            ],
            if (!active.any(
                (a) => a.applicationType == 'out_of_semester')) ...[
              _buildSectionHeader('Out-of-Semester Application'),
              const SizedBox(height: KizSpacing.md),
              const _OutOfSemesterForm(),
              const SizedBox(height: KizSpacing.xl),
            ],
          ] else if (active.isEmpty) ...[
            const _StatusMessage(
                icon: Icons.lock_outline_rounded,
                message: 'Applications are not currently accepted.'),
            const SizedBox(height: KizSpacing.xl),
          ],
          if (history.isNotEmpty) ...[
            _buildSectionHeader('History'),
            const SizedBox(height: KizSpacing.md),
            ...history.map((app) => Padding(
                  padding: const EdgeInsets.only(bottom: KizSpacing.md),
                  child: _ApplicationHistoryTile(application: app),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: KizFonts.display(fontSize: 20),
    );
  }
}

// ---------------------------------------------------------------------------
// Semester form
// ---------------------------------------------------------------------------

class _SemesterForm extends ConsumerStatefulWidget {
  const _SemesterForm();
  @override
  ConsumerState<_SemesterForm> createState() => _SemesterFormState();
}

class _SemesterFormState extends ConsumerState<_SemesterForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRoomType;
  String? _selectedBlockId;
  final Set<LifestyleTag> _selectedTags = {};

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 1 lifestyle tag')),
      );
      return;
    }
    await ref.read(accommodationSubmissionProvider.notifier).submitSemester(
          roomTypePreference: _selectedRoomType!,
          preferredBlockId: _selectedBlockId!,
          lifestyleTags: _selectedTags.map((t) => t.dbValue).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(accommodationBlocksProvider);
    final submission = ref.watch(accommodationSubmissionProvider);

    ref.listen<AccommodationSubmissionState>(
        accommodationSubmissionProvider, (_, next) {
      if (next.isSuccess) {
        ref.invalidate(myAccommodationAppsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(accommodationSubmissionProvider.notifier).reset();
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rate info
          _buildRateInfo([
            _buildRateRow('Single Room', 'RM680.00/month'),
            _buildRateRow('Twin Sharing', 'RM490.00/month per pax'),
          ]),
          const SizedBox(height: KizSpacing.base),
          if (submission.errorMessage != null) ...[
            _buildError(submission.errorMessage!),
            const SizedBox(height: KizSpacing.base),
          ],
          // Room type
          _buildLabel('Room Type'),
          const SizedBox(height: KizSpacing.sm),
          DropdownButtonFormField<String>(
            value: _selectedRoomType,
            decoration: const InputDecoration(hintText: 'Select room type'),
            items: const [
              DropdownMenuItem(
                  value: 'single', child: Text('Single (RM680/month)')),
              DropdownMenuItem(
                  value: 'twin_sharing',
                  child: Text('Twin Sharing (RM490/month per pax)')),
            ],
            onChanged: submission.isSubmitting
                ? null
                : (v) => setState(() => _selectedRoomType = v),
            validator: (v) => v == null ? 'Room type is required' : null,
          ),
          const SizedBox(height: KizSpacing.base),
          // Preferred block
          _buildLabel('Preferred Block'),
          const SizedBox(height: KizSpacing.sm),
          blocksAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text('Could not load blocks',
                style: GoogleFonts.poppins(color: KizColors.error)),
            data: (blocks) => DropdownButtonFormField<String>(
              value: _selectedBlockId,
              decoration:
                  const InputDecoration(hintText: 'Select preferred block'),
              items: blocks
                  .map((b) =>
                      DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
              onChanged: submission.isSubmitting
                  ? null
                  : (v) => setState(() => _selectedBlockId = v),
              validator: (v) => v == null ? 'Preferred block is required' : null,
            ),
          ),
          const SizedBox(height: KizSpacing.base),
          // Lifestyle tags
          _buildLabel('Lifestyle Tags (${_selectedTags.length}/10, min 1)'),
          const SizedBox(height: KizSpacing.sm),
          Wrap(
            spacing: KizSpacing.sm,
            runSpacing: KizSpacing.sm,
            children: LifestyleTag.values.map((tag) {
              final selected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(_tagLabel(tag)),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? KizColors.onBackground
                      : KizColors.onSurface,
                ),
                selected: selected,
                onSelected: submission.isSubmitting
                    ? null
                    : (val) => setState(() {
                          if (val && _selectedTags.length < 10) {
                            _selectedTags.add(tag);
                          } else if (!val) {
                            _selectedTags.remove(tag);
                          }
                        }),
                backgroundColor: Colors.transparent,
                selectedColor: KizColors.primary,
                checkmarkColor: KizColors.onBackground,
                side: BorderSide(
                  color: selected
                      ? KizColors.primary
                      : KizColors.cork.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KizRadius.button),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: KizSpacing.xxl),
          // Submit
          SizedBox(
            height: kMinTouchTarget,
            child: ElevatedButton(
              onPressed: submission.isSubmitting ? null : _handleSubmit,
              child: submission.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Application'),
            ),
          ),
        ],
      ),
    );
  }

  String _tagLabel(LifestyleTag tag) => switch (tag) {
        LifestyleTag.lateSleeper => 'Late Sleeper',
        LifestyleTag.earlyBird => 'Early Bird',
        LifestyleTag.airconUser => 'Aircon User',
        LifestyleTag.noAircon => 'No Aircon',
        LifestyleTag.quietPerson => 'Quiet Person',
        LifestyleTag.social => 'Social',
        LifestyleTag.smoker => 'Smoker',
        LifestyleTag.nonSmoker => 'Non-Smoker',
        LifestyleTag.neatFreak => 'Neat Freak',
        LifestyleTag.relaxed => 'Relaxed',
      };
}

// ---------------------------------------------------------------------------
// Out-of-Semester form
// ---------------------------------------------------------------------------

class _OutOfSemesterForm extends ConsumerStatefulWidget {
  const _OutOfSemesterForm();
  @override
  ConsumerState<_OutOfSemesterForm> createState() =>
      _OutOfSemesterFormState();
}

class _OutOfSemesterFormState extends ConsumerState<_OutOfSemesterForm> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  int get _nights => (_checkInDate != null && _checkOutDate != null)
      ? _checkOutDate!.difference(_checkInDate!).inDays
      : 0;
  double get _totalCost => _nights * 49.0;

  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate != null && !_checkOutDate!.isAfter(picked)) {
          _checkOutDate = null;
        }
      });
    }
  }

  Future<void> _pickCheckOut() async {
    if (_checkInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a check-in date first')));
      return;
    }
    final minDate = _checkInDate!.add(const Duration(days: 1));
    final maxDate = _checkInDate!.add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? minDate,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) setState(() => _checkOutDate = picked);
  }

  Future<void> _handleSubmit() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both dates')));
      return;
    }
    await ref
        .read(accommodationSubmissionProvider.notifier)
        .submitOutOfSemester(
          checkInDate: _checkInDate!,
          checkOutDate: _checkOutDate!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final submission = ref.watch(accommodationSubmissionProvider);

    ref.listen<AccommodationSubmissionState>(
        accommodationSubmissionProvider, (_, next) {
      if (next.isSuccess) {
        ref.invalidate(myAccommodationAppsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(accommodationSubmissionProvider.notifier).reset();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rate info
        _buildRateInfo([_buildRateRow('Single Room', 'RM49.00/night')]),
        const SizedBox(height: KizSpacing.base),
        if (submission.errorMessage != null) ...[
          _buildError(submission.errorMessage!),
          const SizedBox(height: KizSpacing.base),
        ],
        // Check-in date
        _buildLabel('Check-in Date'),
        const SizedBox(height: KizSpacing.sm),
        _buildDateTile(
          _checkInDate != null
              ? _fmtDate(_checkInDate!)
              : 'Select check-in date (today or future)',
          submission.isSubmitting ? null : _pickCheckIn,
        ),
        const SizedBox(height: KizSpacing.base),
        // Check-out date
        _buildLabel('Check-out Date'),
        const SizedBox(height: KizSpacing.sm),
        _buildDateTile(
          _checkOutDate != null
              ? _fmtDate(_checkOutDate!)
              : 'Select check-out date (max 90 nights)',
          submission.isSubmitting ? null : _pickCheckOut,
        ),
        const SizedBox(height: KizSpacing.base),
        // Cost summary
        if (_nights > 0) ...[
          KizCard(
            padding: const EdgeInsets.all(KizSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_nights night${_nights == 1 ? "" : "s"} x RM49.00',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                Text(
                  'RM${_totalCost.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: KizColors.onBackground),
                ),
              ],
            ),
          ),
          const SizedBox(height: KizSpacing.base),
        ],
        const SizedBox(height: KizSpacing.base),
        // Submit
        SizedBox(
          height: kMinTouchTarget,
          child: ElevatedButton(
            onPressed: submission.isSubmitting ? null : _handleSubmit,
            child: submission.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit Application'),
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Status card for active applications
// ---------------------------------------------------------------------------

class _ApplicationStatusCard extends StatelessWidget {
  const _ApplicationStatusCard({required this.application});
  final AccommodationApplication application;

  @override
  Widget build(BuildContext context) {
    final typeLabel = application.applicationType == 'semester'
        ? 'Semester'
        : 'Out-of-Semester';
    final (kind, label) = KizStatusMapper.accommodation(application.status);
    return KizCard(
      spineKind: kind,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(typeLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KizColors.onBackground)),
              KizStatusTab(kind: kind, label: label),
            ],
          ),
          const SizedBox(height: KizSpacing.md),
          _buildInfoRow(Icons.calendar_today_outlined,
              'Submitted ${_fmtDateGlobal(application.createdAt)}'),
          if (_showAssignment(application.status)) ...[
            const SizedBox(height: KizSpacing.sm),
            Wrap(
              spacing: KizSpacing.sm,
              runSpacing: KizSpacing.sm,
              children: [
                if (application.assignedBlockName != null)
                  KizCodeTag('Block ${application.assignedBlockName}'),
                if (application.assignedRoomNumber != null)
                  KizCodeTag('Room ${application.assignedRoomNumber}'),
                if (application.assignedBedLabel != null)
                  KizCodeTag('Bed ${application.assignedBedLabel}'),
              ],
            ),
          ],
          if (_showQrCode(application.status)) ...[
            const SizedBox(height: KizSpacing.lg),
            Center(
              child: Column(
                children: [
                  QrImageView(
                    data: application.id,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                  const SizedBox(height: KizSpacing.sm),
                  Text(
                    'Show this QR code to admin for check-in/check-out',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: KizColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _showAssignment(String s) =>
      s == 'approved' || s == 'checked_in' || s == 'checked_out';

  bool _showQrCode(String s) => s == 'approved' || s == 'checked_in';
}

// ---------------------------------------------------------------------------
// History tile (read-only)
// ---------------------------------------------------------------------------

class _ApplicationHistoryTile extends StatelessWidget {
  const _ApplicationHistoryTile({required this.application});
  final AccommodationApplication application;

  @override
  Widget build(BuildContext context) {
    final typeLabel = application.applicationType == 'semester'
        ? 'Semester'
        : 'Out-of-Semester';
    final (kind, label) = KizStatusMapper.accommodation(application.status);
    return KizCard(
      spineKind: kind,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(typeLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: KizColors.onBackground)),
              KizStatusTab(kind: kind, label: label),
            ],
          ),
          const SizedBox(height: KizSpacing.sm),
          _buildInfoRow(Icons.calendar_today_outlined,
              _fmtDateGlobal(application.createdAt)),
          if (application.status == 'rejected' &&
              application.rejectionReason != null) ...[
            const SizedBox(height: KizSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: KizColors.error),
                const SizedBox(width: KizSpacing.sm),
                Expanded(
                  child: Text(application.rejectionReason!,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: KizColors.error)),
                ),
              ],
            ),
          ],
          if (application.status == 'checked_out' &&
              application.assignedBlockName != null) ...[
            const SizedBox(height: KizSpacing.sm),
            Wrap(
              spacing: KizSpacing.sm,
              runSpacing: KizSpacing.sm,
              children: [
                KizCodeTag('Block ${application.assignedBlockName}'),
                KizCodeTag(
                    'Room ${application.assignedRoomNumber ?? "-"}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets / helpers
// ---------------------------------------------------------------------------

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KizSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48,
                color: KizColors.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: KizSpacing.base),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 15, color: KizColors.onSurface)),
          ],
        ),
      ),
    );
  }
}

Widget _buildLabel(String text) => Text(
      text,
      style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground),
    );

Widget _buildError(String message) => Container(
      padding: const EdgeInsets.all(KizSpacing.md),
      decoration: BoxDecoration(
        color: KizColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KizRadius.input),
        border: Border.all(color: KizColors.error),
      ),
      child: Text(message,
          style: GoogleFonts.poppins(fontSize: 14, color: KizColors.error)),
    );

Widget _buildRateInfo(List<Widget> children) => Container(
      padding: const EdgeInsets.all(KizSpacing.md),
      decoration: BoxDecoration(
        color: KizColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(KizRadius.card),
        border: Border.all(color: KizColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate Information',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KizColors.onBackground)),
          const SizedBox(height: KizSpacing.sm),
          ...children,
        ],
      ),
    );

Widget _buildRateRow(String label, String rate) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          Text(rate,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );

Widget _buildDateTile(String label, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KizRadius.input),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: KizSpacing.md, horizontal: KizSpacing.base),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KizRadius.input),
          border: Border.all(color: KizColors.border, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 20, color: KizColors.onSurface),
            const SizedBox(width: KizSpacing.sm),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: KizColors.onSurface)),
            ),
          ],
        ),
      ),
    );

Widget _buildInfoRow(IconData icon, String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: KizColors.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: KizSpacing.sm),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: KizColors.onSurface)),
          ),
        ],
      ),
    );

String _fmtDateGlobal(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}
