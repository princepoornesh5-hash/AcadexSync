import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart' as auth;
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../providers/department_setup_provider.dart';
import 'setup_continuation_dialog.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_workflow_context_banner.dart';

class FacultyAssignmentDialog extends ConsumerStatefulWidget {
  final Faculty? preselectedFaculty;
  final String? initialCourseId;
  final String? initialSemesterId;
  final String? initialSectionId;
  final String? initialSubjectId;
  final String? initialAcademicYearId;

  const FacultyAssignmentDialog({
    super.key,
    this.preselectedFaculty,
    this.initialCourseId,
    this.initialSemesterId,
    this.initialSectionId,
    this.initialSubjectId,
    this.initialAcademicYearId,
  });

  static Future<void> show(
    BuildContext context, {
    Faculty? faculty,
    String? initialCourseId,
    String? initialSemesterId,
    String? initialSectionId,
    String? initialSubjectId,
    String? initialAcademicYearId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FacultyAssignmentDialog(
        preselectedFaculty: faculty,
        initialCourseId: initialCourseId,
        initialSemesterId: initialSemesterId,
        initialSectionId: initialSectionId,
        initialSubjectId: initialSubjectId,
        initialAcademicYearId: initialAcademicYearId,
      ),
    );
  }

  @override
  ConsumerState<FacultyAssignmentDialog> createState() => _FacultyAssignmentDialogState();
}

