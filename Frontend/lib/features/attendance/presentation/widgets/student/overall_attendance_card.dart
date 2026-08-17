import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import 'attendance_progress_indicator.dart';

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
    final isGood = percentage >= 75;
    final isWarning = percentage >= 60 && percentage < 75;
    
    final statusText = isGood ? "Good Standing" : isWarning ? "Attendance Warning" : "Critical Attendance";
    final statusColor = isGood ? DashboardColors.success : isWarning ? DashboardColors.warning : DashboardColors.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Overall Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isGood ? Icons.check_circle : isWarning ? Icons.warning : Icons.error,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1.0, color: DashboardColors.textPrimary),
              ),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text("Requirement: 75%", style: TextStyle(color: DashboardColors.textSecondary, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AttendanceProgressIndicator(percentage: percentage, height: 12),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Subjects", subjectsCount.toString()),
              _buildStat("Classes Attended", classesAttended.toString(), color: DashboardColors.success),
              _buildStat("Classes Missed", classesMissed.toString(), color: DashboardColors.error),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: DashboardColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? DashboardColors.textPrimary)),
      ],
    );
  }
}
