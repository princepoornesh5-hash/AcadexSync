import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../domain/models/attendance_alert.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/department_attendance_comparison.dart';
import '../../domain/models/student_attendance_models.dart';
import '../providers/student_portal_providers.dart';

class StudentAttendancePortalScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const StudentAttendancePortalScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<StudentAttendancePortalScreen> createState() => _StudentAttendancePortalScreenState();
}

class _StudentAttendancePortalScreenState extends ConsumerState<StudentAttendancePortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _subjectSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(studentPortalSummaryProvider);
    final subjectsAsync = ref.watch(studentDetailedSubjectsProvider);
    final calendarAsync = ref.watch(studentAttendanceCalendarProvider);
    final insightsAsync = ref.watch(studentAttendanceInsightsProvider);
    final alertsAsync = ref.watch(studentPortalAlertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        scrollable: false,
        maxWidth: AcadexLayout.contentMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AcadexPageHeader(
              title: 'Student Attendance Portal',
              subtitle: 'Track your semester standing, subject metrics, attendance calendar, and recovery trajectories.',
              actions: [
                AcadexButton(
                  label: 'Official Reports',
                  icon: LucideIcons.fileText,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => context.push('/attendance/reports'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Navigation Tabs
            Container(
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AcadexColors.primary,
                indicatorWeight: 3,
                labelColor: AcadexColors.primary,
                unselectedLabelColor: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                labelStyle: AcadexTypography.bodySmall().copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AcadexTypography.bodySmall().copyWith(fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(icon: Icon(LucideIcons.layoutDashboard, size: 16), text: 'Dashboard'),
                  Tab(icon: Icon(LucideIcons.bookOpen, size: 16), text: 'Subject Attendance'),
                  Tab(icon: Icon(LucideIcons.calendarDays, size: 16), text: 'Attendance Calendar'),
                  Tab(icon: Icon(LucideIcons.sparkles, size: 16), text: 'Attendance Insights'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: Dashboard
                  _buildDashboardTab(context, summaryAsync, subjectsAsync, alertsAsync, isDark),

                  // Tab 1: Subject-Wise Attendance
                  _buildSubjectsTab(context, subjectsAsync, isDark),

                  // Tab 2: Attendance Calendar
                  _buildCalendarTab(context, calendarAsync, isDark),

                  // Tab 3: Attendance Insights
                  _buildInsightsTab(context, insightsAsync, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: DASHBOARD
  // ==========================================
  Widget _buildDashboardTab(
    BuildContext context,
    AsyncValue<StudentAttendanceAnalytics> summaryAsync,
    AsyncValue<List<StudentDetailedSubjectAttendance>> subjectsAsync,
    AsyncValue<List<AttendanceAlert>> alertsAsync,
    bool isDark,
  ) {
    return summaryAsync.when(
      loading: () => const Center(
        child: SingleChildScrollView(
          child: AcadexLoadingState(message: 'Calculating attendance standing...'),
        ),
      ),
      error: (err, _) => Center(
        child: SingleChildScrollView(
          child: AcadexErrorState(
            message: 'Unable to load attendance summary: $err',
            onRetry: () => ref.refresh(studentPortalSummaryProvider),
          ),
        ),
      ),
      data: (summary) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Intervention Banner (if any)
              if (summary.isLowAttendance) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AcadexColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AcadexColors.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low Attendance Notice (${summary.attendancePercentage.toStringAsFixed(1)}%)',
                              style: AcadexTypography.body(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your attendance is below the institutional 75% requirement. You must attend ${summary.recoverySessionsNeeded} consecutive classes to return to good standing.',
                              style: AcadexTypography.bodySmall(color: AcadexColors.error),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AcadexButton(
                        label: 'View Insights',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () => _tabController.animateTo(3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Metric Stat Cards Grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    'Overall Attendance',
                    '${summary.attendancePercentage.toStringAsFixed(1)}%',
                    summary.attendancePercentage >= 75 ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                    summary.attendancePercentage >= 75 ? AcadexColors.success : AcadexColors.error,
                    isDark,
                  ),
                  _buildStatCard(
                    'Classes Attended',
                    '${summary.presentCount} / ${summary.totalSessions}',
                    LucideIcons.userCheck,
                    AcadexColors.primary,
                    isDark,
                  ),
                  _buildStatCard(
                    'Classes Absent',
                    '${summary.absentCount}',
                    LucideIcons.userX,
                    summary.absentCount > 0 ? AcadexColors.error : AcadexColors.inkMuted,
                    isDark,
                  ),
                  _buildStatCard(
                    'Late Attendances',
                    '${summary.lateCount}',
                    LucideIcons.clock,
                    AcadexColors.warning,
                    isDark,
                  ),
                  _buildStatCard(
                    'Excused Leaves',
                    '${summary.excusedCount}',
                    LucideIcons.fileCheck,
                    AcadexColors.primary,
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Subjects Requiring Attention
              subjectsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (subjects) {
                  final lowSubjects = subjects.where((s) => s.isBelowThreshold).toList();
                  if (lowSubjects.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 18, color: AcadexColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Subjects Requiring Attention (${lowSubjects.length})',
                              style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...lowSubjects.map((s) => _buildSubjectCard(context, s, isDark)),
                      const SizedBox(height: 28),
                    ],
                  );
                },
              ),

              // Recent Attendance Activity Header & Action
              Row(
                children: [
                  const Icon(LucideIcons.calendarCheck, size: 18, color: AcadexColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick Subject Overview',
                      style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.animateTo(1),
                    child: const Text('View All →'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              subjectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading subjects: $err'),
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return const AcadexEmptyState(
                      title: 'No Subjects Enrolled',
                      subtitle: 'No academic course subjects found for the active semester.',
                    );
                  }

                  return Column(
                    children: subjects.take(3).map((s) => _buildSubjectCard(context, s, isDark)).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: SUBJECT-WISE ATTENDANCE
  // ==========================================
  Widget _buildSubjectsTab(
    BuildContext context,
    AsyncValue<List<StudentDetailedSubjectAttendance>> subjectsAsync,
    bool isDark,
  ) {
    return subjectsAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading subject attendance breakdown...'),
      error: (err, _) => AcadexErrorState(
        message: 'Failed to load subject attendance: $err',
        onRetry: () => ref.refresh(studentDetailedSubjectsProvider),
      ),
      data: (subjects) {
        final filtered = subjects.where((s) {
          if (_subjectSearchQuery.trim().isEmpty) return true;
          final q = _subjectSearchQuery.toLowerCase().trim();
          return s.subjectName.toLowerCase().contains(q) ||
              s.subjectCode.toLowerCase().contains(q) ||
              s.facultyName.toLowerCase().contains(q);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search subjects by name, code, or faculty...',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                filled: true,
                fillColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _subjectSearchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: AcadexEmptyState(
                        title: 'No Subjects Found',
                        subtitle: _subjectSearchQuery.isNotEmpty
                            ? 'No subjects matched your query "$_subjectSearchQuery".'
                            : 'No subjects recorded for this term.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        return _buildSubjectCard(context, s, isDark);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 2: ATTENDANCE CALENDAR
  // ==========================================
  Widget _buildCalendarTab(
    BuildContext context,
    AsyncValue<List<StudentAttendanceCalendarDay>> calendarAsync,
    bool isDark,
  ) {
    final selectedDate = ref.watch(studentSelectedCalendarDateProvider);
    final daySessions = ref.watch(studentSelectedDateSessionsProvider);

    return calendarAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading attendance calendar history...'),
      error: (err, _) => AcadexErrorState(
        message: 'Failed to load calendar: $err',
        onRetry: () => ref.refresh(studentAttendanceCalendarProvider),
      ),
      data: (days) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance History by Date',
                style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Select any recorded class date to view verified session records.',
                style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(height: 16),

              // Calendar Days List
              if (days.isEmpty)
                const AcadexEmptyState(
                  title: 'No Calendar Records',
                  subtitle: 'No attendance sessions have been conducted or verified yet.',
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: days.map((day) {
                    final isSelected = selectedDate != null &&
                        selectedDate.year == day.date.year &&
                        selectedDate.month == day.date.month &&
                        selectedDate.day == day.date.day;

                    final color = day.attendancePercentage >= 75
                        ? AcadexColors.success
                        : (day.attendancePercentage >= 50 ? AcadexColors.warning : AcadexColors.error);

                    return InkWell(
                      onTap: () {
                        ref.read(studentSelectedCalendarDateProvider.notifier).state = isSelected ? null : day.date;
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AcadexColors.primary.withValues(alpha: 0.15)
                              : (isDark ? AcadexColors.darkSurface : AcadexColors.surface),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AcadexColors.primary
                                : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${day.date.day}/${day.date.month}',
                              style: AcadexTypography.bodySmall(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.attendancePercentage.toStringAsFixed(0)}%',
                              style: AcadexTypography.caption(color: color).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${day.presentCount}/${day.totalClasses} att.',
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Selected Date Drill-Down Session List
              Row(
                children: [
                  const Icon(LucideIcons.listFilter, size: 18, color: AcadexColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    selectedDate == null
                        ? 'Recent Recorded Sessions'
                        : 'Sessions on ${selectedDate.toIso8601String().split('T').first}',
                    style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  ),
                  if (selectedDate != null) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref.read(studentSelectedCalendarDateProvider.notifier).state = null;
                      },
                      child: const Text('Show All'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              if (daySessions.isEmpty)
                const AcadexEmptyState(
                  title: 'No Sessions for Selected Date',
                  subtitle: 'No attendance records match the selected date.',
                )
              else
                ...daySessions.map((session) => _buildSessionTile(context, session, isDark)),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: ATTENDANCE INSIGHTS
  // ==========================================
  Widget _buildInsightsTab(
    BuildContext context,
    AsyncValue<StudentAttendanceInsights> insightsAsync,
    bool isDark,
  ) {
    return insightsAsync.when(
      loading: () => const AcadexLoadingState(message: 'Generating personalized insights...'),
      error: (err, _) => AcadexErrorState(
        message: 'Failed to compute insights: $err',
        onRetry: () => ref.refresh(studentAttendanceInsightsProvider),
      ),
      data: (insights) {
        final trendIcon = insights.trendDirection == TrendDirection.up
            ? LucideIcons.trendingUp
            : (insights.trendDirection == TrendDirection.down ? LucideIcons.trendingDown : LucideIcons.minus);

        final trendColor = insights.trendDirection == TrendDirection.up
            ? AcadexColors.success
            : (insights.trendDirection == TrendDirection.down ? AcadexColors.error : AcadexColors.warning);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High Level Insight Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(trendIcon, size: 20, color: trendColor),
                        const SizedBox(width: 8),
                        Text(
                          'Overall Term Trajectory: ${insights.trendDirection.name.toUpperCase()}',
                          style: AcadexTypography.title(color: trendColor).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: trendColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            insights.overallRiskLevel.name.toUpperCase(),
                            style: AcadexTypography.caption(color: trendColor).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      insights.isLowAttendance
                          ? 'You are currently in shortage standing. You need to attend ${insights.totalRecoveryNeeded} consecutive classes across affected subjects to reach the 75% target.'
                          : 'Your semester attendance is in good standing. Maintain consistency to remain eligible for term examinations.',
                      style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Best vs Lowest Performing Subjects
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Best Performing
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AcadexColors.success.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AcadexColors.success.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.award, size: 16, color: AcadexColors.success),
                              const SizedBox(width: 8),
                              Text(
                                'Strongest Subjects (>=85%)',
                                style: AcadexTypography.title(color: AcadexColors.success).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (insights.bestAttendanceSubjects.isEmpty)
                            Text(
                              'No subjects above 85% yet.',
                              style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                            )
                          else
                            ...insights.bestAttendanceSubjects.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.subjectName,
                                      style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                    ),
                                  ),
                                  Text(
                                    '${s.attendancePercentage.toStringAsFixed(1)}%',
                                    style: AcadexTypography.bodySmall(color: AcadexColors.success).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Lowest Performing
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AcadexColors.error.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AcadexColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.alertOctagon, size: 16, color: AcadexColors.error),
                              const SizedBox(width: 8),
                              Text(
                                'Low Standing (<75%)',
                                style: AcadexTypography.title(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (insights.lowestAttendanceSubjects.isEmpty)
                            Text(
                              'All subjects meet institutional standards (>=75%).',
                              style: AcadexTypography.caption(color: AcadexColors.success),
                            )
                          else
                            ...insights.lowestAttendanceSubjects.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.subjectName,
                                      style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                    ),
                                  ),
                                  Text(
                                    '${s.attendancePercentage.toStringAsFixed(1)}% (+${s.recoveryClassesNeeded} needed)',
                                    style: AcadexTypography.bodySmall(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recovery Simulator Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calculator, size: 18, color: AcadexColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Attendance Safety Margin & Recovery Simulator',
                          style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...insights.subjectRankings.map((s) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                s.subjectName,
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${s.attendancePercentage.toStringAsFixed(1)}%',
                                style: AcadexTypography.body(
                                  color: s.isBelowThreshold ? AcadexColors.error : AcadexColors.success,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                s.isBelowThreshold
                                    ? 'Requires ${s.recoveryClassesNeeded} consecutive classes'
                                    : 'Can miss up to ${s.marginClassesCanMiss} classes safely',
                                style: AcadexTypography.caption(
                                  color: s.isBelowThreshold ? AcadexColors.error : AcadexColors.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SHARED WIDGETS
  // ==========================================
  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AcadexTypography.heading2(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, StudentDetailedSubjectAttendance s, bool isDark) {
    final statusColor = s.isBelowThreshold
        ? AcadexColors.error
        : (s.attendancePercentage < 85 ? AcadexColors.warning : AcadexColors.success);

    return InkWell(
      onTap: () => context.push('/attendance/student/subject/${s.subjectId}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.subjectName,
                        style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.subjectCode} • ${s.facultyName}',
                        style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${s.attendancePercentage.toStringAsFixed(1)}%',
                    style: AcadexTypography.bodySmall(color: statusColor).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Attendance Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (s.attendancePercentage / 100.0).clamp(0.0, 1.0),
                backgroundColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),

            // Metrics breakdown row
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'Present: ${s.presentCount}',
                  style: AcadexTypography.caption(color: AcadexColors.success).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Absent: ${s.absentCount}',
                  style: AcadexTypography.caption(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Late: ${s.lateCount}',
                  style: AcadexTypography.caption(color: AcadexColors.warning).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Excused: ${s.excusedCount}',
                  style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Total: ${s.totalClasses}',
                  style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  s.isBelowThreshold
                      ? 'Need +${s.recoveryClassesNeeded} classes for 75%'
                      : 'Can miss up to ${s.marginClassesCanMiss} classes',
                  style: AcadexTypography.caption(
                    color: s.isBelowThreshold ? AcadexColors.error : AcadexColors.success,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View History',
                      style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight, size: 14, color: AcadexColors.primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, StudentAttendanceSessionSummary session, bool isDark) {
    final statusColor = session.status == AttendanceStatus.present
        ? AcadexColors.success
        : (session.status == AttendanceStatus.absent ? AcadexColors.error : AcadexColors.warning);

    return InkWell(
      onTap: () => context.push('/attendance/student/sessions/${session.sessionId}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                session.status.name.toUpperCase(),
                style: AcadexTypography.caption(color: statusColor).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.subjectName,
                    style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${session.timeSlot} • ${session.date.toIso8601String().split('T').first}',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16),
          ],
        ),
      ),
    );
  }
}
