import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/applications_provider.dart';
import '../data/accommodation_repository.dart';

/// Applications tab — filterable table with status, type, and lifestyle tag
/// filters (AND logic). Shows Approve/Reject actions only for submitted apps.
class ApplicationsTab extends ConsumerStatefulWidget {
  const ApplicationsTab({super.key});

  @override
  ConsumerState<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends ConsumerState<ApplicationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(applicationsProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applicationsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        _FiltersRow(state: state),
        const Divider(height: 1),
        Expanded(
          child: state.isLoading && state.applications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null && state.applications.isEmpty
                  ? _ErrorView(
                      message: state.errorMessage!,
                      onRetry: () =>
                          ref.read(applicationsProvider.notifier).fetch(),
                    )
                  : state.applications.isEmpty
                      ? Center(
                          child: Text(
                            'No applications found.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      : _ApplicationsTable(state: state),
        ),
        if (state.totalPages > 1) _PaginationBar(state: state),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

class _FiltersRow extends ConsumerWidget {
  const _FiltersRow({required this.state});

  final ApplicationsState state;

  static const _statuses = ['submitted', 'approved', 'checked_in', 'checked_out', 'rejected'];
  static const _types = ['semester', 'out_of_semester'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(KizSpacing.base),
      child: Wrap(
        spacing: KizSpacing.base,
        runSpacing: KizSpacing.sm,
        children: [
          // Status filter
          SizedBox(
            width: 180,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.statusFilter,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final s in _statuses)
                      DropdownMenuItem(value: s, child: Text(_formatStatus(s))),
                  ],
                  onChanged: (v) =>
                      ref.read(applicationsProvider.notifier).setStatusFilter(v),
                ),
              ),
            ),
          ),
          // Type filter
          SizedBox(
            width: 180,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Type',
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.typeFilter,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final t in _types)
                      DropdownMenuItem(value: t, child: Text(_formatType(t))),
                  ],
                  onChanged: (v) =>
                      ref.read(applicationsProvider.notifier).setTypeFilter(v),
                ),
              ),
            ),
          ),
          // Lifestyle tags multi-select (AND logic)
          _TagFilterChips(selectedTags: state.tagFilters),
        ],
      ),
    );
  }

  String _formatStatus(String s) => switch (s) {
        'submitted' => 'Submitted',
        'approved' => 'Approved',
        'checked_in' => 'Checked In',
        'checked_out' => 'Checked Out',
        'rejected' => 'Rejected',
        _ => s,
      };

  String _formatType(String t) => switch (t) {
        'semester' => 'Semester',
        'out_of_semester' => 'Out of Semester',
        _ => t,
      };
}

class _TagFilterChips extends ConsumerWidget {
  const _TagFilterChips({required this.selectedTags});

  final List<String> selectedTags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: KizSpacing.xs,
      runSpacing: KizSpacing.xs,
      children: [
        for (final tag in LifestyleTag.values)
          FilterChip(
            label: Text(_tagLabel(tag)),
            selected: selectedTags.contains(tag.dbValue),
            onSelected: (selected) {
              final updated = List<String>.from(selectedTags);
              if (selected) {
                updated.add(tag.dbValue);
              } else {
                updated.remove(tag.dbValue);
              }
              ref.read(applicationsProvider.notifier).setTagFilters(updated);
            },
          ),
      ],
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
// Table
// ---------------------------------------------------------------------------

class _ApplicationsTable extends ConsumerWidget {
  const _ApplicationsTable({required this.state});

