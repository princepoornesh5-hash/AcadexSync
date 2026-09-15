import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';

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

    final allStudents = studentsState.items;
    final availableStudents = allStudents.where((s) {
      if (enrolledStudentIds.contains(s.id)) return false;
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final nameMatches = s.name.toLowerCase().contains(query);
      final rollMatches = s.rollNumber.toLowerCase().contains(query);
      final emailMatches = s.email.toLowerCase().contains(query);
      return nameMatches || rollMatches || emailMatches;
    }).toList();

    Student? selectedStudent;
    if (_selectedStudentId != null) {
      for (final s in allStudents) {
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
            const Divider(height: 1),
            const SizedBox(height: 16),

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
                                      ? 'No matching unenrolled students found'
                                      : 'All department students are already enrolled or none exist.',
                                  style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                                  textAlign: TextAlign.center,
                                ),
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
                  onPressed: _selectedStudentId == null || _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          try {
                            await ref.read(sectionEnrollmentsNotifierProvider(widget.section.id).notifier).enrollStudent(
                              studentId: _selectedStudentId!,
                              courseId: widget.section.courseId,
                              academicYearId: widget.section.academicYearId,
                              semesterId: widget.section.semesterId,
                              sectionId: widget.section.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Student successfully enrolled in section!'),
                                  backgroundColor: AcadexColors.success,
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Enrollment failed: $e'),
                                  backgroundColor: AcadexColors.error,
                                ),
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
