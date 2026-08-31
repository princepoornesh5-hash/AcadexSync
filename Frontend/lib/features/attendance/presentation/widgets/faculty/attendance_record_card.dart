import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/attendance_session.dart';
import '../../../domain/models/attendance_status.dart';
import 'attendance_lock_chip.dart';

class AttendanceRecordCard extends StatelessWidget {
  final AttendanceSession session;
  final VoidCallback onTap;

  const AttendanceRecordCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final present = session.records.where((r) => r.status == AttendanceStatus.present).length;
    final absent = session.records.where((r) => r.status == AttendanceStatus.absent).length;
    final lateCount = session.records.where((r) => r.status == AttendanceStatus.late).length;

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
      child: Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AcadexRadius.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.subjectName,
                            style: AcadexTypography.title(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "${session.sectionName} • ${session.timeSlot}",
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(session.date),
                          style: AcadexTypography.caption(
                            color: AcadexColors.primary,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        AttendanceLockChip(isLocked: session.isLocked, status: session.status),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat("Present", present.toString(), AcadexColors.success, isDark),
                      _buildStat("Late", lateCount.toString(), AcadexColors.warning, isDark),
                      _buildStat("Absent", absent.toString(), AcadexColors.error, isDark),
                      _buildStat("Total", session.records.length.toString(), isDark ? AcadexColors.darkInk : AcadexColors.ink, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String val, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          val,
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
