import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/monthly_attendance_summary.dart';

class MonthlySummaryCard extends StatelessWidget {
  final MonthlyAttendanceSummary summary;

  const MonthlySummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final perc = summary.percentage;
    final color = perc >= 75 ? AcadexColors.success : perc >= 60 ? AcadexColors.warning : AcadexColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
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
                "${summary.monthName} ${summary.year}",
                style: AcadexTypography.title(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              Text(
                "${perc.toStringAsFixed(1)}%",
                style: AcadexTypography.heading2(color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("Conducted", summary.classesConducted.toString(), AcadexColors.primary, isDark),
              _buildStat("Attended", summary.classesAttended.toString(), AcadexColors.success, isDark),
              _buildStat("Missed", summary.classesMissed.toString(), AcadexColors.error, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          val,
          style: AcadexTypography.heading2(color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
      ],
    );
  }
}
