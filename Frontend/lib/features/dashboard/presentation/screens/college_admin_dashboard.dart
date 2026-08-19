import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _CollegeAdminBody(
        user: user,
        stats: stats,
        quickActions: quickActions,
        activity: activity,
      ),
    );
  }
}

class _CollegeAdminBody extends StatelessWidget {
  final UserModel? user;
  final AsyncValue<List<DashboardStatModel>> stats;
  final List<QuickActionModel> quickActions;
  final AsyncValue<List<ActivityItemModel>> activity;

  const _CollegeAdminBody({
    required this.user,
    required this.stats,
    required this.quickActions,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final statCols = AcadexLayout.statGridColumns(context);
      final firstName = user?.name.split(' ').first ?? 'Admin';

      return AcadexPageContainer(
        particleSphereVariant: ParticleSphereVariant.dashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $firstName 👋',
                        style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage your college operations from here.',
                        style: AcadexTypography.body(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                _RolePill(label: user?.role.displayName ?? 'Admin'),
              ],
            ),
            AcadexLayout.sectionSpacer,
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
            const AcademicStructureSummaryWidget(),
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
                crossAxisCount: width > 600 ? 6 : 3,
                crossAxisSpacing: AcadexLayout.gridSpacing,
                mainAxisSpacing: AcadexLayout.gridSpacing,
                childAspectRatio: 0.9,
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

class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill({required this.label});

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
