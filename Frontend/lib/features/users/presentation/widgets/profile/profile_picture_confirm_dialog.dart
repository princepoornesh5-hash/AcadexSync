import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../../core/errors/acadex_error.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/user_providers.dart';

class ProfilePictureConfirmDialog extends ConsumerStatefulWidget {
  final Uint8List imageBytes;
  final String fileName;
  final int fileSize;
  final String targetUserId;
  final VoidCallback? onSuccess;

  const ProfilePictureConfirmDialog({
    super.key,
    required this.imageBytes,
    required this.fileName,
    required this.fileSize,
    required this.targetUserId,
    this.onSuccess,
  });

  static Future<bool?> show({
    required BuildContext context,
    required Uint8List imageBytes,
    required String fileName,
    required int fileSize,
    required String targetUserId,
    VoidCallback? onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProfilePictureConfirmDialog(
        imageBytes: imageBytes,
        fileName: fileName,
        fileSize: fileSize,
        targetUserId: targetUserId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<ProfilePictureConfirmDialog> createState() => _ProfilePictureConfirmDialogState();
}

class _ProfilePictureConfirmDialogState extends ConsumerState<ProfilePictureConfirmDialog> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleUpload() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final notifier = ref.read(profileImageUploadProvider.notifier);
      await notifier.uploadProfileImage(
        targetUserId: widget.targetUserId,
        bytes: widget.imageBytes,
        fileName: widget.fileName,
      );

      // Invalidate relevant providers to force fresh profile picture loading
      ref.invalidate(authProvider);
      ref.invalidate(usersListProvider);
      ref.invalidate(userDetailProvider(widget.targetUserId));

      widget.onSuccess?.call();

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Profile picture updated successfully!',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = AcadexException.sanitizedMessage(
            e,
            fallback: 'Failed to upload profile picture. Please try again.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final extension = widget.fileName.split('.').last.toUpperCase();

    return Dialog(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AcadexRadius.borderRadiusXl,
        side: BorderSide(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
      ),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: AcadexSpacing.dialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Preview Profile Picture',
                      style: AcadexTypography.heading2(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isUploading)
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Image Preview Frame
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AcadexColors.primary.withValues(alpha: 0.4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AcadexColors.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.memory(
                    widget.imageBytes,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                      child: const Center(
                        child: Icon(LucideIcons.imageOff, size: 36, color: AcadexColors.error),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // File Metadata Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.fileImage,
                      size: 14,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$extension • ${_formatFileSize(widget.fileSize)}',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Explanatory note
              Text(
                'This photo will be displayed across your profile, attendance sheets, and academic records.',
                textAlign: TextAlign.center,
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),

              // Upload Progress Bar
              if (_isUploading) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    backgroundColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(AcadexColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _uploadProgress > 0
                      ? 'Uploading... ${(_uploadProgress * 100).toInt()}%'
                      : 'Preparing and verifying image...',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],

              // Error banner if upload failed
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AcadexColors.error.withValues(alpha: 0.1),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AcadexColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Actions (Responsive Wrap to prevent overflow)
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  AcadexButton(
                    label: 'Cancel',
                    variant: AcadexButtonVariant.secondary,
                    onPressed: _isUploading ? null : () => Navigator.of(context).pop(false),
                  ),
                  AcadexButton(
                    label: _isUploading ? 'Uploading...' : 'Confirm & Upload',
                    icon: LucideIcons.uploadCloud,
                    isLoading: _isUploading,
                    onPressed: _isUploading ? null : _handleUpload,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
