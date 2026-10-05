import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../domain/models/academic_result_models.dart';
import '../providers/academic_result_providers.dart';

/// Official Student Academic Result Screen.
/// Strictly renders only finalized and published official snapshots.
class StudentOfficialResultScreen extends ConsumerWidget {
  final String? semesterId;

  const StudentOfficialResultScreen({
    super.key,
    this.semesterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultAsync = ref.watch(studentOfficialResultProvider(semesterId));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
        ),
        title: Text(
          'Official Academic Result',
          style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Result',
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(studentOfficialResultProvider(semesterId)),
          ),
        ],
      ),
      body: AcadexPageContainer(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Institutional academic record certified and published by the administration.',
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ),

            resultAsync.when(
              loading: () => const AcadexLoadingState(message: 'Loading your official academic result...'),
              error: (err, _) => Center(
                child: AcadexErrorState(
                  message: "Couldn't load your academic result at this time.",
                  retryLabel: 'Retry',
                  onRetry: () => ref.refresh(studentOfficialResultProvider(semesterId)),
                ),
              ),
              data: (result) {
                if (result == null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 24),
                    child: Center(
                      child: AcadexEmptyState(
                        title: 'Result Not Officially Published Yet',
                        subtitle: 'Your academic results have not been finalized or published by the administration. Interim scores can be viewed under Internal Marks.',
                        icon: LucideIcons.fileCheck,
                      ),
                    ),
                  );
                }

                return _OfficialResultView(result: result);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialResultView extends StatelessWidget {
  final StudentOfficialResultModel result;

  const _OfficialResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = result.summary;
    final formattedDate = DateFormat('MMMM d, yyyy').format(result.publishedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Publication Stamp & Version Banner
        AcadexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AcadexBadge(
                    label: 'Official Result — Version ${result.version}',
                    variant: AcadexBadgeVariant.success,
                    icon: LucideIcons.shieldCheck,
                  ),
                  AcadexBadge(
                    label: 'Published $formattedDate',
                    variant: AcadexBadgeVariant.neutral,
                    icon: LucideIcons.calendar,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${result.courseName} • ${result.semesterName}',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Academic Year: ${result.academicYearName}',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Overall Performance Metrics
        _ResultSummaryMetrics(summary: summary),
        const SizedBox(height: 24),

        // Subject Breakdown Section
        Text(
          'Subject-Wise Performance',
          style: AcadexTypography.heading3(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: result.subjectResults.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sub = result.subjectResults[index];
            return _SubjectResultCard(subject: sub);
          },
        ),

        const SizedBox(height: 32),

        // Institutional Certification Footer
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.lock,
                  size: 14,
                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Certified snapshot. Historical official versions are archived and tamper-proof.',
                    textAlign: TextAlign.center,
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ResultSummaryMetrics extends StatelessWidget {
  final ResultSummaryModel summary;

  const _ResultSummaryMetrics({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isPass = summary.overallStatus == OverallResultStatus.pass ||
        summary.overallStatus == OverallResultStatus.promoted;

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Overall Outcome',
                style: AcadexTypography.title(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              AcadexBadge(
                label: summary.overallStatus.label,
                variant: isPass ? AcadexBadgeVariant.success : AcadexBadgeVariant.danger,
                icon: isPass ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Responsive metrics grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MetricItem(
                label: 'Percentage',
                value: '${summary.percentage.toStringAsFixed(1)}%',
              ),
              _MetricItem(
                label: 'Credits Earned',
                value: '${summary.earnedCredits.toStringAsFixed(0)} / ${summary.totalCredits.toStringAsFixed(0)}',
              ),
              _MetricItem(
                label: 'Total Marks',
                value: '${summary.totalMarks.toStringAsFixed(0)} / ${summary.maxMarks.toStringAsFixed(0)}',
              ),
              if (summary.gpa != null)
                _MetricItem(
                  label: 'Semester GPA',
                  value: summary.gpa!.toStringAsFixed(2),
                  highlight: true,
                ),
              if (summary.cgpa != null)
                _MetricItem(
                  label: 'Cumulative CGPA',
                  value: summary.cgpa!.toStringAsFixed(2),
                  highlight: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MetricItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? (isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight)
            : (isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? AcadexColors.primary.withValues(alpha: 0.3) : AcadexColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AcadexTypography.heading3(
              color: highlight
                  ? (isDark ? AcadexColors.primaryLight : AcadexColors.primary)
                  : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectResultCard extends StatelessWidget {
  final SubjectResultModel subject;

  const _SubjectResultCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPass = subject.status == SubjectResultStatus.pass;

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject Code & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (subject.subjectCode.isNotEmpty)
                          AcadexBadge(
                            label: subject.subjectCode,
                            variant: AcadexBadgeVariant.neutral,
                          ),
                        AcadexBadge(
                          label: '${subject.credits.toStringAsFixed(0)} Credits',
                          variant: AcadexBadgeVariant.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subject.subjectName,
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              AcadexBadge(
                label: subject.status.label,
                variant: isPass ? AcadexBadgeVariant.success : AcadexBadgeVariant.danger,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scores & Grades Wrap
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Marks: ${subject.totalMarks.toStringAsFixed(0)} (${subject.percentage.toStringAsFixed(1)}%)',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              if (subject.grade != null && subject.grade!.isNotEmpty)
                AcadexBadge(
                  label: 'Grade: ${subject.grade}' +
                      (subject.gradePoint != null ? ' (${subject.gradePoint!.toStringAsFixed(1)} pts)' : ''),
                  variant: isPass ? AcadexBadgeVariant.primary : AcadexBadgeVariant.danger,
                ),
            ],
          ),

          // Attendance / Practical eligibility notes if evaluated
          if (subject.attendancePassed != null || subject.practicalCompleted != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (subject.attendancePassed != null)
                  AcadexBadge(
                    label: subject.attendancePassed!
                        ? 'Attendance: ${subject.attendancePercentage?.toStringAsFixed(0)}% (Met)'
                        : 'Attendance: ${subject.attendancePercentage?.toStringAsFixed(0)}% (Shortage)',
                    variant: subject.attendancePassed! ? AcadexBadgeVariant.success : AcadexBadgeVariant.warning,
                    icon: LucideIcons.calendarCheck,
                  ),
                if (subject.practicalCompleted != null)
                  AcadexBadge(
                    label: subject.practicalCompleted! ? 'Practical: Completed' : 'Practical: Pending',
                    variant: subject.practicalCompleted! ? AcadexBadgeVariant.success : AcadexBadgeVariant.warning,
                    icon: LucideIcons.flaskConical,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
