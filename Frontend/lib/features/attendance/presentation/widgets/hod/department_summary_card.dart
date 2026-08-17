import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/department_attendance_summary.dart';

class DepartmentSummaryCard extends StatelessWidget {
  final DepartmentAttendanceSummary summary;

  const DepartmentSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Department Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                "Overall Attendance",
                "${summary.overallPercentage}%",
                summary.overallPercentage >= 75 ? DashboardColors.success : DashboardColors.error,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "Critical Students",
                summary.studentsBelow75.toString(),
                DashboardColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricCard(
                "Faculty Completed",
                "${summary.facultyCompleted} / ${summary.totalFaculty}",
                DashboardColors.primary,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "Today's Classes",
                summary.todayClasses.toString(),
                DashboardColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DashboardColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ),
    );
  }
}