  final ApplicationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KizSpacing.base),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Tags')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: [
            for (final app in state.applications)
              DataRow(cells: [
                DataCell(Text(app.studentName ?? '—')),
                DataCell(Text(_formatType(app.applicationType))),
                DataCell(Text(_formatStatus(app.status))),
                DataCell(_TagChips(tags: app.lifestyleTags)),
                DataCell(Text(_formatDate(app.createdAt))),
                DataCell(_ActionButtons(application: app)),
              ]),
          ],
        ),
      ),
    );
  }

  String _formatType(String t) => switch (t) {
        'semester' => 'Semester',
        'out_of_semester' => 'Out of Semester',
        _ => t,
      };

  String _formatStatus(String s) => switch (s) {
        'submitted' => 'Submitted',
        'approved' => 'Approved',
        'checked_in' => 'Checked In',
        'checked_out' => 'Checked Out',
        'rejected' => 'Rejected',
        _ => s,
      };

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: KizSpacing.xs,
      runSpacing: KizSpacing.xs,
      children: [
        for (final tag in tags)
          Chip(
            label: Text(
              _tagLabel(tag),
              style: const TextStyle(fontSize: 11),
            ),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  String _tagLabel(String dbValue) {
    final tag = LifestyleTag.fromDbValue(dbValue);
    if (tag == null) return dbValue;
    return switch (tag) {
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
}

// ---------------------------------------------------------------------------
// Actions — Approve/Reject only for 'submitted' status
// ---------------------------------------------------------------------------

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.application});

  final AccommodationApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ponytail: Only show actions for submitted applications per Req 4.6
    if (application.status != 'submitted') return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _showApproveDialog(context, ref),
          child: const Text('Approve'),
        ),
        const SizedBox(width: KizSpacing.xs),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: KizColors.error),
          onPressed: () => _showRejectDialog(context, ref),
          child: const Text('Reject'),
        ),
      ],
    );
  }

  Future<void> _showApproveDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ApprovalDialog(application: application),
    );

    if (result == true) {
      ref.read(applicationsProvider.notifier).fetch();
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _RejectDialog(applicationId: application.id),
    );

    if (result == true) {
      ref.read(applicationsProvider.notifier).fetch();
    }
  }
}

