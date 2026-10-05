import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';
import '../providers/academic_providers.dart';
import '../../../attendance/domain/models/assigned_class.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';

/// Faculty-specific teaching portal (Prompt 3 Phase 6).
///
/// Gives faculty immediate, one-tap access to:
/// - My Teaching / Active Allocations
/// - Today's Class & Attendance
/// - Subject Workload & Students
/// - Timetable & Notes
class MyAssignmentsScreen extends ConsumerWidget {
  const MyAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final myAssignments = ref.watch(myFacultyAssignmentsProvider);
    final subMap = ref.watch(subjectMapProvider);
    final crsMap = ref.watch(courseMapProvider);
    final semMap = ref.watch(semesterMapProvider);
    final secMap = ref.watch(sectionMapProvider);
    final yearMap = ref.watch(academicYearMapProvider);

    // Watch students to compute enrolled student counts
    final studentsState = ref.watch(studentsProvider((sectionId: null, departmentId: null)));
    final students = studentsState.items;

    final totalClasses = myAssignments.length;
    final totalStudents = myAssignments.fold<int>(0, (sum, a) {
      return sum + students.where((s) => s.sectionId == a.sectionId && s.isActive).length;
    });
    final uniqueSubjects = myAssignments.map((a) => a.subjectId).toSet().length;

    return AcadexPageContainer(
      backgroundColor: Colors.transparent,
      maxWidth: 1400,
      scrollable: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcadexPageHeader(
                title: "My Teaching Assignments",
                subtitle: "Active courses, subjects, and sections allocated for your instruction.",
              ),

              // Operational Snapshot Bar (Phase 6)
              if (myAssignments.isNotEmpty) ...[
                AcadexCard(
                  isFlat: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      _buildSummaryItem(
                        icon: LucideIcons.bookOpen,
                        label: 'Allocated Classes',
                        value: '$totalClasses',
                        isDark: isDark,
                      ),
                      Container(height: 24, width: 1, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      _buildSummaryItem(
                        icon: LucideIcons.users,
                        label: 'Total Students',
                        value: '$totalStudents',
                        isDark: isDark,
                      ),
                      Container(height: 24, width: 1, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      _buildSummaryItem(
                        icon: LucideIcons.layers,
                        label: 'Subjects',
                        value: '$uniqueSubjects',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (myAssignments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 24),
                  child: Center(
                    child: AcadexEmptyState(
                      title: "No Active Teaching Assignments",
                      subtitle: "You currently have no classes or subjects allocated by your Head of Department or College Admin.",
                      icon: LucideIcons.bookOpen,
                    ),
                  ),
                )
              else if (isNarrow)
                // Narrow constraints: Single-column responsive card list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: myAssignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = myAssignments[i];
                    final sub = subMap[a.subjectId];
                    final crs = crsMap[a.courseId];
                    final sem = semMap[a.semesterId];
                    final sec = secMap[a.sectionId];
                    final yr = yearMap[a.academicYearId];
                    final studentCount = students.where((s) => s.sectionId == a.sectionId && s.isActive).length;

                    return _buildAssignmentCard(
                      context: context,
                      ref: ref,
                      a: a,
                      sub: sub,
                      crs: crs,
                      sem: sem,
                      sec: sec,
                      yr: yr,
                      studentCount: studentCount,
                      isDark: isDark,
                    );
                  },
                )
              else
                // Wide constraints: Adaptive 2 or 3 column grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: myAssignments.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 1050 ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth > 1050 ? 1.6 : 1.75,
                  ),
                  itemBuilder: (context, i) {
                    final a = myAssignments[i];
                    final sub = subMap[a.subjectId];
                    final crs = crsMap[a.courseId];
                    final sem = semMap[a.semesterId];
                    final sec = secMap[a.sectionId];
                    final yr = yearMap[a.academicYearId];
                    final studentCount = students.where((s) => s.sectionId == a.sectionId && s.isActive).length;

                    return _buildAssignmentCard(
                      context: context,
                      ref: ref,
                      a: a,
                      sub: sub,
                      crs: crs,
                      sem: sem,
                      sec: sec,
                      yr: yr,
                      studentCount: studentCount,
                      isDark: isDark,
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AcadexColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic a,
    required dynamic sub,
    required dynamic crs,
    required dynamic sem,
    required dynamic sec,
    required dynamic yr,
    required int studentCount,
    required bool isDark,
  }) {
    return AcadexCard(
      isFlat: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Subject Code Badge + Active Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Text(
                  sub?.code ?? 'SUBJECT',
                  style: const TextStyle(
                    color: AcadexColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusSm,
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: Text(
                  AcadexEntityFormatters.formatSectionLabel(sec?.name, rawId: a.sectionId, fallback: 'Assigned Section', compact: true),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
                ),
              ),
              const Spacer(),
              const AcadexBadge(
                label: "Active",
                variant: AcadexBadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Subject Title
          Text(
            AcadexEntityFormatters.formatSubjectLabel(sub?.name, code: sub?.code, rawId: a.subjectId),
            style: AcadexTypography.heading3(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(fontSize: 15.5, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // Academic Context
          Text(
            AcadexEntityFormatters.formatAcademicContext(
              course: crs?.name,
              semester: sem?.name,
              year: yr?.name,
            ),
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Enrolled Students chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.users, size: 12, color: AcadexColors.success),
                    const SizedBox(width: 4),
                    Text(
                      "$studentCount Students Enrolled",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: AcadexColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Action Toolbar
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(LucideIcons.clipboardCheck, size: 15, color: AcadexColors.primary),
                    label: const Text(
                      'Take Attendance',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AcadexColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      final assignedClass = AssignedClass(
                        id: a.id,
                        facultyAssignmentId: a.id,
                        subjectId: a.subjectId,
                        subjectName: AcadexEntityFormatters.formatSubjectLabel(sub?.name, code: sub?.code, rawId: a.subjectId),
                        sectionId: a.sectionId ?? '',
                        sectionName: AcadexEntityFormatters.formatSectionLabel(sec?.name, rawId: a.sectionId, fallback: 'Assigned Section', prefix: false),
                        semester: AcadexEntityFormatters.formatSemesterLabel(sem?.name, semesterNumber: sem?.semesterNumber, rawId: a.semesterId),
                        cohort: a.cohort,
                        academicStage: a.academicStage,
                        timeSlot: 'Regular Session',
                        date: DateTime.now(),
                      );
                      ref.read(activeClassProvider.notifier).state = assignedClass;
                      context.push('/attendance/mark');
                    },
                  ),
                ),
              ),
              IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: "Internal Assessment Marks",
                icon: const Icon(LucideIcons.award, size: 16, color: AcadexColors.primary),
                onPressed: () => context.push('/assessments/entry?sectionId=${a.sectionId}&subjectId=${a.subjectId}'),
              ),
              IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: "Coursework Assignments",
                icon: const Icon(LucideIcons.fileSpreadsheet, size: 16, color: AcadexColors.accentOrange),
                onPressed: () => context.push('/assignments'),
              ),
              IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: "View Timetable",
                icon: const Icon(LucideIcons.calendarDays, size: 16, color: AcadexColors.accentPurple),
                onPressed: () => context.push('/timetable'),
              ),
              IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: "Course Notes",
                icon: const Icon(LucideIcons.fileText, size: 16, color: AcadexColors.accentTeal),
                onPressed: () => context.push('/notes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
