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
          title: 'Unable to load your academic overview.',
          retryLabel: 'Try Again',
          onRetry: () => ref.invalidate(homeDashboardProvider),
        ),
        data: (dashboard) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome & Greeting Area
              DashboardGreetingHeader(greeting: dashboard.greeting),

              // 2. Current Academic Context (StudentEnrollment)
              DashboardContextCard(
                role: dashboard.role,
                contextModel: dashboard.context,
              ),

              // 3. Quick Shortcuts Grid (Immediate 8px gap below hero, matching HOD standard)
              const SizedBox(height: 8),
              DashboardQuickActionsGrid(
                quickActions: dashboard.quickActions,
              ),

              // 4. Important Alerts & Pending Actions
              if (dashboard.alerts.isNotEmpty)
                DashboardAlertsSection(alerts: dashboard.alerts),

              if (dashboard.pendingActions.isNotEmpty)
                DashboardPendingActionsSection(
                  pendingActions: dashboard.pendingActions,
                ),

              // 5. Academic Summary Metrics
              _buildStudentAcademicSummary(context, dashboard.summary),

              // 6. Today / Upcoming Schedule (Unified Calendar aggregation)
              DashboardUpcomingSection(upcoming: dashboard.upcoming),

              // 7. Recent Activity Feed
              DashboardRecentActivitySection(recent: dashboard.recent),

              const SizedBox(height: 16),
            ],
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
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= 768;
            final isNarrow = w < 380;
            final crossAxisCount = isDesktop ? 4 : 2;
            final childAspectRatio = isDesktop
                ? (w >= 1100 ? 2.8 : 2.4)
                : (isNarrow ? 1.7 : 1.85);

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
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
    return AcadexCard(
      isFlat: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(icon, size: 13, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
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
              ).copyWith(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
          ),
          Text(
            subtitle,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
