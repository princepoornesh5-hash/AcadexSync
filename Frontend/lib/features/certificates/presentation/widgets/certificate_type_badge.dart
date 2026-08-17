import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/certificate_type.dart';

class CertificateTypeBadge extends StatelessWidget {
  final CertificateType type;
  const CertificateTypeBadge({super.key, required this.type});

  static Color _bgColor(CertificateType t) {
    switch (t) {
      case CertificateType.academic: return DashboardColors.primaryLight;
      case CertificateType.technical: return DashboardColors.purpleLight;
      case CertificateType.internship: return DashboardColors.orangeLight;
      case CertificateType.workshop: return DashboardColors.tealLight;
      case CertificateType.participation: return DashboardColors.infoLight;
      case CertificateType.achievement: return DashboardColors.warningLight;
      case CertificateType.sports: return DashboardColors.successLight;
      case CertificateType.cultural: return const Color(0xFFFCE7F3);
      case CertificateType.other: return DashboardColors.divider;
    }
  }

  static Color _textColor(CertificateType t) {
    switch (t) {
      case CertificateType.academic: return DashboardColors.primary;
      case CertificateType.technical: return DashboardColors.purple;
      case CertificateType.internship: return DashboardColors.orange;
      case CertificateType.workshop: return DashboardColors.teal;
      case CertificateType.participation: return DashboardColors.info;
      case CertificateType.achievement: return DashboardColors.warning;
      case CertificateType.sports: return DashboardColors.success;
      case CertificateType.cultural: return const Color(0xFFDB2777);
      case CertificateType.other: return DashboardColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(type),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.displayName,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textColor(type),
        ),
      ),
    );
  }
}
