import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';

class RoleBadge extends StatelessWidget {
  final AppRole role;
  
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    
    switch (role) {
      case AppRole.superAdmin:
        bgColor = DashboardColors.errorLight;
        textColor = DashboardColors.error;
        break;
      case AppRole.collegeAdmin:
        bgColor = DashboardColors.primaryLight;
        textColor = DashboardColors.primary;
        break;
      case AppRole.hod:
        bgColor = DashboardColors.warningLight;
        textColor = DashboardColors.warning;
        break;
      case AppRole.faculty:
        bgColor = DashboardColors.purpleLight;
        textColor = DashboardColors.purple;
        break;
      case AppRole.student:
        bgColor = DashboardColors.successLight;
        textColor = DashboardColors.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        role.displayName,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
