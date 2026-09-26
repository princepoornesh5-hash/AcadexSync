import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../providers/department_setup_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'setup_continuation_dialog.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_workflow_context_banner.dart';

class EnrollStudentDialog extends ConsumerStatefulWidget {
  final Section section;
  final Course? course;
  final Semester? semester;
  final AcademicYear? academicYear;

  const EnrollStudentDialog({
    super.key,
    required this.section,
    this.course,
    this.semester,
    this.academicYear,
  });

  static Future<void> show(
    BuildContext context, {
    required Section section,
    Course? course,
    Semester? semester,
    AcademicYear? academicYear,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EnrollStudentDialog(
        section: section,
        course: course,
        semester: semester,
        academicYear: academicYear,
      ),
    );
  }

  @override
  ConsumerState<EnrollStudentDialog> createState() => _EnrollStudentDialogState();
}

class _EnrollStudentDialogState extends ConsumerState<EnrollStudentDialog> {
  String? _selectedStudentId;
  String _searchQuery = '';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final deptId = widget.section.departmentId;
    final studentsState = ref.watch(studentsProvider((sectionId: null, departmentId: deptId.isNotEmpty ? deptId : null)));
    final enrollmentsAsync = ref.watch(sectionEnrollmentsNotifierProvider(widget.section.id));
    final enrolledStudentIds = (enrollmentsAsync.valueOrNull ?? []).map((e) => e.studentId).toSet();

    final authState = ref.watch(authProvider);
    final canAddStudent = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.collegeAdmin ||
         authState.user.role == AppRole.superAdmin ||
         authState.user.role == AppRole.hod);

    final allStudents = studentsState.items;
    final availableStudents = allStudents.where((s) {
      if (!s.isActive || s.accountStatus != AccountStatus.active || s.lifecycleState != StudentLifecycleState.active) {
        return false;
      }
      if (enrolledStudentIds.contains(s.id)) return false;
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final nameMatches = s.name.toLowerCase().contains(query);
      final rollMatches = s.rollNumber.toLowerCase().contains(query);
      final emailMatches = s.email.toLowerCase().contains(query);
      return nameMatches || rollMatches || emailMatches;
    }).toList();

    final isSelectionValid = _selectedStudentId != null &&
        availableStudents.any((s) => s.id == _selectedStudentId);

    Student? selectedStudent;
    if (isSelectionValid) {
      for (final s in availableStudents) {
        if (s.id == _selectedStudentId) {
          selectedStudent = s;
          break;
        }
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(24),
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
                  child: const Icon(LucideIcons.userPlus, color: AcadexColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enroll Student in Section',
                        style: AcadexTypography.heading2(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontSize: 18),
                      ),
                      Text(
                        'Section ${widget.section.name} • Connect real student identity',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 16),
            // Context Banner
            AcadexWorkflowContextBanner(
              targetEntityName: 'Student Enrollment',
              contextItems: [
                if (widget.course != null)
                  AcadexContextItem(
                    label: 'Course',
                    value: widget.course!.name,
                    icon: LucideIcons.bookOpen,
                  ),
                if (widget.semester != null)
                  AcadexContextItem(
                    label: 'Semester',
                    value: widget.semester!.name,
                    icon: LucideIcons.calendar,
                  ),
                AcadexContextItem(
                  label: 'Section',
                  value: widget.section.name,
                  icon: LucideIcons.users,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Existing Students
            TextField(
              key: const Key('student_search_field'),
              decoration: InputDecoration(
                hintText: 'Search student by name, roll number, or email...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 12),

            // Student Selection Dropdown / List
            Expanded(
              child: studentsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : availableStudents.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.userX, size: 32, color: AcadexColors.inkMuted),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No matching eligible students found'
                                      : 'No eligible students are available.',
                                  style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No active unenrolled students match "$_searchQuery".'
                                      : 'All active department students are already enrolled or none exist.',
                                  style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                                  textAlign: TextAlign.center,
                                ),
                                if (canAddStudent && _searchQuery.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    icon: const Icon(LucideIcons.userPlus, size: 14),
                                    label: const Text('Add Student'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      final deptQuery = widget.section.departmentId.isNotEmpty
                                          ? '?departmentId=${widget.section.departmentId}'
                                          : '';
                                      context.push('/academics/students/new$deptQuery');
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: availableStudents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final student = availableStudents[index];
                            final isSelected = student.id == _selectedStudentId;

                            return InkWell(
                              key: Key('student_item_${student.id}'),
                              borderRadius: BorderRadius.circular(AcadexRadius.md),
                              onTap: () => setState(() => _selectedStudentId = student.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AcadexColors.primary.withValues(alpha: 0.1)
                                      : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft),
                                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                                  border: Border.all(
                                    color: isSelected ? AcadexColors.primary : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isSelected ? AcadexColors.primary : AcadexColors.inkMuted.withValues(alpha: 0.2),
                                      child: Text(
                                        student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: AcadexTypography.body(
                                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                            ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          Text(
                                            'Roll: ${student.rollNumber.isNotEmpty ? student.rollNumber : "N/A"} • ${student.email}',
                                            style: AcadexTypography.caption(
                                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                            ).copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(LucideIcons.checkCircle2, size: 18, color: AcadexColors.primary),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 12),

            // Enrollment Summary Preview
            if (selectedStudent != null) ...[
              Container(
                key: const Key('enrollment_summary_preview'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                  border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.sparkles, size: 14, color: AcadexColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Enrollment Summary',
                          style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enrolling: ${selectedStudent.name} (${selectedStudent.rollNumber.isNotEmpty ? selectedStudent.rollNumber : selectedStudent.email})',
                      style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Into: Section ${widget.section.name} • ${widget.course?.name ?? "Course"} • ${widget.semester?.name ?? "Semester"}',
                      style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted).copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                AcadexButton(
                  key: const Key('confirm_enroll_button'),
                  label: _isSubmitting ? 'Enrolling...' : 'Enroll in Section',
                  icon: LucideIcons.userCheck,
                  isLoading: _isSubmitting,
                  onPressed: !isSelectionValid || _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          try {
                            final effectiveCourseId = widget.course?.id.isNotEmpty == true
                                ? widget.course!.id
                                : widget.section.courseId;
                            final effectiveSemesterId = widget.semester?.id.isNotEmpty == true
                                ? widget.semester!.id
                                : widget.section.semesterId;
                            final effectiveAcademicYearId = widget.academicYear?.id.isNotEmpty == true
                                ? widget.academicYear!.id
                                : widget.section.academicYearId;

                            await ref.read(sectionEnrollmentsNotifierProvider(widget.section.id).notifier).enrollStudent(
                              studentId: _selectedStudentId!,
                              courseId: effectiveCourseId,
                              academicYearId: effectiveAcademicYearId,
                              semesterId: effectiveSemesterId,
                              sectionId: widget.section.id,
                            );
                            if (widget.section.departmentId.isNotEmpty) {
                              ref.invalidate(departmentSetupProvider(widget.section.departmentId));
                            }
                            if (context.mounted) {
                              AcadexSnackBar.showSuccess(
                                context,
                                'Student successfully enrolled in section!',
                              );
                              Navigator.of(context).pop();
                              SetupContinuationDialog.show(
                                context,
                                title: 'Student Enrolled Successfully',
                                message: 'Student assigned to section cohort. Continue to timetable scheduling.',
                                primaryActionLabel: 'Continue to Timetable',
                                onContinue: () => context.push('/timetable/manage'),
                                secondaryActionLabel: 'Done',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AcadexSnackBar.showError(
                                context,
                                e,
                                fallbackMessage: 'Student is already enrolled in this section.',
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
