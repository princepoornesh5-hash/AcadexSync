import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/hod_attendance_providers.dart';
import '../widgets/hod/department_summary_card.dart';
import '../widgets/hod/faculty_completion_card.dart';
import '../widgets/hod/student_shortage_card.dart';
import '../widgets/hod/section_attendance_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';

class HodAttendanceDashboardScreen extends ConsumerWidget {
  const HodAttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: AcadexPageContainer(
        backgroundColor: Colors.transparent,
        scrollable: true,
        maxWidth: AcadexLayout.contentMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AcadexPageHeader(
              title: "Department Attendance",
              subtitle: "Monitor departmental session completion, faculty compliance, and student shortage rosters.",
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
                  Tab(text: "Faculty Status"),
                  Tab(text: "Shortages"),
                  Tab(text: "Sections"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 700,
              child: TabBarView(
                children: [
                  _buildOverviewTab(ref, isDark),
                  _buildFacultyTab(ref),
                  _buildShortageTab(ref),
                  _buildSectionTab(ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(WidgetRef ref, bool isDark) {
    final summaryAsync = ref.watch(hodDepartmentSummaryProvider);
    
    return summaryAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading departmental attendance metrics..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load department summary: $err",
          onRetry: () => ref.refresh(hodDepartmentSummaryProvider),
        ),
      ),
      data: (summary) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DepartmentSummaryCard(summary: summary),
              const SizedBox(height: 28),
              Text(
                "QUICK ACTIONS",
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionChip(LucideIcons.fileSpreadsheet, "Export Attendance Report", isDark),
                  _buildActionChip(LucideIcons.mail, "Notify Defaulters", isDark),
                  _buildActionChip(LucideIcons.lock, "Lock Completed Sessions", isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacultyTab(WidgetRef ref) {
    final facultyAsync = ref.watch(hodFacultyCompletionProvider);
    
    return facultyAsync.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading faculty completion records..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load faculty status: $err",
          onRetry: () => ref.refresh(hodFacultyCompletionProvider),
        ),
      ),
      data: (faculties) {
        return ListView.builder(
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
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading critical shortage alerts..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load shortage roster: $err",
          onRetry: () => ref.refresh(hodStudentShortageProvider),
        ),
      ),
      data: (shortages) {
        return ListView.builder(
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
      loading: () => const Center(
        child: AcadexLoadingState(message: "Loading section-wise breakdown..."),
      ),
      error: (err, stack) => Center(
        child: AcadexErrorState(
          message: "Unable to load sections: $err",
          onRetry: () => ref.refresh(hodSectionAttendanceProvider),
        ),
      ),
      data: (sections) {
        return ListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            return SectionAttendanceCard(summary: sections[index]);
          },
        );
      },
    );
  }

  Widget _buildActionChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AcadexColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
