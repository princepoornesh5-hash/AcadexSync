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
import '../providers/dashboard_providers.dart';
import '../widgets/activity_feed.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../timetable/presentation/widgets/timetable_widgets.dart';
import '../../../academic_structure/presentation/widgets/academic_structure_summary_widget.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

class CollegeAdminDashboard extends ConsumerWidget {
  const CollegeAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(collegeAdminStatsProvider);
    final quickActions = ref.watch(collegeAdminQuickActionsProvider);
    final activity = ref.watch(collegeAdminActivityProvider);
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) user = authState.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = user?.name.split(' ').first ?? 'College Admin';

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = AcadexLayout.statGridColumns(context);

          return AcadexPageContainer(
            particleSphereVariant: ParticleSphereVariant.dashboard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting & Role Indicator
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $firstName 👋',
                            style: AcadexTypography.heading1(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Institutional command center for academic operations, scheduling, and faculty management.',
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AcadexBadge(
                      label: 'COLLEGE ADMIN',
                      variant: AcadexBadgeVariant.primary,
                    ),
                  ],
                ),
                AcadexLayout.sectionSpacer,

                // Key Institutional Stat Cards
                const SectionHeader(title: 'College Overview'),
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
                      'Failed to load metrics: $err',
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

                // Today's Campus Timetable Schedule
                const SectionHeader(title: "Today's Schedule & Sessions"),
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

                // Academic Hierarchy Summary Deck
                const AcademicStructureSummaryWidget(),
                AcadexLayout.sectionSpacer,

                // Department Breakdown (Live from /reports/dashboard)
                Consumer(
                  builder: (context, ref, _) {
                    final reportAsync = ref.watch(roleDashboardReportProvider);
                    return reportAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (report) {
                        if (report == null || report.recentActivity.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final depts = report.recentActivity;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'Department Performance Breakdown',
                              actionLabel: 'View Departments',
                              onAction: () => context.go('/academics/departments'),
                            ),
                            AcadexLayout.headerGap,
                            AcadexCard(
                              padding: const EdgeInsets.all(16),
                              child: ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: depts.length > 6 ? 6 : depts.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                ),
                                itemBuilder: (context, idx) {
                                  final dept = depts[idx];
                                  final name = dept['name']?.toString() ?? 'Department';
                                  final code = dept['code']?.toString() ?? '';
                                  final students = dept['studentsCount']?.toString() ?? '0';
                                  final faculty = dept['facultyCount']?.toString() ?? '0';
                                  final attPct = dept['attendancePercentage'] != null
                                      ? '${(dept['attendancePercentage'] as num).toStringAsFixed(1)}%'
                                      : 'N/A';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AcadexColors.primary.withValues(alpha: 0.12),
                                        borderRadius: AcadexRadius.borderRadiusMd,
                                      ),
                                      child: const Icon(LucideIcons.layoutGrid, color: AcadexColors.primary, size: 18),
                                    ),
                                    title: Text(
                                      name,
                                      style: AcadexTypography.body(
                                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      'Code: $code • $students Students • $faculty Faculty',
                                      style: AcadexTypography.caption(
                                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                        borderRadius: AcadexRadius.borderRadiusSm,
                                      ),
                                      child: Text(
                                        'Att: $attPct',
                                        style: AcadexTypography.caption(
                                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            AcadexLayout.sectionSpacer,
                          ],
                        );
                      },
                    );
                  },
                ),

                // Quick Navigation Actions Grid
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
