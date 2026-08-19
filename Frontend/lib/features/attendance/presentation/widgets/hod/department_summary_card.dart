import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/department_attendance_summary.dart';

class DepartmentSummaryCard extends StatelessWidget {
  final DepartmentAttendanceSummary summary;

  const DepartmentSummaryCard({super.key, required this.summary});

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
            "DEPARTMENT OVERVIEW",
            style: AcadexTypography.eyebrow(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                "Overall Attendance",
                "${summary.overallPercentage}%",
                summary.overallPercentage >= 75 ? AcadexColors.success : AcadexColors.error,
                isDark,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "Critical Defaulters",
                summary.studentsBelow75.toString(),
                AcadexColors.warning,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricCard(
                "Faculty Completed",
                "${summary.facultyCompleted} / ${summary.totalFaculty}",
                AcadexColors.primary,
                isDark,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "Today's Classes",
                summary.todayClasses.toString(),
                isDark ? AcadexColors.darkInk : AcadexColors.ink,
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
