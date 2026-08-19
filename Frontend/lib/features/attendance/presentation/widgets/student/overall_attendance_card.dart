import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/acadex_badge.dart';

class OverallAttendanceCard extends StatelessWidget {
  final double percentage;
  final int classesAttended;
  final int classesMissed;
  final int subjectsCount;

  const OverallAttendanceCard({
    super.key,
    required this.percentage,
    required this.classesAttended,
    required this.classesMissed,
    required this.subjectsCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGood = percentage >= 75;
    final isWarning = percentage >= 60 && percentage < 75;
    
    final statusLabel = isGood ? "Good Standing" : isWarning ? "Attendance Warning" : "Critical Shortage";
    final badgeVariant = isGood ? AcadexBadgeVariant.success : isWarning ? AcadexBadgeVariant.warning : AcadexBadgeVariant.danger;
    final progressColor = isGood ? AcadexColors.success : isWarning ? AcadexColors.warning : AcadexColors.error;

    final totalClasses = classesAttended + classesMissed;

    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "OVERALL ATTENDANCE",
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              AcadexBadge(
                label: statusLabel,
                variant: badgeVariant,
                icon: isGood ? LucideIcons.checkCircle2 : (isWarning ? LucideIcons.alertTriangle : LucideIcons.alertOctagon),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: AcadexTypography.display1(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Min. Requirement: 75%",
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percentage / 100.0).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem("Active Subjects", subjectsCount.toString(), isDark),
              _buildMetricItem("Classes Attended", classesAttended.toString(), isDark, valueColor: AcadexColors.success),
              _buildMetricItem("Classes Missed", classesMissed.toString(), isDark, valueColor: AcadexColors.error),
              _buildMetricItem("Total Held", totalClasses.toString(), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AcadexTypography.heading2(
            color: valueColor ?? (isDark ? AcadexColors.darkInk : AcadexColors.ink),
          ),
        ),
      ],
    );
  }
}
