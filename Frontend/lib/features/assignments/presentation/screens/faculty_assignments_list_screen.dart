import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_motion.dart';
import '../../../../core/presentation/widgets/acadex_sliver_page_container.dart';
import '../../../../core/presentation/widgets/acadex_sliver_page_header.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignments_providers.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';

class FacultyAssignmentsListScreen extends ConsumerWidget {
  const FacultyAssignmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentsAsync = ref.watch(facultyCourseAssignmentsProvider);
    final terminology = ref.watch(terminologyProvider);

    return AcadexSliverPageContainer(
      onRefresh: () async => ref.refresh(facultyCourseAssignmentsProvider),
      header: AcadexSliverPageHeader(
        title: 'Assignments',
        subtitle: 'Create coursework, track student submissions, and record marks.',
        actions: [
          AcadexButton(
            label: '+ Create Assignment',
            icon: LucideIcons.plus,
            size: AcadexButtonSize.sm,
            onPressed: () => context.push('/assignments/create'),
          ),
        ],
      ),
      slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          assignmentsAsync.when(
            loading: () => const SliverToBoxAdapter(child: AcadexLoadingState(message: 'Loading assignments...')),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(
                child: AcadexErrorState.fromError(
                  error: err,
                  title: "Couldn't load assignments.",
                  retryLabel: 'Retry',
                  onRetry: () => ref.refresh(facultyCourseAssignmentsProvider),
                ),
              ),
            ),
            data: (assignments) {
              if (assignments.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: AcadexEmptyState(
                      icon: LucideIcons.bookOpen,
                      title: 'No assignments yet.',
                      subtitle: 'Create coursework assignments to track student submissions and record marks.',
                      actionLabel: 'Create Assignment',
                      actionIcon: LucideIcons.plus,
                      onActionTap: () => context.push('/assignments/create'),
                      isCompact: true,
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asgn = assignments[index];
                    return _buildFacultyAssignmentCard(context, asgn, isDark, terminology, index);
                  },
                  childCount: assignments.length,
                ),
              );
            },
          ),
        ],
    );
  }

  Widget _buildFacultyAssignmentCard(
    BuildContext context,
    AssignmentModel asgn,
    bool isDark,
    TerminologyHelper terminology,
    int index,
  ) {
    Color statusColor;
    Color statusBg;
    switch (asgn.status) {
      case AssignmentStatus.published:
        statusColor = const Color(0xFF15803D);
        statusBg = const Color(0xFFDCFCE7);
        break;
      case AssignmentStatus.closed:
      case AssignmentStatus.archived:
        statusColor = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
        statusBg = isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft;
        break;
      case AssignmentStatus.draft:
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
    }

    final total = asgn.totalStudents ?? 0;
    final completed = asgn.completedCount ?? 0;

    return AcadexFadeSlide(
      delay: Duration(milliseconds: (index * 30).clamp(0, 400)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/assignments/${asgn.id}/activity'),
        borderRadius: AcadexRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asgn.title,
                          style: AcadexTypography.title(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          terminology.formatCompactContext(
                            subjectName: AcadexEntityFormatters.formatSubjectLabel(asgn.subjectName),
                            sectionName: AcadexEntityFormatters.formatSectionLabel(asgn.sectionName, compact: true),
                          ),
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      asgn.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${asgn.dueDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.award, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Max: ${asgn.maximumMarks}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.primaryTint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$completed / $total Done',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AcadexColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
