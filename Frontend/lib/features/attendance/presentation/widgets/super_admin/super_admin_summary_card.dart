import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/super_admin_attendance_summary.dart';

class SuperAdminSummaryCard extends StatelessWidget {
  final SuperAdminAttendanceSummary summary;

  const SuperAdminSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusXl,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PLATFORM ATTENDANCE OVERVIEW",
            style: AcadexTypography.eyebrow(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                "System Attendance",
                "${summary.todayAttendancePercentage}%",
                summary.todayAttendancePercentage >= 80 ? AcadexColors.success : AcadexColors.warning,
                isDark,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "Total Students",
                summary.totalStudents.toString(),
                AcadexColors.primary,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricCard(
                "Colleges Online",
                summary.totalColleges.toString(),
                isDark ? AcadexColors.darkInk : AcadexColors.ink,
                isDark,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "Pending Colleges",
                summary.pendingColleges.toString(),
                summary.pendingColleges > 0 ? AcadexColors.error : AcadexColors.success,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color valueColor, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
          borderRadius: AcadexRadius.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AcadexTypography.heading2(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}
