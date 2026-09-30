import 'package:flutter/material.dart';
import '../../domain/models/academic_record_models.dart';
import 'academic_metric_pill.dart';

class SubjectAcademicTile extends StatelessWidget {
  final SubjectRecordSummary subject;

  const SubjectAcademicTile({
    super.key,
    required this.subject,
  });

  Color _getStatusColor(SubjectAcademicStatus status) {
    switch (status) {
      case SubjectAcademicStatus.completed:
        return const Color(0xFF10B981);
      case SubjectAcademicStatus.inProgress:
        return const Color(0xFF3B82F6);
      case SubjectAcademicStatus.exempted:
        return const Color(0xFF8B5CF6);
      case SubjectAcademicStatus.withdrawn:
        return const Color(0xFFEF4444);
      case SubjectAcademicStatus.enrolled:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(subject.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code + Name + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          subject.code,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${subject.credits} Credits • ${subject.type}',
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  subject.status.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          if (subject.facultyName != null && subject.facultyName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Faculty: ${subject.facultyName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // Subject Metrics Wrap (Attendance, Practical, Assignment, Assessment)
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (subject.attendance != null && subject.attendance!.totalClasses > 0)
                AcademicMetricPill(
                  icon: Icons.how_to_reg_rounded,
                  label: 'Att',
                  value: '${subject.attendance!.presentCount}/${subject.attendance!.totalClasses} (${subject.attendance!.percentage}%)',
                  percentage: subject.attendance!.percentage,
                ),
              if (subject.practical != null && subject.practical!.totalSessions > 0)
                AcademicMetricPill(
                  icon: Icons.science_outlined,
                  label: 'Lab',
                  value: '${subject.practical!.completedCount}/${subject.practical!.totalSessions} (${subject.practical!.completionRate}%)',
                  percentage: subject.practical!.completionRate,
                ),
              if (subject.assignment != null && subject.assignment!.totalAssignments > 0)
                AcademicMetricPill(
                  icon: Icons.assignment_outlined,
                  label: 'Tasks',
                  value: '${subject.assignment!.submittedCount}/${subject.assignment!.totalAssignments} (${subject.assignment!.completionRate}%)',
                  percentage: subject.assignment!.completionRate,
                ),
              if (subject.assessment != null && subject.assessment!.isPublished)
                AcademicMetricPill(
                  icon: Icons.analytics_outlined,
                  label: subject.assessment!.title,
                  value: subject.assessment!.totalMarks != null
                      ? '${subject.assessment!.totalMarks} Marks'
                      : 'Published',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
