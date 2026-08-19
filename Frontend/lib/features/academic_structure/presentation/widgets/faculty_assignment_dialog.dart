import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class FacultyAssignmentDialog extends ConsumerStatefulWidget {
  final Faculty? preselectedFaculty;

  const FacultyAssignmentDialog({
    super.key,
    this.preselectedFaculty,
  });

  static Future<void> show(BuildContext context, {Faculty? faculty}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FacultyAssignmentDialog(preselectedFaculty: faculty),
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedFaculty != null) {
      _selectedFacultyId = widget.preselectedFaculty!.id;
      _selectedDepartmentId = widget.preselectedFaculty!.departmentId;
    }
  }

  Future<void> _handleAssign() async {
    if (_selectedFacultyId == null ||
        _selectedDepartmentId == null ||
        _selectedCourseId == null ||
        _selectedSemesterId == null ||
        _selectedSectionId == null ||
        _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields (Faculty, Department, Course, Semester, Section, Subject)')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This faculty member is already assigned to this subject and section.'),
          backgroundColor: AcadexColors.warning,
        ),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned ${faculty.name} successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
        setState(() {
          _selectedSubjectId = null;
          _selectedSectionId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AcadexColors.warning),
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

    // Filter faculty based on selected department or HOD scope
    final availableFaculty = facultyState.items.where((f) {
      if (isHod && hodDeptId != null && hodDeptId.isNotEmpty) {
        return f.departmentId == hodDeptId;
      }
      if (_selectedDepartmentId != null && _selectedDepartmentId!.isNotEmpty) {
        return f.departmentId == _selectedDepartmentId || f.departmentId.isEmpty;
      }
      return true;
    }).toList();

    // Cascading filters
    final filteredCourses = _selectedDepartmentId == null
        ? courses
        : courses.where((c) => c.departmentId == _selectedDepartmentId).toList();

    final filteredSemesters = _selectedCourseId == null
        ? semesters
        : semesters.where((s) => s.courseId == _selectedCourseId).toList();

    final filteredSections = _selectedSemesterId == null
        ? sections
        : sections.where((sec) => sec.semesterId == _selectedSemesterId).toList();

    final filteredSubjects = _selectedSemesterId == null
        ? (_selectedDepartmentId == null ? subjects : subjects.where((sub) => sub.departmentId == _selectedDepartmentId).toList())
        : subjects.where((sub) => sub.semesterId == _selectedSemesterId).toList();

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
                Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Faculty Subject & Class Assignment',
                          style: AcadexTypography.heading3(color: theme.colorScheme.onSurface),
                        ),
                        Text(
                          isHod ? 'Manage teaching allocations for your department' : 'Map faculty members to courses, semesters, sections & subjects',
                          style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ],
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
                    
                    // Row 1: Department + Course
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('dept_$_selectedDepartmentId'),
                            dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                            initialValue: _selectedDepartmentId,
                            decoration: InputDecoration(
                              labelText: isHod ? 'Department (Locked)' : 'Department *',
                              hintText: 'Choose department',
                            ),
                            items: departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
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
                            key: ValueKey('course_${_selectedDepartmentId}_$_selectedCourseId'),
                            dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                            initialValue: _selectedCourseId,
                            decoration: const InputDecoration(labelText: 'Course *', hintText: 'Choose course'),
                            items: filteredCourses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (val) {
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
                            key: ValueKey('ay_$_selectedAcademicYearId'),
                            dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                            initialValue: _selectedAcademicYearId,
                            decoration: const InputDecoration(labelText: 'Academic Year', hintText: 'Current Active'),
                            items: academicYears
                                .map((y) => DropdownMenuItem(value: y.id, child: Text(y.name)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedAcademicYearId = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('sem_${_selectedCourseId}_$_selectedSemesterId'),
                            dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                            initialValue: _selectedSemesterId,
                            decoration: const InputDecoration(labelText: 'Semester *', hintText: 'Choose semester'),
                            items: filteredSemesters.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                            onChanged: (val) {
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
                            key: ValueKey('sec_${_selectedSemesterId}_$_selectedSectionId'),
                            dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                            initialValue: _selectedSectionId,
                            decoration: const InputDecoration(labelText: 'Section *', hintText: 'Choose section'),
                            items: filteredSections.map((sec) => DropdownMenuItem(value: sec.id, child: Text('Section ${sec.name}'))).toList(),
                            onChanged: (val) => setState(() => _selectedSectionId = val),
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
                            key: ValueKey('sub_${_selectedSemesterId}_$_selectedSubjectId'),
                            dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                            initialValue: _selectedSubjectId,
                            decoration: const InputDecoration(labelText: 'Subject *', hintText: 'Choose subject'),
                            items: filteredSubjects.map((sub) => DropdownMenuItem(value: sub.id, child: Text('${sub.code} - ${sub.name}'))).toList(),
                            onChanged: (val) => setState(() => _selectedSubjectId = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('fac_${_selectedDepartmentId}_$_selectedFacultyId'),
                            dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                            initialValue: _selectedFacultyId,
                            decoration: const InputDecoration(labelText: 'Faculty Member *', hintText: 'Choose faculty'),
                            items: availableFaculty.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedFacultyId = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
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
                                Text(
                                  'Current Workload: $subjectCount subject(s) across $sectionCount section(s) (${selectedFacAssignments.length} total assignment${selectedFacAssignments.length == 1 ? '' : 's'})',
                                  style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    // Assign Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: AcadexButton(
                        label: _isSubmitting ? 'Assigning...' : 'Assign Faculty to Class',
                        icon: LucideIcons.plus,
                        isLoading: _isSubmitting,
                        onPressed: _handleAssign,
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
                            title: 'No Active Assignments',
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
}
