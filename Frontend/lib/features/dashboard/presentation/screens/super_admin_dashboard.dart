import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../domain/models/home_dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/home_dashboard_widgets.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(homeDashboardProvider);
      },
      child: dashboardAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState.spinner(
            message: 'Loading platform administration...',
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

              // 2. Global Platform Scope
              DashboardContextCard(
                role: dashboard.role,
                contextModel: dashboard.context,
              ),

              // 3. Platform Shortcuts (Immediate 8px gap below hero, matching HOD standard)
              const SizedBox(height: 8),
              DashboardQuickActionsGrid(quickActions: dashboard.quickActions),

              // 4. Platform Alerts & Pending Actions
              if (dashboard.alerts.isNotEmpty)
                DashboardAlertsSection(alerts: dashboard.alerts),

              if (dashboard.pendingActions.isNotEmpty)
                DashboardPendingActionsSection(
                  pendingActions: dashboard.pendingActions,
                ),

              // 5. Global Platform Metrics
              _buildPlatformMetricsSummary(context, dashboard.summary),

              // 6. Recent Platform Activity
              DashboardRecentActivitySection(recent: dashboard.recent),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlatformMetricsSummary(
    BuildContext context,
    DashboardSummaryModel summary,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Platform Overview',
          style: AcadexTypography.heading3(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w < 280 ? 2 : 4;
            final itemWidth = (w - (crossAxisCount - 1) * 8) / crossAxisCount;
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final targetCardHeight = 80.0 * textScale.clamp(1.0, 1.6);
            final childAspectRatio = (itemWidth / targetCardHeight).clamp(
              0.85,
              1.45,
            );

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
              children: [
                DashboardCompactTile(
                  title: 'Total Colleges',
                  value: '${summary.collegesCount}',
                  subtitle:
                      '${summary.activeCollegesCount} active institutions',
                  icon: LucideIcons.building,
                  color: AcadexColors.primary,
                  onTap: () => context.push('/academics/colleges'),
                ),
                DashboardCompactTile(
                  title: 'Platform Users',
                  value: '${summary.usersCount}',
                  subtitle: 'Registered accounts',
                  icon: LucideIcons.users,
                  color: Colors.teal,
                  onTap: () => context.push('/users'),
                ),
                DashboardCompactTile(
                  title: 'Active Tenants',
                  value: '${summary.activeCollegesCount}',
                  subtitle: 'Operating colleges',
                  icon: LucideIcons.shieldCheck,
                  color: Colors.purple,
                  onTap: () => context.push('/academics/colleges'),
                ),
                DashboardCompactTile(
                  title: 'System Health',
                  value: summary.systemStatus,
                  subtitle: 'All core services healthy',
                  icon: LucideIcons.activity,
                  color: Colors.green,
                  onTap: () => context.push('/settings'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
