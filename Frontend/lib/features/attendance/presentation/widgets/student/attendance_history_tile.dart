import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/attendance_history_record.dart';
import 'attendance_badge.dart';

class AttendanceHistoryTile extends StatelessWidget {
  final AttendanceHistoryRecord record;

  const AttendanceHistoryTile({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Row(
        children: [
          // Date Block
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
              borderRadius: AcadexRadius.borderRadiusMd,
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(record.date).toUpperCase(),
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd').format(record.date),
                  style: AcadexTypography.title(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          
          // Info Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subjectName,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  "${record.facultyName} • ${record.timeSlot}",
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          
          // Badge
          AttendanceBadge(status: record.status),
        ],
      ),
    );
  }
}
