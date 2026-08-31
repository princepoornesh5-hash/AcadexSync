import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_adaptive_gradient_text.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/acadex_hero_card.dart';
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

    return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = AcadexLayout.statGridColumns(context);
          final firstName = user?.name.split(' ').first ?? 'HOD';

          final deptMap = ref.watch(departmentMapProvider);
          final dept = departmentId.isNotEmpty ? deptMap[departmentId] : null;
          final deptName = dept?.name ?? (departmentId.isNotEmpty ? 'Department Administration' : 'Department Administration');
          final deptCode = dept?.code ?? '';

          final isMobile = AcadexBreakpoints.isMobile(context);

          return AcadexPageContainer(
            backgroundColor: Colors.transparent,
            topPadding: isMobile ? 16 : 24,
            onRefresh: () async {
              ref.invalidate(hodStatsProvider);
              ref.invalidate(hodActivityProvider);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting & Role Badge
                if (isMobile) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AcadexAdaptiveGradientText(
                          'Welcome, Dr. $firstName 👋',
                          style: AcadexTypography.heading2(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const AcadexBadge(
                        label: 'HOD',
                        variant: AcadexBadgeVariant.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AcadexAdaptiveGradientText(
                    'Departmental operations, faculty workload, and attendance overview.',
                    style: AcadexTypography.caption(),
                    isSecondary: true,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AcadexAdaptiveGradientText(
                              'Welcome, Dr. $firstName 👋',
                              style: AcadexTypography.heading1(),
                            ),
                            const SizedBox(height: 4),
                            AcadexAdaptiveGradientText(
                              'Departmental operations, faculty teaching workload, and student attendance overview.',
                              style: AcadexTypography.body(),
                              isSecondary: true,
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
                ],
                const SizedBox(height: 20),

                // Department Identification Hero Card
                AcadexHeroCard(
                  eyebrow: 'Department Health & Operations',
                  badge: AcadexBadge(
                    label: deptCode.isNotEmpty ? 'DEPT: $deptCode' : 'OPERATIONAL',
                    variant: AcadexBadgeVariant.primary,
                  ),
                  icon: LucideIcons.building,
                  title: deptName,
                  subtitle: 'Oversee academic performance, faculty teaching allocations, and student attendance.',
                  primaryActionLabel: 'Department Attendance',
                  primaryActionIcon: LucideIcons.clipboardCheck,
                  onPrimaryAction: () => context.go('/attendance'),
                  secondaryActionLabel: 'Faculty Workload',
                  onSecondaryAction: () => context.go('/academics/faculty'),
                ),
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
                QuickActionsRow(actions: quickActions),
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
      );
  }
}
