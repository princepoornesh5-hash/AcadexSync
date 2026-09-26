import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';

class StudentPromotionDialog extends ConsumerStatefulWidget {
  final List<String> studentIds;

  const StudentPromotionDialog({super.key, required this.studentIds});

  @override
  ConsumerState<StudentPromotionDialog> createState() => _StudentPromotionDialogState();
}

class _StudentPromotionDialogState extends ConsumerState<StudentPromotionDialog> {
  String? _selectedAcademicYearId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final academicYearsAsync = ref.watch(academicYearsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return AlertDialog(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AcadexColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AcadexRadius.sm),
            ),
            child: const Icon(LucideIcons.arrowUpRight, color: AcadexColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Academic Promotion', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AcadexRadius.sm),
                  border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.users, size: 18, color: AcadexColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Promoting ${widget.studentIds.length} selected student(s). All academic records and timeline milestones will be preserved.',
                        style: AcadexTypography.caption(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Academic Year
              Text('Target Academic Year', style: AcadexTypography.bodySmall(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              academicYearsAsync.when(
                data: (years) => DropdownButtonFormField<String>(
                  dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.calendar, size: 18),
                    hintText: "Select Academic Year",
                  ),
                  initialValue: _selectedAcademicYearId,
                  items: years.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name))).toList(),
                  onChanged: (val) => setState(() => _selectedAcademicYearId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(AcadexException.sanitizedMessage(e), style: const TextStyle(color: AcadexColors.error, fontSize: 12)),
              ),
              const SizedBox(height: 16),

              // Target Semester
              Text('Target Semester', style: AcadexTypography.bodySmall(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              semestersAsync.when(
                data: (semesters) => DropdownButtonFormField<String>(
                  dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.layers, size: 18),
                    hintText: "Select Semester",
                  ),
                  initialValue: _selectedSemesterId,
                  items: semesters.map((sem) => DropdownMenuItem(value: sem.id, child: Text(sem.name))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedSemesterId = val;
                    _selectedSectionId = null;
                  }),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(AcadexException.sanitizedMessage(e), style: const TextStyle(color: AcadexColors.error, fontSize: 12)),
              ),
              const SizedBox(height: 16),

              // Target Section
              Text('Target Section', style: AcadexTypography.bodySmall(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              sectionsAsync.when(
                data: (sections) {
                  final filtered = _selectedSemesterId != null
                      ? sections.where((s) => s.semesterId == _selectedSemesterId).toList()
                      : <Section>[];

                  return DropdownButtonFormField<String>(
                    dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.layoutGrid, size: 18),
                      hintText: "Select Section",
                    ),
                    initialValue: _selectedSectionId,
                    items: filtered.map((sec) => DropdownMenuItem(value: sec.id, child: Text("Section ${sec.name}"))).toList(),
                    onChanged: (val) => setState(() => _selectedSectionId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(AcadexException.sanitizedMessage(e), style: const TextStyle(color: AcadexColors.error, fontSize: 12)),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: AcadexColors.error, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AcadexColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: (_isLoading || _selectedSemesterId == null || _selectedSectionId == null)
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  try {
                    await ref.read(studentsProvider((sectionId: null, departmentId: null)).notifier).promoteStudents(
                      widget.studentIds,
                      _selectedSemesterId!,
                      _selectedSectionId!,
                      targetAcademicYearId: _selectedAcademicYearId,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    setState(() {
                      _isLoading = false;
                      _errorMessage = AcadexException.sanitizedMessage(e, fallback: 'Failed to promote selected students.');
                    });
                  }
                },
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirm Promotion'),
        ),
      ],
    );
  }
}

class StudentTransferDialog extends ConsumerStatefulWidget {
  final List<String> studentIds;

  const StudentTransferDialog({super.key, required this.studentIds});

  @override
  ConsumerState<StudentTransferDialog> createState() => _StudentTransferDialogState();
}

class _StudentTransferDialogState extends ConsumerState<StudentTransferDialog> {
  String? _selectedSectionId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sectionsAsync = ref.watch(sectionsProvider);

