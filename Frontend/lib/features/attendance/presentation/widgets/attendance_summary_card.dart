import 'package:flutter/material.dart';
import '../../domain/models/attendance_status.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final Map<AttendanceStatus, int> summary;
  final int remainingCount;
  final int totalStudents;

  const AttendanceSummaryCard({
    super.key,
    required this.summary,
    required this.remainingCount,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    final present = summary[AttendanceStatus.present] ?? 0;
    final absent = summary[AttendanceStatus.absent] ?? 0;
    final late = summary[AttendanceStatus.late] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Live Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800)),
              Text("Total: $totalStudents", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("Present", present, AttendanceStatus.present.color),
              _buildStat("Absent", absent, AttendanceStatus.absent.color),
              _buildStat("Late", late, AttendanceStatus.late.color),
              _buildStat("Remaining", remainingCount, Colors.grey.shade600),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
