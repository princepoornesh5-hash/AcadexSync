import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignments_providers.dart';

class StudentAssignmentsScreen extends ConsumerWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
        ),
        title: Text(
          'Assignments',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: assignmentsAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading assignments...'),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: "Couldn't load assignments.",
            retryLabel: 'Retry',
            onRetry: () => ref.refresh(studentAssignmentsProvider),
          ),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(studentAssignmentsProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: AcadexEmptyState(
                      icon: LucideIcons.bookCheck,
                      title: 'No assignments yet.',
                      subtitle: 'No published assignments are waiting for you.',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(studentAssignmentsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final asgn = assignments[index];
                return _buildStudentAssignmentCard(context, asgn, isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentAssignmentCard(
    BuildContext context,
    AssignmentModel asgn,
    bool isDark,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          asgn.subjectName ?? 'Subject',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              const SizedBox(height: 10),
              Row(
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
                  const SizedBox(width: 14),
                  Icon(LucideIcons.award, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Max: ${asgn.maximumMarks}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  if (asgn.marks != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Marks: ${asgn.marks} / ${asgn.maximumMarks}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'View >',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AcadexColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
