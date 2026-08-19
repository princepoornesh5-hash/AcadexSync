import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/department_attendance_comparison.dart';

class DepartmentComparisonCard extends StatelessWidget {
  final DepartmentAttendanceComparison comparison;
  final int rank;

  const DepartmentComparisonCard({super.key, required this.comparison, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData trendIcon;
    Color trendColor;
    
    switch (comparison.trend) {
      case TrendDirection.up:
        trendIcon = LucideIcons.trendingUp;
        trendColor = AcadexColors.success;
        break;
      case TrendDirection.down:
        trendIcon = LucideIcons.trendingDown;
        trendColor = AcadexColors.error;
        break;
      case TrendDirection.neutral:
        trendIcon = LucideIcons.minus;
        trendColor = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
              child: Center(
                child: Text(
                  "#$rank",
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comparison.departmentName,
                    style: AcadexTypography.title(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${comparison.studentCount} Students • ${comparison.facultyCount} Faculty",
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${comparison.attendancePercentage}%",
                        style: AcadexTypography.title(
                          color: AcadexColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(trendIcon, size: 16, color: trendColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${comparison.todayCompletionPercentage.toInt()}% Completion",
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
