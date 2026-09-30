import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/academic_records_providers.dart';
import '../widgets/academic_period_card.dart';

class StudentAcademicHistoryScreen extends ConsumerWidget {
  final String? studentId;

  const StudentAcademicHistoryScreen({
    super.key,
    this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(studentAcademicRecordsHistoryProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(studentAcademicRecordsHistoryProvider(studentId));
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (historyItems) {
          if (historyItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_edu_rounded,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Academic Records Yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your academic history will be populated as your semesters and enrollments become active.',
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
              ref.invalidate(studentAcademicRecordsHistoryProvider(studentId));
              await ref.read(studentAcademicRecordsHistoryProvider(studentId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return AcademicPeriodCard(
                  item: item,
                  onTap: () {
                    context.push('/academic-records/${item.record.id}');
                  },
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
                  'Failed to load academic history',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    ref.invalidate(studentAcademicRecordsHistoryProvider(studentId));
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
