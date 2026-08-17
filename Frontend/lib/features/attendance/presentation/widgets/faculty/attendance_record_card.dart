import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/attendance_session.dart';
import '../../../domain/models/attendance_status.dart';
import 'attendance_lock_chip.dart';
import 'package:intl/intl.dart';

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
    int present = session.records.where((r) => r.status == AttendanceStatus.present).length;
    int absent = session.records.where((r) => r.status == AttendanceStatus.absent).length;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("${session.sectionName} • ${session.timeSlot}", style: const TextStyle(fontSize: 13, color: DashboardColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(session.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DashboardColors.primary)),
                      const SizedBox(height: 6),
                      AttendanceLockChip(isLocked: session.isLocked),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat("Present", present.toString(), DashboardColors.success),
                  _buildStat("Absent", absent.toString(), DashboardColors.error),
                  _buildStat("Total", session.records.length.toString(), DashboardColors.textPrimary),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String val, Color color) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary)),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
