import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../providers/academic_providers.dart';
import '../../../attendance/domain/models/assigned_class.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';

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

    // Watch all students to compute section student counts
    final studentsState = ref.watch(studentsProvider((sectionId: null, departmentId: null)));
    final students = studentsState.items;

    return AcadexPageContainer(
        backgroundColor: Colors.white,
        maxWidth: 1400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AcadexPageHeader(
              title: "My Teaching Assignments",
              subtitle: "Active courses, subjects, and sections allocated for your instruction.",
            ),
            const SizedBox(height: 24),

            if (myAssignments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: AcadexEmptyState(
                    title: "No Active Teaching Assignments",
                    subtitle: "You currently have no classes or subjects allocated by your Head of Department or College Admin.",
                    icon: LucideIcons.bookOpen,
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myAssignments.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 440,
                  mainAxisExtent: 270,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, i) {
                  final a = myAssignments[i];
                  final sub = subMap[a.subjectId];
                  final crs = crsMap[a.courseId];
                  final sem = semMap[a.semesterId];
                  final sec = secMap[a.sectionId];
                  final yr = yearMap[a.academicYearId];

                  final studentCount = students.where((s) => s.sectionId == a.sectionId && s.isActive).length;

                  return AcadexCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Subject Code Badge + Active Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AcadexColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AcadexRadius.sm),
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
                            AcadexBadge(
                              label: "Active",
                              variant: AcadexBadgeVariant.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Subject Title
                        Text(
                          sub?.name ?? a.subjectId,
                          style: AcadexTypography.title(color: theme.colorScheme.onSurface).copyWith(fontSize: 17),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Course & Context
                        Builder(
                          builder: (context) {
                            final parts = <String>[];
                            if (a.cohort != null && a.cohort!.isNotEmpty) parts.add(a.cohort!);
                            if (a.academicStage != null && a.academicStage!.isNotEmpty) parts.add(a.academicStage!);
                            if (sem?.name != null) parts.add(sem!.name);
                            if (yr?.name != null) parts.add(yr!.name);

                            return Text(
                              parts.isNotEmpty ? parts.join(' · ') : '${crs?.name ?? a.courseId} • ${sem?.name ?? a.semesterId} • ${yr?.name ?? a.academicYearId}',
                              style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Section & Student Count Meta Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                                borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                border: Border.all(
                                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.layoutGrid, size: 13, color: AcadexColors.accentOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Section ${sec?.name ?? a.sectionId}",
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                                borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                border: Border.all(
                                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.users, size: 13, color: AcadexColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$studentCount Students",
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Quick Action Buttons (Attendance, Assignments, Timetable, Notes)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: "Take Attendance Now",
                              icon: const Icon(LucideIcons.clipboardCheck, size: 18, color: AcadexColors.primary),
                              onPressed: () {
                                final assignedClass = AssignedClass(
                                  id: a.id,
                                  facultyAssignmentId: a.id,
                                  subjectId: a.subjectId,
                                  subjectName: sub?.name ?? a.subjectId,
                                  sectionId: a.sectionId ?? '',
                                  sectionName: sec?.name ?? (a.sectionId != null && a.sectionId!.isNotEmpty ? a.sectionId! : 'No Section'),
                                  semester: sem?.name ?? a.semesterId,
                                  cohort: a.cohort,
                                  academicStage: a.academicStage,
                                  timeSlot: 'Regular Session',
                                  date: DateTime.now(),
                                );
                                ref.read(activeClassProvider.notifier).state = assignedClass;
                                context.push('/attendance/mark');
                              },
                            ),
                            IconButton(
                              tooltip: "Internal Assessment Marks",
                              icon: const Icon(LucideIcons.award, size: 18, color: AcadexColors.primary),
                              onPressed: () => context.push('/assessments/entry?sectionId=${a.sectionId}&subjectId=${a.subjectId}'),
                            ),
                            IconButton(
                              tooltip: "Coursework Assignments",
                              icon: const Icon(LucideIcons.fileSpreadsheet, size: 18, color: AcadexColors.accentOrange),
                              onPressed: () => context.push('/assignments'),
                            ),
                            IconButton(
                              tooltip: "View Timetable",
                              icon: const Icon(LucideIcons.calendarDays, size: 18, color: AcadexColors.accentPurple),
                              onPressed: () => context.push('/timetable'),
                            ),
                            IconButton(
                              tooltip: "Course Notes",
                              icon: const Icon(LucideIcons.fileText, size: 18, color: AcadexColors.accentTeal),
                              onPressed: () => context.push('/notes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
  }
}