class _FacultyAssignmentDialogState extends ConsumerState<FacultyAssignmentDialog> {
  String? _selectedFacultyId;
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  String? _selectedSubjectId;
  String? _selectedAcademicYearId;
  bool _showManualContext = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedFaculty != null) {
      _selectedFacultyId = widget.preselectedFaculty!.id;
      _selectedDepartmentId = widget.preselectedFaculty!.departmentId;
    }
    if (widget.initialCourseId != null) _selectedCourseId = widget.initialCourseId;
    if (widget.initialSemesterId != null) _selectedSemesterId = widget.initialSemesterId;
    if (widget.initialSectionId != null) _selectedSectionId = widget.initialSectionId;
    if (widget.initialSubjectId != null) _selectedSubjectId = widget.initialSubjectId;
    if (widget.initialAcademicYearId != null) _selectedAcademicYearId = widget.initialAcademicYearId;
  }

  Future<void> _handleAssign() async {
    if (_isSubmitting) return;
    if (_selectedFacultyId == null ||
        _selectedDepartmentId == null ||
        _selectedCourseId == null ||
        _selectedSemesterId == null ||
        _selectedSectionId == null ||
        _selectedSubjectId == null) {
      AcadexSnackBar.showWarning(context, 'Please select all required fields (Faculty, Department, Course, Semester, Section, Subject)');
      return;
    }

    final academicYears = ref.read(academicYearsProvider).valueOrNull ?? [];
    final activeYearId = _selectedAcademicYearId ??
        academicYears.where((y) => y.isActive).firstOrNull?.id ??
        (academicYears.isNotEmpty ? academicYears.first.id : 'ay_current');

    // Check duplicate in active assignments
    final existing = (ref.read(facultyAssignmentsProvider).valueOrNull ?? []).where(
      (a) =>
          a.isActive &&
          a.facultyId == _selectedFacultyId &&
          a.subjectId == _selectedSubjectId &&
          a.sectionId == _selectedSectionId &&
          a.semesterId == _selectedSemesterId &&
          a.courseId == _selectedCourseId &&
          a.academicYearId == activeYearId,
    );

    if (existing.isNotEmpty) {
      AcadexSnackBar.showWarning(
        context,
        'This faculty member is already assigned to this subject and section.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final facultyList = ref.read(facultyProvider(null)).items;
      final faculty = facultyList.firstWhere(
        (f) => f.id == _selectedFacultyId,
        orElse: () => Faculty(
          id: _selectedFacultyId!,
          collegeId: '',
          departmentId: _selectedDepartmentId!,
          name: 'Faculty',
          employeeId: '',
          email: '',
          phone: '',
        ),
      );

      final assignment = FacultyAssignment(
        id: 'fa_${DateTime.now().millisecondsSinceEpoch}',
        collegeId: faculty.collegeId,
        departmentId: _selectedDepartmentId!,
        facultyId: _selectedFacultyId!,
        facultyName: faculty.name,
        courseId: _selectedCourseId!,
        semesterId: _selectedSemesterId!,
        sectionId: _selectedSectionId!,
        subjectId: _selectedSubjectId!,
        academicYearId: activeYearId,
        assignedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(facultyAssignmentsProvider.notifier).createAssignment(assignment);
      ref.invalidate(facultyAssignmentsProvider);
      if (_selectedDepartmentId != null) {
        ref.invalidate(departmentSetupProvider(_selectedDepartmentId!));
      }

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Assigned ${faculty.name} successfully',
        );
        Navigator.of(context).pop();
        SetupContinuationDialog.show(
          context,
          title: 'Faculty Assigned Successfully',
          entityName: faculty.name,
          message: 'Teaching allocation active. Continue to enroll admitted students into section cohorts.',
          primaryActionLabel: 'Continue to Enrollment',
          onContinue: () {
            final queryParts = <String>[];
            if (_selectedCourseId != null) queryParts.add('courseId=$_selectedCourseId');
            if (_selectedSemesterId != null) queryParts.add('semesterId=$_selectedSemesterId');
            if (_selectedSectionId != null) queryParts.add('sectionId=$_selectedSectionId');
            final q = queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
            context.push('/academics/students$q');
          },
          secondaryActionLabel: 'Done',
        );
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Faculty assignment failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(auth.authProvider);
    UserModel? currentUser;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    }
    final isHod = currentUser?.role == AppRole.hod;
    final hodDeptId = currentUser?.departmentId;

    if (isHod && hodDeptId != null && hodDeptId.isNotEmpty && _selectedDepartmentId == null) {
      _selectedDepartmentId = hodDeptId;
    }

    final facultyState = ref.watch(facultyProvider(null));
    final departments = ref.watch(departmentsProvider).valueOrNull ?? [];
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
    final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final academicYears = ref.watch(academicYearsProvider).valueOrNull ?? [];
    final assignmentsAsync = ref.watch(facultyAssignmentsProvider);

    // Filter faculty based on selected department or HOD scope (Strictly Active only)
    final availableFaculty = facultyState.items.where((f) {
      if (!f.isActive || f.accountStatus != AccountStatus.active) return false;
      if (isHod && hodDeptId != null && hodDeptId.isNotEmpty) {
        return f.departmentId == hodDeptId;
      }
      if (_selectedDepartmentId != null && _selectedDepartmentId!.isNotEmpty) {
        return f.departmentId == _selectedDepartmentId || f.departmentId.isEmpty;
      }
      return true;
    }).toList();

    // Cascading filters (Strict dependencies: Dept -> Course -> Semester -> Section / Subject)
    final filteredCourses = _selectedDepartmentId == null
        ? <Course>[]
        : courses.where((c) => c.departmentId == _selectedDepartmentId && c.isActive).toList();

    final filteredSemesters = _selectedCourseId == null
        ? <Semester>[]
        : semesters.where((s) => s.courseId == _selectedCourseId && s.isActive).toList();

    final filteredSections = _selectedSemesterId == null
        ? <Section>[]
        : sections.where((sec) => sec.semesterId == _selectedSemesterId && sec.isActive).toList();

    final filteredSubjects = (_selectedCourseId == null || _selectedSemesterId == null)
        ? <Subject>[]
        : subjects.where((sub) => sub.courseId == _selectedCourseId && sub.semesterId == _selectedSemesterId && sub.isActive).toList();

    final facultyAssignments = (assignmentsAsync.valueOrNull ?? []).where((a) {
      if (isHod && hodDeptId != null && hodDeptId.isNotEmpty && a.departmentId != hodDeptId) {
        return false;
      }
      if (_selectedFacultyId != null) {
        return a.facultyId == _selectedFacultyId;
      }
      return true;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AcadexRadius.md),
                        ),
                        child: const Icon(LucideIcons.userCheck, color: AcadexColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faculty Subject & Class Assignment',
                              style: AcadexTypography.heading3(color: theme.colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isHod ? 'Manage teaching allocations for your department' : 'Map faculty members to courses, semesters, sections & subjects',
                              style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Form selectors
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Scope & Assignment', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    
                    if (widget.initialCourseId != null && !_showManualContext) ...[
                      Builder(builder: (context) {
                        final selectedCourse = filteredCourses.where((c) => c.id == _selectedCourseId).firstOrNull;
                        final selectedSemester = filteredSemesters.where((s) => s.id == _selectedSemesterId).firstOrNull;
                        final selectedSection = filteredSections.where((s) => s.id == _selectedSectionId).firstOrNull;
                        final selectedSubject = filteredSubjects.where((s) => s.id == _selectedSubjectId).firstOrNull;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AcadexWorkflowContextBanner(
                              targetEntityName: 'Faculty Assignment',
                              contextItems: [
                                if (selectedCourse != null)
                                  AcadexContextItem(
                                    label: 'Course',
                                    value: selectedCourse.name,
                                    icon: LucideIcons.bookOpen,
                                  ),
                                if (selectedSemester != null)
                                  AcadexContextItem(
                                    label: 'Semester',
                                    value: selectedSemester.name,
                                    icon: LucideIcons.calendar,
                                  ),
                                if (selectedSection != null)
                                  AcadexContextItem(
                                    label: 'Section',
                                    value: 'Section ${selectedSection.name}',
                                    icon: LucideIcons.users,
                                  ),
                                if (selectedSubject != null)
                                  AcadexContextItem(
                                    label: 'Subject',
                                    value: '${selectedSubject.code} - ${selectedSubject.name}',
                                    icon: LucideIcons.fileText,
                                  ),
                              ],
                              onChangeContext: () => setState(() => _showManualContext = true),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('fac_context_${_selectedDepartmentId}_$_selectedFacultyId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedFacultyId,
                              decoration: InputDecoration(
                                labelText: 'Faculty Member *',
                                hintText: availableFaculty.isEmpty ? 'No active faculty available' : 'Choose faculty',
                              ),
                              items: availableFaculty.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: availableFaculty.isEmpty
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedFacultyId = val;
                                      });
                                    },
                            ),
                          ],
                        );
                      }),
                    ] else ...[
                      // Row 1: Department + Course
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('dept_$_selectedDepartmentId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedDepartmentId,
                              decoration: InputDecoration(
                                labelText: isHod ? 'Department (Locked)' : 'Department *',
                                hintText: 'Choose department',
                              ),
                              items: departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: isHod
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedDepartmentId = val;
                                        _selectedCourseId = null;
                                        _selectedSemesterId = null;
                                        _selectedSectionId = null;
                                        _selectedSubjectId = null;
                                        _selectedFacultyId = null;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('course_${_selectedDepartmentId}_$_selectedCourseId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedCourseId,
                              decoration: InputDecoration(
                                labelText: 'Course *',
                                hintText: _selectedDepartmentId == null ? 'Select Department first' : 'Choose course',
                              ),
                              items: filteredCourses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: _selectedDepartmentId == null
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedCourseId = val;
                                        _selectedSemesterId = null;
                                        _selectedSectionId = null;
                                        _selectedSubjectId = null;
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Academic Year + Semester + Section
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('ay_$_selectedAcademicYearId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedAcademicYearId,
                              decoration: const InputDecoration(labelText: 'Academic Year', hintText: 'Current Active'),
                              items: academicYears
                                  .map((y) => DropdownMenuItem(value: y.id, child: Text(y.name, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedAcademicYearId = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('sem_${_selectedCourseId}_$_selectedSemesterId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedSemesterId,
                              decoration: InputDecoration(
                                labelText: 'Semester *',
                                hintText: _selectedCourseId == null ? 'Select Course first' : 'Choose semester',
                              ),
                              items: filteredSemesters.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: _selectedCourseId == null
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedSemesterId = val;
                                        _selectedSectionId = null;
                                        _selectedSubjectId = null;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('sec_${_selectedSemesterId}_$_selectedSectionId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedSectionId,
                              decoration: InputDecoration(
                                labelText: 'Section *',
                                hintText: _selectedSemesterId == null ? 'Select Semester first' : 'Choose section',
                              ),
                              items: filteredSections.map((sec) => DropdownMenuItem(value: sec.id, child: Text('Section ${sec.name}', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: _selectedSemesterId == null
                                  ? null
                                  : (val) => setState(() => _selectedSectionId = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3: Subject + Faculty
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('sub_${_selectedCourseId}_${_selectedSemesterId}_$_selectedSubjectId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedSubjectId,
                              decoration: InputDecoration(
                                labelText: 'Subject *',
                                hintText: _selectedCourseId == null
                                    ? 'Select Course first'
                                    : (_selectedSemesterId == null
                                        ? 'Select Semester first'
                                        : (filteredSubjects.isEmpty ? 'No subjects in this semester' : 'Choose subject')),
                              ),
                              items: filteredSubjects.map((sub) => DropdownMenuItem(value: sub.id, child: Text('${sub.code} - ${sub.name}', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (_selectedCourseId == null || _selectedSemesterId == null || filteredSubjects.isEmpty)
                                  ? null
                                  : (val) => setState(() => _selectedSubjectId = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('fac_${_selectedDepartmentId}_$_selectedFacultyId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedFacultyId,
                              decoration: InputDecoration(
                                labelText: 'Faculty Member *',
                                hintText: availableFaculty.isEmpty ? 'No active faculty available' : 'Choose faculty',
                              ),
                              items: availableFaculty.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: availableFaculty.isEmpty
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedFacultyId = val;
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Faculty workload summary badge (if faculty selected)
                    if (_selectedFacultyId != null) ...[
                      Builder(
                        builder: (context) {
                          final selectedFacAssignments = (assignmentsAsync.valueOrNull ?? [])
                              .where((a) => a.facultyId == _selectedFacultyId && a.isActive)
                              .toList();
                          final subjectCount = selectedFacAssignments.map((a) => a.subjectId).toSet().length;
                          final sectionCount = selectedFacAssignments.map((a) => a.sectionId).toSet().length;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AcadexRadius.md),
                              border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.activity, color: AcadexColors.primary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Current Workload: $subjectCount subject(s) across $sectionCount section(s) (${selectedFacAssignments.length} total assignment${selectedFacAssignments.length == 1 ? '' : 's'})',
                                    style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    // Compact Assignment Summary Preview (Section 13)
                    Builder(
                      builder: (context) {
                        final fac = availableFaculty.where((f) => f.id == _selectedFacultyId).firstOrNull;
                        final sub = subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
                        final crs = courses.where((c) => c.id == _selectedCourseId).firstOrNull;
                        final sem = semesters.where((s) => s.id == _selectedSemesterId).firstOrNull;
                        final sec = sections.where((s) => s.id == _selectedSectionId).firstOrNull;
                        final ay = academicYears.where((y) => y.id == _selectedAcademicYearId).firstOrNull ??
                            academicYears.where((y) => y.isActive).firstOrNull;

                        return Container(
                          key: const Key('assignment_summary_card'),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            borderRadius: BorderRadius.circular(AcadexRadius.md),
                            border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.sparkles, size: 14, color: AcadexColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ASSIGNMENT PREVIEW',
                                    style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _buildSummaryPill('Faculty', fac?.name ?? 'None', LucideIcons.user),
                                  _buildSummaryPill('Subject', sub != null ? '${sub.code} - ${sub.name}' : 'None', LucideIcons.bookOpen),
                                  _buildSummaryPill('Course', crs?.code ?? crs?.name ?? 'None', LucideIcons.graduationCap),
                                  _buildSummaryPill('Session', ay?.name ?? 'Active Session', LucideIcons.calendar),
                                  _buildSummaryPill('Semester', sem?.name ?? 'None', LucideIcons.calendarClock),
                                  _buildSummaryPill('Section', sec != null ? 'Section ${sec.name}' : 'None', LucideIcons.users),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Assign Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: AcadexButton(
                        label: _isSubmitting ? 'Assigning...' : 'Assign Faculty to Class',
                        icon: LucideIcons.plus,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _handleAssign,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Active Assignments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Assignments (${facultyAssignments.length})', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                        if (_selectedFacultyId != null)
                          TextButton.icon(
                            icon: const Icon(LucideIcons.rotateCcw, size: 14),
                            label: const Text('Show All'),
                            onPressed: () => setState(() => _selectedFacultyId = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (facultyAssignments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: AcadexEmptyState(
                            title: 'No faculty assignments yet.',
                            subtitle: 'Assignments created above will appear here.',
                            icon: LucideIcons.userCheck,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: facultyAssignments.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final a = facultyAssignments[index];
                          final sub = subjects.where((s) => s.id == a.subjectId).firstOrNull;
                          final sec = sections.where((s) => s.id == a.sectionId).firstOrNull;
                          final crs = courses.where((c) => c.id == a.courseId).firstOrNull;
                          final sem = semesters.where((s) => s.id == a.semesterId).firstOrNull;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: AcadexColors.primary.withValues(alpha: 0.12),
                              child: const Icon(LucideIcons.bookOpen, color: AcadexColors.primary, size: 18),
                            ),
                            title: Text(
                              '${a.facultyName} • ${sub?.name ?? a.subjectId}',
                              style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${crs?.name ?? a.courseId} • ${sem?.name ?? a.semesterId} • Section ${sec?.name ?? a.sectionId} • ${sub?.code ?? ''}',
                              style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                            ),
                            trailing: IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning),
                              tooltip: 'Remove Assignment',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove Assignment?'),
                                    content: Text('Unassign ${a.facultyName} from this class?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.warning),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Remove', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(facultyAssignmentsProvider.notifier).removeAssignment(a.id);
                                }
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AcadexColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AcadexRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AcadexColors.primary),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AcadexColors.primary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