    return AlertDialog(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AcadexColors.accentTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AcadexRadius.sm),
            ),
            child: const Icon(LucideIcons.arrowRightLeft, color: AcadexColors.accentTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Section Transfer', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transferring ${widget.studentIds.length} student(s) to a new section. Historical attendance remains intact; future timetable and faculty will immediately update.',
                style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 20),
              Text('Target Section', style: AcadexTypography.bodySmall(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              sectionsAsync.when(
                data: (sections) => DropdownButtonFormField<String>(
                  dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.layoutGrid, size: 18),
                    hintText: "Select New Section",
                  ),
                  initialValue: _selectedSectionId,
                  items: sections.map((sec) => DropdownMenuItem(value: sec.id, child: Text("Section ${sec.name}"))).toList(),
                  onChanged: (val) => setState(() => _selectedSectionId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(AcadexException.sanitizedMessage(e), style: const TextStyle(color: AcadexColors.error, fontSize: 12)),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: AcadexColors.error, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AcadexColors.accentTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: (_isLoading || _selectedSectionId == null)
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  try {
                    await ref.read(studentsProvider((sectionId: null, departmentId: null)).notifier).transferStudents(
                      widget.studentIds,
                      _selectedSectionId!,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    setState(() {
                      _isLoading = false;
                      _errorMessage = AcadexException.sanitizedMessage(e, fallback: 'Failed to transfer selected students.');
                    });
                  }
                },
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirm Transfer'),
        ),
      ],
    );
  }
}

class StudentGraduationDialog extends ConsumerStatefulWidget {
  final List<String> studentIds;

  const StudentGraduationDialog({super.key, required this.studentIds});

  @override
  ConsumerState<StudentGraduationDialog> createState() => _StudentGraduationDialogState();
}

class _StudentGraduationDialogState extends ConsumerState<StudentGraduationDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AcadexColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AcadexRadius.sm),
            ),
            child: const Icon(LucideIcons.graduationCap, color: AcadexColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Graduate Students', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are graduating ${widget.studentIds.length} student(s).',
              style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AcadexColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AcadexRadius.sm),
                border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Active attendance & timetable will be locked.', style: AcadexTypography.caption(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('• Students will be moved to the Alumni registry.', style: AcadexTypography.caption(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('• Full academic timeline & history remain permanently accessible.', style: AcadexTypography.caption(color: theme.colorScheme.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AcadexColors.success,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(studentsProvider((sectionId: null, departmentId: null)).notifier).bulkGraduate(
                      studentIds: widget.studentIds,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      AcadexSnackBar.showError(
                        context,
                        e,
                        fallbackMessage: 'Failed to graduate selected students',
                      );
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirm Graduation'),
        ),
      ],
    );
  }
}

class StudentStatusChangeDialog extends StatefulWidget {
  final Student student;

  const StudentStatusChangeDialog({super.key, required this.student});

  @override
  State<StudentStatusChangeDialog> createState() => _StudentStatusChangeDialogState();
}

class _StudentStatusChangeDialogState extends State<StudentStatusChangeDialog> {
  late StudentLifecycleState _selectedState;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.student.lifecycleState;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
      title: Text('Change Student Status', style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Current Status: ${widget.student.lifecycleState.displayName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<StudentLifecycleState>(
              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              decoration: const InputDecoration(
                labelText: "Target Lifecycle State",
                prefixIcon: Icon(LucideIcons.userCheck),
              ),
              initialValue: _selectedState,
              items: StudentLifecycleState.values.map((s) {
                final isValid = widget.student.lifecycleState.isValidTransition(s);
                return DropdownMenuItem(
                  value: s,
                  child: Text("${s.displayName}${!isValid ? ' (Invalid transition)' : ''}"),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedState = val;
                    if (!widget.student.lifecycleState.isValidTransition(val)) {
                      _validationError = "Transition from ${widget.student.lifecycleState.displayName} to ${val.displayName} is not allowed.";
                    } else {
                      _validationError = null;
                    }
                  });
                }
              },
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Text(_validationError!, style: const TextStyle(color: AcadexColors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary, foregroundColor: Colors.white),
          onPressed: _validationError == null ? () => Navigator.pop(context, _selectedState) : null,
          child: const Text('Apply Status'),
        ),
      ],
    );
  }
}
