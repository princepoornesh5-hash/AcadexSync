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
          child: AcadexLoadingState.spinner(
            message: 'Loading your dashboard...',
          ),
        ),
        error: (err, _) => AcadexErrorState(
          title: 'Unable to load dashboard',
          message: 'Unable to load your academic overview.',
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
              DashboardQuickActionsGrid(quickActions: dashboard.quickActions),

              // 4. Important Alerts & Pending Actions
              if (dashboard.alerts.isNotEmpty)
                DashboardAlertsSection(alerts: dashboard.alerts),

              if (dashboard.pendingActions.isNotEmpty)
                DashboardPendingActionsSection(
                  pendingActions: dashboard.pendingActions,
                ),

              // 5. Academic Summary Metrics (Compact Centered Tiles)
              _buildStudentAcademicSummary(context, dashboard.summary),

              // 6. Today / Upcoming Schedule (Unified Calendar aggregation)
              DashboardUpcomingSection(
                upcoming: dashboard.upcoming,
                emptyMessage: 'No classes or events scheduled right now.',
              ),

              // 7. Recent Activity Feed
              DashboardRecentActivitySection(
                recent: dashboard.recent,
                emptyMessage: "You're all caught up.",
              ),

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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Academic Snapshot',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Personal Academic Status',
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
                  title: 'Attendance',
                  value: attendanceText,
                  subtitle: summary.attendancePercentage != null
                      ? 'Semester Average'
                      : 'No records yet',
                  icon: LucideIcons.checkSquare,
                  color: AcadexColors.primary,
                  onTap: () => context.push('/attendance'),
                ),
                DashboardCompactTile(
                  title: 'Assignments',
                  value:
                      '${summary.assignmentsCompleted} / ${summary.assignmentsCompleted + summary.assignmentsPending}',
                  subtitle:
                      '${summary.assignmentsPending} pending task${summary.assignmentsPending == 1 ? '' : 's'}',
                  icon: LucideIcons.fileSpreadsheet,
                  color: Colors.teal,
                  onTap: () => context.push('/assignments'),
                ),
                DashboardCompactTile(
                  title: 'Practicals',
                  value: '${summary.practicalsCompleted}',
                  subtitle:
                      '${summary.practicalsScheduled} upcoming session${summary.practicalsScheduled == 1 ? '' : 's'}',
                  icon: LucideIcons.flaskConical,
                  color: Colors.purple,
                  onTap: () => context.push('/practicals'),
                ),
                DashboardCompactTile(
                  title: 'Official Results',
                  value: resultText,
                  subtitle: 'Latest published term',
                  icon: LucideIcons.award,
                  color: Colors.amber[700]!,
                  onTap: () => context.push('/academic-results'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
