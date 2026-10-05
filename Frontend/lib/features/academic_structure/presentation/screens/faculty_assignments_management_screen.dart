import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_motion.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../widgets/acadex_academic_context_card.dart';
import '../widgets/faculty_assignment_dialog.dart';
import '../utils/academic_prerequisite_guard.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';
import '../../../../core/errors/acadex_error.dart';

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
    final academicYears = ref.read(academicYearsProvider).valueOrNull ?? [];
    final faculties = ref.read(facultyProvider(null)).items;

    final terminology = ref.read(terminologyProvider);
    final check = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
      courses: courses,
      semesters: semesters,
      sections: sections,
      subjects: subjects,
      academicYears: academicYears,
      faculties: faculties,
      isSectionEnabled: terminology.isSectionEnabled,
      termHelper: terminology,
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

  int _countActiveFilters(bool isHod) {
    int count = 0;
    if (!isHod && _filterDepartmentId != null) count++;
    if (_filterCourseId != null) count++;
    if (_filterSemesterId != null) count++;
    if (_filterSectionId != null) count++;
    if (_filterFacultyId != null) count++;
    if (_filterSubjectId != null) count++;
    if (_filterAcademicYearId != null) count++;
    if (!_filterActiveOnly) count++;
    return count;
  }

  void _clearFilters(bool isHod, String? hodDeptId) {
    setState(() {
      _searchQuery = '';
      _filterDepartmentId = isHod ? hodDeptId : null;
      _filterCourseId = null;
      _filterSemesterId = null;
      _filterSectionId = null;
      _filterFacultyId = null;
      _filterSubjectId = null;
      _filterAcademicYearId = null;
      _filterActiveOnly = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isHod = currentUser?.role == AppRole.hod;
    final hodDeptId = currentUser?.departmentId;

    if (isHod && hodDeptId != null && hodDeptId.isNotEmpty && _filterDepartmentId == null) {
      _filterDepartmentId = hodDeptId;
    }

    final terminology = ref.watch(terminologyProvider);
    final progLabel = terminology.programName();
    final semLabel = terminology.semesterName();
    final secLabel = terminology.sectionName();
    final subLabel = terminology.subjectName();
    final deptLabel = terminology.departmentName();

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

    final activeFilterCount = _countActiveFilters(isHod);

    return AcadexPageContainer(
      backgroundColor: Colors.transparent,
      maxWidth: 1600,
      scrollable: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              AcadexPageHeader(
                title: "Faculty Assignments",
                subtitle: "Manage subject and section teaching allocations.",
                actions: [
                  AcadexButton(
                    label: "Assign Faculty",
                    icon: LucideIcons.userPlus,
                    onPressed: () => _openAssignmentDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Academic Context Summary (Phase 3)
              if (_filterDepartmentId != null || _filterCourseId != null) ...[
                AcadexAcademicContextCard(
                  title: isHod ? 'Department Teaching Scope' : 'Active Assignment Context',
                  departmentName: deptMap[_filterDepartmentId]?.name ?? (isHod ? deptMap[hodDeptId]?.name : null),
                  departmentCode: deptMap[_filterDepartmentId]?.code ?? (isHod ? deptMap[hodDeptId]?.code : null),
                  programName: courseMap[_filterCourseId]?.name,
                  semesterName: semMap[_filterSemesterId]?.name,
                  sectionName: secMap[_filterSectionId]?.name,
                  academicYearName: yearMap[_filterAcademicYearId]?.name,
                  onChangeContext: () => _openFilterSheet(
                    context: context,
                    isDark: isDark,
                    isHod: isHod,
                    departments: departments,
                    courses: filteredCourses,
                    semesters: filteredSemesters,
                    sections: filteredSections,
                    subjects: filteredSubjects,
                    facultyList: filteredFaculty,
                    academicYears: academicYears,
                    progLabel: progLabel,
                    semLabel: semLabel,
                    secLabel: secLabel,
                    subLabel: subLabel,
                    deptLabel: deptLabel,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Smart Adaptive Filter Bar (Phase 8)
              AcadexCard(
                isFlat: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Search Field
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search faculty, subject, or code...",
                              prefixIcon: const Icon(LucideIcons.search, size: 16),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 14),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AcadexRadius.md),
                                borderSide: BorderSide(
                                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                ),
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Filter Trigger Button
                        AcadexPressable(
                          onTap: () => _openFilterSheet(
                            context: context,
                            isDark: isDark,
                            isHod: isHod,
                            departments: departments,
                            courses: filteredCourses,
                            semesters: filteredSemesters,
                            sections: filteredSections,
                            subjects: filteredSubjects,
                            facultyList: filteredFaculty,
                            academicYears: academicYears,
                            progLabel: progLabel,
                            semLabel: semLabel,
                            secLabel: secLabel,
                            subLabel: subLabel,
                            deptLabel: deptLabel,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: activeFilterCount > 0
                                  ? (isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight)
                                  : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft),
                              borderRadius: BorderRadius.circular(AcadexRadius.md),
                              border: Border.all(
                                color: activeFilterCount > 0
                                    ? AcadexColors.primary.withValues(alpha: 0.4)
                                    : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.slidersHorizontal,
                                  size: 15,
                                  color: activeFilterCount > 0 ? AcadexColors.primary : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  activeFilterCount > 0 ? 'Filters ($activeFilterCount)' : 'Filter',
                                  style: AcadexTypography.button.copyWith(
                                    color: activeFilterCount > 0 ? AcadexColors.primary : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Active Filters Chips (Removable)
                    if (activeFilterCount > 0) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (!isHod && _filterDepartmentId != null)
                              _buildActiveFilterChip(
                                label: deptMap[_filterDepartmentId]?.name ?? 'Dept',
                                onRemove: () => setState(() {
                                  _filterDepartmentId = null;
                                  _filterCourseId = null;
                                  _filterSemesterId = null;
                                  _filterSectionId = null;
                                }),
                                isDark: isDark,
                              ),
                            if (_filterCourseId != null)
                              _buildActiveFilterChip(
                                label: courseMap[_filterCourseId]?.code ?? 'Course',
                                onRemove: () => setState(() {
                                  _filterCourseId = null;
                                  _filterSemesterId = null;
                                  _filterSectionId = null;
                                }),
                                isDark: isDark,
                              ),
                            if (_filterSemesterId != null)
                              _buildActiveFilterChip(
                                label: semMap[_filterSemesterId]?.name ?? 'Semester',
                                onRemove: () => setState(() {
                                  _filterSemesterId = null;
                                  _filterSectionId = null;
                                }),
                                isDark: isDark,
                              ),
                            if (_filterSectionId != null)
                              _buildActiveFilterChip(
                                label: 'Sec ${secMap[_filterSectionId]?.name ?? ""}',
                                onRemove: () => setState(() => _filterSectionId = null),
                                isDark: isDark,
                              ),
                            if (_filterFacultyId != null)
                              _buildActiveFilterChip(
                                label: facultyList.firstWhere((f) => f.id == _filterFacultyId, orElse: () => Faculty(id: '', collegeId: '', departmentId: '', name: 'Faculty', employeeId: '', email: '', phone: '')).name,
                                onRemove: () => setState(() => _filterFacultyId = null),
                                isDark: isDark,
                              ),
                            if (!_filterActiveOnly)
                              _buildActiveFilterChip(
                                label: 'All Statuses',
                                onRemove: () => setState(() => _filterActiveOnly = true),
                                isDark: isDark,
                              ),
                            TextButton(
                              onPressed: () => _clearFilters(isHod, hodDeptId),
                              child: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AcadexColors.primary)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Unassigned Subjects Banner
              Consumer(
                builder: (context, ref, _) {
                  final allSubs = subjects;
                  final allAssignments = assignmentsAsync.valueOrNull ?? [];
                  final assignedSubjectIds = allAssignments.where((a) => a.isActive).map((a) => a.subjectId).toSet();
                  final unassigned = allSubs.where((s) => !assignedSubjectIds.contains(s.id)).toList();

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
              assignmentsAsync.when(
                loading: () => const Center(child: AcadexLoadingState(message: "Loading faculty assignments...")),
                error: (err, _) => Center(
                  child: AcadexErrorState(
                    title: "Failed to load faculty assignments",
                    message: AcadexException.sanitizedMessage(err),
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
                              onClearFilters: () => _clearFilters(isHod, hodDeptId),
                            ),
                    );
                  }

                  if (isNarrow) {
                    // Mobile & Narrow: Compact card list with progressive disclosure tap
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = filtered[i];
                        final sub = subMap[a.subjectId];
                        final crs = courseMap[a.courseId];
                        final sem = semMap[a.semesterId];
                        final sec = secMap[a.sectionId];
                        final yr = yearMap[a.academicYearId];

                        return AcadexCard(
                          isFlat: true,
                          padding: const EdgeInsets.all(12),
                          child: InkWell(
                            onTap: () => _openAssignmentDetail(context, a, sub, crs, sem, sec, yr, isDark),
                            borderRadius: BorderRadius.circular(AcadexRadius.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Subject code + Section + Status
                                Row(
                                  children: [
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Container(
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
                                                  fontSize: 11.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
                                                borderRadius: AcadexRadius.borderRadiusSm,
                                                border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                                              ),
                                              child: Text(
                                                AcadexEntityFormatters.formatSectionLabel(sec?.name, rawId: a.sectionId, fallback: 'Assigned Section', compact: true),
                                                style: AcadexTypography.caption(
                                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                                ).copyWith(fontWeight: FontWeight.w600, fontSize: 11.5),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AcadexBadge(
                                      label: a.isActive ? "Active" : "Inactive",
                                      variant: a.isActive ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Subject Title
                                Text(
                                  AcadexEntityFormatters.formatSubjectLabel(sub?.name, code: sub?.code, rawId: a.subjectId),
                                  style: AcadexTypography.heading3(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Faculty Row
                                Row(
                                  children: [
                                    const Icon(LucideIcons.userCheck, size: 14, color: AcadexColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        a.facultyName,
                                        style: AcadexTypography.body(
                                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Academic Context row
                                Text(
                                  AcadexEntityFormatters.formatAcademicContext(
                                    course: crs?.name,
                                    semester: sem?.name,
                                    year: yr?.name ?? (a.academicYearId.isNotEmpty && !AcadexEntityFormatters.isRawIdentifier(a.academicYearId) ? a.academicYearId : null),
                                  ),
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ).copyWith(fontSize: 11.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 4),

                                // Quick Actions Row
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
                                          icon: const Icon(LucideIcons.clipboardCheck, size: 14),
                                          label: const Text(
                                            'Attendance',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onPressed: () => context.push('/attendance/take?classId=${a.id}&facultyAssignmentId=${a.id}'),
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
                                      tooltip: a.isActive ? "Deactivate" : "Activate",
                                      icon: Icon(
                                        a.isActive ? LucideIcons.powerOff : LucideIcons.power,
                                        size: 16,
                                        color: a.isActive ? AcadexColors.warning : AcadexColors.success,
                                      ),
                                      onPressed: () => _toggleAssignmentActive(a),
                                    ),
                                    IconButton(
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      tooltip: "Delete",
                                      icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                                      onPressed: () => _confirmRemove(a),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Desktop & Wide Constraints: Contained Data Table
                  return AcadexDataTable(
                    columns: [
                      "Faculty",
                      deptLabel,
                      subLabel,
                      progLabel,
                      semLabel,
                      secLabel,
                      "Academic Year",
                      "Cohort / Batch",
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
                          DataCell(Text(AcadexEntityFormatters.formatDepartmentLabel(dept?.name, rawId: a.departmentId))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(AcadexEntityFormatters.formatSubjectLabel(sub?.name, code: sub?.code, rawId: a.subjectId), style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (sub != null && !AcadexEntityFormatters.isRawIdentifier(sub.code)) Text(sub.code, style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          DataCell(Text(AcadexEntityFormatters.formatCourseLabel(crs?.name, code: crs?.code, rawId: a.courseId))),
                          DataCell(Text(AcadexEntityFormatters.formatSemesterLabel(sem?.name, semesterNumber: sem?.semesterNumber, rawId: a.semesterId))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AcadexColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AcadexRadius.xs),
                              ),
                              child: Text(
                                AcadexEntityFormatters.formatSectionLabel(sec?.name, rawId: a.sectionId, fallback: 'Assigned Section', compact: true),
                                style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(Text(AcadexEntityFormatters.formatAcademicYearLabel(yr?.name, rawId: a.academicYearId))),
                          DataCell(Text(a.cohort != null && a.cohort!.isNotEmpty ? a.cohort! : '—')),
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
                                  tooltip: "Internal Assessment Marks",
                                  icon: const Icon(LucideIcons.award, size: 18, color: AcadexColors.primary),
                                  onPressed: () => context.push('/assessments/entry?sectionId=${a.sectionId}&subjectId=${a.subjectId}'),
                                ),
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight,
        borderRadius: AcadexRadius.borderRadiusFull,
        border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AcadexColors.primary),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(LucideIcons.x, size: 12, color: AcadexColors.primary),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet({
    required BuildContext context,
    required bool isDark,
    required bool isHod,
    required List<Department> departments,
    required List<Course> courses,
    required List<Semester> semesters,
    required List<Section> sections,
    required List<Subject> subjects,
    required List<Faculty> facultyList,
    required List<AcademicYear> academicYears,
    required String progLabel,
    required String semLabel,
    required String secLabel,
    required String subLabel,
    required String deptLabel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AcadexRadius.xl)),
      ),
      builder: (ctx) {
        String? tempDept = _filterDepartmentId;
        String? tempCourse = _filterCourseId;
        String? tempSem = _filterSemesterId;
        String? tempSec = _filterSectionId;
        String? tempFac = _filterFacultyId;
        String? tempSub = _filterSubjectId;
        bool tempActiveOnly = _filterActiveOnly;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final activeCourses = tempDept == null ? courses : courses.where((c) => c.departmentId == tempDept).toList();
            final activeSemesters = tempCourse == null ? semesters : semesters.where((s) => s.courseId == tempCourse).toList();
            final activeSections = tempSem == null ? sections : sections.where((sec) => sec.semesterId == tempSem).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Filter Assignments',
                              style: AcadexTypography.heading3(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Department Filter (Locked for HOD)
                      if (!isHod) ...[
                        DropdownButtonFormField<String?>(
                          isExpanded: true,
                          decoration: InputDecoration(labelText: deptLabel),
                          initialValue: tempDept,
                          items: [
                            DropdownMenuItem(value: null, child: Text('All ${deptLabel}s')),
                            ...departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              tempDept = val;
                              tempCourse = null;
                              tempSem = null;
                              tempSec = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Course / Program Filter
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        decoration: InputDecoration(labelText: progLabel),
                        initialValue: tempCourse,
                        items: [
                          DropdownMenuItem(value: null, child: Text('All ${progLabel}s')),
                          ...activeCourses.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.code} - ${c.name}'))),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            tempCourse = val;
                            tempSem = null;
                            tempSec = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Semester Filter
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        decoration: InputDecoration(labelText: semLabel),
                        initialValue: tempSem,
                        items: [
                          DropdownMenuItem(value: null, child: Text('All ${semLabel}s')),
                          ...activeSemesters.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            tempSem = val;
                            tempSec = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Section Filter
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        decoration: InputDecoration(labelText: secLabel),
                        initialValue: tempSec,
                        items: [
                          DropdownMenuItem(value: null, child: Text('All ${secLabel}s')),
                          ...activeSections.map((sec) => DropdownMenuItem(value: sec.id, child: Text(sec.name))),
                        ],
                        onChanged: (val) => setModalState(() => tempSec = val),
                      ),
                      const SizedBox(height: 12),

                      // Faculty Filter
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Faculty Member'),
                        initialValue: tempFac,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Faculty')),
                          ...facultyList.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
                        ],
                        onChanged: (val) => setModalState(() => tempFac = val),
                      ),
                      const SizedBox(height: 12),

                      // Active Only Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show active assignments only', style: TextStyle(fontSize: 14)),
                        value: tempActiveOnly,
                        activeColor: AcadexColors.primary,
                        onChanged: (v) => setModalState(() => tempActiveOnly = v),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons: Clear & Apply
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _clearFilters(isHod, isHod ? _filterDepartmentId : null);
                              },
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AcadexButton(
                              label: 'Apply Filters',
                              onPressed: () {
                                setState(() {
                                  _filterDepartmentId = tempDept;
                                  _filterCourseId = tempCourse;
                                  _filterSemesterId = tempSem;
                                  _filterSectionId = tempSec;
                                  _filterFacultyId = tempFac;
                                  _filterSubjectId = tempSub;
                                  _filterActiveOnly = tempActiveOnly;
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAssignmentDetail(
    BuildContext context,
    FacultyAssignment a,
    Subject? sub,
    Course? crs,
    Semester? sem,
    Section? sec,
    AcademicYear? yr,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AcadexRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title Row with Code Badge & Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Text(
                        sub?.code ?? 'SUBJECT',
                        style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sub?.name ?? a.subjectId,
                        style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                      ),
                    ),
                    AcadexBadge(
                      label: a.isActive ? "Active" : "Inactive",
                      variant: a.isActive ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Faculty Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AcadexColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        a.facultyName.isNotEmpty ? a.facultyName[0].toUpperCase() : 'F',
                        style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Allocated Faculty', style: AcadexTypography.caption()),
                          Text(
                            a.facultyName,
                            style: AcadexTypography.body().copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Academic Context Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDetailChip('Program', AcadexEntityFormatters.formatCourseLabel(crs?.name, code: crs?.code, rawId: a.courseId), isDark),
                    _buildDetailChip('Semester', AcadexEntityFormatters.formatSemesterLabel(sem?.name, semesterNumber: sem?.semesterNumber, rawId: a.semesterId), isDark),
                    _buildDetailChip('Section', AcadexEntityFormatters.formatSectionLabel(sec?.name, rawId: a.sectionId, fallback: 'Assigned Section', prefix: false), isDark),
                    _buildDetailChip('Academic Year', AcadexEntityFormatters.formatAcademicYearLabel(yr?.name, rawId: a.academicYearId), isDark),
                    if (a.cohort != null && a.cohort!.isNotEmpty)
                      _buildDetailChip('Cohort', a.cohort!, isDark),
                  ],
                ),
                const SizedBox(height: 20),

                // Operations & Actions
                Row(
                  children: [
                    Expanded(
                      child: AcadexButton(
                        label: 'Take Attendance',
                        icon: LucideIcons.clipboardCheck,
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/attendance/take?classId=${a.id}&facultyAssignmentId=${a.id}');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.calendar, size: 16),
                        label: const Text('Timetable'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/timetable?sectionId=${a.sectionId}');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
        borderRadius: BorderRadius.circular(AcadexRadius.sm),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AcadexColors.inkMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
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
