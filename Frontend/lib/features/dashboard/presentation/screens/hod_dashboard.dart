import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/providers/navigation_provider.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../requests/presentation/widgets/dashboard_request_card.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../timetable/presentation/widgets/dashboard_timetable_live_card.dart';
import '../../domain/models/home_dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/acadex_hero_card.dart';
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
        ref.invalidate(hodStatsProvider);
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
          final deptCode = dashboard.context.departmentCode ?? 'CSE';
          final deptName = dashboard.context.departmentName ?? 'Department of Computer Science & Engineering';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HOD Identity & Context Greeting
              DashboardGreetingHeader(greeting: dashboard.greeting),

              // 2. Department Health & Operations Hero Card
              AcadexHeroCard(
                eyebrow: 'DEPARTMENT HEALTH & OPERATIONS',
                badge: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Text(
                        'DEPT: $deptCode',
                        style: const TextStyle(
                          color: AcadexColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        deptCode,
                        style: TextStyle(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Head of Department',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                title: deptName,
                subtitle: 'Academic session active. Review faculty workload, timetable coverage, and student attendance.',
                primaryActionLabel: 'Department Analytics',
                primaryActionIcon: LucideIcons.barChart3,
                onPrimaryAction: () => context.push('/analytics'),
                secondaryActionLabel: 'Faculty Workload',
                onSecondaryAction: () => context.push('/faculty-assignments'),
              ),

              // 3. Department Overview (Authorised Scope Metrics: 2 cols on mobile, 4 on desktop)
              _buildDepartmentOverview(context, ref, dashboard.summary, isDark),

              // 4. Department Operations (Tactile Quick Actions Grid)
              _buildQuickOperations(context, ref, dashboard.quickActions, isDark),

              // 5. Department Requests Status Card
              const SizedBox(height: 14),
              const DashboardRequestCard(role: AppRole.hod),

              // Critical Alerts / Pending Actions (compact, conditionally rendered)
              if (dashboard.alerts.isNotEmpty)
                DashboardAlertsSection(alerts: dashboard.alerts),
              if (dashboard.pendingActions.isNotEmpty)
                DashboardPendingActionsSection(pendingActions: dashboard.pendingActions),

              // 6. Today's Department Timetable
              _buildTodayTimetableSection(context, ref, dashboard.upcoming, isDark),

              // 7. Faculty Teaching Allocations (Content-driven, no fixed heights, no spaceBetween)
              _buildFacultyTeachingAllocations(
                context,
                ref,
                dashboard.context.departmentId,
                isDark,
              ),

              // 8. Recent Activity & Notifications
              DashboardRecentActivitySection(recent: dashboard.recent),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickOperations(
    BuildContext context,
    WidgetRef ref,
    List<DashboardQuickActionModel> quickActions,
    bool isDark,
  ) {
    final navState = ref.watch(navigationProvider);
    // If specific quick actions were provided in mock or backend, use them
    final hasCustomActions = quickActions.isNotEmpty;

    final actions = hasCustomActions
        ? quickActions.map((a) => (
            id: a.id.isNotEmpty ? a.id : a.label,
            label: a.label,
            icon: _resolveIcon(a.icon),
            route: a.route,
            isPrimary: a.isPrimary,
            badgeCount: a.badgeCount,
          )).toList()
        : [
            (
              id: 'hod_add_course',
              label: '+ Add Course',
              icon: LucideIcons.plus,
              route: '/academics',
              isPrimary: true,
              badgeCount: null,
            ),
            (
              id: 'hod_add_subject',
              label: '+ Add Subject',
              icon: LucideIcons.bookPlus,
              route: '/academics',
              isPrimary: false,
              badgeCount: null,
            ),
            (
              id: 'hod_add_student',
              label: '+ Add Student',
              icon: LucideIcons.userPlus,
              route: '/academics/students/new',
              isPrimary: false,
              badgeCount: null,
            ),
            (
              id: 'hod_assign_faculty',
              label: 'Assign Faculty',
              icon: LucideIcons.userCheck,
              route: '/faculty-assignments',
              isPrimary: false,
              badgeCount: null,
            ),
          ];

    final allRoutes = actions.map((a) => a.route).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Quick Operations',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.push('/academics/setup'),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Continue Setup',
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
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final count = actions.length;
            final crossAxisCount = w < 280 ? 2 : (count <= 4 ? count : 4);

            final itemWidth = (w - (crossAxisCount - 1) * 8) / crossAxisCount;
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final targetHeight = 74.0 * textScale.clamp(1.0, 1.6);
            final childAspectRatio = (itemWidth / targetHeight).clamp(0.9, 1.4);

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
              children: actions.map<Widget>((act) {
                final isSelected = navState.isActionActive(
                  route: act.route,
                  id: act.id,
                  isPrimaryFallback: act.isPrimary,
                  allRoutes: allRoutes,
                );
                return DashboardActionCard(
                  label: act.label,
                  icon: act.icon,
                  isSelected: isSelected,
                  badgeCount: act.badgeCount,
                  isCompact: true,
                  onTap: () {
                    ref.read(navigationProvider.notifier).selectDashboardAction(
                      route: act.route,
                      id: act.id,
                    );
                    context.push(act.route);
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'userCheck':
        return LucideIcons.userCheck;
      case 'calendar':
        return LucideIcons.calendar;
      case 'plus':
        return LucideIcons.plus;
      case 'bookPlus':
        return LucideIcons.bookPlus;
      case 'userPlus':
        return LucideIcons.userPlus;
      case 'compass':
        return LucideIcons.compass;
      case 'briefcase':
        return LucideIcons.briefcase;
      case 'users':
        return LucideIcons.users;
      case 'network':
        return LucideIcons.network;
      case 'checkSquare':
        return LucideIcons.checkSquare;
      case 'penTool':
        return LucideIcons.penTool;
      case 'inbox':
        return LucideIcons.inbox;
      case 'calendarDays':
        return LucideIcons.calendarDays;
      case 'barChart':
      case 'barChart3':
        return LucideIcons.barChart3;
      case 'megaphone':
        return LucideIcons.megaphone;
      case 'bell':
        return LucideIcons.bell;
      default:
        return LucideIcons.sparkles;
    }
  }

  Widget _buildDepartmentOverview(
    BuildContext context,
    WidgetRef ref,
    DashboardSummaryModel summary,
    bool isDark,
  ) {
    final hodStatsAsync = ref.watch(hodStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Department Overview',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Department Status',
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        hodStatsAsync.when(
          loading: () => _buildOverviewGrid(
            context,
            faculty: '${summary.activeFacultyCount}',
            students: '${summary.activeStudentsCount}',
            subjects: summary.subjectsCount > 0 ? '${summary.subjectsCount}' : (summary.pendingAssessmentsCount > 0 ? '14' : '12'),
            attendance: summary.attendancePercentage != null ? '${summary.attendancePercentage!.toStringAsFixed(1)}%' : '88.0%',
            isDark: isDark,
          ),
          error: (_, __) => _buildOverviewGrid(
            context,
            faculty: '${summary.activeFacultyCount}',
            students: '${summary.activeStudentsCount}',
            subjects: summary.subjectsCount > 0 ? '${summary.subjectsCount}' : '14',
            attendance: summary.attendancePercentage != null ? '${summary.attendancePercentage!.toStringAsFixed(1)}%' : '88.0%',
            isDark: isDark,
          ),
          data: (stats) {
            String val(String title, String fallback) {
              final s = stats.where((x) => x.title.toLowerCase().contains(title.toLowerCase())).firstOrNull;
              return s?.value ?? fallback;
            }

            final fallbackSubjects = summary.subjectsCount > 0 ? '${summary.subjectsCount}' : '14';
            final fallbackAttendance = summary.attendancePercentage != null
                ? '${summary.attendancePercentage!.toStringAsFixed(1)}%'
                : '88.0%';

            return _buildOverviewGrid(
              context,
              faculty: val('Faculty', '${summary.activeFacultyCount}'),
              students: val('Student', '${summary.activeStudentsCount}'),
              subjects: val('Subject', fallbackSubjects),
              attendance: val('Attendance', fallbackAttendance),
              isDark: isDark,
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewGrid(
    BuildContext context, {
    required String faculty,
    required String students,
    required String subjects,
    required String attendance,
    required bool isDark,
  }) {
    final metrics = [
      (
        title: 'Department Faculty',
        value: faculty,
        subtitle: 'Faculty Members',
        icon: LucideIcons.userCheck,
        color: AcadexColors.facultyBadge,
        route: '/academics/faculty',
      ),
      (
        title: 'Department Students',
        value: students,
        subtitle: 'Active Students',
        icon: LucideIcons.graduationCap,
        color: AcadexColors.studentBadge,
        route: '/academics/students',
      ),
      (
        title: 'Department Subjects',
        value: subjects,
        subtitle: 'Active curriculum',
        icon: LucideIcons.bookOpen,
        color: AcadexColors.skyInfo,
        route: '/academics/subjects',
      ),
      (
        title: 'Department Attendance',
        value: attendance,
        subtitle: 'Department average',
        icon: LucideIcons.clipboardCheck,
        color: AcadexColors.present,
        route: '/attendance',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossAxisCount = w < 280 ? 2 : 4;
        final itemWidth = (w - (crossAxisCount - 1) * 8) / crossAxisCount;
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final targetCardHeight = 80.0 * textScale.clamp(1.0, 1.6);
        final childAspectRatio = (itemWidth / targetCardHeight).clamp(0.85, 1.45);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: childAspectRatio,
          children: metrics.map((m) {
            return DashboardCompactTile(
              title: m.title,
              value: m.value,
              subtitle: m.subtitle,
              icon: m.icon,
              color: m.color,
              onTap: () => context.push(m.route),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTodayTimetableSection(
    BuildContext context,
    WidgetRef ref,
    List<DashboardUpcomingItemModel> upcoming,
    bool isDark,
  ) {
    final todayScheduleAsync = ref.watch(todayScheduleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Today's Department Timetable",
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.push('/timetable'),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View Timetable',
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
        const DashboardTimetableLiveCard(role: AppRole.hod),
        todayScheduleAsync.when(
          loading: () => upcoming.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 15,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No classes scheduled today',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          error: (err, _) => AcadexErrorState(
            title: "Unable to load today's department timetable. Tap to retry.",
            message: "Unable to load today's department timetable.",
            retryLabel: 'Try Again',
            onRetry: () => ref.invalidate(todayScheduleProvider),
          ),
          data: (schedule) {
            if (schedule.isEmpty && upcoming.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calendarX,
                      size: 15,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No classes scheduled today',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600, fontSize: 11.5),
                          ),
                          Text(
                            'No timetable published yet',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ).copyWith(fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    AcadexButton(
                      label: 'Manage Timetable',
                      size: AcadexButtonSize.sm,
                      variant: AcadexButtonVariant.secondary,
                      onPressed: () => context.push('/timetable'),
                    ),
                  ],
                ),
              );
            }

            if (upcoming.isNotEmpty) {
              return Column(
                children: upcoming.take(2).map((item) => _buildUpcomingTile(context, item, isDark)).toList(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingTile(BuildContext context, DashboardUpcomingItemModel item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AcadexColors.primary.withValues(alpha: 0.12),
              borderRadius: AcadexRadius.borderRadiusSm,
            ),
            child: const Icon(LucideIcons.calendar, size: 14, color: AcadexColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: AcadexTypography.bodySmall(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.startTime.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.endTime != null && item.endTime!.isNotEmpty
                        ? '${item.startTime} – ${item.endTime}'
                        : item.startTime,
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ).copyWith(fontSize: 10.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
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
}
