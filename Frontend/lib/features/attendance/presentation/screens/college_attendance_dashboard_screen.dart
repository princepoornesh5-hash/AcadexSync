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
import '../../../../core/presentation/widgets/acadex_page_header.dart';

class CollegeAttendanceDashboardScreen extends ConsumerWidget {
  const CollegeAttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5,
      child: AcadexPageContainer(
        backgroundColor: Colors.white,
        scrollable: true,
        maxWidth: AcadexLayout.contentMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AcadexPageHeader(
              title: "College Attendance Overview",
              subtitle: "Institutional attendance monitoring, departmental metrics, and shortage tracking.",
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusLg,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
                boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AcadexColors.primary,
                unselectedLabelColor: AcadexColors.inkMuted,
                indicatorColor: AcadexColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "Overview"),
                  Tab(text: "Departments"),
                  Tab(text: "Faculty"),
                  Tab(text: "Shortages"),
                  Tab(text: "Insights"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 700,
              child: TabBarView(
                children: [
                  _buildOverviewTab(ref),
                  _buildDepartmentsTab(ref),
                  _buildFacultyTab(ref),
                  _buildShortageTab(ref),
                  _buildInsightsTab(ref),
                ],
              ),
            ),
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
        return SingleChildScrollView(
          child: CollegeSummaryCard(summary: summary),
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
        return ListView.builder(
          itemCount: depts.length,
          itemBuilder: (context, index) {
            return DepartmentComparisonCard(
              comparison: depts[index],
              rank: index + 1,
            );
          },
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
        return ListView.builder(
          itemCount: faculties.length,
          itemBuilder: (context, index) {
            return CollegeFacultyCard(completion: faculties[index]);
          },
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
        return ListView.builder(
          itemCount: shortages.length,
          itemBuilder: (context, index) {
            return CollegeShortageCard(shortage: shortages[index]);
          },
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
        return ListView.builder(
          itemCount: insights.length,
          itemBuilder: (context, index) {
            return CollegeInsightCard(insight: insights[index]);
          },
        );
      },
    );
  }
}
