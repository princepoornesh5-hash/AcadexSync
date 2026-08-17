import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
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

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        body: _DashboardBody(
          user: user,
          greeting: 'Good day, ${user?.name.split(' ').first ?? 'Admin'}',
          subtitle: 'Here\'s your system overview for today.',
          stats: stats,
          quickActions: quickActions,
          activity: activity,
          extraSection: _SystemHealthCard(),
        ),
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DashboardColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardColors.border),
          ),
          child: Row(
            children: [
              _HealthItem(label: 'API Status', status: 'Operational', color: DashboardColors.success, icon: LucideIcons.server),
              _HealthItem(label: 'Database', status: 'Healthy', color: DashboardColors.success, icon: LucideIcons.database),
              _HealthItem(label: 'Storage', status: '74% Used', color: DashboardColors.warning, icon: LucideIcons.hardDrive),
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
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: DashboardColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(status, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
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
        int statCols = width > 1024 ? 4 : width > 600 ? 3 : 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              _GreetingRow(greeting: greeting, subtitle: subtitle, user: user),
              const SizedBox(height: 28),

              // Stats Grid
              const SectionHeader(title: 'Overview'),
              const SizedBox(height: 12),
              stats.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (err, stack) => Text('Error: $err'),
                data: (data) => GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: data.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: statCols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: width > 600 ? 1.15 : 1.05,
                  ),
                  itemBuilder: (_, i) => StatCard(
                    stat: data[i],
                    animationDelay: i * 80,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const SectionHeader(title: "Today's Timetable"),
              const SizedBox(height: 12),
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
              const SizedBox(height: 28),

              // Quick Actions
              const SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: quickActions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: width > 600 ? 6 : 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (_, i) => QuickActionCard(action: quickActions[i]),
              ),
              const SizedBox(height: 28),

              // Extra section (e.g. System Health for Super Admin)
              if (extraSection != null) ...[
                extraSection!,
                const SizedBox(height: 28),
              ],

              // Recent Activity
              SectionHeader(
                title: 'Recent Activity',
                actionLabel: 'View All',
                onAction: () {},
              ),
              const SizedBox(height: 12),
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
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: DashboardColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: DashboardColors.primaryLight,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: DashboardColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user?.role.displayName ?? 'User',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
