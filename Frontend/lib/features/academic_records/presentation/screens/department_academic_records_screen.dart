import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/academic_record_models.dart';
import '../providers/academic_records_providers.dart';

class DepartmentAcademicRecordsScreen extends ConsumerWidget {
  const DepartmentAcademicRecordsScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(departmentRecordsFilterProvider);
    final recordsAsync = ref.watch(departmentAcademicRecordsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Records Directory'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(departmentAcademicRecordsProvider(filter));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (All, Active, Completed, Promoted, Retained)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Statuses'),
                  selected: filter.progressionStatus == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(departmentRecordsFilterProvider.notifier).state =
                          filter.copyWith(progressionStatus: null, page: 1);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...AcademicProgressionStatus.values.map((status) {
                  final isSelected = filter.progressionStatus == status.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(departmentRecordsFilterProvider.notifier).state =
                            filter.copyWith(
                          progressionStatus: selected ? status.value : null,
                          page: 1,
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main list
          Expanded(
            child: recordsAsync.when(
              data: (paginated) {
                if (paginated.records.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Academic Records Found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No student academic records match the current filter selection.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(departmentAcademicRecordsProvider(filter));
                    await ref.read(departmentAcademicRecordsProvider(filter).future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: paginated.records.length,
                    itemBuilder: (context, index) {
                      final record = paginated.records[index];
                      final statusColor = _getStatusColor(record.progressionStatus);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        color: isDark ? const Color(0xFF1E222A) : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                            child: Icon(
                              Icons.person_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  record.studentName ?? 'Student',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  record.progressionStatus.displayName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${record.rollNumber != null ? "Roll: ${record.rollNumber} • " : ""}${record.academicStage}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                ),
                              ),
                              if (record.cohort.isNotEmpty)
                                Text(
                                  'Cohort: ${record.cohort}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            context.push('/academic-records/${record.id}');
                          },
                        ),
                      );
                    },
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
                        'Failed to load academic records',
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
                          ref.invalidate(departmentAcademicRecordsProvider(filter));
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
