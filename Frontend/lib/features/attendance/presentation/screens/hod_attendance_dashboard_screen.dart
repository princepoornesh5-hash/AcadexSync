import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/hod_attendance_providers.dart';
import '../widgets/hod/department_summary_card.dart';
import '../widgets/hod/faculty_completion_card.dart';
import '../widgets/hod/student_shortage_card.dart';
import '../widgets/hod/section_attendance_card.dart';

class HodAttendanceDashboardScreen extends ConsumerWidget {
  const HodAttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        appBar: AppBar(
          backgroundColor: DashboardColors.surface,
          elevation: 0,
          title: const Text("Department Attendance", style: TextStyle(color: DashboardColors.textPrimary, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: DashboardColors.primary,
            unselectedLabelColor: DashboardColors.textSecondary,
            indicatorColor: DashboardColors.primary,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Faculty"),
              Tab(text: "Shortages"),
              Tab(text: "Sections"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(ref),
            _buildFacultyTab(ref),
            _buildShortageTab(ref),
            _buildSectionTab(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(WidgetRef ref) {
    final summaryAsync = ref.watch(hodDepartmentSummaryProvider);
    
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (summary) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DepartmentSummaryCard(summary: summary),
              const SizedBox(height: 24),
              const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
              const SizedBox(height: 12),
              // Dummy actions
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionChip(LucideIcons.fileSpreadsheet, "Export Report"),
                  _buildActionChip(LucideIcons.mail, "Email Defaulters"),
                  _buildActionChip(LucideIcons.lock, "Lock All Drafts"),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacultyTab(WidgetRef ref) {
    final facultyAsync = ref.watch(hodFacultyCompletionProvider);
    
    return facultyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (faculties) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: faculties.length,
          itemBuilder: (context, index) {
            return FacultyCompletionCard(completion: faculties[index]);
          },
        );
      },
    );
  }

  Widget _buildShortageTab(WidgetRef ref) {
    final shortageAsync = ref.watch(hodStudentShortageProvider);
    
    return shortageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (shortages) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shortages.length,
          itemBuilder: (context, index) {
            return StudentShortageCard(shortage: shortages[index]);
          },
        );
      },
    );
  }

  Widget _buildSectionTab(WidgetRef ref) {
    final sectionAsync = ref.watch(hodSectionAttendanceProvider);
    
    return sectionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (sections) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            return SectionAttendanceCard(summary: sections[index]);
          },
        );
      },
    );
  }

  Widget _buildActionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DashboardColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
        ],
      ),
    );
  }
}
