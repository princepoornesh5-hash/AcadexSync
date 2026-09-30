import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/academic_record_models.dart';
import '../providers/academic_records_providers.dart';
import '../widgets/subject_academic_tile.dart';

class AcademicRecordDetailScreen extends ConsumerStatefulWidget {
  final String recordId;

  const AcademicRecordDetailScreen({
    super.key,
    required this.recordId,
  });

  @override
  ConsumerState<AcademicRecordDetailScreen> createState() =>
      _AcademicRecordDetailScreenState();
}

class _AcademicRecordDetailScreenState
    extends ConsumerState<AcademicRecordDetailScreen> {
  void _showProgressionDialog(
    BuildContext context,
    AcademicRecordDetailModel detail,
  ) {
    AcademicProgressionStatus selectedStatus =
        detail.record.progressionStatus;
    final remarksController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.upgrade_rounded, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Update Academic Progression',
                        style: Theme.of(modalContext).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Target Progression Status',
                    style: Theme.of(modalContext).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AcademicProgressionStatus>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: AcademicProgressionStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedStatus = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText: 'Remarks / Academic Council Note (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(modalContext).pop();
                        final success = await ref
                            .read(academicRecordActionControllerProvider.notifier)
                            .updateProgression(
                              widget.recordId,
                              status: selectedStatus,
                              remarks: remarksController.text.trim().isNotEmpty
                                  ? remarksController.text.trim()
                                  : null,
                            );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Progression status updated successfully'
                                    : 'Failed to update progression status',
                              ),
                              backgroundColor:
                                  success ? Colors.green : Colors.redAccent,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Progression Status'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(AcademicProgressionStatus status) {
    switch (status) {
      case AcademicProgressionStatus.promoted:
      case AcademicProgressionStatus.completed:
        return const Color(0xFF10B981);
      case AcademicProgressionStatus.active:
        return const Color(0xFF3B82F6);
      case AcademicProgressionStatus.retained:
        return const Color(0xFFF59E0B);
      case AcademicProgressionStatus.withdrawn:
      case AcademicProgressionStatus.discontinued:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailAsync = ref.watch(academicRecordDetailProvider(widget.recordId));
    final currentUser = ref.watch(currentUserProvider);

    final canManageProgression = currentUser?.role == AppRole.collegeAdmin ||
        currentUser?.role == AppRole.superAdmin ||
        currentUser?.role == AppRole.hod;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Record Detail'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(academicRecordDetailProvider(widget.recordId));
            },
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          final statusColor = _getStatusColor(detail.record.progressionStatus);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Academic Context Header Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E222A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              detail.academicYearName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              detail.record.progressionStatus.displayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Semester ${detail.semesterNumber} • ${detail.courseName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${detail.departmentName} ${detail.sectionName != null ? "• Section ${detail.sectionName}" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (detail.record.academicStage.isNotEmpty)
                            Text(
                              'Stage: ${detail.record.academicStage}',
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                            ),
                          if (detail.record.cohort.isNotEmpty)
                            Text(
                              '• Cohort: ${detail.record.cohort}',
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Aggregation Summaries Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Overall Performance Aggregates',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AggregateMetricBox(
                          title: 'Attendance',
                          icon: Icons.how_to_reg_rounded,
                          percentage: detail.overallAttendance.percentage,
                          subtitle:
                              '${detail.overallAttendance.presentCount}/${detail.overallAttendance.totalClasses}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AggregateMetricBox(
                          title: 'Labs / Practicals',
                          icon: Icons.biotech_rounded,
                          percentage: detail.overallPractical.completionRate,
                          subtitle:
                              '${detail.overallPractical.completedCount}/${detail.overallPractical.totalSessions}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AggregateMetricBox(
                          title: 'Assignments',
                          icon: Icons.task_alt_rounded,
                          percentage: detail.overallAssignment.completionRate,
                          subtitle:
                              '${detail.overallAssignment.submittedCount}/${detail.overallAssignment.totalAssignments}',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Subjects Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Enrolled Subjects (${detail.subjects.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Credits: ${detail.subjects.fold<int>(0, (sum, s) => sum + s.credits)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 4. Subject List
                if (detail.subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No subject records found for this academic period.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                else
                  ...detail.subjects.map(
                    (subj) => SubjectAcademicTile(subject: subj),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load academic record',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(academicRecordDetailProvider(widget.recordId));
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canManageProgression
          ? FloatingActionButton.extended(
              onPressed: () {
                final detail = detailAsync.asData?.value;
                if (detail != null) {
                  _showProgressionDialog(context, detail);
                }
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Progression Status'),
            )
          : null,
    );
  }
}

class _AggregateMetricBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final int percentage;
  final String subtitle;

  const _AggregateMetricBox({
    required this.title,
    required this.icon,
    required this.percentage,
    required this.subtitle,
  });

  Color _resolveColor() {
    if (percentage >= 75) return const Color(0xFF10B981);
    if (percentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _resolveColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$percentage%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
