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

  static IconData _icon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return LucideIcons.fileText;
      case 'jpg':
      case 'jpeg':
      case 'png': return LucideIcons.image;
      case 'doc':
      case 'docx': return LucideIcons.fileText;
      default: return LucideIcons.file;
    }
  }

  static Color _color(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return DashboardColors.error;
      case 'jpg':
      case 'jpeg':
      case 'png': return DashboardColors.teal;
      case 'doc':
      case 'docx': return DashboardColors.primary;
      default: return DashboardColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(fileType);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(_icon(fileType), size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            fileName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$fileSize · ${fileType.toUpperCase()}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: DashboardColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: DashboardColors.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '📁 Development Mode — Mock File',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: DashboardColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
