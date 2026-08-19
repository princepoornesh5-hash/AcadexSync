import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/activity_item_model.dart';
import '../../domain/models/dashboard_stat_model.dart';
import '../../domain/models/quick_action_model.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _HodBody(user: user, stats: stats, quickActions: quickActions, activity: activity),
    );
  }
}

class _HodBody extends ConsumerWidget {
  final UserModel? user;
  final AsyncValue<List<DashboardStatModel>> stats;
  final List<QuickActionModel> quickActions;
  final AsyncValue<List<ActivityItemModel>> activity;

  const _HodBody({required this.user, required this.stats, required this.quickActions, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptMap = ref.watch(departmentMapProvider);
    final deptName = user?.departmentId != null && deptMap.containsKey(user!.departmentId)
        ? deptMap[user!.departmentId]!.name
        : 'Department Administration';

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final statCols = AcadexLayout.statGridColumns(context);
      final firstName = user?.name.split(' ').first ?? 'HOD';

      return AcadexPageContainer(
        particleSphereVariant: ParticleSphereVariant.dashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, Dr. $firstName', style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text('Department overview & management tools.', style: AcadexTypography.body(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)),
                    ],
                  ),
                ),
                _RoleBadge(label: user?.role.displayName ?? 'HOD'),
              ],
            ),
            const SizedBox(height: 24),
            // Dept summary banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AcadexRadius.borderRadiusLg,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.building, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deptName, style: AcadexTypography.title(color: Colors.white)),
                        Text('Department Summary', style: AcadexTypography.bodySmall(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const SectionHeader(title: "Today's Timetable"),
            AcadexLayout.headerGap,
            Consumer(
              builder: (context, ref, _) {
                final todayAsync = ref.watch(todayScheduleProvider);
                return todayAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error loading schedule: $err'),
                  data: (data) => TodayScheduleWidget(todayEntries: data),
                );
              },
            ),
            AcadexLayout.sectionSpacer,
            AcademicStructureSummaryWidget(departmentId: user?.departmentId),
            AcadexLayout.sectionSpacer,

            // Faculty Assignments Section
            SectionHeader(
              title: "Faculty Assignments",
              actionLabel: "Manage All",
              onAction: () => Navigator.of(context).pushNamed('/faculty-assignments'),
            ),
            AcadexLayout.headerGap,
            Consumer(
              builder: (context, ref, _) {
                final assignmentsAsync = ref.watch(facultyAssignmentsProvider);
                final subMap = ref.watch(subjectMapProvider);
                final secMap = ref.watch(sectionMapProvider);

                return assignmentsAsync.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                  error: (err, _) => Text('Error loading assignments: $err'),
                  data: (allAssignments) {
                    final deptAssignments = user?.departmentId != null && user!.departmentId!.isNotEmpty
                        ? allAssignments.where((a) => a.departmentId == user!.departmentId && a.isActive).take(4).toList()
                        : allAssignments.where((a) => a.isActive).take(4).toList();

                    if (deptAssignments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "No active faculty assignments found for this department.",
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
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
                        childAspectRatio: width > 600 ? 1.5 : 2.0,
                      ),
                      itemBuilder: (context, i) {
                        final a = deptAssignments[i];
                        final sub = subMap[a.subjectId];
                        final sec = secMap[a.sectionId];

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(AcadexRadius.md),
                            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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
                                      style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AcadexColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                    ),
                                    child: Text(
                                      "Sec ${sec?.name ?? a.sectionId}",
                                      style: const TextStyle(color: AcadexColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                sub?.name ?? a.subjectId,
                                style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                sub?.code ?? '',
                                style: const TextStyle(color: AcadexColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
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

            const SectionHeader(title: 'Overview'),
            AcadexLayout.headerGap,
            stats.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              error: (err, stack) => Text('Error: $err'),
              data: (data) => GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: data.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: statCols,
                  crossAxisSpacing: AcadexLayout.gridSpacing,
                  mainAxisSpacing: AcadexLayout.gridSpacing,
                  childAspectRatio: width > 600 ? 1.15 : 1.05,
                ),
                itemBuilder: (_, i) => StatCard(stat: data[i], animationDelay: i * 80),
              ),
            ),
            AcadexLayout.sectionSpacer,
            const SectionHeader(title: 'Quick Actions'),
            AcadexLayout.headerGap,
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: quickActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width > 600 ? 4 : 2,
                crossAxisSpacing: AcadexLayout.gridSpacing,
                mainAxisSpacing: AcadexLayout.gridSpacing,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (_, i) => QuickActionCard(action: quickActions[i]),
            ),
            AcadexLayout.sectionSpacer,
            SectionHeader(title: 'Recent Activity', actionLabel: 'View All', onAction: () {}),
            AcadexLayout.headerGap,
            activity.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              error: (err, stack) => Text('Error: $err'),
              data: (data) => ActivityFeed(items: data),
            ),
          ],
        ),
      );
    });
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: AcadexRadius.borderRadiusFull,
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AcadexColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AcadexTypography.eyebrow(color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }
}
