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

class FacultyDashboard extends ConsumerWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(homeDashboardProvider);
      },
      child: dashboardAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState(message: 'Loading faculty dashboard...'),
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

              // 2. Current Teaching Context (FacultyAssignment)
              DashboardContextCard(
                role: dashboard.role,
                contextModel: dashboard.context,
              ),

              // 3. Role Quick Shortcuts (Immediate 8px gap below hero, matching HOD standard)
              const SizedBox(height: 8),
              DashboardQuickActionsGrid(
                quickActions: dashboard.quickActions,
              ),

              // 4. Operational Alerts & Pending Actions
              if (dashboard.alerts.isNotEmpty)
                DashboardAlertsSection(alerts: dashboard.alerts),

              if (dashboard.pendingActions.isNotEmpty)
                DashboardPendingActionsSection(
                  pendingActions: dashboard.pendingActions,
                ),

              // 5. Faculty Operational Metrics
              _buildFacultyOperationalSummary(context, dashboard.summary),

              // 6. Today / Upcoming Teaching Schedule
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

  Widget _buildFacultyOperationalSummary(
    BuildContext context,
    DashboardSummaryModel summary,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          'Teaching & Evaluation Snapshot',
          style: AcadexTypography.heading3(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
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
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
              children: [
                _buildMetricTile(
                  context,
                  title: 'Assigned Classes',
                  value: '${summary.assignedClassesCount}',
                  subtitle: 'Teaching sections',
                  icon: LucideIcons.bookOpen,
                  color: AcadexColors.primary,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Pending Reviews',
                  value: '${summary.submissionsAwaitingReview}',
                  subtitle: 'Awaiting grading',
                  icon: LucideIcons.fileSpreadsheet,
                  color: summary.submissionsAwaitingReview > 0 ? AcadexColors.warning : AcadexColors.inkMuted,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Pending Attendance',
                  value: '${summary.pendingAttendanceSessions}',
                  subtitle: 'Sessions to complete',
                  icon: LucideIcons.checkSquare,
                  color: summary.pendingAttendanceSessions > 0 ? AcadexColors.warning : AcadexColors.inkMuted,
                  isDark: isDark,
                ),
                _buildMetricTile(
                  context,
                  title: 'Assessment Marks',
                  value: '${summary.pendingAssessmentMarks}',
                  subtitle: 'Marks pending entry',
                  icon: LucideIcons.penTool,
                  color: summary.pendingAssessmentMarks > 0 ? AcadexColors.error : AcadexColors.inkMuted,
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
