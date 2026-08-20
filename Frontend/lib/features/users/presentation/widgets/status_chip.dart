import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/user_status_enum.dart';

class StatusChip extends StatelessWidget {
  final UserStatus status;
  
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    
    switch (status) {
      case UserStatus.active:
        bgColor = DashboardColors.successLight;
        textColor = DashboardColors.success;
        break;
      case UserStatus.pending:
        bgColor = DashboardColors.warningLight;
        textColor = DashboardColors.warning;
        break;
      case UserStatus.inactive:
      case UserStatus.deactivated:
        bgColor = DashboardColors.textMuted.withValues(alpha: 0.1);
        textColor = DashboardColors.textSecondary;
        break;
      case UserStatus.suspended:
        bgColor = DashboardColors.errorLight;
        textColor = DashboardColors.error;
        break;
      case UserStatus.graduated:
        bgColor = DashboardColors.primaryLight;
        textColor = DashboardColors.primary;
        break;
      case UserStatus.transferred:
        bgColor = DashboardColors.warningLight;
        textColor = DashboardColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
