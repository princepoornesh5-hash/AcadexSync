import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/subject_attendance.dart';
import 'attendance_progress_indicator.dart';

class SubjectAttendanceCard extends StatelessWidget {
  final SubjectAttendance subject;
  final VoidCallback onTap;

  const SubjectAttendanceCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final perc = subject.percentage;
    final color = perc >= 75 ? DashboardColors.success : perc >= 60 ? DashboardColors.warning : DashboardColors.error;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject.subjectName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text("${subject.subjectCode} • ${subject.facultyName}", style: const TextStyle(fontSize: 13, color: DashboardColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    "${perc.toStringAsFixed(0)}%",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  )
                ],
              ),
              const SizedBox(height: 16),
              AttendanceProgressIndicator(percentage: perc),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat("Attended", subject.attendedClasses.toString(), DashboardColors.success),
                  _buildMiniStat("Missed", subject.missedClasses.toString(), DashboardColors.error),
                  _buildMiniStat("Total", subject.totalClasses.toString(), DashboardColors.textPrimary),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String val, Color color) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary)),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
