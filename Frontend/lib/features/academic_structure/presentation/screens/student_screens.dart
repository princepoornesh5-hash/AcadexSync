import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../widgets/import_data_dialog.dart';
import '../widgets/student_bulk_action_dialogs.dart';
import '../widgets/student_promotion_stepper_dialog.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  StudentLifecycleState? _selectedLifecycleFilter;

  void _showBulkPromotionDialog() async {
    if (_selectedIds.isEmpty) return;
    final allStudents = ref.read(studentsProvider((sectionId: null, departmentId: null))).items;
    final selectedStudents = allStudents.where((s) => _selectedIds.contains(s.id)).toList();
    final result = await StudentPromotionStepperDialog.show(
      context,
      students: selectedStudents,
    );
    if (result == true) {
      setState(() => _selectedIds.clear());
      ref.invalidate(studentsProvider((sectionId: null, departmentId: null)));
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
      ref.invalidate(studentsProvider((sectionId: null, departmentId: null)));
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
    }
  }

  void _showImportDialog() {
    showDialog(context: context, builder: (ctx) => const ImportDataDialog(entityName: 'Students'));
  }

  AcadexBadgeVariant _getBadgeVariant(StudentLifecycleState state) {
    switch (state) {
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

    final studentsState = ref.watch(studentsProvider((sectionId: null, departmentId: null)));
    final deptMap = ref.watch(departmentMapProvider);
    final semMap = ref.watch(semesterMapProvider);
    final secMap = ref.watch(sectionMapProvider);

    final filteredStudents = studentsState.items.where((s) {
      if (_selectedLifecycleFilter != null && s.lifecycleState != _selectedLifecycleFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = s.name.toLowerCase().contains(q);
        final matchRoll = s.rollNumber.toLowerCase().contains(q);
        final matchEmail = s.email.toLowerCase().contains(q);
        if (!matchName && !matchRoll && !matchEmail) return false;
      }
      return true;
    }).toList();

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: AcadexPageHeader(
                  title: "Students",
                  subtitle: "Manage student lifecycle, admissions, promotions, and academic records.",
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
                      hint: Text("${_selectedIds.length} Selected", style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 12),

          // Lifecycle State Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text("All Students"),
                  selected: _selectedLifecycleFilter == null,
                  onSelected: (_) => setState(() => _selectedLifecycleFilter = null),
                ),
                const SizedBox(width: 8),
                ...StudentLifecycleState.values.map((state) {
                  final isSelected = _selectedLifecycleFilter == state;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(state.displayName),
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        _selectedLifecycleFilter = isSelected ? null : state;
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          AcadexSearchFilterBar(
            searchHint: "Search students by name, roll number, or email...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/students/new'),
            actionLabel: "Admit Student",
          ),
          const SizedBox(height: 16),
          Expanded(
            child: studentsState.isLoading && studentsState.items.isEmpty
                ? const Center(child: AcadexLoadingState(message: "Loading students..."))
                : studentsState.error != null
                    ? Center(child: Text("Error: ${studentsState.error}", style: const TextStyle(color: AcadexColors.warning)))
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!studentsState.isLoading &&
                              !studentsState.hasReachedMax &&
                              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                            ref.read(studentsProvider((sectionId: null, departmentId: null)).notifier).loadMore();
                          }
                          return false;
                        },
                        child: AcadexDataTable(
                          columns: const ["Roll No", "Name", "Department", "Semester", "Section", "Status", "Actions"],
                          rows: filteredStudents.map((s) {
                            final deptName = deptMap[s.departmentId]?.name ?? (s.departmentId.isNotEmpty ? s.departmentId : '—');
                            final sem = semMap[s.semesterId];
                            final semName = sem != null ? 'Semester ${sem.semesterNumber}' : (s.semesterId.isNotEmpty ? s.semesterId : '—');
                            final sec = secMap[s.sectionId];
                            final secName = sec != null ? 'Sec ${sec.name}' : (s.sectionId.isNotEmpty ? s.sectionId : '—');

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
                                  InkWell(
                                    onTap: () => context.push('/academics/students/${s.id}'),
                                    child: Text(
                                      s.rollNumber,
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
                                    label: s.lifecycleState.displayName,
                                    variant: _getBadgeVariant(s.lifecycleState),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: "View Academic Profile",
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
                            title: "No Students Found",
                            subtitle: "Admit students into sections to get started.",
                            icon: LucideIcons.users,
                            actionLabel: "Admit Student",
                            onActionTap: () => context.push('/academics/students/new'),
                          ),
                        ),
                      ),
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
}

class StudentFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const StudentFormScreen({super.key, this.id});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _addressController = TextEditingController();

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
    if (widget.id != null) {
      _loadExistingStudent();
    }
  }

  void _loadExistingStudent() async {
    setState(() => _isLoading = true);
    final repo = ref.read(academicRepositoryProvider);
    final student = await repo.getStudentById(widget.id!);
    if (student != null && mounted) {
      _nameController.text = student.name;
      _emailController.text = student.email;
      _phoneController.text = student.phone;
      _rollNumberController.text = student.rollNumber;
      _parentNameController.text = student.parentName ?? '';
      _parentPhoneController.text = student.parentPhone ?? '';
      _bloodGroupController.text = student.bloodGroup ?? '';
      _addressController.text = student.address ?? '';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Course first.")),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate roll number: $e")),
      );
    } finally {
      setState(() => _isAutoGenerating = false);
    }
  }

  void _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final collegeId = authState is AuthAuthenticated ? (authState.user.collegeId ?? 'c1') : 'c1';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentId = widget.id ?? 'stu_${DateTime.now().millisecondsSinceEpoch}';
      final student = Student(
        id: studentId,
        collegeId: collegeId,
        departmentId: _selectedDeptId ?? '',
        courseId: _selectedCourseId ?? '',
        academicYearId: _selectedAcademicYearId ?? '',
        semesterId: _selectedSemesterId ?? '',
        sectionId: _selectedSectionId ?? '',
        name: _nameController.text.trim(),
        rollNumber: _rollNumberController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        parentName: _parentNameController.text.trim().isNotEmpty ? _parentNameController.text.trim() : null,
        parentPhone: _parentPhoneController.text.trim().isNotEmpty ? _parentPhoneController.text.trim() : null,
        bloodGroup: _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        lifecycleState: _lifecycleState,
        isActive: _lifecycleState == StudentLifecycleState.active || _lifecycleState == StudentLifecycleState.admitted,
      );

      if (widget.id != null) {
        await ref.read(academicRepositoryProvider).updateStudent(student);
      } else {
        await ref.read(studentsProvider((sectionId: null, departmentId: null)).notifier).admitStudent(student);
      }

      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.id != null;

    final departmentsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final academicYearsAsync = ref.watch(academicYearsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEdit ? "Edit Student Profile" : "Admit New Student",
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

                        // Personal Information Card
                        AcadexFormCard(
                          title: "Personal Information",
                          icon: LucideIcons.user,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: "Full Name *",
                                  prefixIcon: Icon(LucideIcons.user, size: 18),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter student full name' : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: "Email Address *",
                                        prefixIcon: Icon(LucideIcons.mail, size: 18),
                                      ),
                                      validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: "Phone Number *",
                                        prefixIcon: Icon(LucideIcons.phone, size: 18),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _parentNameController,
                                      decoration: const InputDecoration(
                                        labelText: "Parent / Guardian Name",
                                        prefixIcon: Icon(LucideIcons.shieldCheck, size: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _parentPhoneController,
                                      decoration: const InputDecoration(
                                        labelText: "Parent Contact",
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
                                      controller: _bloodGroupController,
                                      decoration: const InputDecoration(
                                        labelText: "Blood Group",
                                        prefixIcon: Icon(LucideIcons.heartPulse, size: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _addressController,
                                      decoration: const InputDecoration(
                                        labelText: "Residential Address",
                                        prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Academic Enrollment Card
                        AcadexFormCard(
                          title: "Academic Enrollment & Structure",
                          icon: LucideIcons.graduationCap,
                          child: Column(
                            children: [
                              // Department & Course
                              Row(
                                children: [
                                  Expanded(
                                    child: departmentsAsync.when(
                                      data: (departments) => DropdownButtonFormField<String>(
                                        dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                        decoration: const InputDecoration(
                                          labelText: "Department *",
                                          prefixIcon: Icon(LucideIcons.building, size: 18),
                                        ),
                                        initialValue: _selectedDeptId,
                                        items: departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                                        onChanged: (val) => setState(() {
                                          _selectedDeptId = val;
                                          _selectedCourseId = null;
                                          _selectedSemesterId = null;
                                          _selectedSectionId = null;
                                        }),
                                        validator: (v) => v == null ? 'Select department' : null,
                                      ),
                                      loading: () => const LinearProgressIndicator(),
                                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: coursesAsync.when(
                                      data: (courses) {
                                        final filtered = _selectedDeptId != null
                                            ? courses.where((c) => c.departmentId == _selectedDeptId).toList()
                                            : courses;
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                          decoration: const InputDecoration(
                                            labelText: "Course *",
                                            prefixIcon: Icon(LucideIcons.book, size: 18),
                                          ),
                                          initialValue: _selectedCourseId,
                                          items: filtered.map((c) => DropdownMenuItem(value: c.id, child: Text("${c.name} (${c.code})"))).toList(),
                                          onChanged: (val) => setState(() {
                                            _selectedCourseId = val;
                                            _selectedSemesterId = null;
                                            _selectedSectionId = null;
                                          }),
                                          validator: (v) => v == null ? 'Select course' : null,
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
                                      data: (years) => DropdownButtonFormField<String>(
                                        dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                        decoration: const InputDecoration(
                                          labelText: "Academic Year *",
                                          prefixIcon: Icon(LucideIcons.calendar, size: 18),
                                        ),
                                        initialValue: _selectedAcademicYearId,
                                        items: years.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name))).toList(),
                                        onChanged: (val) => setState(() => _selectedAcademicYearId = val),
                                        validator: (v) => v == null ? 'Select academic year' : null,
                                      ),
                                      loading: () => const LinearProgressIndicator(),
                                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: semestersAsync.when(
                                      data: (semesters) {
                                        final filtered = _selectedCourseId != null
                                            ? semesters.where((s) => s.courseId == _selectedCourseId).toList()
                                            : semesters;
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                          decoration: const InputDecoration(
                                            labelText: "Semester *",
                                            prefixIcon: Icon(LucideIcons.layers, size: 18),
                                          ),
                                          initialValue: _selectedSemesterId,
                                          items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                                          onChanged: (val) => setState(() {
                                            _selectedSemesterId = val;
                                            _selectedSectionId = null;
                                          }),
                                          validator: (v) => v == null ? 'Select semester' : null,
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
                                            ? sections.where((s) => s.semesterId == _selectedSemesterId).toList()
                                            : sections;
                                        return DropdownButtonFormField<String>(
                                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                          decoration: const InputDecoration(
                                            labelText: "Section *",
                                            prefixIcon: Icon(LucideIcons.layoutGrid, size: 18),
                                          ),
                                          initialValue: _selectedSectionId,
                                          items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text("Section ${s.name}"))).toList(),
                                          onChanged: (val) => setState(() => _selectedSectionId = val),
                                          validator: (v) => v == null ? 'Select section' : null,
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
                                        labelText: "Roll Number *",
                                        prefixIcon: const Icon(LucideIcons.hash, size: 18),
                                        suffixIcon: IconButton(
                                          tooltip: "Auto-Generate Roll Number",
                                          icon: _isAutoGenerating
                                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                              : const Icon(LucideIcons.sparkles, color: AcadexColors.primary),
                                          onPressed: _isAutoGenerating ? null : _autoGenerateRollNumber,
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter or generate roll number' : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isLoading ? null : () => context.pop(),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcadexColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              ),
                              onPressed: _isLoading ? null : _saveStudent,
                              child: _isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(isEdit ? "Update Student" : "Admit Student"),
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
