import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/kiz_theme.dart';
import '../application/announcements_provider.dart';

/// Form screen for creating or editing an announcement.
///
/// Validates title (1-200 chars) and body (1-5000 chars) client-side.
/// In edit mode, pre-fills fields with existing announcement data.
class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({
    super.key,
    this.announcementId,
  });

  /// If non-null, the screen is in edit mode for this announcement.
  final String? announcementId;

  bool get isEditing => announcementId != null;

  @override
  ConsumerState<AnnouncementFormScreen> createState() =>
      _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState
    extends ConsumerState<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _initialized = false;

  static const int _maxTitleLength = 200;
  static const int _maxBodyLength = 5000;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(announcementDetailProvider.notifier)
            .fetchAnnouncement(widget.announcementId!);
      });
    } else {
      // Reset state for creation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(announcementDetailProvider.notifier).reset();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _populateFields(AnnouncementDetailState state) {
    if (!_initialized && widget.isEditing && state.announcement != null) {
      _titleController.text = state.announcement!.title;
      _bodyController.text = state.announcement!.body;
      _initialized = true;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final notifier = ref.read(announcementDetailProvider.notifier);

    bool success;
    if (widget.isEditing) {
      success = await notifier.updateAnnouncement(
        widget.announcementId!,
        title: title,
        body: body,
      );
    } else {
      success = await notifier.createAnnouncement(
        title: title,
        body: body,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Announcement updated successfully.'
                : 'Announcement created successfully.',
          ),
          backgroundColor: KizColors.navigationBar,
        ),
      );
      context.go(AppRoutes.announcements);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementDetailProvider);
    final theme = Theme.of(context);

    // Populate fields when data arrives in edit mode
    _populateFields(state);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.announcements),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          widget.isEditing ? 'Edit Announcement' : 'New Announcement',
        ),
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(AnnouncementDetailState state, ThemeData theme) {
    // Show loading only in edit mode while fetching
    if (widget.isEditing && state.isLoading && state.announcement == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KizSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter announcement title',
                    counterText:
                        '${_titleController.text.length}/$_maxTitleLength',
                  ),
                  maxLength: _maxTitleLength,
                  textInputAction: TextInputAction.next,
                  enabled: !state.isSaving,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (value.trim().length > _maxTitleLength) {
                      return 'Title must be at most $_maxTitleLength characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: KizSpacing.lg),

                // Body field
                TextFormField(
                  controller: _bodyController,
                  decoration: InputDecoration(
                    labelText: 'Body',
                    hintText: 'Enter announcement body',
                    alignLabelWithHint: true,
                    counterText:
                        '${_bodyController.text.length}/$_maxBodyLength',
                  ),
                  maxLines: 12,
                  maxLength: _maxBodyLength,
                  enabled: !state.isSaving,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Body is required';
                    }
                    if (value.trim().length > _maxBodyLength) {
                      return 'Body must be at most $_maxBodyLength characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: KizSpacing.xl),

                // Error message
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(KizSpacing.md),
                    decoration: BoxDecoration(
                      color: KizColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: KizColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: KizColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: KizSpacing.sm),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: KizColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KizSpacing.base),
                ],

                // Submit button
                SizedBox(
                  height: KizTheme.minTouchTarget,
                  child: ElevatedButton(
                    onPressed: state.isSaving ? null : _handleSubmit,
                    child: state.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KizColors.onBackground,
                            ),
                          )
                        : Text(widget.isEditing ? 'Update' : 'Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
