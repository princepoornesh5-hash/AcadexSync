import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../providers/department_setup_provider.dart';
import '../widgets/import_data_dialog.dart';
import '../widgets/student_bulk_action_dialogs.dart';
import '../widgets/student_promotion_stepper_dialog.dart';
import '../widgets/progressive_enrollment_dialog.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/errors/acadex_error.dart';

// =============================================================================
// 1. STUDENT LIST SCREEN
// =============================================================================

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final Set<String> _selectedIds = {};
  String? _departmentId;
  String? _courseId;
  String? _academicYearId;
  String? _semesterId;
  String? _sectionId;
  String _searchQuery = '';
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated && authState.user.role == AppRole.hod) {
      _departmentId = authState.user.departmentId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFilters();
    });
  }

  void _syncFilters() {
    // Clear selections whenever the filter scope changes to avoid stale selected
    // IDs referencing students that are no longer in the visible dataset.
    if (_selectedIds.isNotEmpty) {
      setState(() => _selectedIds.clear());
    }
    ref.read(studentListFilterProvider.notifier).state = StudentFilterCriteria(
      departmentId: _departmentId,
      courseId: _courseId,
      academicYearId: _academicYearId,
      semesterId: _semesterId,
      sectionId: _sectionId,
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
    );
  }

  void _showBulkPromotionDialog() async {
    if (_selectedIds.isEmpty) return;
    final allStudents = ref.read(filteredStudentsProvider).valueOrNull ?? [];
    final selectedStudents = allStudents
        .where((s) => _selectedIds.contains(s.id))
        .toList();
    final result = await StudentPromotionStepperDialog.show(
      context,
      students: selectedStudents,
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
      ref.invalidate(filteredStudentsProvider);
      ref.invalidate(studentsProvider);
    }
  }

  void _showEnrollStudentDialog([Student? s]) async {
    final result = await ProgressiveEnrollmentDialog.show(
      context,
      initialStudent: s,
      initialDepartmentId: s?.departmentId ?? _departmentId,
      initialCourseId: s?.courseId ?? _courseId,
      initialSemesterId: s?.semesterId ?? _semesterId,
      initialSectionId: s?.sectionId ?? _sectionId,
    );
    if (result == true) {
      ref.invalidate(filteredStudentsProvider);
      ref.invalidate(studentsProvider);
    }
  }

  void _showBulkTransferDialog() async {
    if (_selectedIds.isEmpty) return;
    final result = await showDialog(
      context: context,
      builder: (ctx) =>
          StudentTransferDialog(studentIds: _selectedIds.toList()),
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
      ref.invalidate(filteredStudentsProvider);
      ref.invalidate(studentsProvider);
    }
  }

  void _showBulkGraduationDialog() async {
    if (_selectedIds.isEmpty) return;
    final result = await showDialog(
      context: context,
      builder: (ctx) =>
          StudentGraduationDialog(studentIds: _selectedIds.toList()),
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
      ref.invalidate(filteredStudentsProvider);
      ref.invalidate(studentsProvider);
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ImportDataDialog(entityName: 'Students'),
    );
  }

  AcadexBadgeVariant _getBadgeVariant(Student student) {
    if (student.accountStatus == AccountStatus.pendingActivation) {
      return AcadexBadgeVariant.warning;
    }
    switch (student.lifecycleState) {
      case StudentLifecycleState.active:
        return AcadexBadgeVariant.success;
      case StudentLifecycleState.admitted:
      case StudentLifecycleState.applicant:
        return AcadexBadgeVariant.neutral;
      case StudentLifecycleState.onLeave:
        return AcadexBadgeVariant.warning;
      case StudentLifecycleState.suspended:
        return AcadexBadgeVariant.danger;
      case StudentLifecycleState.transferred:
        return AcadexBadgeVariant.neutral;
      case StudentLifecycleState.graduated:
      case StudentLifecycleState.alumni:
        return AcadexBadgeVariant.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isHod = currentUser?.role == AppRole.hod;
    // isStaff controls bulk-action visibility and the checkbox column.
    // Faculty does NOT have bulk-action rights on the student directory.
    final isStaff =
        currentUser?.role == AppRole.superAdmin ||
        currentUser?.role == AppRole.collegeAdmin ||
        currentUser?.role == AppRole.hod;

    final depts = ref.watch(departmentsProvider).valueOrNull ?? [];
    final allCourses = ref.watch(coursesProvider).valueOrNull ?? [];
    final allYears = ref.watch(academicYearsProvider).valueOrNull ?? [];
    final allSemesters = ref.watch(semestersProvider).valueOrNull ?? [];
    final allSections = ref.watch(sectionsProvider).valueOrNull ?? [];

    final availableCourses = _departmentId != null
        ? allCourses
              .where((c) => c.departmentId == _departmentId && c.isActive)
              .toList()
        : allCourses.where((c) => c.isActive).toList();

    final availableSemesters = allSemesters.where((s) {
      if (!s.isActive) return false;
      if (_courseId != null && s.courseId != _courseId) return false;
      if (_academicYearId != null && s.academicYearId != _academicYearId)
        return false;
      return true;
    }).toList();

    final availableSections = _semesterId != null
        ? allSections
              .where((sec) => sec.semesterId == _semesterId && sec.isActive)
              .toList()
        : allSections.where((sec) => sec.isActive).toList();

    final studentsAsync = ref.watch(filteredStudentsProvider);

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (isMobile) ...[
            AcadexPageHeader(
              title: "Students",
              subtitle: "Direct directory & academic roster.",
              actions: [
                if (isStaff) ...[
                  IconButton(
                    icon: const Icon(LucideIcons.userCheck, size: 20),
                    tooltip: "Enroll Student",
                    onPressed: () => _showEnrollStudentDialog(),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.uploadCloud, size: 20),
                    tooltip: "Import CSV",
                    onPressed: _showImportDialog,
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: AcadexPageHeader(
                    title: "Students Directory",
                    subtitle:
                        "Filter and locate students across active academic hierarchy contexts.",
                  ),
                ),
                if (isStaff) ...[
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showEnrollStudentDialog(),
                        icon: const Icon(LucideIcons.userCheck, size: 16),
                        label: const Text("Enroll Student"),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _showImportDialog,
                        icon: const Icon(LucideIcons.uploadCloud, size: 16),
                        label: const Text("Import CSV"),
                      ),
                      if (_selectedIds.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          dropdownColor: isDark
                              ? AcadexColors.darkSurfaceCard
                              : AcadexColors.surface,
                          hint: Text(
                            "${_selectedIds.length} Selected",
                            style: const TextStyle(
                              color: AcadexColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          underline: const SizedBox(),
                          icon: const Icon(
                            LucideIcons.chevronDown,
                            color: AcadexColors.primary,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'promote',
                              child: Text(
                                "Promote Students",
                                style: AcadexTypography.body(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'transfer',
                              child: Text(
                                "Transfer Section",
                                style: AcadexTypography.body(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'graduate',
                              child: Text(
                                "Graduate Cohort",
                                style: AcadexTypography.body(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == 'promote') _showBulkPromotionDialog();
                            if (val == 'transfer') _showBulkTransferDialog();
                            if (val == 'graduate') _showBulkGraduationDialog();
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Hierarchical Filter Controls (Department -> Course -> Year -> Semester -> Section)
          _buildHierarchicalFilterBar(
            isDark: isDark,
            isHod: isHod,
            depts: depts,
            courses: availableCourses,
            years: allYears,
            sems: availableSemesters,
            secs: availableSections,
          ),

          // Search Bar & Status Chips / Actions
          if (isMobile) ...[
            TextField(
              decoration: InputDecoration(
                hintText: "Search by name or roll number...",
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: AcadexRadius.borderRadiusMd,
                  borderSide: BorderSide(
                    color: isDark
                        ? AcadexColors.darkHairline
                        : AcadexColors.hairline,
                  ),
                ),
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _syncFilters();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Status Filter
                PopupMenuButton<String?>(
                  tooltip: "Filter by Status",
                  initialValue: _statusFilter,
                  onSelected: (val) => setState(() => _statusFilter = val),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AcadexColors.darkSurfaceCard
                          : AcadexColors.surface,
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(
                        color: isDark
                            ? AcadexColors.darkHairline
                            : AcadexColors.hairline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.filter,
                          size: 16,
                          color: _statusFilter != null
                              ? AcadexColors.primary
                              : AcadexColors.inkMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusFilter == null
                              ? "All Status"
                              : _statusFilter == 'active'
                              ? "Active"
                              : _statusFilter == 'pending_activation'
                              ? "Pending"
                              : _statusFilter == 'on_leave'
                              ? "On Leave"
                              : "Alumni",
                          style: AcadexTypography.caption().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: null, child: Text("All Status")),
                    const PopupMenuItem(value: 'active', child: Text("Active")),
                    const PopupMenuItem(
                      value: 'pending_activation',
                      child: Text("Pending Activation"),
                    ),
                    const PopupMenuItem(
                      value: 'on_leave',
                      child: Text("On Leave"),
                    ),
                    const PopupMenuItem(
                      value: 'alumni',
                      child: Text("Alumni / Graduated"),
                    ),
                  ],
                ),
                const Spacer(),
                if (isStaff) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => context.push('/academics/students/new'),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text("Add Student"),
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search students by name or roll number...",
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: BorderSide(
                          color: isDark
                              ? AcadexColors.darkHairline
                              : AcadexColors.hairline,
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() => _searchQuery = v);
                      _syncFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Status Filter
                PopupMenuButton<String?>(
                  tooltip: "Filter by Status",
                  initialValue: _statusFilter,
                  onSelected: (val) => setState(() => _statusFilter = val),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AcadexColors.darkSurfaceCard
                          : AcadexColors.surface,
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(
                        color: isDark
                            ? AcadexColors.darkHairline
                            : AcadexColors.hairline,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.filter,
                          size: 16,
                          color: _statusFilter != null
                              ? AcadexColors.primary
                              : AcadexColors.inkMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusFilter == null
                              ? "All Status"
                              : _statusFilter == 'active'
                              ? "Active"
                              : _statusFilter == 'pending_activation'
                              ? "Pending"
                              : _statusFilter == 'on_leave'
                              ? "On Leave"
                              : "Alumni",
                          style: AcadexTypography.caption().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: null, child: Text("All Status")),
                    const PopupMenuItem(value: 'active', child: Text("Active")),
                    const PopupMenuItem(
                      value: 'pending_activation',
                      child: Text("Pending Activation"),
                    ),
                    const PopupMenuItem(
                      value: 'on_leave',
                      child: Text("On Leave"),
                    ),
                    const PopupMenuItem(
                      value: 'alumni',
                      child: Text("Alumni / Graduated"),
                    ),
                  ],
                ),
                if (isStaff) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => context.push('/academics/students/new'),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text("Add Student"),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Clean Row-Based Student List
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(
                child: AcadexLoadingState(message: "Loading student roster..."),
              ),
              error: (err, _) => AcadexErrorState.fromError(
                error: err,
                title: "Unable to load students",
                onRetry: () => ref.invalidate(filteredStudentsProvider),
              ),
              data: (students) {
                final filtered = students.where((s) {
                  if (_statusFilter != null) {
                    if (_statusFilter == 'pending_activation') {
                      if (s.accountStatus != AccountStatus.pendingActivation)
                        return false;
                    } else if (_statusFilter == 'active') {
                      if (s.accountStatus != AccountStatus.active ||
                          s.lifecycleState != StudentLifecycleState.active) {
                        return false;
                      }
                    } else if (_statusFilter == 'on_leave') {
                      if (s.lifecycleState != StudentLifecycleState.onLeave)
                        return false;
                    } else if (_statusFilter == 'alumni') {
                      if (s.lifecycleState != StudentLifecycleState.alumni &&
                          s.lifecycleState != StudentLifecycleState.graduated) {
                        return false;
                      }
                    }
                  }
                  return true;
                }).toList();

                // Prune any selected IDs that are no longer present in the
                // loaded dataset. This handles workspace changes, data reloads,
                // and any case where the underlying list is replaced without
                // an explicit filter change (e.g. pull-to-refresh).
                final visibleIds = filtered.map((s) => s.id).toSet();
                final staleIds = _selectedIds.difference(visibleIds);
                if (staleIds.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted)
                      setState(() => _selectedIds.removeAll(staleIds));
                  });
                }

                if (filtered.isEmpty) {
                  return AcadexEmptyState(
                    title: "No students found",
                    subtitle:
                        _searchQuery.isNotEmpty ||
                            _courseId != null ||
                            _semesterId != null ||
                            _sectionId != null
                        ? "Try clearing filters or search to view students in this context."
                        : "No students are enrolled in this scope.",
                    icon: LucideIcons.users,
                    actionLabel: isStaff ? "Enroll Student" : null,
                    onActionTap: isStaff
                        ? () => context.push('/academics/students/new')
                        : null,
                  );
                }

                return isMobile
                    ? _buildMobileList(filtered, isDark)
                    : _buildDesktopTable(filtered, theme, isStaff: isStaff);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchicalFilterBar({
    required bool isDark,
    required bool isHod,
    required List<Department> depts,
    required List<Course> courses,
    required List<AcademicYear> years,
    required List<Semester> sems,
    required List<Section> secs,
  }) {
    final hasActiveFilter =
        (!isHod && _departmentId != null) ||
        _courseId != null ||
        _academicYearId != null ||
        _semesterId != null ||
        _sectionId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 750;
          final itemWidth = isNarrow ? (constraints.maxWidth - 24) / 2 : 175.0;

          return Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Department Dropdown
              if (!isHod)
                SizedBox(
                  width: itemWidth,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _departmentId,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Department",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("All Departments"),
                      ),
                      ...depts
                          .where((d) => d.isActive)
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(
                                d.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _departmentId = val;
                        _courseId = null;
                        _semesterId = null;
                        _sectionId = null;
                      });
                      _syncFilters();
                    },
                  ),
                ),

              // Course Dropdown
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String?>(
                  initialValue: _courseId,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Course",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("All Courses"),
                    ),
                    ...courses.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _courseId = val;
                      _semesterId = null;
                      _sectionId = null;
                    });
                    _syncFilters();
                  },
                ),
              ),

              // Academic Year Dropdown
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String?>(
                  initialValue: _academicYearId,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Academic Year",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("All Years"),
                    ),
                    ...years
                        .where((y) => y.isActive)
                        .map(
                          (y) => DropdownMenuItem(
                            value: y.id,
                            child: Text(
                              y.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _academicYearId = val;
                      _semesterId = null;
                      _sectionId = null;
                    });
                    _syncFilters();
                  },
                ),
              ),

              // Semester Dropdown
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String?>(
                  initialValue: _semesterId,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Semester",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("All Semesters"),
                    ),
                    ...sems.map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _semesterId = val;
                      _sectionId = null;
                    });
                    _syncFilters();
                  },
                ),
              ),

              // Section Dropdown
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String?>(
                  initialValue: _sectionId,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Section",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("All Sections"),
                    ),
                    ...secs.map(
                      (sec) => DropdownMenuItem(
                        value: sec.id,
                        child: Text(sec.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _sectionId = val;
                    });
                    _syncFilters();
                  },
                ),
              ),

              // Clear Button
              if (hasActiveFilter)
                IconButton(
                  tooltip: "Reset All Filters",
                  icon: const Icon(
                    LucideIcons.xCircle,
                    size: 20,
                    color: AcadexColors.inkMuted,
                  ),
                  onPressed: () {
                    setState(() {
                      if (!isHod) _departmentId = null;
                      _courseId = null;
                      _academicYearId = null;
                      _semesterId = null;
                      _sectionId = null;
                    });
                    _syncFilters();
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileList(List<Student> students, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = students[i];
        final isSelected = _selectedIds.contains(s.id);
        final statusLabel = s.accountStatus == AccountStatus.pendingActivation
            ? 'Pending'
            : s.lifecycleState.displayName;

        return InkWell(
          onTap: () => context.push('/academics/students/${s.id}'),
          borderRadius: AcadexRadius.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AcadexColors.darkSurfaceCard
                  : AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(
                color: isSelected
                    ? AcadexColors.primary
                    : (isDark
                          ? AcadexColors.darkHairline
                          : AcadexColors.hairline),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AcadexColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AcadexColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: AcadexTypography.body(
                          color: isDark
                              ? AcadexColors.darkInk
                              : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.rollNumber.isNotEmpty
                            ? s.rollNumber
                            : (s.instituteId ?? '—'),
                        style: AcadexTypography.caption(
                          color: AcadexColors.primary,
                        ).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: AcadexBadge(
                    label: statusLabel,
                    variant: _getBadgeVariant(s),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AcadexColors.inkMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(
    List<Student> students,
    ThemeData theme, {
    bool isStaff = false,
  }) {
    // Unwanted checkboxes removed: Directory is designed for clean roster viewing & profile access.
    // Legitimate batch/import operations are handled via dedicated modal wizards (e.g. CSV import, promotion stepper).
    return AcadexDataTable(
      showCheckboxColumn: false,
      columns: const ["Student", "Roll No.", "Status", "Actions"],
      rows: students.map((s) {
        final statusLabel = s.accountStatus == AccountStatus.pendingActivation
            ? 'Pending'
            : s.lifecycleState.displayName;

        return DataRow(
          cells: [
            DataCell(
              Semantics(
                label: 'View profile for ${s.name}',
                child: InkWell(
                  onTap: () => context.push('/academics/students/${s.id}'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AcadexColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AcadexColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            DataCell(
              Semantics(
                label:
                    'Roll number: ${s.rollNumber.isNotEmpty ? s.rollNumber : (s.instituteId ?? 'not assigned')}',
                child: InkWell(
                  onTap: () => context.push('/academics/students/${s.id}'),
                  child: Text(
                    s.rollNumber.isNotEmpty
                        ? s.rollNumber
                        : (s.instituteId ?? '—'),
                    style: AcadexTypography.body(
                      color: AcadexColors.primary,
                    ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                ),
              ),
            ),
            DataCell(
              AcadexBadge(label: statusLabel, variant: _getBadgeVariant(s)),
            ),
            DataCell(
              IconButton(
                tooltip: 'View ${s.name}\'s profile',
                icon: const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AcadexColors.primary,
                ),
                onPressed: () => context.push('/academics/students/${s.id}'),
              ),
            ),
          ],
        );
      }).toList(),
      emptyState: AcadexEmptyState(
        title: "No students found",
        subtitle: "No students are enrolled in this scope.",
        icon: LucideIcons.users,
      ),
    );
  }
}

// =============================================================================
// 2. STUDENT PROVISIONING & EDIT FORM SCREEN
// =============================================================================

class StudentFormScreen extends ConsumerStatefulWidget {
  final String? id;
  final String? initialDepartmentId;

  const StudentFormScreen({super.key, this.id, this.initialDepartmentId});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _instituteIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _admissionDate;

  String? _selectedDeptId;
  String? _selectedCourseId;
  String? _selectedAcademicYearId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  StudentLifecycleState _lifecycleState = StudentLifecycleState.admitted;

  bool _isLoading = false;
  bool _isAutoGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDeptId = widget.initialDepartmentId;
    if (widget.id != null) {
      _loadExistingStudent();
    } else {
      // For HOD / Faculty, pre-lock department from authenticated user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authState = ref.read(authProvider);
        if (authState is AuthAuthenticated) {
          final user = authState.user;
          if (user.role == AppRole.hod || user.role == AppRole.faculty) {
            if (user.departmentId != null && user.departmentId!.isNotEmpty) {
              setState(() {
                _selectedDeptId = user.departmentId;
              });
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instituteIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rollNumberController.dispose();
    _admissionNumberController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadExistingStudent() async {
    setState(() => _isLoading = true);
    final repo = ref.read(academicRepositoryProvider);
    final student = await repo.getStudentById(widget.id!);
    if (student != null && mounted) {
      _nameController.text = student.name;
      _instituteIdController.text = student.instituteId ?? '';
      _emailController.text = student.email;
      _phoneController.text = student.phone;
      _rollNumberController.text = student.rollNumber;
      _admissionNumberController.text = student.admissionNumber ?? '';
      _parentNameController.text = student.parentName ?? '';
      _parentPhoneController.text = student.parentPhone ?? '';
      _bloodGroupController.text = student.bloodGroup ?? '';
      _addressController.text = student.address ?? '';
      _dateOfBirth = student.dateOfBirth;
      _admissionDate = student.admissionDate;
      _selectedDeptId = student.departmentId;
      _selectedCourseId = student.courseId;
      _selectedAcademicYearId = student.academicYearId;
      _selectedSemesterId = student.semesterId;
      _selectedSectionId = student.sectionId;
      _lifecycleState = student.lifecycleState;
    }
    setState(() => _isLoading = false);
  }

  void _autoGenerateRollNumber() async {
    final authState = ref.read(authProvider);
    final collegeId = authState is AuthAuthenticated
        ? (authState.user.collegeId ?? 'c1')
        : 'c1';

    if (_selectedCourseId == null) {
      AcadexSnackBar.showWarning(context, "Please select a Course first.");
      return;
    }

    setState(() => _isAutoGenerating = true);
    try {
      final roll = await ref
          .read(academicRepositoryProvider)
          .generateRollNumber(
            collegeId,
            _selectedCourseId!,
            _selectedAcademicYearId ?? '',
          );
      setState(() => _rollNumberController.text = roll);
    } catch (e) {
      AcadexSnackBar.showError(
        context,
        e,
        fallbackMessage: "Failed to generate roll number",
      );
    } finally {
      setState(() => _isAutoGenerating = false);
    }
  }

  Future<void> _pickDate({required bool isDob}) async {
    final initialDate = isDob
        ? (_dateOfBirth ?? DateTime(2004, 1, 1))
        : (_admissionDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isDob ? DateTime(1970) : DateTime(2000),
      lastDate: isDob ? DateTime.now() : DateTime(2050),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDob) {
          _dateOfBirth = picked;
        } else {
          _admissionDate = picked;
        }
      });
    }
  }

  void _saveStudent() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDeptId == null || _selectedDeptId!.isEmpty) {
      setState(() => _errorMessage = "Please select a department.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(academicRepositoryProvider);

      if (widget.id != null) {
        // Edit existing student
        final student = Student(
          id: widget.id!,
          collegeId: '',
          departmentId: _selectedDeptId!,
          courseId: _selectedCourseId ?? '',
          academicYearId: _selectedAcademicYearId ?? '',
          semesterId: _selectedSemesterId ?? '',
          sectionId: _selectedSectionId ?? '',
          name: _nameController.text.trim(),
          instituteId: _instituteIdController.text.trim().toUpperCase(),
          rollNumber: _rollNumberController.text.trim(),
          admissionNumber: _admissionNumberController.text.trim().isNotEmpty
              ? _admissionNumberController.text.trim()
              : null,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          parentName: _parentNameController.text.trim().isNotEmpty
              ? _parentNameController.text.trim()
              : null,
          parentPhone: _parentPhoneController.text.trim().isNotEmpty
              ? _parentPhoneController.text.trim()
              : null,
          bloodGroup: _bloodGroupController.text.trim().isNotEmpty
              ? _bloodGroupController.text.trim()
              : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          dateOfBirth: _dateOfBirth,
          admissionDate: _admissionDate,
          lifecycleState: _lifecycleState,
        );

        await repo.updateStudent(student);
        ref.invalidate(studentsProvider);
        if (student.departmentId.isNotEmpty) {
          ref.invalidate(studentsByDepartmentProvider(student.departmentId));
          ref.invalidate(departmentSetupProvider(student.departmentId));
        }
        if (student.sectionId.isNotEmpty) {
          ref.invalidate(studentsBySectionProvider(student.sectionId));
          ref.invalidate(sectionStudentCountProvider(student.sectionId));
        }
        if (mounted) {
          AcadexSnackBar.showSuccess(
            context,
            "Student profile updated successfully",
          );
          context.safePop(fallbackRoute: '/academics/students');
        }
      } else {
        // Provision New Student
        final req = ProvisionStudentRequest(
          departmentId: _selectedDeptId!,
          name: _nameController.text.trim(),
          instituteId: _instituteIdController.text.trim().toUpperCase(),
          rollNumber: _rollNumberController.text.trim().isNotEmpty
              ? _rollNumberController.text.trim()
              : null,
          admissionNumber: _admissionNumberController.text.trim().isNotEmpty
              ? _admissionNumberController.text.trim()
              : null,
          email: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          parentName: _parentNameController.text.trim().isNotEmpty
              ? _parentNameController.text.trim()
              : null,
          parentPhone: _parentPhoneController.text.trim().isNotEmpty
              ? _parentPhoneController.text.trim()
              : null,
          bloodGroup: _bloodGroupController.text.trim().isNotEmpty
              ? _bloodGroupController.text.trim()
              : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          dateOfBirth: _dateOfBirth?.toIso8601String(),
          admissionDate: _admissionDate?.toIso8601String(),
          courseId: _selectedCourseId,
          academicYearId: _selectedAcademicYearId,
          semesterId: _selectedSemesterId,
          sectionId: _selectedSectionId,
        );

        final result = await repo.provisionStudent(req);
        ref.invalidate(studentsProvider);
        if (_selectedDeptId != null && _selectedDeptId!.isNotEmpty) {
          ref.invalidate(studentsByDepartmentProvider(_selectedDeptId!));
          ref.invalidate(departmentSetupProvider(_selectedDeptId!));
        }
        if (_selectedSectionId != null && _selectedSectionId!.isNotEmpty) {
          ref.invalidate(studentsBySectionProvider(_selectedSectionId!));
          ref.invalidate(sectionStudentCountProvider(_selectedSectionId!));
        }

        if (mounted) {
          setState(() => _isLoading = false);
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => StudentActivationResultDialog(result: result),
          );
          if (mounted) context.safePop(fallbackRoute: '/academics/students');
        }
      }
    } catch (e) {
      final sanitized = AcadexException.fromError(e).userMessage;
      setState(() {
        _isLoading = false;
        _errorMessage = sanitized;
      });
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: "Failed to save student",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.id != null;

    final authState = ref.watch(authProvider);
    final isStaff =
        authState is AuthAuthenticated &&
        (authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.faculty);

    final terminology = ref.watch(terminologyProvider);
    final isSectionEnabled = terminology.isSectionEnabled;
    final progLabel = terminology.programName();
    final semLabel = terminology.semesterName();
    final secLabel = terminology.sectionName();

    final departmentsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final academicYearsAsync = ref.watch(academicYearsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? AcadexColors.darkSurface
            : AcadexColors.surface,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () =>
              context.safePop(fallbackRoute: '/academics/students'),
        ),
        title: Text(
          isEdit ? "Edit Student" : "Add Student",
          style: AcadexTypography.title(color: theme.colorScheme.onSurface),
        ),
      ),
      body: _isLoading && isEdit
          ? const Center(
              child: AcadexLoadingState(message: "Loading student record..."),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AcadexColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AcadexRadius.sm,
                              ),
                              border: Border.all(
                                color: AcadexColors.error.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.alertCircle,
                                  color: AcadexColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AcadexColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Student Identity & Credentials Card
                        AcadexFormCard(
                          title: "Student Identity & Credentials",
                          icon: LucideIcons.user,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: "Full Name *",
                                        prefixIcon: Icon(
                                          LucideIcons.user,
                                          size: 18,
                                        ),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().length < 2)
                                          ? 'Name must be at least 2 characters'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _instituteIdController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: const InputDecoration(
                                        labelText: "PIN Number *",
                                        prefixIcon: Icon(
                                          LucideIcons.idCard,
                                          size: 18,
                                        ),
                                        hintText: "e.g. 26CSE042",
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().length < 2)
                                          ? 'PIN Number is required (min 2 chars)'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: "Official Email Address",
                                        prefixIcon: Icon(
                                          LucideIcons.mail,
                                          size: 18,
                                        ),
                                        hintText: "student@institute.edu",
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: "Phone Number",
                                        prefixIcon: Icon(
                                          LucideIcons.phone,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Cascading Academic Placement Card
                        AcadexFormCard(
                          title: "Academic Placement & Enrollment",
                          icon: LucideIcons.graduationCap,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Department & Course
                              Row(
                                children: [
                                  Expanded(
                                    child: departmentsAsync.when(
                                      data: (departments) {
                                        final activeDepts = departments
                                            .where((d) => d.isActive)
                                            .toList();
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark
                                              ? AcadexColors.darkSurfaceCard
                                              : AcadexColors.surface,
                                          decoration: InputDecoration(
                                            labelText: "Department *",
                                            prefixIcon: const Icon(
                                              LucideIcons.building,
                                              size: 18,
                                            ),
                                            helperText: isStaff
                                                ? "Locked to your assigned department"
                                                : null,
                                          ),
                                          initialValue: _selectedDeptId,
                                          items: activeDepts
                                              .map(
                                                (d) => DropdownMenuItem(
                                                  value: d.id,
                                                  child: Text(d.name),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: isStaff
                                              ? null
                                              : (val) => setState(() {
                                                  _selectedDeptId = val;
                                                  _selectedCourseId = null;
                                                  _selectedSemesterId = null;
                                                  _selectedSectionId = null;
                                                }),
                                          validator: (v) => v == null
                                              ? 'Select department'
                                              : null,
                                        );
                                      },
                                      loading: () =>
                                          const LinearProgressIndicator(),
                                      error: (e, _) => Text(
                                        'Error: $e',
                                        style: const TextStyle(
                                          color: AcadexColors.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: coursesAsync.when(
                                      data: (courses) {
                                        final filtered = _selectedDeptId != null
                                            ? courses
                                                  .where(
                                                    (c) =>
                                                        c.departmentId ==
                                                            _selectedDeptId &&
                                                        c.isActive,
                                                  )
                                                  .toList()
                                            : <Course>[];
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark
                                              ? AcadexColors.darkSurfaceCard
                                              : AcadexColors.surface,
                                          decoration: InputDecoration(
                                            labelText: progLabel,
                                            prefixIcon: const Icon(
                                              LucideIcons.book,
                                              size: 18,
                                            ),
                                            hintText: _selectedDeptId == null
                                                ? 'Select Department first'
                                                : 'Choose $progLabel',
                                          ),
                                          initialValue: _selectedCourseId,
                                          items: filtered
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c.id,
                                                  child: Text(
                                                    "${c.name} (${c.code})",
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: _selectedDeptId == null
                                              ? null
                                              : (val) => setState(() {
                                                  _selectedCourseId = val;
                                                  _selectedSemesterId = null;
                                                  _selectedSectionId = null;
                                                }),
                                        );
                                      },
                                      loading: () =>
                                          const LinearProgressIndicator(),
                                      error: (e, _) => Text(
                                        'Error: $e',
                                        style: const TextStyle(
                                          color: AcadexColors.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Academic Year & Semester
                              Row(
                                children: [
                                  Expanded(
                                    child: academicYearsAsync.when(
                                      data: (years) {
                                        final activeYears = years
                                            .where((y) => y.isActive)
                                            .toList();
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark
                                              ? AcadexColors.darkSurfaceCard
                                              : AcadexColors.surface,
                                          decoration: const InputDecoration(
                                            labelText: "Academic Year",
                                            prefixIcon: Icon(
                                              LucideIcons.calendar,
                                              size: 18,
                                            ),
                                          ),
                                          initialValue: _selectedAcademicYearId,
                                          items: activeYears
                                              .map(
                                                (y) => DropdownMenuItem(
                                                  value: y.id,
                                                  child: Text(y.name),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) => setState(() {
                                            _selectedAcademicYearId = val;
                                            _selectedSemesterId = null;
                                            _selectedSectionId = null;
                                          }),
                                        );
                                      },
                                      loading: () =>
                                          const LinearProgressIndicator(),
                                      error: (e, _) => Text(
                                        'Error: $e',
                                        style: const TextStyle(
                                          color: AcadexColors.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: semestersAsync.when(
                                      data: (semesters) {
                                        final filtered =
                                            _selectedCourseId != null
                                            ? semesters.where((s) {
                                                if (s.courseId !=
                                                    _selectedCourseId)
                                                  return false;
                                                if (_selectedAcademicYearId !=
                                                        null &&
                                                    s.academicYearId !=
                                                        _selectedAcademicYearId)
                                                  return false;
                                                return s.isActive;
                                              }).toList()
                                            : <Semester>[];
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark
                                              ? AcadexColors.darkSurfaceCard
                                              : AcadexColors.surface,
                                          decoration: InputDecoration(
                                            labelText: semLabel,
                                            prefixIcon: const Icon(
                                              LucideIcons.layers,
                                              size: 18,
                                            ),
                                            hintText: _selectedCourseId == null
                                                ? 'Select $progLabel first'
                                                : 'Choose $semLabel',
                                          ),
                                          initialValue: _selectedSemesterId,
                                          items: filtered
                                              .map(
                                                (s) => DropdownMenuItem(
                                                  value: s.id,
                                                  child: Text(
                                                    s.name.isNotEmpty
                                                        ? s.name
                                                        : "$semLabel ${s.semesterNumber}",
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: _selectedCourseId == null
                                              ? null
                                              : (val) => setState(() {
                                                  _selectedSemesterId = val;
                                                  _selectedSectionId = null;
                                                }),
                                        );
                                      },
                                      loading: () =>
                                          const LinearProgressIndicator(),
                                      error: (e, _) => Text(
                                        'Error: $e',
                                        style: const TextStyle(
                                          color: AcadexColors.error,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Section & Roll Number (Section optional based on config)
                              Row(
                                children: [
                                  if (isSectionEnabled) ...[
                                    Expanded(
                                      child: sectionsAsync.when(
                                        data: (sections) {
                                          final filtered =
                                              _selectedSemesterId != null
                                              ? sections.where((s) {
                                                  if (s.semesterId !=
                                                      _selectedSemesterId)
                                                    return false;
                                                  return s.isActive;
                                                }).toList()
                                              : <Section>[];
                                          return DropdownButtonFormField<
                                            String
                                          >(
                                            dropdownColor: isDark
                                                ? AcadexColors.darkSurfaceCard
                                                : AcadexColors.surface,
                                            decoration: InputDecoration(
                                              labelText: secLabel,
                                              prefixIcon: const Icon(
                                                LucideIcons.layoutGrid,
                                                size: 18,
                                              ),
                                              hintText:
                                                  _selectedSemesterId == null
                                                  ? 'Select $semLabel first'
                                                  : 'Choose $secLabel',
                                            ),
                                            initialValue: _selectedSectionId,
                                            items: filtered
                                                .map(
                                                  (s) => DropdownMenuItem(
                                                    value: s.id,
                                                    child: Text(
                                                      "$secLabel ${s.name}",
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged:
                                                _selectedSemesterId == null
                                                ? null
                                                : (val) => setState(
                                                    () => _selectedSectionId =
                                                        val,
                                                  ),
                                          );
                                        },
                                        loading: () =>
                                            const LinearProgressIndicator(),
                                        error: (e, _) => Text(
                                          'Error: $e',
                                          style: const TextStyle(
                                            color: AcadexColors.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Expanded(
                                    child: TextFormField(
                                      controller: _rollNumberController,
                                      decoration: InputDecoration(
                                        labelText: "Roll Number",
                                        prefixIcon: const Icon(
                                          LucideIcons.hash,
                                          size: 18,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: "Auto-Generate Roll Number",
                                          icon: _isAutoGenerating
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  LucideIcons.sparkles,
                                                  color: AcadexColors.primary,
                                                ),
                                          onPressed: _isAutoGenerating
                                              ? null
                                              : _autoGenerateRollNumber,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Guardian & Additional Information Card
                        AcadexFormCard(
                          title: "Guardian & Additional Profile",
                          icon: LucideIcons.shieldCheck,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _parentNameController,
                                      decoration: const InputDecoration(
                                        labelText: "Parent / Guardian Name",
                                        prefixIcon: Icon(
                                          LucideIcons.userCheck,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _parentPhoneController,
                                      decoration: const InputDecoration(
                                        labelText: "Parent Phone Number",
                                        prefixIcon: Icon(
                                          LucideIcons.phoneCall,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _admissionNumberController,
                                      decoration: const InputDecoration(
                                        labelText: "Admission Registration No.",
                                        prefixIcon: Icon(
                                          LucideIcons.fileText,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _bloodGroupController,
                                      decoration: const InputDecoration(
                                        labelText: "Blood Group (e.g. O+, A+)",
                                        prefixIcon: Icon(
                                          LucideIcons.heartPulse,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _pickDate(isDob: true),
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: "Date of Birth",
                                          prefixIcon: Icon(
                                            LucideIcons.calendar,
                                            size: 18,
                                          ),
                                        ),
                                        child: Text(
                                          _dateOfBirth != null
                                              ? "${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}"
                                              : "Select Date of Birth",
                                          style: TextStyle(
                                            color: _dateOfBirth != null
                                                ? null
                                                : theme.hintColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _pickDate(isDob: false),
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: "Admission Date",
                                          prefixIcon: Icon(
                                            LucideIcons.calendarCheck,
                                            size: 18,
                                          ),
                                        ),
                                        child: Text(
                                          _admissionDate != null
                                              ? "${_admissionDate!.year}-${_admissionDate!.month.toString().padLeft(2, '0')}-${_admissionDate!.day.toString().padLeft(2, '0')}"
                                              : "Select Admission Date",
                                          style: TextStyle(
                                            color: _admissionDate != null
                                                ? null
                                                : theme.hintColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: "Residential Address",
                                  prefixIcon: Icon(
                                    LucideIcons.mapPin,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.safePop(
                                fallbackRoute: '/academics/students',
                              ),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveStudent,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      isEdit
                                          ? LucideIcons.save
                                          : LucideIcons.userPlus,
                                      size: 18,
                                    ),
                              label: Text(
                                isEdit ? "Save Changes" : "Add Student",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcadexColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// =============================================================================
// 3. STUDENT ACTIVATION RESULT DIALOG
// =============================================================================

class StudentActivationResultDialog extends StatelessWidget {
  final ProvisionStudentResult result;

  const StudentActivationResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
      backgroundColor: isDark
          ? AcadexColors.darkSurfaceCard
          : AcadexColors.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AcadexColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle,
                    color: AcadexColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Student Provisioned Successfully",
                        style: AcadexTypography.heading3(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "Single-use activation code generated",
                        style: AcadexTypography.caption(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Student Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurface : AcadexColors.canvas,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : AcadexColors.hairline,
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Student Name", result.student.name),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                    "PIN Number",
                    result.user.instituteId ??
                        result.student.instituteId ??
                        '—',
                  ),
                  const SizedBox(height: 6),
                  _buildSummaryRow("Role", "STUDENT"),
                  const SizedBox(height: 6),
                  _buildSummaryRow("Initial Status", "Pending Activation"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Activation Code",
              style: AcadexTypography.caption(
                color: theme.hintColor,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),

            // Activation Code Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.08),
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(
                  color: AcadexColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.key,
                    color: AcadexColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      result.activationCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 2.0,
                        color: AcadexColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "Copy Code",
                    icon: const Icon(
                      LucideIcons.copy,
                      size: 18,
                      color: AcadexColors.primary,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: result.activationCode),
                      );
                      AcadexSnackBar.showSuccess(
                        context,
                        "Activation code copied to clipboard!",
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (result.invitation.expiresAt != null)
              Text(
                "Code expires on: ${result.invitation.expiresAt!.toLocal().toString().split('.').first}",
                style: AcadexTypography.caption(color: theme.hintColor),
              ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AcadexColors.warning.withValues(alpha: 0.1),
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.shieldAlert,
                    color: AcadexColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Provide this activation code and PIN Number to the student. They will use it once to activate their account and set their password.",
                      style: AcadexTypography.caption(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
