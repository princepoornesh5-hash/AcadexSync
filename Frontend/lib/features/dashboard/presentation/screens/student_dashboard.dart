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

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(homeDashboardProvider);
      },
      child: dashboardAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState(message: 'Loading your dashboard...'),
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
                // 1. Welcome & Greeting Area
                DashboardGreetingHeader(greeting: dashboard.greeting),

                // 2. Current Academic Context (StudentEnrollment)
                DashboardContextCard(
                  role: dashboard.role,
                  contextModel: dashboard.context,
                ),

                // 3. Important Alerts
                DashboardAlertsSection(alerts: dashboard.alerts),

                // 4. Pending Actions Requiring Attention
                DashboardPendingActionsSection(
                  pendingActions: dashboard.pendingActions,
                ),

                // 5. Today / Upcoming Schedule (Unified Calendar aggregation)
                DashboardUpcomingSection(upcoming: dashboard.upcoming),

                // 6. Quick Shortcuts Grid
                DashboardQuickActionsGrid(
                  quickActions: dashboard.quickActions,
                ),

                // 7. Academic Summary Metrics
                _buildStudentAcademicSummary(context, dashboard.summary),

                // 8. Recent Activity Feed
                DashboardRecentActivitySection(recent: dashboard.recent),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentAcademicSummary(
    BuildContext context,
    DashboardSummaryModel summary,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final attendanceText = summary.attendancePercentage != null
        ? '${summary.attendancePercentage!.toStringAsFixed(1)}%'
        : 'Not available';

    final resultText = summary.latestResultStatus == 'AVAILABLE'
        ? 'Available'
        : (summary.latestResultStatus == 'NOT_YET_PUBLISHED'
            ? 'Not yet published'
            : 'Not available');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Academic Snapshot',
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
                _buildSummaryTile(
                  context,
                  title: 'Attendance',
                  value: attendanceText,
                  subtitle: summary.attendancePercentage != null ? 'Semester Average' : 'No records yet',
                  icon: LucideIcons.checkSquare,
                  color: AcadexColors.primary,
                  isDark: isDark,
                ),
                _buildSummaryTile(
                  context,
                  title: 'Assignments',
                  value: '${summary.assignmentsCompleted} / ${summary.assignmentsCompleted + summary.assignmentsPending}',
                  subtitle: '${summary.assignmentsPending} pending task${summary.assignmentsPending == 1 ? '' : 's'}',
                  icon: LucideIcons.fileSpreadsheet,
                  color: Colors.teal,
                  isDark: isDark,
                ),
                _buildSummaryTile(
                  context,
                  title: 'Practicals',
                  value: '${summary.practicalsCompleted}',
                  subtitle: '${summary.practicalsScheduled} upcoming session${summary.practicalsScheduled == 1 ? '' : 's'}',
                  icon: LucideIcons.flaskConical,
                  color: Colors.purple,
                  isDark: isDark,
                ),
                _buildSummaryTile(
                  context,
                  title: 'Official Results',
                  value: resultText,
                  subtitle: 'Latest published term',
                  icon: LucideIcons.award,
                  color: Colors.amber[700]!,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryTile(
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
