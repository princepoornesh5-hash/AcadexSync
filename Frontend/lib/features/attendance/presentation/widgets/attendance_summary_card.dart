import 'package:flutter/material.dart';
import '../../domain/models/attendance_status.dart';
import '../../../../app/theme/app_theme.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final Map<AttendanceStatus, int> summary;
  final int remainingCount;
  final int totalStudents;
  final bool isVertical;

  const AttendanceSummaryCard({
    super.key,
    required this.summary,
    required this.remainingCount,
    required this.totalStudents,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final present = summary[AttendanceStatus.present] ?? 0;
    final absent = summary[AttendanceStatus.absent] ?? 0;
    final lateCount = summary[AttendanceStatus.late] ?? 0;
    
    final markedCount = present + absent + lateCount;
    final progress = totalStudents > 0 ? (markedCount / totalStudents) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SESSION OVERVIEW",
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.25) : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusFull,
                ),
                child: Text(
                  "$totalStudents Total",
                  style: AcadexTypography.caption(
                    color: isDark ? Colors.white : AcadexColors.primary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                remainingCount == 0 ? AcadexColors.success : AcadexColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (isVertical) ...[
            _buildVerticalStatRow("Present", present, AcadexColors.success, isDark),
            Divider(height: 16, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            _buildVerticalStatRow("Late", lateCount, AcadexColors.warning, isDark),
            Divider(height: 16, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            _buildVerticalStatRow("Absent", absent, AcadexColors.error, isDark),
            Divider(height: 16, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            _buildVerticalStatRow(
              "Unmarked",
              remainingCount,
              remainingCount > 0
                  ? (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)
                  : AcadexColors.success,
              isDark,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildMetricBlock("Present", present, AcadexColors.success, isDark)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricBlock("Late", lateCount, AcadexColors.warning, isDark)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricBlock("Absent", absent, AcadexColors.error, isDark)),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricBlock(
                    "Remaining",
                    remainingCount,
                    remainingCount > 0
                        ? (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)
                        : AcadexColors.success,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricBlock(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusMd,
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AcadexTypography.heading2(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalStatRow(String label, int count, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AcadexTypography.bodySmall(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          count.toString(),
          style: AcadexTypography.title(color: color),
        ),
      ],
    );
  }
}
