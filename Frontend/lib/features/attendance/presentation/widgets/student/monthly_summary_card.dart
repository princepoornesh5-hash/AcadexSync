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
    final perc = summary.percentage;
    final color = perc >= 75 ? DashboardColors.success : perc >= 60 ? DashboardColors.warning : DashboardColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DashboardColors.surface, DashboardColors.surface.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${summary.monthName} ${summary.year}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
              ),
              Text(
                "${perc.toStringAsFixed(1)}%",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("Conducted", summary.classesConducted.toString(), DashboardColors.primary),
              _buildStat("Attended", summary.classesAttended.toString(), DashboardColors.success),
              _buildStat("Missed", summary.classesMissed.toString(), DashboardColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary)),
      ],
    );
  }
}
