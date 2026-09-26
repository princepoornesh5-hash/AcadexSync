import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../widgets/faculty_assignment_dialog.dart';
import '../utils/academic_prerequisite_guard.dart';

class FacultyAssignmentsManagementScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  final String? initialCourseId;
  final String? initialSemesterId;
  final String? initialSectionId;

  const FacultyAssignmentsManagementScreen({
    super.key,
    this.initialSubjectId,
    this.initialCourseId,
    this.initialSemesterId,
    this.initialSectionId,
  });

  @override
  ConsumerState<FacultyAssignmentsManagementScreen> createState() => _FacultyAssignmentsManagementScreenState();
}

class _FacultyAssignmentsManagementScreenState extends ConsumerState<FacultyAssignmentsManagementScreen> {
  String _searchQuery = '';
  String? _filterDepartmentId;
  String? _filterCourseId;
  String? _filterSemesterId;
  String? _filterSectionId;
  String? _filterFacultyId;
  String? _filterSubjectId;
  String? _filterAcademicYearId;
  bool _filterActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _filterSubjectId = widget.initialSubjectId;
    _filterCourseId = widget.initialCourseId;
    _filterSemesterId = widget.initialSemesterId;
    _filterSectionId = widget.initialSectionId;
  }

  void _openAssignmentDialog({Faculty? faculty}) {
    final courses = ref.read(coursesProvider).valueOrNull ?? [];
    final semesters = ref.read(semestersProvider).valueOrNull ?? [];
    final sections = ref.read(sectionsProvider).valueOrNull ?? [];
    final subjects = ref.read(subjectsProvider).valueOrNull ?? [];
    final faculties = ref.read(facultyProvider(null)).items;

    final check = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
      courses: courses,
      semesters: semesters,
      sections: sections,
      subjects: subjects,
      faculties: faculties,
    );

    if (!check.isSatisfied) {
      AcademicPrerequisiteGuard.showBlockerDialog(context, check);
      return;
    }

    FacultyAssignmentDialog.show(
      context,
      faculty: faculty,
      initialCourseId: _filterCourseId,
      initialSemesterId: _filterSemesterId,
      initialSectionId: _filterSectionId,
      initialSubjectId: _filterSubjectId,
      initialAcademicYearId: _filterAcademicYearId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isHod = currentUser?.role == AppRole.hod;
    final hodDeptId = currentUser?.departmentId;

    if (isHod && hodDeptId != null && hodDeptId.isNotEmpty && _filterDepartmentId == null) {
      _filterDepartmentId = hodDeptId;
    }

    final assignmentsAsync = ref.watch(facultyAssignmentsProvider);
    final deptMap = ref.watch(departmentMapProvider);
    final courseMap = ref.watch(courseMapProvider);
    final semMap = ref.watch(semesterMapProvider);
    final secMap = ref.watch(sectionMapProvider);
    final subMap = ref.watch(subjectMapProvider);
    final yearMap = ref.watch(academicYearMapProvider);

    final departments = ref.watch(departmentsProvider).valueOrNull ?? [];
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
    final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final academicYears = ref.watch(academicYearsProvider).valueOrNull ?? [];
    final facultyList = ref.watch(facultyProvider(null)).items;

    // Cascading options
    final filteredCourses = _filterDepartmentId == null
        ? courses
        : courses.where((c) => c.departmentId == _filterDepartmentId).toList();

    final filteredSemesters = _filterCourseId == null
        ? semesters
        : semesters.where((s) => s.courseId == _filterCourseId).toList();

    final filteredSections = _filterSemesterId == null
        ? sections
        : sections.where((sec) => sec.semesterId == _filterSemesterId).toList();

    final filteredSubjects = _filterSemesterId == null
        ? (_filterDepartmentId == null ? subjects : subjects.where((sub) => sub.departmentId == _filterDepartmentId).toList())
        : subjects.where((sub) => sub.semesterId == _filterSemesterId).toList();

    final filteredFaculty = facultyList.where((f) {
      if (isHod && hodDeptId != null && hodDeptId.isNotEmpty) {
        return f.departmentId == hodDeptId;
      }
      if (_filterDepartmentId != null && _filterDepartmentId!.isNotEmpty) {
        return f.departmentId == _filterDepartmentId || f.departmentId.isEmpty;
      }
      return true;
    }).toList();

    final isMobile = AcadexBreakpoints.isMobile(context);

    return AcadexPageContainer(
        backgroundColor: Colors.transparent,
        maxWidth: 1600,
        scrollable: isMobile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            AcadexPageHeader(
              title: "Faculty Assignments",
              subtitle: "Manage subject and section teaching assignments.",
              actions: [
                AcadexButton(
                  label: "Assign Faculty",
                  icon: LucideIcons.userPlus,
                  onPressed: () => _openAssignmentDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search and Filter Controls
            AcadexCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search by faculty name, subject, or code...",
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, filterConstraints) {
                      final isNarrow = filterConstraints.maxWidth < 700;
                      if (isNarrow) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                if (!isHod) ...[
                                  Expanded(
                                    child: DropdownButtonFormField<String?>(
                                      isExpanded: true,
                                      key: ValueKey('filter_dept_$_filterDepartmentId'),
                                      decoration: const InputDecoration(labelText: "Department", isDense: true),
                                      initialValue: _filterDepartmentId,
                                      items: [
                                        const DropdownMenuItem(value: null, child: Text("All Depts", overflow: TextOverflow.ellipsis)),
                                        ...departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _filterDepartmentId = val;
                                          _filterCourseId = null;
                                          _filterSemesterId = null;
                                          _filterSectionId = null;
                                          _filterSubjectId = null;
                                          _filterFacultyId = null;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    key: ValueKey('filter_course_${_filterDepartmentId}_$_filterCourseId'),
                                    decoration: const InputDecoration(labelText: "Course", isDense: true),
                                    initialValue: _filterCourseId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("All Courses", overflow: TextOverflow.ellipsis)),
                                      ...filteredCourses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.code, overflow: TextOverflow.ellipsis))),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _filterCourseId = val;
                                        _filterSemesterId = null;
                                        _filterSectionId = null;
                                        _filterSubjectId = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    key: ValueKey('filter_sem_${_filterCourseId}_$_filterSemesterId'),
                                    decoration: const InputDecoration(labelText: "Semester", isDense: true),
                                    initialValue: _filterSemesterId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("All Sems", overflow: TextOverflow.ellipsis)),
                                      ...filteredSemesters.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _filterSemesterId = val;
                                        _filterSectionId = null;
                                        _filterSubjectId = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    key: ValueKey('filter_sec_${_filterSemesterId}_$_filterSectionId'),
                                    decoration: const InputDecoration(labelText: "Section", isDense: true),
                                    initialValue: _filterSectionId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("All Secs", overflow: TextOverflow.ellipsis)),
                                      ...filteredSections.map((sec) => DropdownMenuItem(value: sec.id, child: Text(sec.name, overflow: TextOverflow.ellipsis))),
                                    ],
                                    onChanged: (val) => setState(() => _filterSectionId = val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    key: ValueKey('filter_fac_${_filterDepartmentId}_$_filterFacultyId'),
                                    decoration: const InputDecoration(labelText: "Faculty", isDense: true),
                                    initialValue: _filterFacultyId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("All Faculty", overflow: TextOverflow.ellipsis)),
                                      ...filteredFaculty.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis))),
                                    ],
                                    onChanged: (val) => setState(() => _filterFacultyId = val),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _filterActiveOnly,
                                        onChanged: (v) => setState(() => _filterActiveOnly = v ?? true),
                                      ),
                                      const Flexible(child: Text("Active only", overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              if (!isHod) ...[
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    key: ValueKey('filter_dept_$_filterDepartmentId'),
                                    decoration: const InputDecoration(labelText: "Department", hintText: "All Depts"),
                                    initialValue: _filterDepartmentId,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("All Departments", overflow: TextOverflow.ellipsis)),
                                      ...departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _filterDepartmentId = val;
                                        _filterCourseId = null;
                                        _filterSemesterId = null;
                                        _filterSectionId = null;
                                        _filterSubjectId = null;
                                        _filterFacultyId = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String?>(
                                  isExpanded: true,
                                  key: ValueKey('filter_course_${_filterDepartmentId}_$_filterCourseId'),
                                  decoration: const InputDecoration(labelText: "Course", hintText: "All Courses"),
                                  initialValue: _filterCourseId,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text("All Courses", overflow: TextOverflow.ellipsis)),
                                    ...filteredCourses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.code, overflow: TextOverflow.ellipsis))),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _filterCourseId = val;
                                      _filterSemesterId = null;
                                      _filterSectionId = null;
                                      _filterSubjectId = null;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String?>(
                                  isExpanded: true,
                                  key: ValueKey('filter_sem_${_filterCourseId}_$_filterSemesterId'),
                                  decoration: const InputDecoration(labelText: "Semester", hintText: "All Semesters"),
                                  initialValue: _filterSemesterId,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text("All Semesters", overflow: TextOverflow.ellipsis)),
                                    ...filteredSemesters.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _filterSemesterId = val;
                                      _filterSectionId = null;
                                      _filterSubjectId = null;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String?>(
                                  isExpanded: true,
                                  key: ValueKey('filter_sec_${_filterSemesterId}_$_filterSectionId'),
                                  decoration: const InputDecoration(labelText: "Section", hintText: "All Sections"),
                                  initialValue: _filterSectionId,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text("All Sections", overflow: TextOverflow.ellipsis)),
                                    ...filteredSections.map((sec) => DropdownMenuItem(value: sec.id, child: Text(sec.name, overflow: TextOverflow.ellipsis))),
                                  ],
                                  onChanged: (val) => setState(() => _filterSectionId = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String?>(
                                  isExpanded: true,
                                  key: ValueKey('filter_fac_${_filterDepartmentId}_$_filterFacultyId'),
                                  decoration: const InputDecoration(labelText: "Faculty", hintText: "All Faculty"),
                                  initialValue: _filterFacultyId,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text("All Faculty", overflow: TextOverflow.ellipsis)),
                                    ...filteredFaculty.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis))),
                                  ],
                                  onChanged: (val) => setState(() => _filterFacultyId = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String?>(
                                  isExpanded: true,
                                  key: ValueKey('filter_sub_${_filterSemesterId}_$_filterSubjectId'),
                                  decoration: const InputDecoration(labelText: "Subject", hintText: "All Subjects"),
                                  initialValue: _filterSubjectId,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text("All Subjects", overflow: TextOverflow.ellipsis)),
                                    ...filteredSubjects.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.code} - ${s.name}', overflow: TextOverflow.ellipsis))),
                                  ],
                                  onChanged: (val) => setState(() => _filterSubjectId = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String?>(
                                  isExpanded: true,
                                  key: ValueKey('filter_ay_$_filterAcademicYearId'),
                                  decoration: const InputDecoration(labelText: "Academic Year", hintText: "All Years"),
                                  initialValue: _filterAcademicYearId,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text("All Academic Years", overflow: TextOverflow.ellipsis)),
                                    ...academicYears.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name, overflow: TextOverflow.ellipsis))),
                                  ],
                                  onChanged: (val) => setState(() => _filterAcademicYearId = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _filterActiveOnly,
                                    onChanged: (v) => setState(() => _filterActiveOnly = v ?? true),
                                  ),
                                  const Text("Active only"),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Unassigned Subjects Indicator Banner
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final activeAssignments = (assignmentsAsync.valueOrNull ?? []).where((a) {
                  if (!a.isActive) return false;
                  if (_filterSemesterId != null && a.semesterId != _filterSemesterId) return false;
                  if (_filterSectionId != null && a.sectionId != _filterSectionId) return false;
                  return true;
                }).toList();
                final assignedSubjectIds = activeAssignments.map((a) => a.subjectId).toSet();
                final unassigned = filteredSubjects.where((s) => !assignedSubjectIds.contains(s.id)).toList();

                if (unassigned.isEmpty) return const SizedBox.shrink();

                return Container(
                  key: const Key('unassigned_subjects_banner'),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AcadexColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AcadexRadius.md),
                    border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 18, color: AcadexColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Unassigned Subjects (${unassigned.length}): ${unassigned.map((s) => "${s.code} ${s.name}").join(", ")}',
                          style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _openAssignmentDialog(),
                        child: const Text('Assign Now', style: TextStyle(fontWeight: FontWeight.w700, color: AcadexColors.primary)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Content Area
            Expanded(
              child: assignmentsAsync.when(
                loading: () => const Center(child: AcadexLoadingState(message: "Loading faculty assignments...")),
                error: (err, _) => Center(
                  child: AcadexErrorState(
                    title: "Failed to load faculty assignments",
                    message: err.toString(),
                    onRetry: () => ref.invalidate(facultyAssignmentsProvider),
                    retryLabel: "Retry",
                  ),
                ),
                data: (allAssignments) {
                  // Apply filters
                  final filtered = allAssignments.where((a) {
                    if (isHod && hodDeptId != null && hodDeptId.isNotEmpty && a.departmentId != hodDeptId) {
                      return false;
                    }
                    if (_filterActiveOnly && !a.isActive) return false;
                    if (_filterDepartmentId != null && a.departmentId != _filterDepartmentId) return false;
                    if (_filterCourseId != null && a.courseId != _filterCourseId) return false;
                    if (_filterSemesterId != null && a.semesterId != _filterSemesterId) return false;
                    if (_filterSectionId != null && a.sectionId != _filterSectionId) return false;
                    if (_filterFacultyId != null && a.facultyId != _filterFacultyId) return false;
                    if (_filterSubjectId != null && a.subjectId != _filterSubjectId) return false;
                    if (_filterAcademicYearId != null && a.academicYearId != _filterAcademicYearId) return false;

                    if (_searchQuery.isNotEmpty) {
                      final nameMatch = a.facultyName.toLowerCase().contains(_searchQuery);
                      final sub = subMap[a.subjectId];
                      final subMatch = sub != null && (sub.name.toLowerCase().contains(_searchQuery) || sub.code.toLowerCase().contains(_searchQuery));
                      if (!nameMatch && !subMatch) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: allAssignments.isEmpty
                          ? AcadexEmptyState(
                              title: "No faculty assignments yet.",
                              subtitle: "Assign faculty members to subjects and sections to start academic scheduling.",
                              icon: LucideIcons.userCheck,
                              actionLabel: "Assign Faculty",
                              onActionTap: () => _openAssignmentDialog(),
                            )
                          : AcadexEmptyState.filterEmpty(
                              title: "No assignments match criteria",
                              subtitle: "Try adjusting search or filters to see all faculty assignments.",
                              onClearFilters: () => setState(() {
                                _searchQuery = '';
                                _filterDepartmentId = isHod ? currentUser?.departmentId : null;
                                _filterCourseId = null;
                                _filterSemesterId = null;
                                _filterSectionId = null;
                                _filterFacultyId = null;
                                _filterSubjectId = null;
                              }),
                            ),
                    );
                  }

                  final isMobile = AcadexBreakpoints.isMobile(context);

                  if (isMobile) {
                    // Mobile stacked card list with subtle hover transition
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final a = filtered[i];
                        final sub = subMap[a.subjectId];
                        final crs = courseMap[a.courseId];
                        final sem = semMap[a.semesterId];
                        final sec = secMap[a.sectionId];

                        return AcadexCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.facultyName,
                                      style: AcadexTypography.title(color: theme.colorScheme.onSurface),
                                    ),
                                  ),
                                  AcadexBadge(
                                    label: a.isActive ? "Active" : "Inactive",
                                    variant: a.isActive ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${sub?.code ?? ''} — ${sub?.name ?? a.subjectId}',
                                style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${crs?.name ?? a.courseId} • ${sem?.name ?? a.semesterId} • Section ${sec?.name ?? a.sectionId}',
                                style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: a.isActive ? "Deactivate" : "Activate",
                                    icon: Icon(a.isActive ? LucideIcons.powerOff : LucideIcons.power, size: 16, color: a.isActive ? AcadexColors.warning : AcadexColors.success),
                                    onPressed: () => _toggleAssignmentActive(a),
                                  ),
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                                    onPressed: () => _confirmRemove(a),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  // Desktop Contained Data Table
                  return AcadexDataTable(
                    columns: const [
                      "Faculty",
                      "Department",
                      "Subject",
                      "Course",
                      "Semester",
                      "Section",
                      "Academic Year",
                      "Status",
                      "Actions",
                    ],
                    rows: filtered.map((a) {
                      final dept = deptMap[a.departmentId];
                      final sub = subMap[a.subjectId];
                      final crs = courseMap[a.courseId];
                      final sem = semMap[a.semesterId];
                      final sec = secMap[a.sectionId];
                      final yr = yearMap[a.academicYearId];

                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AcadexColors.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    a.facultyName.isNotEmpty ? a.facultyName[0].toUpperCase() : 'F',
                                    style: const TextStyle(color: AcadexColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  a.facultyName,
                                  style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(dept?.name ?? a.departmentId)),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(sub?.name ?? a.subjectId, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (sub != null) Text(sub.code, style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          DataCell(Text(crs?.name ?? a.courseId)),
                          DataCell(Text(sem?.name ?? a.semesterId)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AcadexColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AcadexRadius.xs),
                              ),
                              child: Text(
                                "Sec ${sec?.name ?? a.sectionId}",
                                style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(Text(yr?.name ?? (a.academicYearId.isNotEmpty ? a.academicYearId : 'Current'))),
                          DataCell(
                            AcadexBadge(
                              label: a.isActive ? "Active" : "Inactive",
                              variant: a.isActive ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: a.isActive ? "Deactivate" : "Activate",
                                  icon: Icon(a.isActive ? LucideIcons.powerOff : LucideIcons.power, size: 18, color: a.isActive ? AcadexColors.warning : AcadexColors.success),
                                  onPressed: () => _toggleAssignmentActive(a),
                                ),
                                IconButton(
                                  tooltip: "Delete Assignment",
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.error),
                                  onPressed: () => _confirmRemove(a),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      );
  }

  Future<void> _toggleAssignmentActive(FacultyAssignment assignment) async {
    final updated = assignment.copyWith(isActive: !assignment.isActive);
    await ref.read(facultyAssignmentsProvider.notifier).updateAssignment(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated.isActive ? "Assignment activated" : "Assignment deactivated"),
          backgroundColor: AcadexColors.success,
        ),
      );
    }
  }

  Future<void> _confirmRemove(FacultyAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Assignment?"),
        content: Text("Delete teaching allocation of ${assignment.facultyName} for ${assignment.subjectId}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(facultyAssignmentsProvider.notifier).removeAssignment(assignment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Assignment deleted successfully"),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    }
  }
}
