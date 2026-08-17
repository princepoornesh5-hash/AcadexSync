import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/section_attendance_summary.dart';

class SectionAttendanceCard extends StatelessWidget {
  final SectionAttendanceSummary summary;

  const SectionAttendanceCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DashboardColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DashboardColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  summary.sectionName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
                ),
                Text(
                  summary.semester,
                  style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat("Attendance", "${summary.attendancePercentage}%", DashboardColors.primary),
                _buildStat("Present", summary.present.toString(), DashboardColors.success),
                _buildStat("Absent", summary.absent.toString(), DashboardColors.error),
                _buildStat("Late", summary.late.toString(), DashboardColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: DashboardColors.textSecondary),
        ),
      ],
    );
  }
}
