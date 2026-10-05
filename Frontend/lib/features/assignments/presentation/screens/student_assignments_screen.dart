import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_motion.dart';
import '../../../../core/presentation/widgets/acadex_sliver_page_container.dart';
import '../../../../core/presentation/widgets/acadex_sliver_page_header.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignments_providers.dart';

class StudentAssignmentsScreen extends ConsumerWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return AcadexSliverPageContainer(
      onRefresh: () async => ref.refresh(studentAssignmentsProvider),
      header: const AcadexSliverPageHeader(
        title: 'Assignments',
        subtitle: 'View active coursework, track deadlines, and submit your work.',
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
                  onRetry: () => ref.refresh(studentAssignmentsProvider),
                ),
              ),
            ),
            data: (assignments) {
              if (assignments.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: AcadexEmptyState(
                      icon: LucideIcons.bookCheck,
                      title: 'No assignments yet.',
                      subtitle: 'No published assignments are waiting for you.',
                      isCompact: true,
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asgn = assignments[index];
                    return _buildStudentAssignmentCard(context, asgn, isDark, index);
                  },
                  childCount: assignments.length,
                ),
              );
            },
          ),
        ],
    );
  }

  Widget _buildStudentAssignmentCard(
    BuildContext context,
    AssignmentModel asgn,
    bool isDark,
    int index,
  ) {
    final status = asgn.studentStatus ?? StudentTaskStatus.pending;
    final isCompleted = status == StudentTaskStatus.completed;
    final isOverdue = status == StudentTaskStatus.overdue;

    Color badgeColor;
    Color badgeBg;
    if (isCompleted) {
      badgeColor = const Color(0xFF15803D);
      badgeBg = const Color(0xFFDCFCE7);
    } else if (isOverdue) {
      badgeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
    } else {
      badgeColor = AcadexColors.primary;
      badgeBg = AcadexColors.primaryTint;
    }

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
        onTap: () => context.push('/assignments/${asgn.id}'),
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
                          AcadexEntityFormatters.formatSubjectLabel(asgn.subjectName),
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
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
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
                  if (asgn.marks != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.primaryTint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Score: ${asgn.marks}/${asgn.maximumMarks}',
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
