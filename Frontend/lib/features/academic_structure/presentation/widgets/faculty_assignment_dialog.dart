import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
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
import '../../../../core/errors/acadex_error.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';

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
  int _currentStep = 0; // 0: Context, 1: Subject/Section, 2: Faculty, 3: Review
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
    final authState = ref.read(auth.authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final deptId = user?.departmentId;
    if (user?.role == AppRole.hod && deptId != null && deptId.isNotEmpty) {
      _selectedDepartmentId = deptId;
    }
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
    final terminology = ref.read(terminologyProvider);
    final isSecEnabled = terminology.isSectionEnabled;

    if (_selectedFacultyId == null ||
        _selectedDepartmentId == null ||
        _selectedCourseId == null ||
        _selectedSemesterId == null ||
        (isSecEnabled && _selectedSectionId == null) ||
        _selectedSubjectId == null) {
      AcadexSnackBar.showWarning(
        context,
        'Please select all required fields (Faculty, Department, ${terminology.programName()}, ${terminology.semesterName()}${isSecEnabled ? ", " + terminology.sectionName() : ""}, ${terminology.subjectName()})',
      );
      return;
    }

    final sections = ref.read(sectionsProvider).valueOrNull ?? [];
    final selectedSection = sections.where((s) => s.id == _selectedSectionId).firstOrNull;
    final semesters = ref.read(semestersProvider).valueOrNull ?? [];
    final selectedSemester = semesters.where((s) => s.id == _selectedSemesterId).firstOrNull;
    final academicYears = ref.read(academicYearsProvider).valueOrNull ?? [];
    final String activeYearId = _selectedAcademicYearId ??
        (selectedSection != null && selectedSection.academicYearId.isNotEmpty ? selectedSection.academicYearId : null) ??
        (selectedSemester != null && selectedSemester.academicYearId.isNotEmpty ? selectedSemester.academicYearId : null) ??
        academicYears.where((y) => y.isActive).firstOrNull?.id ??
        (academicYears.isNotEmpty ? academicYears.first.id : '');

    // Check duplicate in active assignments
    final existing = (ref.read(facultyAssignmentsProvider).valueOrNull ?? []).where(
      (a) =>
          a.isActive &&
          a.facultyId == _selectedFacultyId &&
          a.subjectId == _selectedSubjectId &&
          (!isSecEnabled || a.sectionId == _selectedSectionId) &&
          a.semesterId == _selectedSemesterId &&
          a.courseId == _selectedCourseId &&
          (activeYearId.isEmpty || a.academicYearId == activeYearId),
    );

    if (existing.isNotEmpty) {
      AcadexSnackBar.showWarning(
        context,
        'This faculty member is already assigned to this ${terminology.subjectName().toLowerCase()}${isSecEnabled ? " and " + terminology.sectionName().toLowerCase() : ""}.',
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

      final authState = ref.read(auth.authProvider);
      final String fallbackCollegeId = (authState is AuthAuthenticated ? authState.user.collegeId : '') ?? '';
      final String collegeId = faculty.collegeId.isNotEmpty ? faculty.collegeId : fallbackCollegeId;

      final assignment = FacultyAssignment(
        id: 'fa_${DateTime.now().millisecondsSinceEpoch}',
        collegeId: collegeId,
        departmentId: _selectedDepartmentId!,
        facultyId: _selectedFacultyId!,
        facultyName: faculty.name,
        courseId: _selectedCourseId!,
        semesterId: _selectedSemesterId!,
        sectionId: _selectedSectionId ?? '',
        subjectId: _selectedSubjectId!,
        academicYearId: activeYearId,
        assignedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(facultyAssignmentsProvider.notifier).createAssignment(assignment);
      ref.invalidate(facultyAssignmentsProvider);
      ref.invalidate(myFacultyAssignmentsProvider);
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
        final message = AcadexException.sanitizedMessage(
          e,
          fallback: "We couldn't complete this faculty assignment. The selected faculty record is unavailable. Please refresh the faculty list and try again.",
        );
        AcadexSnackBar.showError(
          context,
          message,
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

    final terminology = ref.watch(terminologyProvider);
    final isSecEnabled = terminology.isSectionEnabled;

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
      if (!f.isActive || f.accountStatus == AccountStatus.deactivated) return false;
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
        : semesters.where((s) {
            if (s.courseId != _selectedCourseId || !s.isActive) return false;
            if (_selectedAcademicYearId != null &&
                s.academicYearId.isNotEmpty &&
                s.academicYearId != _selectedAcademicYearId) {
              return false;
            }
            return true;
          }).toList();

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

    final isMobile = AcadexBreakpoints.isMobile(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxDialogHeight = (screenHeight * 0.90).clamp(380.0, isMobile ? 640.0 : 760.0);

    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      child: Container(
        width: isMobile ? double.infinity : 760,
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
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
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            if (isMobile) ...[
              _buildProgressiveStepHeader(isDark, terminology, isSecEnabled),
              const SizedBox(height: 14),
              Expanded(
                child: _buildProgressiveStepBody(
                  context: context,
                  isDark: isDark,
                  isHod: isHod,
                  theme: theme,
                  terminology: terminology,
                  isSecEnabled: isSecEnabled,
                  departments: departments,
                  filteredCourses: filteredCourses,
                  filteredSemesters: filteredSemesters,
                  filteredSections: filteredSections,
                  filteredSubjects: filteredSubjects,
                  availableFaculty: availableFaculty,
                  assignmentsAsync: assignmentsAsync,
                  courses: courses,
                  semesters: semesters,
                  sections: sections,
                  subjects: subjects,
                  academicYears: academicYears,
                ),
              ),
            ] else ...[
              // Form selectors (Desktop)
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
                                    label: terminology.programName(),
                                    value: selectedCourse.name,
                                    icon: LucideIcons.bookOpen,
                                  ),
                                if (selectedSemester != null)
                                  AcadexContextItem(
                                    label: terminology.semesterName(),
                                    value: selectedSemester.name,
                                    icon: LucideIcons.calendar,
                                  ),
                                if (isSecEnabled && selectedSection != null)
                                  AcadexContextItem(
                                    label: terminology.sectionName(),
                                    value: '${terminology.sectionName()} ${selectedSection.name}',
                                    icon: LucideIcons.users,
                                  ),
                                if (selectedSubject != null)
                                  AcadexContextItem(
                                    label: terminology.subjectName(),
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
                                labelText: '${terminology.programName()} *',
                                hintText: _selectedDepartmentId == null ? 'Select ${terminology.departmentName()} first' : 'Choose ${terminology.programName().toLowerCase()}',
                              ),
                              items: filteredCourses.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.code})', overflow: TextOverflow.ellipsis))).toList(),
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

                      // Row 2: Academic Year + Semester + Section (if enabled)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              key: ValueKey('ay_$_selectedAcademicYearId'),
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                              initialValue: _selectedAcademicYearId,
                              decoration: InputDecoration(labelText: terminology.academicYearName(), hintText: 'Current Active'),
                              items: academicYears
                                  .map((y) => DropdownMenuItem(value: y.id, child: Text(y.name, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedAcademicYearId = val;
                                  if (_selectedSemesterId != null) {
                                    final currentSem = semesters.where((s) => s.id == _selectedSemesterId).firstOrNull;
                                    if (currentSem != null && val != null && currentSem.academicYearId.isNotEmpty && currentSem.academicYearId != val) {
                                      _selectedSemesterId = null;
                                      _selectedSectionId = null;
                                      _selectedSubjectId = null;
                                    }
                                  }
                                });
                              },
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
                                labelText: '${terminology.semesterName()} *',
                                hintText: _selectedCourseId == null ? 'Select ${terminology.programName()} first' : 'Choose ${terminology.semesterName().toLowerCase()}',
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
                          if (isSecEnabled) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                key: ValueKey('sec_${_selectedSemesterId}_$_selectedSectionId'),
                                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                                initialValue: _selectedSectionId,
                                decoration: InputDecoration(
                                  labelText: '${terminology.sectionName()} *',
                                  hintText: _selectedSemesterId == null ? 'Select ${terminology.semesterName()} first' : 'Choose ${terminology.sectionName().toLowerCase()}',
                                ),
                                items: filteredSections.map((sec) => DropdownMenuItem(value: sec.id, child: Text('${terminology.sectionName()} ${sec.name}', overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: _selectedSemesterId == null
                                    ? null
                                    : (val) => setState(() => _selectedSectionId = val),
                              ),
                            ),
                          ],
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
                                labelText: '${terminology.subjectName()} *',
                                hintText: _selectedCourseId == null
                                    ? 'Select ${terminology.programName()} first'
                                    : (_selectedSemesterId == null
                                        ? 'Select ${terminology.semesterName()} first'
                                        : (filteredSubjects.isEmpty ? 'No ${terminology.subjectName(plural: true).toLowerCase()} in this ${terminology.semesterName().toLowerCase()}' : 'Choose ${terminology.subjectName().toLowerCase()}')),
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
                          if (assignmentsAsync.isLoading) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AcadexColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AcadexRadius.md),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AcadexColors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Calculating faculty teaching workload...',
                                    style: AcadexTypography.caption(color: AcadexColors.primary),
                                  ),
                                ],
                              ),
                            );
                          }

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
                                  _buildSummaryPill(terminology.subjectName(), sub != null ? '${sub.code} · ${sub.name}' : 'None', LucideIcons.bookOpen),
                                  _buildSummaryPill(terminology.programName(), crs != null ? '${crs.name} (${crs.code})' : 'None', LucideIcons.graduationCap),
                                  _buildSummaryPill(terminology.academicYearName(), ay?.name ?? 'Active Session', LucideIcons.calendar),
                                  _buildSummaryPill(terminology.semesterName(), sem?.name ?? 'None', LucideIcons.calendarClock),
                                  if (isSecEnabled)
                                    _buildSummaryPill(terminology.sectionName(), sec != null ? '${terminology.sectionName()} ${sec.name}' : 'None', LucideIcons.users),
                                  _buildSummaryPill('Status', 'Active', LucideIcons.checkCircle),
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
                              '${a.facultyName} • ${sub?.name ?? 'Subject'}',
                              style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${crs?.name ?? 'Course'} • ${sem?.name ?? 'Semester'} • Section ${sec?.name ?? '—'}${sub != null && sub.code.isNotEmpty ? ' • ${sub.code}' : ''}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgressiveStepHeader(bool isDark, TerminologyHelper terminology, bool isSecEnabled) {
    final stepTitles = [
      'Academic Context',
      isSecEnabled ? '${terminology.subjectName()} & ${terminology.sectionName()}' : terminology.subjectName(),
      'Faculty Member',
      'Review & Assign',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Step ${_currentStep + 1} of 4: ${stepTitles[_currentStep]}',
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${((_currentStep + 1) * 25)}%',
              style: const TextStyle(
                color: AcadexColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4.0,
            minHeight: 4,
            backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            valueColor: const AlwaysStoppedAnimation<Color>(AcadexColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressiveStepBody({
    required BuildContext context,
    required bool isDark,
    required bool isHod,
    required ThemeData theme,
    required TerminologyHelper terminology,
    required bool isSecEnabled,
    required List<Department> departments,
    required List<Course> filteredCourses,
    required List<Semester> filteredSemesters,
    required List<Section> filteredSections,
    required List<Subject> filteredSubjects,
    required List<Faculty> availableFaculty,
    required AsyncValue<List<FacultyAssignment>> assignmentsAsync,
    required List<Course> courses,
    required List<Semester> semesters,
    required List<Section> sections,
    required List<Subject> subjects,
    required List<AcademicYear> academicYears,
  }) {
    switch (_currentStep) {
      case 0:
        // Step 1: Academic Context (Department, Course, Semester)
        final canProceed = _selectedDepartmentId != null && _selectedCourseId != null && _selectedSemesterId != null;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 1: Academic Context', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                'Select the academic branch and term for this teaching assignment.',
                style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(height: 16),
              if (isHod)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withValues(alpha: 0.08),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.building, size: 16, color: AcadexColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          departments.where((d) => d.id == _selectedDepartmentId).firstOrNull?.name ?? 'Department',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AcadexColors.primary),
                        ),
                      ),
                      const AcadexBadge(label: 'LOCKED', variant: AcadexBadgeVariant.primary),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: ValueKey('mob_dept_$_selectedDepartmentId'),
                  dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                  value: _selectedDepartmentId,
                  decoration: const InputDecoration(labelText: 'Department *', hintText: 'Choose department'),
                  items: departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('mob_course_${_selectedDepartmentId}_$_selectedCourseId'),
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                value: _selectedCourseId,
                decoration: InputDecoration(
                  labelText: '${terminology.programName()} *',
                  hintText: _selectedDepartmentId == null ? 'Select Department first' : 'Choose ${terminology.programName().toLowerCase()}',
                ),
                items: filteredCourses.map((c) => DropdownMenuItem(value: c.id, child: Text("${c.name} (${c.code})", overflow: TextOverflow.ellipsis))).toList(),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('mob_sem_${_selectedCourseId}_$_selectedSemesterId'),
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                value: _selectedSemesterId,
                decoration: InputDecoration(
                  labelText: '${terminology.semesterName()} *',
                  hintText: _selectedCourseId == null ? 'Select ${terminology.programName()} first' : 'Choose ${terminology.semesterName().toLowerCase()}',
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AcadexButton(
                  label: isSecEnabled
                      ? 'Next: ${terminology.subjectName()} & ${terminology.sectionName()} →'
                      : 'Next: ${terminology.subjectName()} →',
                  icon: LucideIcons.arrowRight,
                  variant: canProceed ? AcadexButtonVariant.primary : AcadexButtonVariant.secondary,
                  onPressed: canProceed ? () => setState(() => _currentStep = 1) : null,
                ),
              ),
            ],
          ),
        );

      case 1:
        // Step 2: Subject & Section
        final canProceed = _selectedSubjectId != null && (!isSecEnabled || _selectedSectionId != null);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSecEnabled
                    ? 'Step 2: ${terminology.subjectName()} & ${terminology.sectionName()}'
                    : 'Step 2: ${terminology.subjectName()}',
                style: AcadexTypography.title(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                isSecEnabled
                    ? 'Choose the specific ${terminology.subjectName().toLowerCase()} curriculum and ${terminology.sectionName().toLowerCase()}.'
                    : 'Choose the specific ${terminology.subjectName().toLowerCase()} curriculum.',
                style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('mob_sub_${_selectedCourseId}_${_selectedSemesterId}_$_selectedSubjectId'),
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                value: _selectedSubjectId,
                decoration: InputDecoration(
                  labelText: '${terminology.subjectName()} *',
                  hintText: filteredSubjects.isEmpty ? 'No ${terminology.subjectsName().toLowerCase()} found in ${terminology.semesterName().toLowerCase()}' : 'Choose ${terminology.subjectName().toLowerCase()}',
                ),
                items: filteredSubjects.map((sub) => DropdownMenuItem(value: sub.id, child: Text('${sub.code} - ${sub.name}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _selectedSubjectId = val),
              ),
              if (isSecEnabled) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: ValueKey('mob_sec_${_selectedSemesterId}_$_selectedSectionId'),
                  dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                  value: _selectedSectionId,
                  decoration: InputDecoration(
                    labelText: '${terminology.sectionName()} *',
                    hintText: filteredSections.isEmpty ? 'No ${terminology.sectionsName().toLowerCase()} found in ${terminology.semesterName().toLowerCase()}' : 'Choose ${terminology.sectionName().toLowerCase()}',
                  ),
                  items: filteredSections.map((sec) => DropdownMenuItem(value: sec.id, child: Text('${terminology.sectionName()} ${sec.name}', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => _selectedSectionId = val),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AcadexButton(
                      label: 'Next: Faculty →',
                      icon: LucideIcons.arrowRight,
                      variant: canProceed ? AcadexButtonVariant.primary : AcadexButtonVariant.secondary,
                      onPressed: canProceed ? () => setState(() => _currentStep = 2) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case 2:
        // Step 3: Faculty Member
        final canProceed = _selectedFacultyId != null;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 3: Select Faculty Member', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                'Assign an active faculty instructor to own this teaching context.',
                style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('mob_fac_${_selectedDepartmentId}_$_selectedFacultyId'),
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                value: _selectedFacultyId,
                decoration: InputDecoration(
                  labelText: 'Faculty Member *',
                  hintText: availableFaculty.isEmpty ? 'No active faculty available' : 'Choose instructor',
                ),
                items: availableFaculty.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: availableFaculty.isEmpty ? null : (val) => setState(() => _selectedFacultyId = val),
              ),
              const SizedBox(height: 16),
              if (_selectedFacultyId != null) ...[
                Builder(
                  builder: (context) {
                    final selectedFacAssignments = (assignmentsAsync.valueOrNull ?? [])
                        .where((a) => a.facultyId == _selectedFacultyId && a.isActive)
                        .toList();
                    final subjectCount = selectedFacAssignments.map((a) => a.subjectId).toSet().length;
                    final sectionCount = selectedFacAssignments.map((a) => a.sectionId).toSet().length;
                    return Container(
                      padding: const EdgeInsets.all(12),
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
                              'Current Workload: $subjectCount ${terminology.subjectsName().toLowerCase()}${isSecEnabled ? ' across $sectionCount ${terminology.sectionsName().toLowerCase()}' : ''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AcadexColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 1),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AcadexButton(
                      label: 'Next: Review →',
                      icon: LucideIcons.arrowRight,
                      variant: canProceed ? AcadexButtonVariant.primary : AcadexButtonVariant.secondary,
                      onPressed: canProceed ? () => setState(() => _currentStep = 3) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case 3:
      default:
        // Step 4: Review & Assign
        final fac = availableFaculty.where((f) => f.id == _selectedFacultyId).firstOrNull;
        final sub = subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
        final crs = courses.where((c) => c.id == _selectedCourseId).firstOrNull;
        final sem = semesters.where((s) => s.id == _selectedSemesterId).firstOrNull;
        final sec = sections.where((s) => s.id == _selectedSectionId).firstOrNull;
        final ay = academicYears.where((y) => y.id == _selectedAcademicYearId).firstOrNull ??
            academicYears.where((y) => y.isActive).firstOrNull;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 4: Review Assignment', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                'Confirm the teaching allocation details before activating ownership.',
                style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                  border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _buildReviewRow('Faculty', fac?.name ?? '—', LucideIcons.user, isDark),
                    const Divider(height: 16),
                    _buildReviewRow(terminology.subjectName(), sub != null ? '${sub.code} · ${sub.name}' : '—', LucideIcons.bookOpen, isDark),
                    if (isSecEnabled) ...[
                      const Divider(height: 16),
                      _buildReviewRow(terminology.sectionName(), sec != null ? '${terminology.sectionName()} ${sec.name}' : '—', LucideIcons.users, isDark),
                    ],
                    const Divider(height: 16),
                    _buildReviewRow(terminology.semesterName(), sem?.name ?? '—', LucideIcons.calendarClock, isDark),
                    const Divider(height: 16),
                    _buildReviewRow(terminology.programName(), crs != null ? '${crs.name} (${crs.code})' : '—', LucideIcons.graduationCap, isDark),
                    const Divider(height: 16),
                    _buildReviewRow(terminology.academicYearName(), ay?.name ?? 'Active Session', LucideIcons.calendar, isDark),
                    const Divider(height: 16),
                    _buildReviewRow('Status', 'Active', LucideIcons.checkCircle, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 2),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AcadexButton(
                      label: _isSubmitting ? 'Assigning...' : 'Assign Faculty',
                      icon: LucideIcons.check,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleAssign,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _buildReviewRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AcadexColors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
