import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(superAdminStatsProvider);
    final quickActions = ref.watch(superAdminQuickActionsProvider);
    final activity = ref.watch(superAdminActivityProvider);
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) user = authState.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _DashboardBody(
        user: user,
        greeting: 'Good day, ${user?.name.split(' ').first ?? 'Admin'}',
        subtitle: 'Here\'s your system overview for today.',
        stats: stats,
        quickActions: quickActions,
        activity: activity,
        extraSection: _SystemHealthCard(),
      ),
    );
  }
}

class _SystemHealthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'System Health'),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              _HealthItem(label: 'API Status', status: 'Operational', color: AcadexColors.success, icon: LucideIcons.server),
              _HealthItem(label: 'Database', status: 'Healthy', color: AcadexColors.success, icon: LucideIcons.database),
              _HealthItem(label: 'Storage', status: '74% Used', color: AcadexColors.warning, icon: LucideIcons.hardDrive),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthItem extends StatelessWidget {
  final String label;
  final String status;
  final Color color;
  final IconData icon;
  const _HealthItem({required this.label, required this.status, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(height: 8),
          Text(label, style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(status, style: AcadexTypography.bodySmall(color: color).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Dashboard Body Layout
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final UserModel? user;
  final String greeting;
  final String subtitle;
  final AsyncValue<List<DashboardStatModel>> stats;
  final List<QuickActionModel> quickActions;
  final AsyncValue<List<ActivityItemModel>> activity;
  final Widget? extraSection;

  const _DashboardBody({
    required this.user,
    required this.greeting,
    required this.subtitle,
    required this.stats,
    required this.quickActions,
    required this.activity,
    this.extraSection,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final statCols = AcadexLayout.statGridColumns(context);

        return AcadexPageContainer(
          particleSphereVariant: ParticleSphereVariant.dashboard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              _GreetingRow(greeting: greeting, subtitle: subtitle, user: user),
              AcadexLayout.sectionSpacer,

              // Stats Grid
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
                  itemBuilder: (_, i) => StatCard(
                    stat: data[i],
                    animationDelay: i * 80,
                  ),
                ),
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

              // Quick Actions
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

              // Extra section (e.g. System Health for Super Admin)
              if (extraSection != null) ...[
                extraSection!,
                AcadexLayout.sectionSpacer,
              ],

              // Recent Activity
              SectionHeader(
                title: 'Recent Activity',
                actionLabel: 'View All',
                onAction: () {},
              ),
              AcadexLayout.headerGap,
              activity.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (err, stack) => Text('Error: $err'),
                data: (data) => ActivityFeed(items: data),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GreetingRow extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final UserModel? user;

  const _GreetingRow({required this.greeting, required this.subtitle, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 6),
              Text(
                subtitle,
                style: AcadexTypography.body(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: AcadexRadius.borderRadiusFull,
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AcadexColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user?.role.displayName ?? 'User',
                style: AcadexTypography.eyebrow(color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
