import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/complaints_provider.dart';

/// Maximum allowed image size in bytes (5 MB).
const int _maxImageSizeBytes = 5 * 1024 * 1024;

/// Allowed image file extensions.
const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png'};

/// Screen for submitting a new complaint with description, location,
/// and optional image attachment.
class ComplaintSubmitScreen extends ConsumerStatefulWidget {
  const ComplaintSubmitScreen({super.key});

  @override
  ConsumerState<ComplaintSubmitScreen> createState() =>
      _ComplaintSubmitScreenState();
}

class _ComplaintSubmitScreenState extends ConsumerState<ComplaintSubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  String? _imageError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

    if (picked == null) return;

    // Validate file extension.
    final extension = picked.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      setState(() {
        _imageError = 'Only JPEG and PNG images are allowed.';
        _imageBytes = null;
        _imageName = null;
      });
      return;
    }

    // Read bytes and validate size.
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > _maxImageSizeBytes) {
      setState(() {
        _imageError = 'Image must be less than 5 MB.';
        _imageBytes = null;
        _imageName = null;
      });
      return;
    }

    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
      _imageError = null;
    });
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _imageError = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(complaintSubmissionProvider.notifier).submit(
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          imageBytes: _imageBytes,
          imageName: _imageName,
        );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KizSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(complaintSubmissionProvider);

    // Navigate back on successful submission.
    ref.listen<ComplaintSubmissionState>(complaintSubmissionProvider,
        (previous, next) {
      if (next.isSuccess) {
        // Refresh the complaints list.
        ref.read(complaintsListProvider.notifier).refresh();
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit Complaint',
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KizSpacing.base),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message from submission
              if (submissionState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(KizSpacing.md),
                  decoration: BoxDecoration(
                    color: KizColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(KizRadius.input),
                    border: Border.all(color: KizColors.error),
                  ),
                  child: Text(
                    submissionState.errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: KizColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: KizSpacing.base),
              ],

              // Description field
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KizColors.onBackground,
                ),
              ),
              const SizedBox(height: KizSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                enabled: !submissionState.isSubmitting,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue in detail...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.trim().length > 1000) {
                    return 'Description must be 1000 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: KizSpacing.base),

              // Location field
              Text(
                'Location',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KizColors.onBackground,
                ),
              ),
              const SizedBox(height: KizSpacing.sm),
              TextFormField(
                controller: _locationController,
                enabled: !submissionState.isSubmitting,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'e.g. Block A, Level 3, Room 301',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  if (value.trim().length > 200) {
                    return 'Location must be 200 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: KizSpacing.base),

              // Image attachment section
              Text(
                'Photo (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KizColors.onBackground,
                ),
              ),
              const SizedBox(height: KizSpacing.sm),

              if (_imageBytes != null) ...[
                // Image preview
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(KizRadius.card),
                      child: Image.memory(
                        _imageBytes!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: KizSpacing.sm,
                      right: KizSpacing.sm,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(KizSpacing.xs),
                          decoration: BoxDecoration(
                            color: KizColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Image picker button
                GestureDetector(
                  onTap: submissionState.isSubmitting
                      ? null
                      : _showImageSourceDialog,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: KizColors.cork.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(KizRadius.card),
                      border: Border.all(
                        color: _imageError != null
                            ? KizColors.error
                            : KizColors.cork.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: KizColors.cork,
                          ),
                          const SizedBox(height: KizSpacing.sm),
                          Text(
                            'Tap to attach a photo',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color:
                                  KizColors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            'JPEG or PNG, max 5 MB',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color:
                                  KizColors.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Image error
              if (_imageError != null) ...[
                const SizedBox(height: KizSpacing.sm),
                Text(
                  _imageError!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: KizColors.error,
                  ),
                ),
              ],

              const SizedBox(height: KizSpacing.xxl),

              // Submit button
              SizedBox(
                height: kMinTouchTarget,
                child: ElevatedButton(
                  onPressed:
                      submissionState.isSubmitting ? null : _handleSubmit,
                  child: submissionState.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KizColors.onBackground,
                          ),
                        )
                      : const Text('Submit Complaint'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
