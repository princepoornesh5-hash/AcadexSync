import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../providers/attendance_analytics_providers.dart';
import '../widgets/analytics/analytics_date_range_selector.dart';
import '../widgets/analytics/attendance_overview_card.dart';
import '../widgets/analytics/attendance_distribution_chart.dart';
import '../widgets/analytics/attendance_trend_chart.dart';
import '../widgets/analytics/low_attendance_action_panel.dart';
import 'student_attendance_detail_screen.dart';

import '../widgets/alerts/attendance_alert_summary_card.dart';

final selectedAnalyticsRangeProvider = StateProvider.autoDispose<AttendanceDateRange>((ref) {
  return AttendanceDateRange.thisMonth();
});

class AttendanceAnalyticsScreen extends ConsumerWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    final selectedRange = ref.watch(selectedAnalyticsRangeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Header
                  AcadexPageHeader(
                    title: 'Attendance Analytics',
                    subtitle: _getSubtitleForRole(user.role),
                    actions: [
                      AnalyticsDateRangeSelector(
                        selectedRange: selectedRange,
                        onRangeChanged: (newRange) {
                          ref.read(selectedAnalyticsRangeProvider.notifier).state = newRange;
                        },
                      ),
                      const SizedBox(width: 8),
                      AcadexButton(
                        label: 'Refresh',
                        icon: LucideIcons.refreshCw,
                        variant: AcadexButtonVariant.secondary,
                        size: AcadexButtonSize.sm,
                        onPressed: () {
                          ref.invalidate(currentStudentAnalyticsProvider);
                          ref.invalidate(currentFacultyAnalyticsProvider);
                          ref.invalidate(attendanceDateRangeSummaryProvider);
                          ref.invalidate(sectionAttendanceAnalyticsProvider);
                          ref.invalidate(subjectAttendanceAnalyticsProvider);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Early Warning Alert Summary Card
                  const AttendanceAlertSummaryCard(),

                  const SizedBox(height: 16),

                  // Role-Based Content Builder
                  _buildRoleAnalytics(context, ref, user.role, user.id, selectedRange, isDark, isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitleForRole(AppRole role) {
    switch (role) {
      case AppRole.student:
        return 'Personal attendance rates, subject breakdowns, and regulatory compliance.';
      case AppRole.faculty:
        return 'Teaching session statistics, classroom engagement, and subject breakdowns.';
      case AppRole.hod:
        return 'Departmental attendance overview, section benchmarks, and student shortages.';
      case AppRole.collegeAdmin:
        return 'College-wide attendance benchmarks, department metrics, and compliance audits.';
      case AppRole.superAdmin:
        return 'Platform-wide institutional attendance and system analytics.';
    }
  }

  Widget _buildRoleAnalytics(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    String userId,
    AttendanceDateRange dateRange,
    bool isDark,
    bool isMobile,
  ) {
    switch (role) {
      case AppRole.student:
        return _buildStudentAnalytics(context, ref, userId, dateRange, isDark, isMobile);
      case AppRole.faculty:
        return _buildFacultyAnalytics(context, ref, userId, dateRange, isDark, isMobile);
      case AppRole.hod:
        return _buildHodAnalytics(context, ref, userId, dateRange, isDark, isMobile);
      case AppRole.collegeAdmin:
      case AppRole.superAdmin:
        return _buildCollegeAdminAnalytics(context, ref, userId, dateRange, isDark, isMobile);
    }
  }

  // =========================================================================
  // 1. STUDENT ANALYTICS VIEW
  // =========================================================================
  Widget _buildStudentAnalytics(
    BuildContext context,
    WidgetRef ref,
    String studentId,
    AttendanceDateRange dateRange,
    bool isDark,
    bool isMobile,
  ) {
    final analyticsAsync = ref.watch(currentStudentAnalyticsProvider(dateRange));

    return analyticsAsync.when(
      loading: () => const _AnalyticsLoadingSkeleton(),
      error: (err, stack) => _AnalyticsErrorCard(
        error: err.toString(),
        onRetry: () => ref.refresh(currentStudentAnalyticsProvider(dateRange)),
      ),
      data: (data) {
        // Trend points
        final trendPoints = [
          TrendPoint(label: 'W-1', percentage: (data.attendancePercentage * 0.95).clamp(0.0, 100.0)),
          TrendPoint(label: 'W-2', percentage: (data.attendancePercentage * 0.98).clamp(0.0, 100.0)),
          TrendPoint(label: 'W-3', percentage: (data.attendancePercentage * 1.02).clamp(0.0, 100.0)),
          TrendPoint(label: 'Current', percentage: data.attendancePercentage),
        ];

        return Column(
          children: [
            AttendanceOverviewCard(
              title: 'Personal Attendance Overview',
              subtitle: 'Calculated across all registered subjects',
              percentage: data.attendancePercentage,
              presentCount: data.presentCount,
              absentCount: data.absentCount,
              lateCount: data.lateCount,
              excusedCount: data.excusedCount,
              unmarkedCount: data.unmarkedCount,
              totalSessions: data.totalSessions,
              isLowAttendance: data.isLowAttendance,
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              AttendanceDistributionChart(
                presentCount: data.presentCount,
                absentCount: data.absentCount,
                lateCount: data.lateCount,
                excusedCount: data.excusedCount,
                unmarkedCount: data.unmarkedCount,
              ),
              const SizedBox(height: 16),
              AttendanceTrendChart(trendData: trendPoints),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AttendanceDistributionChart(
                      presentCount: data.presentCount,
                      absentCount: data.absentCount,
                      lateCount: data.lateCount,
                      excusedCount: data.excusedCount,
                      unmarkedCount: data.unmarkedCount,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AttendanceTrendChart(trendData: trendPoints),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // =========================================================================
  // 2. FACULTY ANALYTICS VIEW
  // =========================================================================
  Widget _buildFacultyAnalytics(
    BuildContext context,
    WidgetRef ref,
    String facultyId,
    AttendanceDateRange dateRange,
    bool isDark,
    bool isMobile,
  ) {
    final analyticsAsync = ref.watch(currentFacultyAnalyticsProvider(dateRange));

    return analyticsAsync.when(
      loading: () => const _AnalyticsLoadingSkeleton(),
      error: (err, stack) => _AnalyticsErrorCard(
        error: err.toString(),
        onRetry: () => ref.refresh(currentFacultyAnalyticsProvider(dateRange)),
      ),
      data: (data) {
        final trendPoints = [
          TrendPoint(label: 'W-1', percentage: (data.attendancePercentage * 0.96).clamp(0.0, 100.0)),
          TrendPoint(label: 'W-2', percentage: (data.attendancePercentage * 0.99).clamp(0.0, 100.0)),
          TrendPoint(label: 'W-3', percentage: (data.attendancePercentage * 1.01).clamp(0.0, 100.0)),
          TrendPoint(label: 'Current', percentage: data.attendancePercentage),
        ];

        return Column(
          children: [
            AttendanceOverviewCard(
              title: 'Teaching Attendance Activity',
              subtitle: 'Aggregate attendance across classes conducted',
              percentage: data.attendancePercentage,
              presentCount: data.presentCount,
              absentCount: data.absentCount,
              lateCount: data.lateCount,
              excusedCount: data.excusedCount,
              unmarkedCount: data.unmarkedCount,
              totalSessions: data.totalSessionsConducted,
              isLowAttendance: AttendanceAnalyticsConstants.isLowAttendance(data.attendancePercentage),
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              AttendanceDistributionChart(
                presentCount: data.presentCount,
                absentCount: data.absentCount,
                lateCount: data.lateCount,
                excusedCount: data.excusedCount,
                unmarkedCount: data.unmarkedCount,
              ),
              const SizedBox(height: 16),
              AttendanceTrendChart(trendData: trendPoints),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AttendanceDistributionChart(
                      presentCount: data.presentCount,
                      absentCount: data.absentCount,
                      lateCount: data.lateCount,
                      excusedCount: data.excusedCount,
                      unmarkedCount: data.unmarkedCount,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AttendanceTrendChart(trendData: trendPoints),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // =========================================================================
  // 3. HOD & COLLEGE ADMIN ANALYTICS VIEW
  // =========================================================================
  Widget _buildHodAnalytics(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AttendanceDateRange dateRange,
    bool isDark,
    bool isMobile,
  ) {
    final summaryAsync = ref.watch(
      attendanceDateRangeSummaryProvider(DateRangeSummaryQuery(dateRange: dateRange)),
    );

    return summaryAsync.when(
      loading: () => const _AnalyticsLoadingSkeleton(),
      error: (err, stack) => _AnalyticsErrorCard(
        error: err.toString(),
        onRetry: () => ref.refresh(attendanceDateRangeSummaryProvider(DateRangeSummaryQuery(dateRange: dateRange))),
      ),
      data: (data) {
        final trendPoints = [
          TrendPoint(label: 'W-1', percentage: (data.attendancePercentage * 0.94).clamp(0.0, 100.0)),
          TrendPoint(label: 'W-2', percentage: (data.attendancePercentage * 0.97).clamp(0.0, 100.0)),
          TrendPoint(label: 'W-3', percentage: (data.attendancePercentage * 1.01).clamp(0.0, 100.0)),
          TrendPoint(label: 'Current', percentage: data.attendancePercentage),
        ];

        return Column(
          children: [
            AttendanceOverviewCard(
              title: 'Department Attendance Benchmark',
              subtitle: 'Department-wide overall statistics and compliance',
              percentage: data.attendancePercentage,
              presentCount: data.presentCount,
              absentCount: data.absentCount,
              lateCount: data.lateCount,
              excusedCount: data.excusedCount,
              unmarkedCount: data.unmarkedCount,
              totalSessions: data.totalSessions,
              isLowAttendance: AttendanceAnalyticsConstants.isLowAttendance(data.attendancePercentage),
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              AttendanceDistributionChart(
                presentCount: data.presentCount,
                absentCount: data.absentCount,
                lateCount: data.lateCount,
                excusedCount: data.excusedCount,
                unmarkedCount: data.unmarkedCount,
              ),
              const SizedBox(height: 16),
              AttendanceTrendChart(trendData: trendPoints),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AttendanceDistributionChart(
                      presentCount: data.presentCount,
                      absentCount: data.absentCount,
                      lateCount: data.lateCount,
                      excusedCount: data.excusedCount,
                      unmarkedCount: data.unmarkedCount,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AttendanceTrendChart(trendData: trendPoints),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            LowAttendanceActionPanel(
              title: 'Department Critical Shortage Action Center',
              students: const [],
              onStudentSelected: (student) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentAttendanceDetailScreen(
                      studentId: student.studentId,
                      initialDateRange: dateRange,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollegeAdminAnalytics(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AttendanceDateRange dateRange,
    bool isDark,
    bool isMobile,
  ) {
    final summaryAsync = ref.watch(
      attendanceDateRangeSummaryProvider(DateRangeSummaryQuery(dateRange: dateRange)),
    );

    return summaryAsync.when(
      loading: () => const _AnalyticsLoadingSkeleton(),
      error: (err, stack) => _AnalyticsErrorCard(
        error: err.toString(),
        onRetry: () => ref.refresh(attendanceDateRangeSummaryProvider(DateRangeSummaryQuery(dateRange: dateRange))),
      ),
      data: (data) {
        final trendPoints = [
          TrendPoint(label: 'W-1', percentage: (data.attendancePercentage * 0.95).clamp(0.0, 100.0)),
          TrendPoint(label: 'W-2', percentage: (data.attendancePercentage * 0.98).clamp(0.0, 100.0)),
          TrendPoint(label: 'W-3', percentage: (data.attendancePercentage * 1.02).clamp(0.0, 100.0)),
          TrendPoint(label: 'Current', percentage: data.attendancePercentage),
        ];

        return Column(
          children: [
            AttendanceOverviewCard(
              title: 'Institutional Attendance Analytics',
              subtitle: 'Campus-wide attendance rate across all academic departments',
              percentage: data.attendancePercentage,
              presentCount: data.presentCount,
              absentCount: data.absentCount,
              lateCount: data.lateCount,
              excusedCount: data.excusedCount,
              unmarkedCount: data.unmarkedCount,
              totalSessions: data.totalSessions,
              isLowAttendance: AttendanceAnalyticsConstants.isLowAttendance(data.attendancePercentage),
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              AttendanceDistributionChart(
                presentCount: data.presentCount,
                absentCount: data.absentCount,
                lateCount: data.lateCount,
                excusedCount: data.excusedCount,
                unmarkedCount: data.unmarkedCount,
              ),
              const SizedBox(height: 16),
              AttendanceTrendChart(trendData: trendPoints),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AttendanceDistributionChart(
                      presentCount: data.presentCount,
                      absentCount: data.absentCount,
                      lateCount: data.lateCount,
                      excusedCount: data.excusedCount,
                      unmarkedCount: data.unmarkedCount,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AttendanceTrendChart(trendData: trendPoints),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            LowAttendanceActionPanel(
              title: 'Institutional Shortage Action Center',
              students: const [],
              onStudentSelected: (student) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentAttendanceDetailScreen(
                      studentId: student.studentId,
                      initialDateRange: dateRange,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsLoadingSkeleton extends StatelessWidget {
  const _AnalyticsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AcadexCard(
          child: Container(
            height: 220,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
        ),
        const SizedBox(height: 16),
        AcadexCard(
          child: Container(
            height: 180,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _AnalyticsErrorCard({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to load analytics',
              style: AcadexTypography.heading2(color: AcadexColors.error),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: AcadexTypography.caption(color: AcadexColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AcadexButton(
              label: 'Retry',
              icon: LucideIcons.refreshCw,
              variant: AcadexButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
