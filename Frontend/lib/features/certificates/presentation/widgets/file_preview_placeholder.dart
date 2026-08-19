import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';

class FilePreviewPlaceholder extends StatelessWidget {
  final String fileType;
  final String fileName;
  final String fileSize;

  const FilePreviewPlaceholder({
    super.key,
    required this.fileType,
    required this.fileName,
    required this.fileSize,
  });

  bool get isPreviewable {
    final ext = fileType.toLowerCase();
    return ext == 'pdf' || ext == 'jpg' || ext == 'jpeg' || ext == 'png';
  }

  static IconData _icon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return LucideIcons.image;
      case 'doc':
      case 'docx':
        return LucideIcons.fileCode;
      default:
        return LucideIcons.file;
    }
  }

  static Color _color(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return AcadexColors.error;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return AcadexColors.accentTeal;
      case 'doc':
      case 'docx':
        return AcadexColors.primary;
      default:
        return AcadexColors.inkMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color(fileType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AcadexRadius.lg),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon(fileType), size: 36, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            fileName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '$fileSize · ${fileType.toUpperCase()}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPreviewable
                  ? (isDark ? AcadexColors.success.withValues(alpha: 0.2) : AcadexColors.successLight)
                  : (isDark ? AcadexColors.warning.withValues(alpha: 0.2) : AcadexColors.warningLight),
              borderRadius: BorderRadius.circular(AcadexRadius.full),
              border: Border.all(
                color: isPreviewable
                    ? (isDark ? AcadexColors.success.withValues(alpha: 0.4) : AcadexColors.success.withValues(alpha: 0.3))
                    : (isDark ? AcadexColors.warning.withValues(alpha: 0.4) : AcadexColors.warning.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPreviewable ? LucideIcons.eye : LucideIcons.download,
                  size: 13,
                  color: isPreviewable
                      ? (isDark ? AcadexColors.success : AcadexColors.successDark)
                      : (isDark ? AcadexColors.warning : AcadexColors.warningDark),
                ),
                const SizedBox(width: 5),
                Text(
                  isPreviewable ? 'In-App Preview Ready' : 'Download Required to View',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPreviewable
                        ? (isDark ? AcadexColors.success : AcadexColors.successDark)
                        : (isDark ? AcadexColors.warning : AcadexColors.warningDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
