import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/attendance_history_record.dart';
import 'attendance_badge.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryTile extends StatelessWidget {
  final AttendanceHistoryRecord record;

  const AttendanceHistoryTile({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date Block
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: DashboardColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(DateFormat('MMM').format(record.date).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DashboardColors.textSecondary)),
                Text(DateFormat('dd').format(record.date), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("${record.facultyName} • ${record.timeSlot}", style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge
          AttendanceBadge(status: record.status),
        ],
      ),
    );
  }
}
