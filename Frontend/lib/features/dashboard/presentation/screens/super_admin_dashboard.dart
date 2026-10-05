import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
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
          child: AcadexLoadingState(message: 'Loading platform administration...'),
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

              // 3. Platform Alerts
              DashboardAlertsSection(alerts: dashboard.alerts),

              // 4. Pending Actions
              DashboardPendingActionsSection(
                pendingActions: dashboard.pendingActions,
              ),

              // 5. Platform Shortcuts
              DashboardQuickActionsGrid(
                quickActions: dashboard.quickActions,
              ),

              // 6. Global Platform Metrics
              _buildPlatformMetricsSummary(context, dashboard.summary),

              // 7. Recent Platform Activity
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
        const SizedBox(height: 18),
        Text(
          'Platform Overview',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 380;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isNarrow ? 2 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isNarrow ? 2.0 : 2.2,
              children: [
                _buildMetricTile(
                  context,
                  title: 'Total Colleges',
                  value: '${summary.collegesCount}',
                  subtitle: '${summary.activeCollegesCount} active institutions',
                  icon: LucideIcons.building,
                  color: AcadexColors.primary,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Platform Users',
                  value: '${summary.usersCount}',
                  subtitle: 'Registered accounts',
                  icon: LucideIcons.users,
                  color: Colors.teal,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Active Tenants',
                  value: '${summary.activeCollegesCount}',
                  subtitle: 'Operating colleges',
                  icon: LucideIcons.shieldCheck,
                  color: Colors.purple,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'System Health',
                  value: summary.systemStatus,
                  subtitle: 'All core services healthy',
                  icon: LucideIcons.activity,
                  color: Colors.green,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return AcadexCard(
      isFlat: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(icon, size: 12, color: color),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AcadexTypography.heading2(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
          ),
          Text(
            subtitle,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
