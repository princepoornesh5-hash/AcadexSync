import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/providers/navigation_provider.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../domain/models/home_dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/home_dashboard_widgets.dart';

/// College Admin Institutional Command Centre Dashboard
/// Authorised college-wide operational overview adhering to the ACADEX design system.
class CollegeAdminDashboard extends ConsumerWidget {
  const CollegeAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(homeDashboardProvider);
        ref.invalidate(collegeAdminStatsProvider);
        ref.invalidate(collegeAdminActivityProvider);
      },
      child: dashboardAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState.spinner(
            message: 'Loading institutional dashboard...',
          ),
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
              // 1. Welcome & Greeting
              DashboardGreetingHeader(greeting: dashboard.greeting),

              // 2. Institutional Context & Header Strip
              DashboardContextCard(
                role: dashboard.role,
                contextModel: dashboard.context,
              ),

              // 3. Institutional Command Overview (Authorised Scope Metrics)
              _buildInstitutionalOverview(context, dashboard.summary, isDark),

              // 4. Institutional Operations (Tactile Quick Actions Grid)
              _buildAcademicOperations(
                context,
                ref,
                dashboard.quickActions,
                isDark,
              ),

              // 5. Institutional Alerts & Pending Actions
              if (dashboard.alerts.isNotEmpty)
                DashboardAlertsSection(alerts: dashboard.alerts),

              if (dashboard.pendingActions.isNotEmpty)
                DashboardPendingActionsSection(
                  pendingActions: dashboard.pendingActions,
                ),

              // 6. Institutional Calendar & Upcoming Events
              DashboardUpcomingSection(upcoming: dashboard.upcoming),

              // 7. Recent Institutional Activity
              DashboardRecentActivitySection(recent: dashboard.recent),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // ── 3. Institutional Overview Metrics ─────────────────────────────────────
  Widget _buildInstitutionalOverview(
    BuildContext context,
    DashboardSummaryModel summary,
    bool isDark,
  ) {
    final metrics = [
      (
        title: 'Departments',
        value: '${summary.departmentsCount}',
        subtitle: 'Academic divisions',
        icon: LucideIcons.building2,
        color: AcadexColors.collegeAdminBadge,
        route: '/academics/departments',
      ),
      (
        title: 'Total Students',
        value: '${summary.studentsCount}',
        subtitle: 'Enrolled learners',
        icon: LucideIcons.graduationCap,
        color: AcadexColors.studentBadge,
        route: '/academics/students',
      ),
      (
        title: 'Total Faculty',
        value: '${summary.facultyCount}',
        subtitle: 'Teaching staff',
        icon: LucideIcons.users,
        color: AcadexColors.facultyBadge,
        route: '/academics/faculty',
      ),
      if (summary.coursesCount > 0)
        (
          title: 'Programmes',
          value: '${summary.coursesCount}',
          subtitle: 'Degree curricula',
          icon: LucideIcons.layers,
          color: AcadexColors.skyInfo,
          route: '/academics/courses',
        ),
      if (summary.sectionsCount > 0)
        (
          title: 'Active Sections',
          value: '${summary.sectionsCount}',
          subtitle: 'Class cohorts',
          icon: LucideIcons.layoutGrid,
          color: Colors.teal,
          route: '/academics/sections',
        ),
      if (summary.attendancePercentage != null)
        (
          title: 'Campus Attendance',
          value: '${summary.attendancePercentage!.toStringAsFixed(1)}%',
          subtitle: 'College-wide rate',
          icon: LucideIcons.clipboardCheck,
          color: AcadexColors.present,
          route: '/attendance',
        )
      else if (summary.pendingRequestsCount > 0)
        (
          title: 'Pending Requests',
          value: '${summary.pendingRequestsCount}',
          subtitle: 'Awaiting action',
          icon: LucideIcons.inbox,
          color: AcadexColors.warning,
          route: '/requests',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Institutional Overview',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'College Scope',
              style: AcadexTypography.caption(
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final count = metrics.length;
            final int crossAxisCount;
            if (w < 340) {
              crossAxisCount = 2;
            } else if (w < 600) {
              crossAxisCount = count <= 4 ? count : 3;
            } else if (w < 1000) {
              crossAxisCount = count <= 4 ? count : 3;
            } else {
              crossAxisCount = count <= 6 ? count : 6;
            }

            final itemWidth = (w - (crossAxisCount - 1) * 8) / crossAxisCount;
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final targetCardHeight = 80.0 * textScale.clamp(1.0, 1.6);
            final childAspectRatio = (itemWidth / targetCardHeight).clamp(
              0.85,
              1.45,
            );

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, i) {
                final m = metrics[i];
                return DashboardCompactTile(
                  title: m.title,
                  value: m.value,
                  subtitle: m.subtitle,
                  icon: m.icon,
                  color: m.color,
                  onTap: () => context.push(m.route),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ── 4. Academic Operations (Tactile Quick Actions Grid) ────────────────────
  Widget _buildAcademicOperations(
    BuildContext context,
    WidgetRef ref,
    List<DashboardQuickActionModel> quickActions,
    bool isDark,
  ) {
    final navState = ref.watch(navigationProvider);
    // If the backend or test mock provided specific actions, use them
    final bool hasProvidedActions = quickActions.isNotEmpty;

    final actions = hasProvidedActions
        ? quickActions
              .map(
                (a) => (
                  id: a.id.isNotEmpty ? a.id : a.label,
                  label: a.label,
                  icon: _resolveIcon(a.icon),
                  route: a.route,
                  isPrimary: a.isPrimary,
                  badgeCount: a.badgeCount,
                ),
              )
              .toList()
        : [
            (
              id: 'ca_structure',
              label: 'Academic Structure',
              icon: LucideIcons.layers,
              route: '/academics',
              isPrimary: true,
              badgeCount: null,
            ),
            (
              id: 'ca_students',
              label: 'Student Directory',
              icon: LucideIcons.graduationCap,
              route: '/academics/students',
              isPrimary: false,
              badgeCount: null,
            ),
            (
              id: 'ca_faculty',
              label: 'Faculty Directory',
              icon: LucideIcons.users,
              route: '/academics/faculty',
              isPrimary: false,
              badgeCount: null,
            ),
            (
              id: 'ca_departments',
              label: 'Departments',
              icon: LucideIcons.building2,
              route: '/academics/departments',
              isPrimary: false,
              badgeCount: null,
            ),
            (
              id: 'ca_timetable',
              label: 'Timetable Manager',
              icon: LucideIcons.calendar,
              route: '/timetable',
              isPrimary: false,
              badgeCount: null,
            ),
            (
              id: 'ca_calendar',
              label: 'Academic Calendar',
              icon: LucideIcons.calendarDays,
              route: '/calendar',
              isPrimary: false,
              badgeCount: null,
            ),
            (
              id: 'ca_requests',
              label: 'Request Centre',
              icon: LucideIcons.inbox,
              route: '/requests',
              isPrimary: false,
              badgeCount: null,
            ),
            (
              id: 'ca_reports',
              label: 'Institutional Reports',
              icon: LucideIcons.barChart3,
              route: '/analytics',
              isPrimary: false,
              badgeCount: null,
            ),
          ];

    final allRoutes = actions.map((a) => a.route).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Academic Operations',
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
                  'Academic Setup',
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
            final isWide = w >= 600;
            final count = actions.length;
            final crossAxisCount = isWide
                ? (count > 4 ? 4 : count)
                : (w < 340 ? 2 : 4);

            final itemWidth = (w - (crossAxisCount - 1) * 8) / crossAxisCount;
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final targetHeight = 74.0 * textScale.clamp(1.0, 1.6);
            final childAspectRatio = (itemWidth / targetHeight).clamp(0.9, 1.4);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, i) {
                final act = actions[i];
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
                    ref
                        .read(navigationProvider.notifier)
                        .selectDashboardAction(route: act.route, id: act.id);
                    context.push(act.route);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'layers':
        return LucideIcons.layers;
      case 'graduationCap':
        return LucideIcons.graduationCap;
      case 'users':
        return LucideIcons.users;
      case 'building':
      case 'building2':
        return LucideIcons.building2;
      case 'calendar':
        return LucideIcons.calendar;
      case 'calendarDays':
        return LucideIcons.calendarDays;
      case 'inbox':
        return LucideIcons.inbox;
      case 'barChart':
      case 'barChart3':
        return LucideIcons.barChart3;
      case 'megaphone':
        return LucideIcons.megaphone;
      case 'bell':
        return LucideIcons.bell;
      case 'userCheck':
        return LucideIcons.userCheck;
      case 'fileText':
        return LucideIcons.fileText;
      case 'settings':
        return LucideIcons.settings;
      case 'penTool':
        return LucideIcons.penTool;
      case 'award':
        return LucideIcons.award;
      default:
        return LucideIcons.folder;
    }
  }
}
