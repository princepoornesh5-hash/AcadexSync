import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/department_analytics_models.dart';
import '../providers/department_analytics_providers.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class DepartmentAnalyticsScreen extends ConsumerStatefulWidget {
  const DepartmentAnalyticsScreen({super.key});

  @override
  ConsumerState<DepartmentAnalyticsScreen> createState() =>
      _DepartmentAnalyticsScreenState();
}

class _DepartmentAnalyticsScreenState extends ConsumerState<DepartmentAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(departmentAnalyticsFilterProvider);
    final overviewAsync = ref.watch(departmentOverviewProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AcadexBreakpoints.desktopMin;
    final horizontalPadding = screenWidth < 400 ? 12.0 : (isDesktop ? 24.0 : 16.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
                child: const AcadexPageHeader(
                  title: 'Department Analytics',
                  subtitle:
                      'Authoritative attendance records, course/section drilldowns, and student attendance alerts.',
                ),
              ),

              // 2. Cascading Context-Aware Filter Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildFilterBar(context, filter),
              ),
              const SizedBox(height: 12),

              // 3. Tab Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AcadexRadius.md),
                    border: Border.all(color: AcadexColors.hairline),
                    boxShadow: AcadexShadows.lightSm,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AcadexColors.primary,
                    unselectedLabelColor: AcadexColors.inkMuted,
                    indicatorColor: AcadexColors.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Courses'),
                      Tab(text: 'Sections'),
                      Tab(text: 'Subjects'),
                      Tab(text: 'Students'),
                      Tab(text: 'At-Risk Alerts'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(context, overviewAsync, horizontalPadding),
                    _buildCoursesTab(context, horizontalPadding),
                    _buildSectionsTab(context, horizontalPadding),
                    _buildSubjectsTab(context, horizontalPadding),
                    _buildStudentsTab(context, horizontalPadding),
                    _buildAtRiskTab(context, horizontalPadding),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // FILTER BAR (Section 6)
  // =========================================================================
  Widget _buildFilterBar(BuildContext context, DepartmentAnalyticsFilter filter) {
    final courses = ref.watch(availableCoursesFilterProvider);
    final semesters = ref.watch(availableSemestersFilterProvider);
    final sections = ref.watch(availableSectionsFilterProvider);
    final subjects = ref.watch(availableSubjectsFilterProvider);

    final hasActiveFilters = filter.courseId != null ||
        filter.semesterId != null ||
        filter.sectionId != null ||
        filter.subjectId != null ||
        filter.startDate != null ||
        filter.endDate != null;

    return AcadexCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(LucideIcons.filter, size: 16, color: AcadexColors.inkMuted),
            const SizedBox(width: 8),
            Text('Filters:', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
            const SizedBox(width: 8),

            // Course Dropdown
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: filter.courseId,
                hint: const Text('All Courses', style: TextStyle(fontSize: 12)),
                style: const TextStyle(fontSize: 12, color: AcadexColors.ink),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Courses')),
                  ...courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (val) {
                  ref.read(departmentAnalyticsFilterProvider.notifier).update(
                        (f) => f.copyWith(
                          courseId: () => val,
                          semesterId: () => null,
                          sectionId: () => null,
                          subjectId: () => null,
                        ),
                      );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Semester Dropdown
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: filter.semesterId,
                hint: const Text('All Semesters', style: TextStyle(fontSize: 12)),
                style: const TextStyle(fontSize: 12, color: AcadexColors.ink),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Semesters')),
                  ...semesters.map(
                    (s) => DropdownMenuItem(value: s.id, child: Text('Sem ${s.number}')),
                  ),
                ],
                onChanged: (val) {
                  ref.read(departmentAnalyticsFilterProvider.notifier).update(
                        (f) => f.copyWith(
                          semesterId: () => val,
                          sectionId: () => null,
                          subjectId: () => null,
                        ),
                      );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Section Dropdown
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: filter.sectionId,
                hint: const Text('All Sections', style: TextStyle(fontSize: 12)),
                style: const TextStyle(fontSize: 12, color: AcadexColors.ink),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Sections')),
                  ...sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (val) {
                  ref.read(departmentAnalyticsFilterProvider.notifier).update(
                        (f) => f.copyWith(sectionId: () => val),
                      );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Subject Dropdown
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: filter.subjectId,
                hint: const Text('All Subjects', style: TextStyle(fontSize: 12)),
                style: const TextStyle(fontSize: 12, color: AcadexColors.ink),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Subjects')),
                  ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (val) {
                  ref.read(departmentAnalyticsFilterProvider.notifier).update(
                        (f) => f.copyWith(subjectId: () => val),
                      );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Date Range Picker Button
            InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2025, 1, 1),
                  lastDate: DateTime(2030, 12, 31),
                  initialDateRange: filter.startDate != null && filter.endDate != null
                      ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
                      : null,
                );
                if (range != null) {
                  ref.read(departmentAnalyticsFilterProvider.notifier).update(
                        (f) => f.copyWith(
                          startDate: () => range.start,
                          endDate: () => range.end,
                        ),
                      );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AcadexRadius.sm),
                  border: Border.all(color: AcadexColors.hairline),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 14, color: AcadexColors.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      filter.startDate != null && filter.endDate != null
                          ? '${DateFormat('MM/dd').format(filter.startDate!)} - ${DateFormat('MM/dd').format(filter.endDate!)}'
                          : 'Date Range',
                      style: const TextStyle(fontSize: 12, color: AcadexColors.ink),
                    ),
                  ],
                ),
              ),
            ),

            if (hasActiveFilters) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ref.read(departmentAnalyticsFilterProvider.notifier).state =
                      const DepartmentAnalyticsFilter();
                  _searchController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AcadexRadius.sm),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.x, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text('Reset', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. OVERVIEW TAB (Section 5)
  // =========================================================================
  Widget _buildOverviewTab(
    BuildContext context,
    AsyncValue<DepartmentOverviewModel> overviewAsync,
    double horizontalPadding,
  ) {
    return overviewAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: AcadexErrorState(
          message: 'Error loading department overview: $err',
          onRetry: () => ref.refresh(departmentOverviewProvider),
        ),
      ),
      data: (overview) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top KPI Summary Cards Grid
              _buildOverviewKpiGrid(context, overview),
              const SizedBox(height: 20),

              // Attendance Trend Section
              const AcadexSectionHeader(title: 'Attendance Trends Over Time'),
              const SizedBox(height: 8),
              _buildTrendTimeline(context),
              const SizedBox(height: 20),

              // Course Breakdown Summary
              const AcadexSectionHeader(title: 'Attendance by Course'),
              const SizedBox(height: 8),
              if (overview.courseBreakdown.isEmpty)
                const AcadexEmptyState(
                  icon: LucideIcons.bookOpen,
                  title: 'No Course Data',
                  subtitle: 'No courses found for this department.',
                )
              else
                ...overview.courseBreakdown.map((c) => _buildCourseBreakdownTile(c)),
              const SizedBox(height: 20),

              // Section Breakdown Summary
              const AcadexSectionHeader(title: 'Attendance by Section'),
              const SizedBox(height: 8),
              if (overview.sectionBreakdown.isEmpty)
                const AcadexEmptyState(
                  icon: LucideIcons.layoutGrid,
                  title: 'No Section Data',
                  subtitle: 'No sections found for this department.',
                )
              else
                ...overview.sectionBreakdown.map((s) => _buildSectionBreakdownTile(s)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewKpiGrid(BuildContext context, DepartmentOverviewModel overview) {
    final width = MediaQuery.of(context).size.width;
    final isHealthy = overview.overallAttendancePercentage >= overview.atRiskThreshold;

    final kpis = [
      _KpiItem(
        label: 'Overall Attendance',
        value: '${overview.overallAttendancePercentage.toStringAsFixed(1)}%',
        icon: LucideIcons.percent,
        color: isHealthy ? AcadexColors.primary : Colors.red,
        caption: 'Dept Average',
      ),
      _KpiItem(
        label: 'Total Students',
        value: '${overview.totalStudents}',
        icon: LucideIcons.users,
        color: const Color(0xFF0284C7),
        caption: 'Enrolled',
      ),
      _KpiItem(
        label: 'Sessions Conducted',
        value: '${overview.totalSessions}',
        icon: LucideIcons.calendarCheck,
        color: const Color(0xFF0D9488),
        caption: '${overview.totalRecords} records',
      ),
      _KpiItem(
        label: 'Present Marks',
        value: '${overview.presentCount}',
        icon: LucideIcons.checkCircle2,
        color: const Color(0xFF16A34A),
        caption: '${overview.lateCount} late marks',
      ),
      _KpiItem(
        label: 'Absent Marks',
        value: '${overview.absentCount}',
        icon: LucideIcons.xCircle,
        color: Colors.red,
        caption: '${overview.excusedCount} excused',
      ),
      _KpiItem(
        label: 'At-Risk Students',
        value: '${overview.atRiskCount}',
        icon: LucideIcons.alertTriangle,
        color: overview.atRiskCount > 0 ? Colors.orange : AcadexColors.inkMuted,
        caption: '< ${overview.atRiskThreshold.toInt()}% threshold',
      ),
    ];

    final crossAxisCount = width >= 800 ? 3 : (width >= 500 ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: crossAxisCount == 1 ? 3.0 : 2.0,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return AcadexCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kpi.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(kpi.icon, size: 20, color: kpi.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      kpi.label,
                      style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kpi.value,
                      style: AcadexTypography.heading3(color: AcadexColors.ink),
                    ),
                    if (kpi.caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        kpi.caption!,
                        style: AcadexTypography.caption(color: AcadexColors.inkMuted)
                            .copyWith(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendTimeline(BuildContext context) {
    final trendsAsync = ref.watch(departmentTrendsProvider);

    return trendsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => AcadexErrorState(message: 'Failed to load trend timeline: $err'),
      data: (trends) {
        if (trends.isEmpty) {
          return const AcadexEmptyState(
            icon: LucideIcons.trendingUp,
            title: 'No Trend Data',
            subtitle: 'No attendance sessions recorded for the selected scope or period.',
          );
        }

        return AcadexCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Attendance Distribution',
                style: AcadexTypography.title(color: AcadexColors.ink),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: trends.map((t) {
                    final pct = t.attendancePercentage;
                    final isGood = pct >= 75.0;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isGood
                            ? AcadexColors.primary.withValues(alpha: 0.05)
                            : Colors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AcadexRadius.md),
                        border: Border.all(
                          color: isGood
                              ? AcadexColors.primary.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.label, style: const TextStyle(fontSize: 11, color: AcadexColors.inkMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isGood ? AcadexColors.primary : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${t.present}P / ${t.absent}A',
                            style: const TextStyle(fontSize: 10, color: AcadexColors.inkMuted),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseBreakdownTile(CourseBreakdownModel c) {
    final isGood = c.attendancePercentage >= 75.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AcadexCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.courseName, style: AcadexTypography.body(color: AcadexColors.ink).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${c.studentCount} students • ${c.sessionCount} sessions',
                    style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${c.attendancePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isGood ? AcadexColors.primary : Colors.red,
                  ),
                ),
                if (c.atRiskCount > 0)
                  Text(
                    '${c.atRiskCount} at risk',
                    style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionBreakdownTile(SectionBreakdownModel s) {
    final isGood = s.attendancePercentage >= 75.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AcadexCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.sectionName, style: AcadexTypography.body(color: AcadexColors.ink).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${s.studentCount} enrolled • ${s.sessionCount} sessions',
                    style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${s.attendancePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isGood ? AcadexColors.primary : Colors.red,
                  ),
                ),
                if (s.atRiskCount > 0)
                  Text(
                    '${s.atRiskCount} at risk',
                    style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. COURSES TAB (Section 7)
  // =========================================================================
  Widget _buildCoursesTab(BuildContext context, double horizontalPadding) {
    final coursesAsync = ref.watch(departmentCoursesProvider);

    return coursesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: AcadexErrorState(message: 'Error loading courses: $err')),
      data: (courses) {
        if (courses.isEmpty) {
          return const AcadexEmptyState(
            icon: LucideIcons.bookOpen,
            title: 'No Courses',
            subtitle: 'No course analytics available for the selected filters.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final c = courses[index];
            final isGood = c.attendancePercentage >= 75.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AcadexCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c.courseName,
                            style: AcadexTypography.title(color: AcadexColors.ink),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isGood
                                ? AcadexColors.primary.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AcadexRadius.sm),
                          ),
                          child: Text(
                            '${c.attendancePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isGood ? AcadexColors.primary : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text('Code: ${c.courseCode}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Students: ${c.studentCount}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Sessions: ${c.sessionCount}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Present: ${c.present}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Absent: ${c.absent}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        if (c.atRiskCount > 0)
                          Text(
                            'At Risk: ${c.atRiskCount}',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Filter to this course and jump to Sections tab
                          ref.read(departmentAnalyticsFilterProvider.notifier).update(
                                (f) => f.copyWith(
                                  courseId: () => c.courseId,
                                  semesterId: () => null,
                                  sectionId: () => null,
                                  subjectId: () => null,
                                ),
                              );
                          _tabController.animateTo(2); // Sections tab
                        },
                        icon: const Icon(LucideIcons.arrowRight, size: 14),
                        label: const Text('Drill into Sections', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 3. SECTIONS TAB (Section 8)
  // =========================================================================
  Widget _buildSectionsTab(BuildContext context, double horizontalPadding) {
    final sectionsAsync = ref.watch(departmentSectionsProvider);

    return sectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: AcadexErrorState(message: 'Error loading sections: $err')),
      data: (sections) {
        if (sections.isEmpty) {
          return const AcadexEmptyState(
            icon: LucideIcons.layoutGrid,
            title: 'No Sections',
            subtitle: 'No sections found for this course or department.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final s = sections[index];
            final isGood = s.attendancePercentage >= 75.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AcadexCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.sectionName, style: AcadexTypography.title(color: AcadexColors.ink)),
                              if (s.courseName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('${s.courseName} • Sem ${s.semesterNumber}',
                                    style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isGood
                                ? AcadexColors.primary.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AcadexRadius.sm),
                          ),
                          child: Text(
                            '${s.attendancePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isGood ? AcadexColors.primary : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text('Enrolled: ${s.enrolledStudents}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Sessions: ${s.totalSessions}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Present: ${s.present}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Absent: ${s.absent}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Late: ${s.late}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        if (s.atRiskStudents > 0)
                          Text(
                            'At Risk: ${s.atRiskStudents}',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Filter to this section and jump to Students tab
                          ref.read(departmentAnalyticsFilterProvider.notifier).update(
                                (f) => f.copyWith(
                                  sectionId: () => s.sectionId,
                                ),
                              );
                          _tabController.animateTo(4); // Students tab
                        },
                        icon: const Icon(LucideIcons.users, size: 14),
                        label: const Text('View Student Roster', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 4. SUBJECTS TAB (Section 9)
  // =========================================================================
  Widget _buildSubjectsTab(BuildContext context, double horizontalPadding) {
    final subjectsAsync = ref.watch(departmentSubjectsProvider);

    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: AcadexErrorState(message: 'Error loading subjects: $err')),
      data: (subjects) {
        if (subjects.isEmpty) {
          return const AcadexEmptyState(
            icon: LucideIcons.book,
            title: 'No Subjects',
            subtitle: 'No subjects found matching the filter scope.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final sub = subjects[index];
            final isGood = sub.attendancePercentage >= 75.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AcadexCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sub.subjectName, style: AcadexTypography.title(color: AcadexColors.ink)),
                              const SizedBox(height: 2),
                              Text('Code: ${sub.subjectCode} • ${sub.courseName}',
                                  style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isGood
                                ? AcadexColors.primary.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AcadexRadius.sm),
                          ),
                          child: Text(
                            '${sub.attendancePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isGood ? AcadexColors.primary : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text('Sessions: ${sub.sessionCount}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Present: ${sub.present}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        Text('Absent: ${sub.absent}', style: AcadexTypography.caption(color: AcadexColors.inkMuted)),
                        if (sub.assignedSections.isNotEmpty)
                          Text(
                            'Sections: ${sub.assignedSections.join(", ")}',
                            style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 5. STUDENTS TAB (Section 10)
  // =========================================================================
  Widget _buildStudentsTab(BuildContext context, double horizontalPadding) {
    final studentsAsync = ref.watch(departmentStudentsProvider);

    return Column(
      children: [
        // Search & Filter controls
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name, roll number...',
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AcadexRadius.sm),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    ref.read(departmentAnalyticsFilterProvider.notifier).update(
                          (f) => f.copyWith(search: () => val.isEmpty ? null : val),
                        );
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: AcadexErrorState(message: 'Error loading students: $err')),
            data: (result) {
              if (result.students.isEmpty) {
                return const AcadexEmptyState(
                  icon: LucideIcons.userX,
                  title: 'No Students Found',
                  subtitle: 'No enrolled students match the active department filters.',
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                itemCount: result.students.length,
                itemBuilder: (context, index) {
                  final s = result.students[index];
                  return _buildStudentAnalyticsCard(s);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 6. AT-RISK ALERTS TAB (Section 11)
  // =========================================================================
  Widget _buildAtRiskTab(BuildContext context, double horizontalPadding) {
    final atRiskStudentsAsync = ref.watch(departmentAtRiskStudentsProvider);

    return atRiskStudentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: AcadexErrorState(message: 'Error loading at-risk students: $err')),
      data: (result) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Header Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Attendance Shortage Warnings',
                            style: AcadexTypography.title(color: Colors.orange.shade900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Students below institutional threshold of ${result.threshold.toInt()}%. Immediate counseling or intervention recommended.',
                            style: AcadexTypography.caption(color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (result.students.isEmpty)
                const AcadexEmptyState(
                  icon: LucideIcons.checkCircle2,
                  title: 'No At-Risk Students',
                  subtitle: 'All enrolled students meet or exceed the attendance threshold!',
                )
              else
                ...result.students.map((s) => _buildStudentAnalyticsCard(s)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentAnalyticsCard(StudentAttendanceAnalyticsModel s) {
    final isAtRisk = s.isAtRisk;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AcadexCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.studentName, style: AcadexTypography.body(color: AcadexColors.ink).copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Roll: ${s.rollNumber.isNotEmpty ? s.rollNumber : "N/A"} • Adm: ${s.admissionNumber.isNotEmpty ? s.admissionNumber : "N/A"}',
                        style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAtRisk
                        ? Colors.red.withValues(alpha: 0.12)
                        : AcadexColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AcadexRadius.sm),
                  ),
                  child: Text(
                    '${s.overallAttendancePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isAtRisk ? Colors.red : AcadexColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${s.courseName} • Sem ${s.semesterNumber} • ${s.sectionName}',
              style: AcadexTypography.caption(color: AcadexColors.inkMuted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                Text('Present: ${s.present}', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                Text('Absent: ${s.absent}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                if (s.late > 0)
                  Text('Late: ${s.late}', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                if (s.excused > 0)
                  Text('Excused: ${s.excused}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                if (s.onDuty > 0)
                  Text('On Duty: ${s.onDuty}', style: const TextStyle(fontSize: 11, color: Colors.teal)),
                Text('Sessions: ${s.sessionsConsidered}', style: const TextStyle(fontSize: 11, color: AcadexColors.inkMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });
}
