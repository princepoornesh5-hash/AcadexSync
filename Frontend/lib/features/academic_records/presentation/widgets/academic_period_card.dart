import 'package:flutter/material.dart';
import '../../domain/models/academic_record_models.dart';
import 'academic_metric_pill.dart';

class AcademicPeriodCard extends StatelessWidget {
  final AcademicHistoryItemModel item;
  final VoidCallback onTap;

  const AcademicPeriodCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  Color _getStatusColor(AcademicProgressionStatus status) {
    switch (status) {
      case AcademicProgressionStatus.promoted:
      case AcademicProgressionStatus.completed:
        return const Color(0xFF10B981); // Emerald
      case AcademicProgressionStatus.active:
        return const Color(0xFF3B82F6); // Blue
      case AcademicProgressionStatus.retained:
        return const Color(0xFFF59E0B); // Amber
      case AcademicProgressionStatus.withdrawn:
      case AcademicProgressionStatus.discontinued:
        return const Color(0xFFEF4444); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(item.record.progressionStatus);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E222A) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Academic Year + Semester Badge + Progression Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.academicYearName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Semester ${item.semesterNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      item.record.progressionStatus.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Course & Stage Details
              Text(
                item.courseName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.departmentName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.sectionName != null && item.sectionName!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '•  Sec ${item.sectionName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 20),

              // Metrics Wrap (Attendance %, Practicals %, Assignments %, Subjects count)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AcademicMetricPill(
                    icon: Icons.menu_book_rounded,
                    label: 'Subjects',
                    value: '${item.subjectCount}',
                  ),
                  AcademicMetricPill(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Attendance',
                    value: '${item.attendance.percentage}%',
                    percentage: item.attendance.percentage,
                  ),
                  if (item.practical.totalSessions > 0)
                    AcademicMetricPill(
                      icon: Icons.biotech_rounded,
                      label: 'Labs',
                      value: '${item.practical.completionRate}%',
                      percentage: item.practical.completionRate,
                    ),
                  if (item.assignment.totalAssignments > 0)
                    AcademicMetricPill(
                      icon: Icons.task_alt_rounded,
                      label: 'Assignments',
                      value: '${item.assignment.completionRate}%',
                      percentage: item.assignment.completionRate,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
