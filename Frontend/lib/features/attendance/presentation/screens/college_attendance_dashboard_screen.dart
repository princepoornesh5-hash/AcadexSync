import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/college_attendance_providers.dart';
import '../widgets/college/college_summary_card.dart';
import '../widgets/college/department_comparison_card.dart';
import '../widgets/college/college_faculty_card.dart';
import '../widgets/college/college_shortage_card.dart';
import '../widgets/college/college_insight_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';

class CollegeAttendanceDashboardScreen extends ConsumerWidget {
  const CollegeAttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          title: Text(
            "College Attendance Overview",
            style: AcadexTypography.title(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AcadexColors.primary,
            unselectedLabelColor: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            indicatorColor: AcadexColors.primary,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(text: "Overview"),
              Tab(text: "Departments"),
              Tab(text: "Faculty"),
              Tab(text: "Shortages"),
              Tab(text: "Insights"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(ref),
            _buildDepartmentsTab(ref),
            _buildFacultyTab(ref),
            _buildShortageTab(ref),
            _buildInsightsTab(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(WidgetRef ref) {
    final summaryAsync = ref.watch(collegeSummaryProvider);
    
    return summaryAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading college-wide attendance metrics..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load college metrics: $err",
          onRetry: () => ref.refresh(collegeSummaryProvider),
        ),
      ),
      data: (summary) {
        return AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CollegeSummaryCard(summary: summary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepartmentsTab(WidgetRef ref) {
    final deptsAsync = ref.watch(departmentComparisonProvider);
    
    return deptsAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Comparing departmental metrics..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load comparison: $err",
          onRetry: () => ref.refresh(departmentComparisonProvider),
        ),
      ),
      data: (depts) {
        return AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: depts.length,
            itemBuilder: (context, index) {
              return DepartmentComparisonCard(
                comparison: depts[index],
                rank: index + 1,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFacultyTab(WidgetRef ref) {
    final facultyAsync = ref.watch(collegeFacultyProvider);
    
    return facultyAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading faculty status..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load faculty: $err",
          onRetry: () => ref.refresh(collegeFacultyProvider),
        ),
      ),
      data: (faculties) {
        return AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: faculties.length,
            itemBuilder: (context, index) {
              return CollegeFacultyCard(completion: faculties[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildShortageTab(WidgetRef ref) {
    final shortageAsync = ref.watch(collegeShortageProvider);
    
    return shortageAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading shortage alerts..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load shortage roster: $err",
          onRetry: () => ref.refresh(collegeShortageProvider),
        ),
      ),
      data: (shortages) {
        return AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shortages.length,
            itemBuilder: (context, index) {
              return CollegeShortageCard(shortage: shortages[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildInsightsTab(WidgetRef ref) {
    final insightsAsync = ref.watch(collegeInsightsProvider);
    
    return insightsAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Generating attendance insights..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load insights: $err",
          onRetry: () => ref.refresh(collegeInsightsProvider),
        ),
      ),
      data: (insights) {
        return AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              return CollegeInsightCard(insight: insights[index]);
            },
          ),
        );
      },
    );
  }
}
