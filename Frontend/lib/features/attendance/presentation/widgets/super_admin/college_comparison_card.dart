import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/college_attendance_comparison.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../domain/models/department_attendance_comparison.dart' show TrendDirection;

class CollegeComparisonCard extends StatelessWidget {
  final CollegeAttendanceComparison comparison;
  final int rank;

  const CollegeComparisonCard({super.key, required this.comparison, required this.rank});

  @override
  Widget build(BuildContext context) {
    IconData trendIcon;
    Color trendColor;
    
    switch (comparison.trend) {
      case TrendDirection.up:
        trendIcon = LucideIcons.trendingUp;
        trendColor = DashboardColors.success;
        break;
      case TrendDirection.down:
        trendIcon = LucideIcons.trendingDown;
        trendColor = DashboardColors.error;
        break;
      case TrendDirection.neutral:
        trendIcon = LucideIcons.minus;
        trendColor = DashboardColors.textSecondary;
        break;
    }

    return Card(
      color: DashboardColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: DashboardColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DashboardColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "#$rank",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: DashboardColors.textSecondary),
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
                    comparison.collegeName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${comparison.collegeCode} • ${comparison.studentCount} Students",
                    style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary),
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(trendIcon, size: 16, color: trendColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${comparison.completionRate.toInt()}% Completion",
                    style: const TextStyle(fontSize: 11, color: DashboardColors.textSecondary),
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
