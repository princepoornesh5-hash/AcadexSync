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
          child: AcadexLoadingState.spinner(
            message: 'Loading faculty dashboard...',
          ),
        ),
        error: (err, _) => AcadexErrorState.fromError(
          error: err,
          title: 'Unable to load dashboard',
          retryLabel: 'Try Again',
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
              DashboardQuickActionsGrid(quickActions: dashboard.quickActions),

              // 4. Operational Alerts & Pending Actions
              if (dashboard.alerts.isNotEmpty)
                DashboardAlertsSection(alerts: dashboard.alerts),

              if (dashboard.pendingActions.isNotEmpty)
                DashboardPendingActionsSection(
                  pendingActions: dashboard.pendingActions,
                ),

              // 5. Faculty Operational Metrics (Compact Centered Tiles)
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Teaching & Evaluation Snapshot',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Faculty Instruction Scope',
              style: AcadexTypography.caption(
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
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
                  title: 'Assigned Classes',
                  value: '${summary.assignedClassesCount}',
                  subtitle: 'Teaching sections',
                  icon: LucideIcons.bookOpen,
                  color: AcadexColors.primary,
                  onTap: () => context.push('/timetable'),
                ),
                DashboardCompactTile(
                  title: 'Pending Reviews',
                  value: '${summary.submissionsAwaitingReview}',
                  subtitle: 'Awaiting grading',
                  icon: LucideIcons.fileSpreadsheet,
                  color: summary.submissionsAwaitingReview > 0
                      ? AcadexColors.warning
                      : AcadexColors.inkMuted,
                  onTap: () => context.push('/assignments'),
                ),
                DashboardCompactTile(
                  title: 'Pending Attendance',
                  value: '${summary.pendingAttendanceSessions}',
                  subtitle: 'Sessions to complete',
                  icon: LucideIcons.checkSquare,
                  color: summary.pendingAttendanceSessions > 0
                      ? AcadexColors.warning
                      : AcadexColors.inkMuted,
                  onTap: () => context.push('/attendance'),
                ),
                DashboardCompactTile(
                  title: 'Assessment Marks',
                  value: '${summary.pendingAssessmentMarks}',
                  subtitle: 'Marks pending entry',
                  icon: LucideIcons.penTool,
                  color: summary.pendingAssessmentMarks > 0
                      ? AcadexColors.error
                      : AcadexColors.inkMuted,
                  onTap: () => context.push('/assessments'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
