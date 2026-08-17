import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/super_admin_attendance_summary.dart';

class SuperAdminSummaryCard extends StatelessWidget {
  final SuperAdminAttendanceSummary summary;

  const SuperAdminSummaryCard({super.key, required this.summary});

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
          const Text("Platform Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                "System Attendance",
                "${summary.todayAttendancePercentage}%",
                summary.todayAttendancePercentage >= 80 ? DashboardColors.success : DashboardColors.warning,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "Total Students",
                summary.totalStudents.toString(),
                DashboardColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricCard(
                "Colleges Online",
                summary.totalColleges.toString(),
                DashboardColors.textSecondary,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                "Pending Colleges",
                summary.pendingColleges.toString(),
                summary.pendingColleges > 0 ? DashboardColors.error : DashboardColors.success,
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
