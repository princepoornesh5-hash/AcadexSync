import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/home_dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/home_dashboard_widgets.dart';

class HodDashboard extends ConsumerWidget {
  const HodDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(homeDashboardProvider);
        ref.invalidate(facultyAssignmentsProvider);
      },
      child: dashboardAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState(message: 'Loading department dashboard...'),
        ),
        error: (err, _) => AcadexErrorState.fromError(
          error: err,
          title: 'Unable to load dashboard',
          onRetry: () => ref.invalidate(homeDashboardProvider),
        ),
        data: (dashboard) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HOD Identity & Context
              DashboardGreetingHeader(greeting: dashboard.greeting),
              DashboardContextCard(
                role: dashboard.role,
                contextModel: dashboard.context,
              ),

              // 2. Department Health & Current State
              _buildDepartmentMetricsSummary(context, dashboard.summary),

              // 3. Immediate Setup / Action (Compact, only rendered if pending)
              DashboardAlertsSection(alerts: dashboard.alerts),
              DashboardPendingActionsSection(
                pendingActions: dashboard.pendingActions,
              ),

              // 4. Faculty Teaching Allocations (Content-driven card sizing)
              _buildFacultyTeachingAllocations(
                context,
                ref,
                dashboard.context.departmentId,
                isDark,
              ),

              // 5. Department Overview & Quick Operations
              DashboardQuickActionsGrid(
                quickActions: dashboard.quickActions,
              ),

              // 6. Today's Timetable & Activity
              DashboardUpcomingSection(upcoming: dashboard.upcoming),
              DashboardRecentActivitySection(recent: dashboard.recent),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFacultyTeachingAllocations(
    BuildContext context,
    WidgetRef ref,
    String? departmentId,
    bool isDark,
  ) {
    final assignmentsAsync = ref.watch(facultyAssignmentsProvider);
    final subMap = ref.watch(subjectMapProvider);
    final secMap = ref.watch(sectionMapProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Faculty Teaching Allocations',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.push('/faculty-assignments'),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Manage All',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AcadexColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        assignmentsAsync.when(
          loading: () => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.loader, size: 16, color: isDark ? AcadexColors.darkInkMuted : Colors.grey.shade400),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Loading teaching allocations...',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          error: (err, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle, size: 16, color: AcadexColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to load allocations.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ),
                AcadexButton(
                  label: 'Retry',
                  size: AcadexButtonSize.sm,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => ref.invalidate(facultyAssignmentsProvider),
                ),
              ],
            ),
          ),
          data: (allAssignments) {
            final deptAssignments = (departmentId != null && departmentId.isNotEmpty)
                ? allAssignments.where((a) => a.departmentId == departmentId && a.isActive).take(4).toList()
                : allAssignments.where((a) => a.isActive).take(4).toList();

            if (deptAssignments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.users, size: 16, color: isDark ? AcadexColors.darkInkMuted : Colors.grey.shade400),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No teaching allocations recorded for this department.',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ),
                    AcadexButton(
                      label: 'Assign',
                      icon: LucideIcons.plus,
                      size: AcadexButtonSize.sm,
                      variant: AcadexButtonVariant.secondary,
                      onPressed: () => context.push('/faculty-assignments'),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                if (isWide) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: deptAssignments.map((a) {
                      final itemWidth = (constraints.maxWidth - 8) / 2;
                      return SizedBox(
                        width: itemWidth,
                        child: _buildAllocationCard(context, a, subMap[a.subjectId], secMap[a.sectionId], isDark),
                      );
                    }).toList(),
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < deptAssignments.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _buildAllocationCard(
                        context,
                        deptAssignments[i],
                        subMap[deptAssignments[i].subjectId],
                        secMap[deptAssignments[i].sectionId],
                        isDark,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAllocationCard(
    BuildContext context,
    FacultyAssignment a,
    Subject? sub,
    Section? sec,
    bool isDark,
  ) {
    final sectionLabel = AcadexEntityFormatters.formatSectionLabel(
      sec?.name,
      rawId: a.sectionId,
      fallback: 'Sec A',
      compact: true,
    );
    final subjectName = sub?.name ?? (AcadexEntityFormatters.isRawIdentifier(a.subjectId) ? 'Course Subject' : a.subjectId);
    final subjectCode = sub?.code ?? '';

    return AcadexCard(
      isFlat: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  a.facultyName,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Text(
                  sectionLabel,
                  style: const TextStyle(
                    color: AcadexColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subjectName,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 12.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subjectCode.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subjectCode,
              style: const TextStyle(
                color: AcadexColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentMetricsSummary(
    BuildContext context,
    DashboardSummaryModel summary,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          'Department Status',
          style: AcadexTypography.heading3(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 380;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isNarrow ? 2.0 : 2.2,
              children: [
                _buildMetricTile(
                  context,
                  title: 'Active Students',
                  value: '${summary.activeStudentsCount}',
                  subtitle: 'Enrolled in department',
                  icon: LucideIcons.graduationCap,
                  color: AcadexColors.primary,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Faculty Members',
                  value: '${summary.activeFacultyCount}',
                  subtitle: 'Teaching in department',
                  icon: LucideIcons.users,
                  color: AcadexColors.primary,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Pending Attendance',
                  value: '${summary.pendingAttendanceCount}',
                  subtitle: 'Faculty sessions',
                  icon: LucideIcons.checkSquare,
                  color: summary.pendingAttendanceCount > 0 ? AcadexColors.warning : AcadexColors.inkMuted,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Incomplete Marks',
                  value: '${summary.pendingAssessmentsCount}',
                  subtitle: 'Pending finalization',
                  icon: LucideIcons.penTool,
                  color: summary.pendingAssessmentsCount > 0 ? AcadexColors.error : AcadexColors.inkMuted,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return AcadexCard(
      isFlat: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(icon, size: 12, color: color),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AcadexTypography.heading2(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
          ),
          Text(
            subtitle,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