/// Dialog with text input for rejection reason (1-500 chars, non-whitespace).
class _RejectDialog extends ConsumerStatefulWidget {
  const _RejectDialog({required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends ConsumerState<_RejectDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateReason(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'A reason is required.';
    if (trimmed.length > 500) return 'Reason must be 500 characters or less.';
    return null;
  }

  bool get _canSubmit {
    final trimmed = _controller.text.trim();
    return trimmed.isNotEmpty && trimmed.length <= 500 && !_isSubmitting;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(accommodationRepositoryProvider);
      await repo.rejectApplication(
        widget.applicationId,
        reason: _controller.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to reject application.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Application'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide a reason for rejecting this application:'),
              const SizedBox(height: KizSpacing.base),
              TextFormField(
                controller: _controller,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(),
                ),
                validator: _validateReason,
                onChanged: (_) => setState(() {}),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: KizSpacing.sm),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: KizColors.error, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: KizColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: _canSubmit ? _submit : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm Rejection'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Approval Dialog — cascading Block → Room → Bed dropdowns (Req 4.2–4.5)
// ---------------------------------------------------------------------------

class _ApprovalDialog extends ConsumerStatefulWidget {
  const _ApprovalDialog({required this.application});

  final AccommodationApplication application;

  @override
  ConsumerState<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends ConsumerState<_ApprovalDialog> {
  List<Block> _blocks = [];
  List<Room> _rooms = [];
  List<Bed> _beds = [];

  Block? _selectedBlock;
  Room? _selectedRoom;
  Bed? _selectedBed;

  bool _isLoadingBlocks = true;
  bool _isLoadingRooms = false;
  bool _isLoadingBeds = false;
  bool _isApproving = false;
  String? _error;

  AccommodationRepository get _repo =>
      ref.read(accommodationRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  Future<void> _loadBlocks() async {
    setState(() {
      _isLoadingBlocks = true;
      _error = null;
    });
    try {
      _blocks = await _repo.listBlocks();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load blocks.';
    }
    if (mounted) setState(() => _isLoadingBlocks = false);
  }

  Future<void> _loadRooms(Block block) async {
    setState(() {
      _selectedBlock = block;
      _selectedRoom = null;
      _selectedBed = null;
      _rooms = [];
      _beds = [];
      _isLoadingRooms = true;
      _error = null;
    });
    try {
      _rooms = await _repo.listRooms(
        blockId: block.id,
        roomType: widget.application.roomTypePreference,
      );
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load rooms.';
    }
    if (mounted) setState(() => _isLoadingRooms = false);
  }

  Future<void> _loadBeds(Room room) async {
    setState(() {
      _selectedRoom = room;
      _selectedBed = null;
      _beds = [];
      _isLoadingBeds = true;
      _error = null;
    });
    try {
      _beds = await _repo.listAvailableBeds(roomId: room.id);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load beds.';
    }
    if (mounted) setState(() => _isLoadingBeds = false);
  }

  Future<void> _confirmApproval() async {
    if (_selectedBed == null) return;
    setState(() {
      _isApproving = true;
      _error = null;
    });
    try {
      await _repo.approveApplication(
        widget.application.id,
        bedId: _selectedBed!.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ConflictException catch (e) {
      // ponytail: BED_UNAVAILABLE — refresh dropdowns so admin can re-select
      setState(() {
        _error = e.message;
        _isApproving = false;
      });
      _refreshDropdowns();
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isApproving = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Approval failed. Please try again.';
        _isApproving = false;
      });
    }
  }

  /// Re-fetches rooms and beds after a BED_UNAVAILABLE error.
  Future<void> _refreshDropdowns() async {
    if (_selectedBlock != null) {
      await _loadRooms(_selectedBlock!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Approve Application'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign a bed to ${widget.application.studentName ?? 'this student'}.',
              style: theme.textTheme.bodyMedium,
            ),
            if (widget.application.roomTypePreference != null)
              Padding(
                padding: const EdgeInsets.only(top: KizSpacing.xs),
                child: Text(
                  'Requested type: ${_formatRoomType(widget.application.roomTypePreference!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: KizSpacing.base),
            if (_isLoadingBlocks)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Block dropdown
              DropdownButtonFormField<Block>(
                key: ValueKey('block_${_blocks.length}'),
                decoration: const InputDecoration(
                  labelText: 'Block',
                  isDense: true,
                ),
                initialValue: _selectedBlock,
                items: [
                  for (final block in _blocks)
                    DropdownMenuItem(value: block, child: Text(block.name)),
                ],
                onChanged: (block) {
                  if (block != null) _loadRooms(block);
                },
              ),
              const SizedBox(height: KizSpacing.sm),
              // Room dropdown
              if (_isLoadingRooms)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: KizSpacing.sm),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_selectedBlock != null)
                DropdownButtonFormField<Room>(
                  key: ValueKey('room_${_selectedBlock?.id}_${_rooms.length}'),
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    isDense: true,
                  ),
                  initialValue: _selectedRoom,
                  items: [
                    for (final room in _rooms)
                      DropdownMenuItem(
                        value: room,
                        child: Text(
                          '${room.roomNumber} (${_formatRoomType(room.roomType)})',
                        ),
                      ),
                  ],
                  onChanged: (room) {
                    if (room != null) _loadBeds(room);
                  },
                ),
              const SizedBox(height: KizSpacing.sm),
              // Bed dropdown
              if (_isLoadingBeds)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: KizSpacing.sm),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_selectedRoom != null)
                DropdownButtonFormField<Bed>(
                  key: ValueKey('bed_${_selectedRoom?.id}_${_beds.length}'),
                  decoration: const InputDecoration(
                    labelText: 'Bed',
                    isDense: true,
                  ),
                  initialValue: _selectedBed,
                  items: [
                    for (final bed in _beds)
                      DropdownMenuItem(
                        value: bed,
                        child: Text('Bed ${bed.bedLabel}'),
                      ),
                  ],
                  onChanged: (bed) => setState(() => _selectedBed = bed),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: KizSpacing.sm),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: KizColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isApproving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _selectedBed != null && !_isApproving ? _confirmApproval : null,
          child: _isApproving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm Approval'),
        ),
      ],
    );
  }

  String _formatRoomType(String type) => switch (type) {
        'single' => 'Single',
        'twin_sharing' => 'Twin Sharing',
        _ => type,
      };
}

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

class _PaginationBar extends ConsumerWidget {
  const _PaginationBar({required this.state});

  final ApplicationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: KizSpacing.sm,
        horizontal: KizSpacing.base,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.page > 1
                ? () => ref
                    .read(applicationsProvider.notifier)
                    .goToPage(state.page - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page ${state.page} of ${state.totalPages}'),
          IconButton(
            onPressed: state.page < state.totalPages
                ? () => ref
                    .read(applicationsProvider.notifier)
                    .goToPage(state.page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: KizColors.error),
          const SizedBox(height: KizSpacing.base),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: KizColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KizSpacing.base),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
