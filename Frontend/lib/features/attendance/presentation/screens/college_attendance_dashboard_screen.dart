import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/college_attendance_providers.dart';
import '../widgets/college/college_summary_card.dart';
import '../widgets/college/department_comparison_card.dart';
import '../widgets/college/college_faculty_card.dart';
import '../widgets/college/college_shortage_card.dart';
import '../widgets/college/college_insight_card.dart';

class CollegeAttendanceDashboardScreen extends ConsumerWidget {
  const CollegeAttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        appBar: AppBar(
          backgroundColor: DashboardColors.surface,
          elevation: 0,
          title: const Text("College Attendance", style: TextStyle(color: DashboardColors.textPrimary, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: DashboardColors.primary,
            unselectedLabelColor: DashboardColors.textSecondary,
            indicatorColor: DashboardColors.primary,
            tabs: [
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (summary) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CollegeSummaryCard(summary: summary),
              const SizedBox(height: 24),
              const Text("Top Departments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
              const SizedBox(height: 12),
              _buildTopDepartmentsPreview(ref),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopDepartmentsPreview(WidgetRef ref) {
    final comparisonAsync = ref.watch(departmentComparisonProvider);
    return comparisonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox(),
      data: (comparisons) {
        // Show top 2
        return Column(
          children: comparisons.take(2).map((comp) {
            final index = comparisons.indexOf(comp);
            return DepartmentComparisonCard(comparison: comp, rank: index + 1);
          }).toList(),
        );
      },
    );
  }

  Widget _buildDepartmentsTab(WidgetRef ref) {
    final comparisonAsync = ref.watch(departmentComparisonProvider);
    
    return comparisonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (comparisons) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: comparisons.length,
          itemBuilder: (context, index) {
            return DepartmentComparisonCard(comparison: comparisons[index], rank: index + 1);
          },
        );
      },
    );
  }

  Widget _buildFacultyTab(WidgetRef ref) {
    final facultyAsync = ref.watch(collegeFacultyProvider);
    
    return facultyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (faculties) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (shortages) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (insights) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: insights.length,
          itemBuilder: (context, index) {
            return CollegeInsightCard(insight: insights[index]);
          },
        );
      },
    );
  }
}
