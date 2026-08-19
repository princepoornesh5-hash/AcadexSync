import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/certificate_type.dart';

class CertificateTypeBadge extends StatelessWidget {
  final CertificateType type;
  const CertificateTypeBadge({super.key, required this.type});

  static Color _color(CertificateType t) {
    switch (t) {
      case CertificateType.academic:
        return AcadexColors.primary;
      case CertificateType.technical:
        return AcadexColors.accentPurple;
      case CertificateType.internship:
        return AcadexColors.accentOrange;
      case CertificateType.workshop:
        return AcadexColors.accentTeal;
      case CertificateType.participation:
        return AcadexColors.info;
      case CertificateType.achievement:
        return AcadexColors.warning;
      case CertificateType.sports:
        return AcadexColors.success;
      case CertificateType.cultural:
        return AcadexColors.accentPink;
      case CertificateType.other:
        return AcadexColors.inkMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = _color(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? baseColor.withValues(alpha: 0.2) : baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AcadexRadius.full),
        border: Border.all(
          color: isDark ? baseColor.withValues(alpha: 0.4) : baseColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        type.displayName,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? baseColor.withValues(alpha: 0.95) : baseColor,
        ),
      ),
    );
  }
}
