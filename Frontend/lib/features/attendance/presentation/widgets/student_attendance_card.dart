import 'package:flutter/material.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_status.dart';
import 'attendance_status_chip.dart';

class StudentAttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const StudentAttendanceCard({
    super.key,
    required this.record,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final status = record.status;
    
    // Future support for network images, falling back to initials
    final initials = record.studentName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade900,
                  radius: 20,
                  child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(record.rollNumber, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                if (status != null)
                  Icon(
                    status == AttendanceStatus.present ? Icons.check_circle :
                    status == AttendanceStatus.absent ? Icons.cancel : Icons.info,
                    color: status.color,
                  )
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AttendanceStatusChip(
                  status: AttendanceStatus.present,
                  isSelected: status == AttendanceStatus.present,
                  onTap: () => onStatusChanged(AttendanceStatus.present),
                ),
                AttendanceStatusChip(
                  status: AttendanceStatus.absent,
                  isSelected: status == AttendanceStatus.absent,
                  onTap: () => onStatusChanged(AttendanceStatus.absent),
                ),
                AttendanceStatusChip(
                  status: AttendanceStatus.late,
                  isSelected: status == AttendanceStatus.late,
                  onTap: () => onStatusChanged(AttendanceStatus.late),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
