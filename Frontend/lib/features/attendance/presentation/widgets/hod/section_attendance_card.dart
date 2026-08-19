import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/section_attendance_summary.dart';

class SectionAttendanceCard extends StatelessWidget {
  final SectionAttendanceSummary summary;

  const SectionAttendanceCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  summary.sectionName,
                  style: AcadexTypography.title(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                Text(
                  summary.semester,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat("Attendance", "${summary.attendancePercentage}%", AcadexColors.primary, isDark),
                  _buildStat("Present", summary.present.toString(), AcadexColors.success, isDark),
                  _buildStat("Late", summary.late.toString(), AcadexColors.warning, isDark),
                  _buildStat("Absent", summary.absent.toString(), AcadexColors.error, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: AcadexTypography.title(color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
