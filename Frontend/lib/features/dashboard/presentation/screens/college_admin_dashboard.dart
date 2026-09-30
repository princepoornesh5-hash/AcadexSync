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

class CollegeAdminDashboard extends ConsumerWidget {
  const CollegeAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(homeDashboardProvider);
      },
      child: dashboardAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState(message: 'Loading institution dashboard...'),
        ),
        error: (err, _) => AcadexErrorState.fromError(
          error: err,
          title: 'Unable to load dashboard',
          onRetry: () => ref.invalidate(homeDashboardProvider),
        ),
        data: (dashboard) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Welcome & Greeting
                DashboardGreetingHeader(greeting: dashboard.greeting),

                // 2. Tenant Context
                DashboardContextCard(
                  role: dashboard.role,
                  contextModel: dashboard.context,
                ),

                // 3. Institution Alerts
                DashboardAlertsSection(alerts: dashboard.alerts),

                // 4. Pending Operational Actions
                DashboardPendingActionsSection(
                  pendingActions: dashboard.pendingActions,
                ),

                // 5. Institution Calendar & Upcoming
                DashboardUpcomingSection(upcoming: dashboard.upcoming),

                // 6. Management Shortcuts Grid
                DashboardQuickActionsGrid(
                  quickActions: dashboard.quickActions,
                ),

                // 7. Tenant Scoped Metrics
                _buildCollegeAdminMetricsSummary(context, dashboard.summary),

                // 8. Recent Activity
                DashboardRecentActivitySection(recent: dashboard.recent),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollegeAdminMetricsSummary(
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
          'Institution Operations Snapshot',
          style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
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
              childAspectRatio: isNarrow ? 1.6 : 1.8,
              children: [
                _buildMetricTile(
                  context,
                  title: 'Departments',
                  value: '${summary.departmentsCount}',
                  subtitle: 'Academic divisions',
                  icon: LucideIcons.layers,
                  color: AcadexColors.primary,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Faculty Members',
                  value: '${summary.facultyCount}',
                  subtitle: 'Active educators',
                  icon: LucideIcons.users,
                  color: Colors.teal,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Total Students',
                  value: '${summary.studentsCount}',
                  subtitle: 'Enrolled learners',
                  icon: LucideIcons.graduationCap,
                  color: Colors.purple,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Pending Requests',
                  value: '${summary.pendingRequestsCount}',
                  subtitle: 'Awaiting institutional action',
                  icon: LucideIcons.inbox,
                  color: summary.pendingRequestsCount > 0 ? AcadexColors.warning : Colors.teal,
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
    final theme = Theme.of(context);

    return AcadexCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
