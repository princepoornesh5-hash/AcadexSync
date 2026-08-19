import 'package:flutter/material.dart';
import '../../domain/models/attendance_status.dart';
import '../../../../app/theme/app_theme.dart';

class AttendanceStatusChip extends StatelessWidget {
  final AttendanceStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const AttendanceStatusChip({
    super.key,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final color = status == AttendanceStatus.present
        ? AcadexColors.success
        : status == AttendanceStatus.late
            ? AcadexColors.warning
            : AcadexColors.error;

    final activeBg = status == AttendanceStatus.present
        ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
        : status == AttendanceStatus.late
            ? (isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight)
            : (isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: AcadexRadius.borderRadiusFull,
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          status.displayName,
          style: AcadexTypography.caption(
            color: isSelected ? color : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
