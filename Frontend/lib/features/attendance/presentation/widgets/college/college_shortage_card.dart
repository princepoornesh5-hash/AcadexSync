import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/college_student_shortage.dart';
import '../../../domain/models/student_shortage.dart' show ShortageStatus;

class CollegeShortageCard extends StatelessWidget {
  final CollegeStudentShortage shortage;

  const CollegeShortageCard({super.key, required this.shortage});

  @override
  Widget build(BuildContext context) {
    final color = shortage.status == ShortageStatus.critical ? DashboardColors.error : DashboardColors.warning;
    
    return Card(
      color: DashboardColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${shortage.currentPercentage.toInt()}%",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortage.studentName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${shortage.rollNumber} • ${shortage.departmentName}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shortage.semester,
                    style: const TextStyle(fontSize: 11, color: DashboardColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: DashboardColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
