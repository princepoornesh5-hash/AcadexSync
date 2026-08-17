import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/super_admin_faculty_completion.dart';

class SuperAdminFacultyCard extends StatelessWidget {
  final SuperAdminFacultyCompletion completion;

  const SuperAdminFacultyCard({super.key, required this.completion});

  @override
  Widget build(BuildContext context) {
    final isComplete = completion.pendingClasses == 0;
    
    return Card(
      color: DashboardColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isComplete ? DashboardColors.success.withValues(alpha: 0.3) : DashboardColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completion.facultyName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${completion.collegeName} • ${completion.departmentName}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DashboardColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete ? DashboardColors.success.withValues(alpha: 0.1) : DashboardColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isComplete ? "Completed" : "${completion.pendingClasses} Pending",
                    style: TextStyle(
                      color: isComplete ? DashboardColors.success : DashboardColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completion.progress,
                      backgroundColor: DashboardColors.background,
                      color: isComplete ? DashboardColors.success : DashboardColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${completion.completedClasses} / ${completion.completedClasses + completion.pendingClasses}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
