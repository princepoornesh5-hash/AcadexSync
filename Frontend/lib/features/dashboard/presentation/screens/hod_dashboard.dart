import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/activity_feed.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../timetable/presentation/widgets/timetable_widgets.dart';
import '../../../academic_structure/presentation/widgets/academic_structure_summary_widget.dart';

class HodDashboard extends ConsumerWidget {
  const HodDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(hodStatsProvider);
    final quickActions = ref.watch(hodQuickActionsProvider);
    final activity = ref.watch(hodActivityProvider);
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) user = authState.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final departmentId = user?.departmentId ?? '';

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = AcadexLayout.statGridColumns(context);
          final firstName = user?.name.split(' ').first ?? 'HOD';

          final deptMap = ref.watch(departmentMapProvider);
          final dept = departmentId.isNotEmpty ? deptMap[departmentId] : null;
          final deptName = dept?.name ?? (departmentId.isNotEmpty ? 'Department Administration' : 'No Department Assigned');
          final deptCode = dept?.code ?? '';

          return AcadexPageContainer(
            particleSphereVariant: ParticleSphereVariant.dashboard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting & Role Badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Dr. $firstName 👋',
                            style: AcadexTypography.heading1(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Departmental operations, faculty teaching workload, and student attendance overview.',
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AcadexBadge(
                      label: 'HOD',
                      variant: AcadexBadgeVariant.primary,
                    ),
                  ],
                ),
                AcadexLayout.sectionSpacer,

                // Department Identification Banner
                if (departmentId.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AcadexColors.primary, const Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AcadexRadius.borderRadiusLg,
                      boxShadow: [
                        BoxShadow(
                          color: AcadexColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: AcadexRadius.borderRadiusMd,
                          ),
                          child: const Icon(LucideIcons.building, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deptName,
                                style: AcadexTypography.heading2(color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                deptCode.isNotEmpty
                                    ? 'Department Code: $deptCode • Department Operational Overview'
                                    : 'Department Operational Overview',
                                style: AcadexTypography.caption(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(color: AcadexColors.warning),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AcadexColors.warning, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Department Not Assigned',
                                style: AcadexTypography.body(
                                  color: isDark ? Colors.white : AcadexColors.warningDark,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Your account has not been linked to a specific department yet. Please contact your college administrator.',
                                style: AcadexTypography.caption(
                                  color: isDark ? Colors.white70 : AcadexColors.warningDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                AcadexLayout.sectionSpacer,

                // Department Key Metrics
                const SectionHeader(title: 'Department Overview'),
                AcadexLayout.headerGap,
                stats.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => AcadexCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load department metrics: $err',
                      style: AcadexTypography.caption(color: AcadexColors.error),
                    ),
                  ),
                  data: (data) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: statCols,
                      crossAxisSpacing: AcadexLayout.gridSpacing,
                      mainAxisSpacing: AcadexLayout.gridSpacing,
                      childAspectRatio: width > 600 ? 1.25 : 1.15,
                    ),
                    itemBuilder: (_, i) => StatCard(stat: data[i]),
                  ),
                ),
                AcadexLayout.sectionSpacer,

                // Today's Timetable Preview
                const SectionHeader(title: "Today's Department Timetable"),
                AcadexLayout.headerGap,
                Consumer(
                  builder: (context, ref, _) {
                    final todayAsync = ref.watch(todayScheduleProvider);
                    return todayAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error loading schedule: $err'),
                      data: (data) => TodayScheduleWidget(todayEntries: data),
                    );
                  },
                ),
                AcadexLayout.sectionSpacer,

                // Department Academic Structure Summary
                if (departmentId.isNotEmpty) ...[
                  AcademicStructureSummaryWidget(departmentId: departmentId),
                  AcadexLayout.sectionSpacer,
                ],

                // Active Faculty Allocations (Live from facultyAssignmentsProvider)
                SectionHeader(
                  title: 'Faculty Teaching Allocations',
                  actionLabel: 'Manage All',
                  onAction: () => context.go('/faculty-assignments'),
                ),
                AcadexLayout.headerGap,
                Consumer(
                  builder: (context, ref, _) {
                    final assignmentsAsync = ref.watch(facultyAssignmentsProvider);
                    final subMap = ref.watch(subjectMapProvider);
                    final secMap = ref.watch(sectionMapProvider);

                    return assignmentsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Text('Error loading assignments: $err'),
                      data: (allAssignments) {
                        final deptAssignments = departmentId.isNotEmpty
                            ? allAssignments.where((a) => a.departmentId == departmentId && a.isActive).take(4).toList()
                            : allAssignments.where((a) => a.isActive).take(4).toList();

                        if (deptAssignments.isEmpty) {
                          return AcadexCard(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No active faculty allocations recorded for this department.',
                              style: AcadexTypography.bodySmall(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: deptAssignments.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: width > 900 ? 4 : (width > 600 ? 2 : 1),
                            crossAxisSpacing: AcadexLayout.gridSpacing,
                            mainAxisSpacing: AcadexLayout.gridSpacing,
                            childAspectRatio: width > 600 ? 1.6 : 2.0,
                          ),
                          itemBuilder: (context, i) {
                            final a = deptAssignments[i];
                            final sub = subMap[a.subjectId];
                            final sec = secMap[a.sectionId];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                borderRadius: AcadexRadius.borderRadiusMd,
                                border: Border.all(
                                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a.facultyName,
                                          style: AcadexTypography.body(
                                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                          ).copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AcadexColors.primary.withValues(alpha: 0.12),
                                          borderRadius: AcadexRadius.borderRadiusSm,
                                        ),
                                        child: Text(
                                          'Sec ${sec?.name ?? a.sectionId}',
                                          style: const TextStyle(
                                            color: AcadexColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    sub?.name ?? a.subjectId,
                                    style: AcadexTypography.caption(
                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    sub?.code ?? '',
                                    style: const TextStyle(
                                      color: AcadexColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                AcadexLayout.sectionSpacer,

                // Quick Navigation Actions
                const SectionHeader(title: 'Quick Operations'),
                AcadexLayout.headerGap,
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: quickActions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 900 ? 5 : (width > 600 ? 3 : 2),
                    crossAxisSpacing: AcadexLayout.gridSpacing,
                    mainAxisSpacing: AcadexLayout.gridSpacing,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (_, i) => QuickActionCard(action: quickActions[i]),
                ),
                AcadexLayout.sectionSpacer,

                // Recent Notifications
                SectionHeader(
                  title: 'Recent Activity & Notifications',
                  actionLabel: 'View All',
                  onAction: () => context.go('/notifications'),
                ),
                AcadexLayout.headerGap,
                activity.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => AcadexCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load activity: $err',
                      style: AcadexTypography.caption(color: AcadexColors.error),
                    ),
                  ),
                  data: (data) => ActivityFeed(items: data),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
