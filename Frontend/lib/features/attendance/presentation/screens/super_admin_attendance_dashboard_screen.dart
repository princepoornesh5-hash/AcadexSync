import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/super_admin_attendance_providers.dart';
import '../widgets/super_admin/super_admin_summary_card.dart';
import '../widgets/super_admin/college_comparison_card.dart';
import '../widgets/super_admin/system_health_card.dart';
import '../widgets/super_admin/super_admin_faculty_card.dart';
import '../widgets/super_admin/super_admin_shortage_card.dart';
import '../widgets/super_admin/super_admin_insight_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';

class SuperAdminAttendanceDashboardScreen extends ConsumerWidget {
  const SuperAdminAttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          title: Text(
            "Multi-Campus Attendance",
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
              Tab(text: "Colleges"),
              Tab(text: "Faculty"),
              Tab(text: "Students"),
              Tab(text: "Insights"),
              Tab(text: "Health"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(ref),
            _buildCollegesTab(ref),
            _buildFacultyTab(ref),
            _buildShortagesTab(ref),
            _buildInsightsTab(ref),
            _buildHealthTab(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(WidgetRef ref) {
    final summaryAsync = ref.watch(superAdminSummaryProvider);
    
    return summaryAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading platform overview..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load platform overview: $err",
          onRetry: () => ref.refresh(superAdminSummaryProvider),
        ),
      ),
      data: (summary) {
        return AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SuperAdminSummaryCard(summary: summary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollegesTab(WidgetRef ref) {
    final collegesAsync = ref.watch(collegeComparisonProvider);
    
    return collegesAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading college performance comparison..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load colleges: $err",
          onRetry: () => ref.refresh(collegeComparisonProvider),
        ),
      ),
      data: (colleges) {
        return AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: colleges.length,
            itemBuilder: (context, index) {
              return CollegeComparisonCard(
                comparison: colleges[index],
                rank: index + 1,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFacultyTab(WidgetRef ref) {
    final facultyAsync = ref.watch(superAdminFacultyProvider);
    
    return facultyAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading faculty tracking records..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load faculty: $err",
          onRetry: () => ref.refresh(superAdminFacultyProvider),
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
              return SuperAdminFacultyCard(completion: faculties[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildShortagesTab(WidgetRef ref) {
    final shortageAsync = ref.watch(superAdminShortageProvider);
    
    return shortageAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading cross-campus shortages..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load shortages: $err",
          onRetry: () => ref.refresh(superAdminShortageProvider),
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
              return SuperAdminShortageCard(shortage: shortages[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildInsightsTab(WidgetRef ref) {
    final insightsAsync = ref.watch(superAdminInsightsProvider);
    
    return insightsAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading platform insights..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load insights: $err",
          onRetry: () => ref.refresh(superAdminInsightsProvider),
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
              return SuperAdminInsightCard(insight: insights[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildHealthTab(WidgetRef ref) {
    final healthAsync = ref.watch(superAdminSystemHealthProvider);
    
    return healthAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Checking system telemetry..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load health metrics: $err",
          onRetry: () => ref.refresh(superAdminSystemHealthProvider),
        ),
      ),
      data: (health) {
        return AcadexPageContainer(
          maxWidth: AcadexLayout.contentMaxWidth,
          child: SystemHealthCard(health: health),
        );
      },
    );
  }
}
