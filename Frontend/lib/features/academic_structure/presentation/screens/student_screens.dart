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
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
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
  String _searchQuery = '';
  String? _statusFilter; // null = all, 'active', 'pending_activation', etc.
  String? _departmentFilter;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated && authState.user.role == AppRole.hod) {
      _departmentFilter = authState.user.departmentId;
    }
  }

  void _showBulkPromotionDialog() async {
    if (_selectedIds.isEmpty) return;
    final allStudents = ref.read(studentsProvider((sectionId: null, departmentId: _departmentFilter))).items;
    final selectedStudents = allStudents.where((s) => _selectedIds.contains(s.id)).toList();
    final result = await StudentPromotionStepperDialog.show(
      context,
      students: selectedStudents,
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
      ref.invalidate(studentsProvider);
    }
  }

  void _showSinglePromotionDialog(Student s) async {
    final result = await StudentPromotionStepperDialog.show(
      context,
      students: [s],
      initialSectionId: s.sectionId,
      initialSemesterId: s.semesterId,
      initialDepartmentId: s.departmentId,
    );
    if (result == true) {
      ref.invalidate(studentsProvider);
    }
  }

  void _showBulkTransferDialog() async {
    if (_selectedIds.isEmpty) return;
    final result = await showDialog(
      context: context,
      builder: (ctx) => StudentTransferDialog(studentIds: _selectedIds.toList()),
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
      ref.invalidate(studentsProvider);
    }
  }

  void _showBulkGraduationDialog() async {
    if (_selectedIds.isEmpty) return;
    final result = await showDialog(
      context: context,
      builder: (ctx) => StudentGraduationDialog(studentIds: _selectedIds.toList()),
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
      ref.invalidate(studentsProvider);
    }
  }

  void _showImportDialog() {
    showDialog(context: context, builder: (ctx) => const ImportDataDialog(entityName: 'Students'));
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

    final studentsState = ref.watch(studentsProvider((sectionId: null, departmentId: _departmentFilter)));
    final deptMap = ref.watch(departmentMapProvider);
    final semMap = ref.watch(semesterMapProvider);
    final secMap = ref.watch(sectionMapProvider);

    final filteredStudents = studentsState.items.where((s) {
      if (_statusFilter != null) {
        if (_statusFilter == 'pending_activation') {
          if (s.accountStatus != AccountStatus.pendingActivation) return false;
        } else if (_statusFilter == 'active') {
          if (s.accountStatus != AccountStatus.active || s.lifecycleState != StudentLifecycleState.active) {
            return false;
          }
        } else if (_statusFilter == 'on_leave') {
          if (s.lifecycleState != StudentLifecycleState.onLeave) return false;
        } else if (_statusFilter == 'alumni') {
          if (s.lifecycleState != StudentLifecycleState.alumni && s.lifecycleState != StudentLifecycleState.graduated) {
            return false;
          }
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = s.name.toLowerCase().contains(q);
        final matchRoll = s.rollNumber.toLowerCase().contains(q);
        final matchInst = s.instituteId?.toLowerCase().contains(q) ?? false;
        final matchEmail = s.email.toLowerCase().contains(q);
        final dept = deptMap[s.departmentId]?.name.toLowerCase() ?? '';
        final matchDept = dept.contains(q);
        if (!matchName && !matchRoll && !matchInst && !matchEmail && !matchDept) return false;
      }
      return true;
    }).toList();

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: AcadexPageHeader(
                    title: "Students",
                    subtitle: "Manage student enrollments & admissions.",
                  ),
                ),
                if (_selectedIds.isNotEmpty) ...[
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.1),
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${_selectedIds.length}",
                            style: const TextStyle(
                              color: AcadexColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 14, color: AcadexColors.primary),
                        ],
                      ),
                    ),
                    onSelected: (val) {
                      if (val == 'promote') _showBulkPromotionDialog();
                      if (val == 'transfer') _showBulkTransferDialog();
                      if (val == 'graduate') _showBulkGraduationDialog();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'promote', child: Text("Promote Students")),
                      const PopupMenuItem(value: 'transfer', child: Text("Transfer Section")),
                      const PopupMenuItem(value: 'graduate', child: Text("Graduate Cohort")),
                    ],
                  ),
                ] else ...[
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
                    title: "Student Management",
                    subtitle: "Manage admissions, enrollments, promotions, and student profiles.",
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showImportDialog,
                      icon: const Icon(LucideIcons.uploadCloud, size: 16),
                      label: const Text("Import CSV"),
                    ),
                    const SizedBox(width: 12),
                    if (_selectedIds.isNotEmpty) ...[
                      DropdownButton<String>(
                        dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                        hint: Text(
                          "${_selectedIds.length} Selected",
                          style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold),
                        ),
                        underline: const SizedBox(),
                        icon: const Icon(LucideIcons.chevronDown, color: AcadexColors.primary),
                        items: [
                          DropdownMenuItem(value: 'promote', child: Text("Promote Students", style: AcadexTypography.body(color: theme.colorScheme.onSurface))),
                          DropdownMenuItem(value: 'transfer', child: Text("Transfer Section", style: AcadexTypography.body(color: theme.colorScheme.onSurface))),
                          DropdownMenuItem(value: 'graduate', child: Text("Graduate Cohort", style: AcadexTypography.body(color: theme.colorScheme.onSurface))),
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
            ),
          ],
          const SizedBox(height: 8),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Students', null),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending Activation', 'pending_activation'),
                const SizedBox(width: 8),
                _buildFilterChip('On Leave', 'on_leave'),
                const SizedBox(width: 8),
                _buildFilterChip('Alumni / Graduated', 'alumni'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          AcadexSearchFilterBar(
            searchHint: "Search students by name, roll no, PIN number, or department...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/students/new'),
            actionLabel: "Add Student",
          ),
          const SizedBox(height: 14),
          Expanded(
            child: studentsState.isLoading && studentsState.items.isEmpty
                ? const Center(child: AcadexLoadingState(message: "Loading students..."))
                : studentsState.error != null
                    ? AcadexErrorState.fromError(
                        error: studentsState.error,
                        title: "Unable to load students",
                        onRetry: () => ref.read(studentsProvider((sectionId: null, departmentId: _departmentFilter)).notifier).loadInitial(),
                      )
                    : filteredStudents.isEmpty
                        ? (studentsState.items.isNotEmpty
                            ? AcadexEmptyState.filterEmpty(
                                title: "No students match criteria",
                                subtitle: "Try clearing search or filters to see all students.",
                                onClearFilters: () {
                                  final authState = ref.read(authProvider);
                                  final isHod = authState is AuthAuthenticated && authState.user.role == AppRole.hod;
                                  setState(() {
                                    _searchQuery = '';
                                    _statusFilter = null;
                                    _departmentFilter = isHod ? authState.user.departmentId : null;
                                  });
                                },
                              )
                            : AcadexEmptyState(
                                title: "No students have been added yet.",
                                subtitle: "Add students to manage admissions and academic enrollments.",
                                icon: LucideIcons.users,
                                actionLabel: "Add Student",
                                onActionTap: () => context.push('/academics/students/new'),
                              ))
                        : isMobile
                            ? _buildMobileList(filteredStudents, deptMap, semMap, secMap, isDark)
                            : _buildDesktopTable(filteredStudents, deptMap, semMap, secMap, theme),
          ),
          if (studentsState.isFetchingMore)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator(color: AcadexColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AcadexColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AcadexColors.primary : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildMobileList(
    List<Student> students,
    Map<String, Department> deptMap,
    Map<String, Semester> semMap,
    Map<String, Section> secMap,
    bool isDark,
  ) {
    if (students.isEmpty) {
      return AcadexEmptyState(
        title: "No students have been added yet.",
        subtitle: _searchQuery.isNotEmpty
            ? "No students match '$_searchQuery'."
            : "Add students to manage admissions and academic enrollments.",
        icon: LucideIcons.users,
        actionLabel: "Add Student",
        onActionTap: () => context.push('/academics/students/new'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = students[i];
        final deptName = deptMap[s.departmentId]?.name ?? (s.departmentId.isNotEmpty ? s.departmentId : '—');
        final sem = semMap[s.semesterId];
        final semName = sem != null ? 'Sem ${sem.semesterNumber}' : (s.semesterId.isNotEmpty ? s.semesterId : '—');
        final sec = secMap[s.sectionId];
        final secName = sec != null ? 'Sec ${sec.name}' : (s.sectionId.isNotEmpty ? s.sectionId : '—');
        final isSelected = _selectedIds.contains(s.id);
        final statusLabel = s.accountStatus == AccountStatus.pendingActivation
            ? 'Pending Activation'
            : s.lifecycleState.displayName;

        return InkWell(
          onTap: () => context.push('/academics/students/${s.id}'),
          borderRadius: AcadexRadius.borderRadiusLg,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(
                color: isSelected
                    ? AcadexColors.primary
                    : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AcadexBadge(
                      label: statusLabel,
                      variant: _getBadgeVariant(s),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "PIN: ${s.instituteId ?? s.rollNumber} • $deptName",
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$semName • $secName",
                      style: AcadexTypography.caption(
                        color: AcadexColors.primary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: "Promote",
                          icon: const Icon(LucideIcons.arrowUpRight, size: 18, color: AcadexColors.success),
                          onPressed: () => _showSinglePromotionDialog(s),
                        ),
                        IconButton(
                          tooltip: "Edit",
                          icon: Icon(
                            LucideIcons.edit,
                            size: 18,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                          onPressed: () => context.push('/academics/students/edit/${s.id}'),
                        ),
                      ],
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

  Widget _buildDesktopTable(
    List<Student> filteredStudents,
    Map<String, Department> deptMap,
    Map<String, Semester> semMap,
    Map<String, Section> secMap,
    ThemeData theme,
  ) {
    return AcadexDataTable(
      showCheckboxColumn: true,
      columns: const ["PIN Number", "Roll No", "Student Name", "Department", "Semester", "Section", "Status", "Actions"],
      rows: filteredStudents.map((s) {
        final deptName = deptMap[s.departmentId]?.name ?? (s.departmentId.isNotEmpty ? s.departmentId : '—');
        final sem = semMap[s.semesterId];
        final semName = sem != null ? 'Semester ${sem.semesterNumber}' : (s.semesterId.isNotEmpty ? s.semesterId : '—');
        final sec = secMap[s.sectionId];
        final secName = sec != null ? 'Sec ${sec.name}' : (s.sectionId.isNotEmpty ? s.sectionId : '—');
        final statusLabel = s.accountStatus == AccountStatus.pendingActivation
            ? 'Pending Activation'
            : s.lifecycleState.displayName;

        return DataRow(
          selected: _selectedIds.contains(s.id),
          onSelectChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedIds.add(s.id);
              } else {
                _selectedIds.remove(s.id);
              }
            });
          },
          cells: [
            DataCell(
              Text(
                s.instituteId ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(
              InkWell(
                onTap: () => context.push('/academics/students/${s.id}'),
                child: Text(
                  s.rollNumber.isNotEmpty ? s.rollNumber : '—',
                  style: AcadexTypography.body(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(
              InkWell(
                onTap: () => context.push('/academics/students/${s.id}'),
                child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            DataCell(Text(deptName)),
            DataCell(Text(semName)),
            DataCell(Text(secName)),
            DataCell(
              AcadexBadge(
                label: statusLabel,
                variant: _getBadgeVariant(s),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: "View Profile",
                    icon: const Icon(LucideIcons.user, size: 18, color: AcadexColors.primary),
                    onPressed: () => context.push('/academics/students/${s.id}'),
                  ),
                  IconButton(
                    tooltip: "Promote Student",
                    icon: const Icon(LucideIcons.arrowUpRight, size: 18, color: AcadexColors.success),
                    onPressed: () => _showSinglePromotionDialog(s),
                  ),
                  IconButton(
                    tooltip: "Edit Student",
                    icon: Icon(LucideIcons.edit, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    onPressed: () => context.push('/academics/students/edit/${s.id}'),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
      emptyState: AcadexEmptyState(
        title: "No students have been added yet.",
        subtitle: "Add students to manage admissions and academic enrollments.",
        icon: LucideIcons.users,
        actionLabel: "Add Student",
        onActionTap: () => context.push('/academics/students/new'),
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
    final collegeId = authState is AuthAuthenticated ? (authState.user.collegeId ?? 'c1') : 'c1';

    if (_selectedCourseId == null) {
      AcadexSnackBar.showWarning(context, "Please select a Course first.");
      return;
    }

    setState(() => _isAutoGenerating = true);
    try {
      final roll = await ref.read(academicRepositoryProvider).generateRollNumber(
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
          parentName: _parentNameController.text.trim().isNotEmpty ? _parentNameController.text.trim() : null,
          parentPhone: _parentPhoneController.text.trim().isNotEmpty ? _parentPhoneController.text.trim() : null,
          bloodGroup: _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
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
          AcadexSnackBar.showSuccess(context, "Student profile updated successfully");
          context.safePop(fallbackRoute: '/academics/students');
        }
      } else {
        // Provision New Student
        final req = ProvisionStudentRequest(
          departmentId: _selectedDeptId!,
          name: _nameController.text.trim(),
          instituteId: _instituteIdController.text.trim().toUpperCase(),
          rollNumber: _rollNumberController.text.trim().isNotEmpty ? _rollNumberController.text.trim() : null,
          admissionNumber: _admissionNumberController.text.trim().isNotEmpty ? _admissionNumberController.text.trim() : null,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          parentName: _parentNameController.text.trim().isNotEmpty ? _parentNameController.text.trim() : null,
          parentPhone: _parentPhoneController.text.trim().isNotEmpty ? _parentPhoneController.text.trim() : null,
          bloodGroup: _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
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
        AcadexSnackBar.showError(context, e, fallbackMessage: "Failed to save student");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.id != null;

    final authState = ref.watch(authProvider);
    final isStaff = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.hod || authState.user.role == AppRole.faculty);

    final departmentsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final academicYearsAsync = ref.watch(academicYearsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.safePop(fallbackRoute: '/academics/students'),
        ),
        title: Text(
          isEdit ? "Edit Student" : "Add Student",
          style: AcadexTypography.title(color: theme.colorScheme.onSurface),
        ),
      ),
      body: _isLoading && isEdit
          ? const Center(child: AcadexLoadingState(message: "Loading student record..."))
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
                              borderRadius: BorderRadius.circular(AcadexRadius.sm),
                              border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AcadexColors.error))),
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
                                        prefixIcon: Icon(LucideIcons.user, size: 18),
                                      ),
                                      validator: (v) => (v == null || v.trim().length < 2)
                                          ? 'Name must be at least 2 characters'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _instituteIdController,
                                      textCapitalization: TextCapitalization.characters,
                                      decoration: const InputDecoration(
                                        labelText: "PIN Number *",
                                        prefixIcon: Icon(LucideIcons.idCard, size: 18),
                                        hintText: "e.g. 26CSE042",
                                      ),
                                      validator: (v) => (v == null || v.trim().length < 2)
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
                                        prefixIcon: Icon(LucideIcons.mail, size: 18),
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
                                        prefixIcon: Icon(LucideIcons.phone, size: 18),
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
                                        final activeDepts = departments.where((d) => d.isActive).toList();
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                          decoration: InputDecoration(
                                            labelText: "Department *",
                                            prefixIcon: const Icon(LucideIcons.building, size: 18),
                                            helperText: isStaff ? "Locked to your assigned department" : null,
                                          ),
                                          initialValue: _selectedDeptId,
                                          items: activeDepts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                                          onChanged: isStaff
                                              ? null
                                              : (val) => setState(() {
                                                    _selectedDeptId = val;
                                                    _selectedCourseId = null;
                                                    _selectedSemesterId = null;
                                                    _selectedSectionId = null;
                                                  }),
                                          validator: (v) => v == null ? 'Select department' : null,
                                        );
                                      },
                                      loading: () => const LinearProgressIndicator(),
                                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: coursesAsync.when(
                                      data: (courses) {
                                        final filtered = _selectedDeptId != null
                                            ? courses.where((c) => c.departmentId == _selectedDeptId && c.isActive).toList()
                                            : <Course>[];
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                          decoration: InputDecoration(
                                            labelText: "Course",
                                            prefixIcon: const Icon(LucideIcons.book, size: 18),
                                            hintText: _selectedDeptId == null ? 'Select Department first' : 'Choose Course',
                                          ),
                                          initialValue: _selectedCourseId,
                                          items: filtered.map((c) => DropdownMenuItem(value: c.id, child: Text("${c.name} (${c.code})"))).toList(),
                                          onChanged: _selectedDeptId == null
                                              ? null
                                              : (val) => setState(() {
                                                    _selectedCourseId = val;
                                                    _selectedSemesterId = null;
                                                    _selectedSectionId = null;
                                                  }),
                                        );
                                      },
                                      loading: () => const LinearProgressIndicator(),
                                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
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
                                        final activeYears = years.where((y) => y.isActive).toList();
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                          decoration: const InputDecoration(
                                            labelText: "Academic Year",
                                            prefixIcon: Icon(LucideIcons.calendar, size: 18),
                                          ),
                                          initialValue: _selectedAcademicYearId,
                                          items: activeYears.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name))).toList(),
                                          onChanged: (val) => setState(() {
                                            _selectedAcademicYearId = val;
                                            _selectedSemesterId = null;
                                            _selectedSectionId = null;
                                          }),
                                        );
                                      },
                                      loading: () => const LinearProgressIndicator(),
                                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: semestersAsync.when(
                                      data: (semesters) {
                                        final filtered = _selectedCourseId != null
                                            ? semesters.where((s) {
                                                if (s.courseId != _selectedCourseId) return false;
                                                if (_selectedAcademicYearId != null && s.academicYearId != _selectedAcademicYearId) return false;
                                                return s.isActive;
                                              }).toList()
                                            : <Semester>[];
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                          decoration: InputDecoration(
                                            labelText: "Semester",
                                            prefixIcon: const Icon(LucideIcons.layers, size: 18),
                                            hintText: _selectedCourseId == null ? 'Select Course first' : 'Choose Semester',
                                          ),
                                          initialValue: _selectedSemesterId,
                                          items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name.isNotEmpty ? s.name : "Semester ${s.semesterNumber}"))).toList(),
                                          onChanged: _selectedCourseId == null
                                              ? null
                                              : (val) => setState(() {
                                                    _selectedSemesterId = val;
                                                    _selectedSectionId = null;
                                                  }),
                                        );
                                      },
                                      loading: () => const LinearProgressIndicator(),
                                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Section & Roll Number
                              Row(
                                children: [
                                  Expanded(
                                    child: sectionsAsync.when(
                                      data: (sections) {
                                        final filtered = _selectedSemesterId != null
                                            ? sections.where((s) {
                                                if (s.semesterId != _selectedSemesterId) return false;
                                                return s.isActive;
                                              }).toList()
                                            : <Section>[];
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                          decoration: InputDecoration(
                                            labelText: "Section",
                                            prefixIcon: const Icon(LucideIcons.layoutGrid, size: 18),
                                            hintText: _selectedSemesterId == null ? 'Select Semester first' : 'Choose Section',
                                          ),
                                          initialValue: _selectedSectionId,
                                          items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text("Section ${s.name}"))).toList(),
                                          onChanged: _selectedSemesterId == null
                                              ? null
                                              : (val) => setState(() => _selectedSectionId = val),
                                        );
                                      },
                                      loading: () => const LinearProgressIndicator(),
                                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _rollNumberController,
                                      decoration: InputDecoration(
                                        labelText: "Roll Number",
                                        prefixIcon: const Icon(LucideIcons.hash, size: 18),
                                        suffixIcon: IconButton(
                                          tooltip: "Auto-Generate Roll Number",
                                          icon: _isAutoGenerating
                                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Icon(LucideIcons.sparkles, color: AcadexColors.primary),
                                          onPressed: _isAutoGenerating ? null : _autoGenerateRollNumber,
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
                                        prefixIcon: Icon(LucideIcons.userCheck, size: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _parentPhoneController,
                                      decoration: const InputDecoration(
                                        labelText: "Parent Phone Number",
                                        prefixIcon: Icon(LucideIcons.phoneCall, size: 18),
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
                                        prefixIcon: Icon(LucideIcons.fileText, size: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _bloodGroupController,
                                      decoration: const InputDecoration(
                                        labelText: "Blood Group (e.g. O+, A+)",
                                        prefixIcon: Icon(LucideIcons.heartPulse, size: 18),
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
                                          prefixIcon: Icon(LucideIcons.calendar, size: 18),
                                        ),
                                        child: Text(
                                          _dateOfBirth != null
                                              ? "${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}"
                                              : "Select Date of Birth",
                                          style: TextStyle(
                                            color: _dateOfBirth != null ? null : theme.hintColor,
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
                                          prefixIcon: Icon(LucideIcons.calendarCheck, size: 18),
                                        ),
                                        child: Text(
                                          _admissionDate != null
                                              ? "${_admissionDate!.year}-${_admissionDate!.month.toString().padLeft(2, '0')}-${_admissionDate!.day.toString().padLeft(2, '0')}"
                                              : "Select Admission Date",
                                          style: TextStyle(
                                            color: _admissionDate != null ? null : theme.hintColor,
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
                                  prefixIcon: Icon(LucideIcons.mapPin, size: 18),
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
                              onPressed: () => context.safePop(fallbackRoute: '/academics/students'),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveStudent,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Icon(isEdit ? LucideIcons.save : LucideIcons.userPlus, size: 18),
                              label: Text(isEdit ? "Save Changes" : "Add Student"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcadexColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
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
                  child: const Icon(LucideIcons.checkCircle, color: AcadexColors.success, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Student Provisioned Successfully",
                        style: AcadexTypography.heading3(color: theme.colorScheme.onSurface),
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
                border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Student Name", result.student.name),
                  const SizedBox(height: 6),
                  _buildSummaryRow("PIN Number", result.user.instituteId ?? result.student.instituteId ?? '—'),
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
              style: AcadexTypography.caption(color: theme.hintColor).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),

            // Activation Code Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.08),
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.key, color: AcadexColors.primary, size: 20),
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
                    icon: const Icon(LucideIcons.copy, size: 18, color: AcadexColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.activationCode));
                      AcadexSnackBar.showSuccess(context, "Activation code copied to clipboard!");
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
                  const Icon(LucideIcons.shieldAlert, color: AcadexColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Provide this activation code and PIN Number to the student. They will use it once to activate their account and set their password.",
                      style: AcadexTypography.caption(color: theme.colorScheme.onSurface),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
