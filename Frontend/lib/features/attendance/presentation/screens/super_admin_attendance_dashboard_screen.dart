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

class SuperAdminAttendanceDashboardScreen extends ConsumerWidget {
  const SuperAdminAttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        appBar: AppBar(
          backgroundColor: DashboardColors.surface,
          elevation: 0,
          title: const Text("Super Admin Attendance", style: TextStyle(color: DashboardColors.textPrimary, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: DashboardColors.primary,
            unselectedLabelColor: DashboardColors.textSecondary,
            indicatorColor: DashboardColors.primary,
            tabs: [
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (summary) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SuperAdminSummaryCard(summary: summary),
              const SizedBox(height: 24),
              const Text("Top Colleges", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
              const SizedBox(height: 12),
              _buildTopCollegesPreview(ref),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopCollegesPreview(WidgetRef ref) {
    final comparisonAsync = ref.watch(collegeComparisonProvider);
    return comparisonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox(),
      data: (comparisons) {
        // Show top 2
        return Column(
          children: comparisons.take(2).map((comp) {
            final index = comparisons.indexOf(comp);
            return CollegeComparisonCard(comparison: comp, rank: index + 1);
          }).toList(),
        );
      },
    );
  }

  Widget _buildCollegesTab(WidgetRef ref) {
    final comparisonAsync = ref.watch(collegeComparisonProvider);
    
    return comparisonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (comparisons) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: comparisons.length,
          itemBuilder: (context, index) {
            return CollegeComparisonCard(comparison: comparisons[index], rank: index + 1);
          },
        );
      },
    );
  }

  Widget _buildFacultyTab(WidgetRef ref) {
    final facultyAsync = ref.watch(superAdminFacultyProvider);
    
    return facultyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (faculties) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: faculties.length,
          itemBuilder: (context, index) {
            return SuperAdminFacultyCard(completion: faculties[index]);
          },
        );
      },
    );
  }

  Widget _buildShortagesTab(WidgetRef ref) {
    final shortageAsync = ref.watch(superAdminShortageProvider);
    
    return shortageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (shortages) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shortages.length,
          itemBuilder: (context, index) {
            return SuperAdminShortageCard(shortage: shortages[index]);
          },
        );
      },
    );
  }

  Widget _buildInsightsTab(WidgetRef ref) {
    final insightsAsync = ref.watch(superAdminInsightsProvider);
    
    return insightsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (insights) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: insights.length,
          itemBuilder: (context, index) {
            return SuperAdminInsightCard(insight: insights[index]);
          },
        );
      },
    );
  }

  Widget _buildHealthTab(WidgetRef ref) {
    final healthAsync = ref.watch(superAdminSystemHealthProvider);
    
    return healthAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (health) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SystemHealthCard(health: health),
            ],
          ),
        );
      },
    );
  }
}
