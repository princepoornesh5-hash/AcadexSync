import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProgressiveEnrollmentDialog extends ConsumerStatefulWidget {
  final Student? initialStudent;
  final String? initialDepartmentId;
  final String? initialCourseId;
  final String? initialSemesterId;
  final String? initialSectionId;

  const ProgressiveEnrollmentDialog({
    super.key,
    this.initialStudent,
    this.initialDepartmentId,
    this.initialCourseId,
    this.initialSemesterId,
    this.initialSectionId,
  });

  static Future<bool?> show(
    BuildContext context, {
    Student? initialStudent,
    String? initialDepartmentId,
    String? initialCourseId,
    String? initialSemesterId,
    String? initialSectionId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProgressiveEnrollmentDialog(
        initialStudent: initialStudent,
        initialDepartmentId: initialDepartmentId,
        initialCourseId: initialCourseId,
        initialSemesterId: initialSemesterId,
        initialSectionId: initialSectionId,
      ),
    );
  }

  @override
  ConsumerState<ProgressiveEnrollmentDialog> createState() => _ProgressiveEnrollmentDialogState();
}

class _ProgressiveEnrollmentDialogState extends ConsumerState<ProgressiveEnrollmentDialog> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  Student? _selectedStudent;
  String? _selectedDeptId;
  String? _selectedCourseId;
  String? _selectedAcademicYearId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialStudent;
    _selectedDeptId = widget.initialDepartmentId ?? widget.initialStudent?.departmentId;
    _selectedCourseId = widget.initialCourseId ?? widget.initialStudent?.courseId;
    _selectedSemesterId = widget.initialSemesterId ?? widget.initialStudent?.semesterId;
    _selectedSectionId = widget.initialSectionId ?? widget.initialStudent?.sectionId;

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated && authState.user.role == AppRole.hod) {
      _selectedDeptId = authState.user.departmentId;
    }

    if (_selectedStudent != null) {
      _currentStep = 1; // Skip student picker if preselected
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final terminology = ref.watch(terminologyProvider);
    final isSectionEnabled = terminology.isSectionEnabled;

    final progLabel = terminology.programName();
    final semLabel = terminology.semesterName();
    final secLabel = terminology.sectionName();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enroll Student',
                        style: AcadexTypography.heading2(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontSize: 18),
                      ),
                      Text(
                        'Progressive academic placement & context registration',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Step Counter & Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentStep + 1} of ${_getTotalSteps(isSectionEnabled)}',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildStepIndicator(isSectionEnabled),
            const SizedBox(height: 16),

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
                    const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AcadexColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                child: _buildCurrentStepContent(progLabel, semLabel, secLabel, isSectionEnabled),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Actions (Mobile-Optimized)
            Row(
              children: [
                Expanded(
                  child: _currentStep > 0
                      ? OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : () => setState(() => _currentStep--),
                          icon: const Icon(LucideIcons.chevronLeft, size: 16),
                          label: const Text('Back'),
                        )
                      : OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _currentStep < _getTotalSteps(isSectionEnabled) - 1
                      ? ElevatedButton.icon(
                          onPressed: _canProceedNext(isSectionEnabled)
                              ? () => setState(() {
                                    _errorMessage = null;
                                    _currentStep++;
                                  })
                              : null,
                          icon: const Icon(LucideIcons.chevronRight, size: 16),
                          label: const Text('Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitEnrollment,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(LucideIcons.check, size: 16),
                          label: const Text('Confirm', overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalSteps(bool isSectionEnabled) => isSectionEnabled ? 7 : 6;

  Widget _buildStepIndicator(bool isSectionEnabled) {
    final totalSteps = _getTotalSteps(isSectionEnabled);
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AcadexColors.success
                  : isCurrent
                      ? AcadexColors.primary
                      : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  bool _canProceedNext(bool isSectionEnabled) {
    switch (_currentStep) {
      case 0:
        return _selectedStudent != null;
      case 1:
        return _selectedDeptId != null && _selectedDeptId!.isNotEmpty;
      case 2:
        return _selectedCourseId != null && _selectedCourseId!.isNotEmpty;
      case 3:
        return _selectedAcademicYearId != null && _selectedAcademicYearId!.isNotEmpty;
      case 4:
        return _selectedSemesterId != null && _selectedSemesterId!.isNotEmpty;
      case 5:
        return !isSectionEnabled || (_selectedSectionId != null && _selectedSectionId!.isNotEmpty);
      default:
        return false;
    }
  }

  Widget _buildCurrentStepContent(String progLabel, String semLabel, String secLabel, bool isSectionEnabled) {
    switch (_currentStep) {
      case 0:
        return _buildStudentSelectionStep();
      case 1:
        return _buildDepartmentStep();
      case 2:
        return _buildCourseStep(progLabel);
      case 3:
        return _buildAcademicYearStep();
      case 4:
        return _buildSemesterStep(semLabel);
      case 5:
        if (isSectionEnabled) {
          return _buildSectionStep(secLabel);
        } else {
          return _buildReviewStep(progLabel, semLabel, secLabel, isSectionEnabled);
        }
      case 6:
        return _buildReviewStep(progLabel, semLabel, secLabel, isSectionEnabled);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStudentSelectionStep() {
    final studentsState = ref.watch(studentsProvider((sectionId: null, departmentId: _selectedDeptId)));
    final allStudents = studentsState.items;
    final filtered = allStudents.where((s) {
      if (!s.isActive) return false;
      if (_studentSearchQuery.isEmpty) return true;
      final q = _studentSearchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.rollNumber.toLowerCase().contains(q) ||
          (s.instituteId?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Select Student', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search by student name, roll number, or institute ID...',
            prefixIcon: Icon(LucideIcons.search, size: 18),
          ),
          onChanged: (val) => setState(() => _studentSearchQuery = val),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No matching students found')),
          )
        else
          ...filtered.take(10).map((s) {
            final isSelected = _selectedStudent?.id == s.id;
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AcadexRadius.md),
                side: BorderSide(
                  color: isSelected ? AcadexColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: isSelected ? AcadexColors.primary : AcadexColors.primary.withValues(alpha: 0.1),
                foregroundColor: isSelected ? Colors.white : AcadexColors.primary,
                child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S'),
              ),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Roll: ${s.rollNumber.isNotEmpty ? s.rollNumber : 'N/A'} • ID: ${s.instituteId ?? 'N/A'}"),
              trailing: isSelected ? const Icon(LucideIcons.checkCircle, color: AcadexColors.primary) : null,
              onTap: () => setState(() {
                _selectedStudent = s;
                _selectedDeptId ??= s.departmentId;
              }),
            );
          }),
      ],
    );
  }

  Widget _buildDepartmentStep() {
    final deptsAsync = ref.watch(departmentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Department Context', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        deptsAsync.when(
          data: (depts) {
            final activeDepts = depts.where((d) => d.isActive).toList();
            return Column(
              children: activeDepts.map((d) {
                return RadioListTile<String>(
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Code: ${d.code}"),
                  value: d.id,
                  groupValue: _selectedDeptId,
                  onChanged: (val) => setState(() {
                    _selectedDeptId = val;
                    _selectedCourseId = null;
                    _selectedSemesterId = null;
                    _selectedSectionId = null;
                  }),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading departments: $e'),
        ),
      ],
    );
  }

  Widget _buildCourseStep(String progLabel) {
    final coursesAsync = ref.watch(coursesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Select $progLabel', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        coursesAsync.when(
          data: (courses) {
            final filtered = courses.where((c) => c.departmentId == _selectedDeptId && c.isActive).toList();
            if (filtered.isEmpty) {
              return Text('No active $progLabel available for this department.');
            }
            return Column(
              children: filtered.map((c) {
                return RadioListTile<String>(
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Code: ${c.code} • Duration: ${c.duration} Years"),
                  value: c.id,
                  groupValue: _selectedCourseId,
                  onChanged: (val) => setState(() {
                    _selectedCourseId = val;
                    _selectedSemesterId = null;
                    _selectedSectionId = null;
                  }),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading $progLabel: $e'),
        ),
      ],
    );
  }

  Widget _buildAcademicYearStep() {
    final ayAsync = ref.watch(academicYearsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4: Academic Year (Operational Cycle)', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Represents the institutional cycle (e.g. 2026–27), distinct from multi-year student cohorts.',
          style: AcadexTypography.caption(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 12),
        ayAsync.when(
          data: (years) {
            final activeYears = years.where((y) => y.isActive).toList();
            if (activeYears.isEmpty) {
              return const Text('No active Academic Year found. Please create an Academic Year first.');
            }
            return Column(
              children: activeYears.map((ay) {
                return RadioListTile<String>(
                  title: Row(
                    children: [
                      Text(ay.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (ay.isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AcadexColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('CURRENT', style: TextStyle(color: AcadexColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  value: ay.id,
                  groupValue: _selectedAcademicYearId,
                  onChanged: (val) => setState(() {
                    _selectedAcademicYearId = val;
                    _selectedSemesterId = null;
                    _selectedSectionId = null;
                  }),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading academic years: $e'),
        ),
      ],
    );
  }

  Widget _buildSemesterStep(String semLabel) {
    final semAsync = ref.watch(semestersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 5: Select $semLabel', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        semAsync.when(
          data: (semesters) {
            final filtered = semesters.where((s) {
              if (s.courseId != _selectedCourseId) return false;
              if (_selectedAcademicYearId != null && s.academicYearId != _selectedAcademicYearId) return false;
              return s.isActive;
            }).toList();
            if (filtered.isEmpty) {
              return Text('No active $semLabel found for this course and academic year.');
            }
            return Column(
              children: filtered.map((s) {
                return RadioListTile<String>(
                  title: Text(s.name.isNotEmpty ? s.name : "$semLabel ${s.semesterNumber}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Academic Period ${s.semesterNumber}"),
                  value: s.id,
                  groupValue: _selectedSemesterId,
                  onChanged: (val) => setState(() {
                    _selectedSemesterId = val;
                    _selectedSectionId = null;
                  }),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading $semLabel: $e'),
        ),
      ],
    );
  }

  Widget _buildSectionStep(String secLabel) {
    final secAsync = ref.watch(sectionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 6: Select $secLabel', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        secAsync.when(
          data: (sections) {
            final filtered = sections.where((sec) => sec.semesterId == _selectedSemesterId && sec.isActive).toList();
            if (filtered.isEmpty) {
              return Text('No active $secLabel available for this semester.');
            }
            return Column(
              children: filtered.map((sec) {
                return RadioListTile<String>(
                  title: Text(sec.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Capacity: ${sec.capacity}"),
                  value: sec.id,
                  groupValue: _selectedSectionId,
                  onChanged: (val) => setState(() => _selectedSectionId = val),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading $secLabel: $e'),
        ),
      ],
    );
  }

  Widget _buildReviewStep(String progLabel, String semLabel, String secLabel, bool isSectionEnabled) {
    final depts = ref.watch(departmentMapProvider);
    final courses = ref.watch(courseMapProvider);
    final ays = ref.watch(academicYearMapProvider);
    final sems = ref.watch(semesterMapProvider);
    final secs = ref.watch(sectionMapProvider);

    final deptName = depts[_selectedDeptId]?.name ?? 'Selected Department';
    final courseName = courses[_selectedCourseId]?.name ?? 'Selected $progLabel';
    final ayName = ays[_selectedAcademicYearId]?.name ?? 'Selected Academic Year';
    final semName = sems[_selectedSemesterId]?.name ?? 'Selected $semLabel';
    final secName = isSectionEnabled ? (secs[_selectedSectionId]?.name ?? 'None') : 'Disabled by Institution';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review Academic Placement', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AcadexColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AcadexRadius.md),
            border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildReviewRow('Student', "${_selectedStudent?.name} (${_selectedStudent?.rollNumber})"),
              const Divider(height: 20),
              _buildReviewRow('Department', deptName),
              const Divider(height: 20),
              _buildReviewRow(progLabel, courseName),
              const Divider(height: 20),
              _buildReviewRow('Academic Year', ayName),
              const Divider(height: 20),
              _buildReviewRow(semLabel, semName),
              if (isSectionEnabled) ...[
                const Divider(height: 20),
                _buildReviewRow(secLabel, secName),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _submitEnrollment() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final isSectionEnabled = ref.read(terminologyProvider).isSectionEnabled;
      await ref.read(academicRepositoryProvider).enrollStudent(
        studentId: _selectedStudent!.id,
        courseId: _selectedCourseId!,
        academicYearId: _selectedAcademicYearId!,
        semesterId: _selectedSemesterId!,
        sectionId: isSectionEnabled ? _selectedSectionId : null,
      );

      ref.invalidate(studentsProvider);
      if (_selectedDeptId != null) ref.invalidate(studentsByDepartmentProvider(_selectedDeptId!));
      if (_selectedSectionId != null) ref.invalidate(studentsBySectionProvider(_selectedSectionId!));

      if (mounted) {
        AcadexSnackBar.showSuccess(context, "Student successfully enrolled in academic context");
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      final sanitized = AcadexException.fromError(e).userMessage;
      setState(() {
        _isSubmitting = false;
        _errorMessage = sanitized;
      });
    }
  }
}
