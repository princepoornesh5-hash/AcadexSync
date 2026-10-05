import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../domain/models/academic_result_models.dart';
import '../providers/academic_result_providers.dart';

/// Admin & HOD Academic Results Dashboard Screen.
/// Provides review, finalization, publication, and controlled reopening workflows.
class AdminResultsDashboardScreen extends ConsumerWidget {
  const AdminResultsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultsAsync = ref.watch(adminResultsQueryProvider);
    final filter = ref.watch(academicResultFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
        ),
        title: Text(
          'Academic Finalization',
          style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Calculate Batch',
            icon: const Icon(LucideIcons.calculator, size: 20),
            onPressed: () => _showBatchCalculateDialog(context, ref),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(adminResultsQueryProvider),
          ),
        ],
      ),
      body: AcadexPageContainer(
        maxWidth: 1040,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Calculate, review, finalize and publish semester results under institutional governance.',
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ),

            // Status Filter Chips
            _StatusFilterChips(
              selectedStatus: filter.status,
              onStatusSelected: (status) {
                ref.read(academicResultFilterProvider.notifier).setStatus(status);
              },
            ),
            const SizedBox(height: 16),

            // Results List / States
            resultsAsync.when(
              loading: () => const AcadexLoadingState(message: 'Loading academic results...'),
              error: (err, _) => Center(
                child: AcadexErrorState(
                  message: "Failed to load academic results.",
                  retryLabel: 'Retry',
                  onRetry: () => ref.refresh(adminResultsQueryProvider),
                ),
              ),
              data: (data) {
                final results = data.results;

                if (results.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 24),
                    child: Center(
                      child: AcadexEmptyState(
                        title: 'No Academic Results Found',
                        subtitle: 'No student results match the current filter. Use the Calculate action to evaluate semester cohorts.',
                        icon: LucideIcons.graduationCap,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return _AdminResultItemCard(result: item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchCalculateDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final semesterController = TextEditingController();
    final yearController = TextEditingController();
    final courseController = TextEditingController();
    final sectionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calculate Class Results'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: courseController,
                  decoration: const InputDecoration(labelText: 'Course ID *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Academic Year ID *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: semesterController,
                  decoration: const InputDecoration(labelText: 'Semester ID *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: sectionController,
                  decoration: const InputDecoration(labelText: 'Section ID (Optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop();
                final success = await ref.read(academicResultActionProvider.notifier).calculateClass(
                  courseId: courseController.text.trim(),
                  academicYearId: yearController.text.trim(),
                  semesterId: semesterController.text.trim(),
                  sectionId: sectionController.text.trim().isEmpty ? null : sectionController.text.trim(),
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Class calculation completed successfully.'
                            : 'Calculation failed. Please verify rule configuration.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  final ResultLifecycleStatus? selectedStatus;
  final ValueChanged<ResultLifecycleStatus?> onStatusSelected;

  const _StatusFilterChips({
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      null,
      ResultLifecycleStatus.calculated,
      ResultLifecycleStatus.underReview,
      ResultLifecycleStatus.finalized,
      ResultLifecycleStatus.published,
      ResultLifecycleStatus.reopened,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final isSelected = selectedStatus == status;
          final label = status == null ? 'All Statuses' : status.label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onStatusSelected(isSelected ? null : status),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AdminResultItemCard extends ConsumerWidget {
  final AcademicResultModel result;

  const _AdminResultItemCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = result.summary;

    final studentName = result.studentInfo?['name']?.toString() ?? 'Student';
    final rollNumber = result.studentInfo?['rollNumber']?.toString();

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Student Info & Lifecycle Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    if (rollNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Roll: $rollNumber',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _LifecycleStatusBadge(status: result.status),
            ],
          ),
          const SizedBox(height: 12),

          // Scores & Metrics Strip
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Total: ${summary.totalMarks.toStringAsFixed(0)} / ${summary.maxMarks.toStringAsFixed(0)} (${summary.percentage.toStringAsFixed(1)}%)',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              Text(
                'Credits: ${summary.earnedCredits.toStringAsFixed(0)} / ${summary.totalCredits.toStringAsFixed(0)}',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                ),
              ),
              if (summary.gpa != null)
                AcadexBadge(
                  label: 'GPA: ${summary.gpa!.toStringAsFixed(2)}',
                  variant: AcadexBadgeVariant.info,
                ),
              AcadexBadge(
                label: summary.overallStatus.label,
                variant: summary.overallStatus == OverallResultStatus.pass
                    ? AcadexBadgeVariant.success
                    : AcadexBadgeVariant.danger,
              ),
              if (result.calculationVersion > 1)
                AcadexBadge(
                  label: 'v${result.calculationVersion}',
                  variant: AcadexBadgeVariant.neutral,
                ),
            ],
          ),

          // Validation Warnings Badge
          if (result.validationWarnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            AcadexBadge(
              label: '${result.validationWarnings.length} validation warning(s)',
              variant: AcadexBadgeVariant.warning,
              icon: LucideIcons.alertTriangle,
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons Bar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Details Button
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.eye, size: 16),
                label: const Text('View Breakdown'),
                onPressed: () => _showDetailModal(context, result),
              ),

              // Review Button (Calculated -> Under Review)
              if (result.status == ResultLifecycleStatus.calculated)
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.fileSearch, size: 16),
                  label: const Text('Review'),
                  onPressed: () async {
                    final ok = await ref.read(academicResultActionProvider.notifier).reviewResult(result.id);
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Result moved to Under Review')),
                      );
                    }
                  },
                ),

              // Finalize Button (Calculated / Under Review -> Finalized)
              if (result.status == ResultLifecycleStatus.calculated ||
                  result.status == ResultLifecycleStatus.underReview)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(LucideIcons.lock, size: 16),
                  label: const Text('Finalize'),
                  onPressed: () async {
                    final ok = await ref.read(academicResultActionProvider.notifier).finalizeResult(result.id);
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Result finalized successfully')),
                      );
                    }
                  },
                ),

              // Publish Button (Finalized -> Published)
              if (result.status == ResultLifecycleStatus.finalized)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('Publish Officially'),
                  onPressed: () async {
                    final ok = await ref.read(academicResultActionProvider.notifier).publishResult(result.id);
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Result officially published to student')),
                      );
                    }
                  },
                ),

              // Reopen Button (Finalized or Published -> Reopened)
              if (result.status == ResultLifecycleStatus.finalized ||
                  result.status == ResultLifecycleStatus.published)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                  ),
                  icon: const Icon(LucideIcons.unlock, size: 16),
                  label: const Text('Reopen / Correction'),
                  onPressed: () => _showReopenDialog(context, ref, result.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailModal(BuildContext context, AcademicResultModel result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subject Performance Breakdown',
                    style: AcadexTypography.heading3(),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...result.subjectResults.map((sub) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Card(
                      elevation: 0,
                      color: AcadexColors.canvasSoft,
                      child: ListTile(
                        title: Text('${sub.subjectCode} — ${sub.subjectName}'),
                        subtitle: Text(
                          'Credits: ${sub.credits} | Marks: ${sub.totalMarks} (${sub.percentage}%)' +
                              (sub.grade != null ? ' | Grade: ${sub.grade}' : ''),
                        ),
                        trailing: AcadexBadge(
                          label: sub.status.label,
                          variant: sub.status == SubjectResultStatus.pass
                              ? AcadexBadgeVariant.success
                              : AcadexBadgeVariant.danger,
                        ),
                      ),
                    ),
                  )),
              if (result.validationWarnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Validation Warnings', style: AcadexTypography.heading3()),
                const SizedBox(height: 8),
                ...result.validationWarnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(w)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReopenDialog(BuildContext context, WidgetRef ref, String resultId) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reopen Result for Correction'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reopening allows recalculation under administrative audit. Students will continue seeing the previously published official snapshot until a newly finalized result is published.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Justification / Reason *',
                  hintText: 'e.g. Grade re-evaluation approved by academic board',
                ),
                maxLines: 2,
                validator: (v) {
                  if (v == null || v.trim().length < 5) {
                    return 'Reason must be at least 5 characters.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop();
                final ok = await ref.read(academicResultActionProvider.notifier).reopenResult(
                      resultId,
                      reason: reasonController.text.trim(),
                    );
                if (context.mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Result unlocked and reopened for correction.')),
                  );
                }
              }
            },
            child: const Text('Confirm Reopen'),
          ),
        ],
      ),
    );
  }
}

class _LifecycleStatusBadge extends StatelessWidget {
  final ResultLifecycleStatus status;

  const _LifecycleStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    AcadexBadgeVariant variant;
    IconData icon;

    switch (status) {
      case ResultLifecycleStatus.published:
        variant = AcadexBadgeVariant.success;
        icon = LucideIcons.checkCircle;
        break;
      case ResultLifecycleStatus.finalized:
        variant = AcadexBadgeVariant.primary;
        icon = LucideIcons.lock;
        break;
      case ResultLifecycleStatus.underReview:
        variant = AcadexBadgeVariant.warning;
        icon = LucideIcons.fileSearch;
        break;
      case ResultLifecycleStatus.reopened:
        variant = AcadexBadgeVariant.purple;
        icon = LucideIcons.history;
        break;
      case ResultLifecycleStatus.calculated:
        variant = AcadexBadgeVariant.teal;
        icon = LucideIcons.calculator;
        break;
      case ResultLifecycleStatus.draft:
      case ResultLifecycleStatus.archived:
        variant = AcadexBadgeVariant.neutral;
        icon = LucideIcons.fileText;
        break;
    }

    return AcadexBadge(
      label: status.label,
      variant: variant,
      icon: icon,
    );
  }
}
