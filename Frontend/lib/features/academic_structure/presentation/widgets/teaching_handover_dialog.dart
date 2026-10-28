import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';

class TeachingHandoverDialog extends ConsumerStatefulWidget {
  final FacultyAssignment assignment;

  const TeachingHandoverDialog({super.key, required this.assignment});

  static Future<TeachingHandover?> show(
    BuildContext context, {
    required FacultyAssignment assignment,
  }) {
    return showDialog<TeachingHandover>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TeachingHandoverDialog(assignment: assignment),
    );
  }

  @override
  ConsumerState<TeachingHandoverDialog> createState() =>
      _TeachingHandoverDialogState();
}

class _TeachingHandoverDialogState
    extends ConsumerState<TeachingHandoverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedSuccessorId;
  bool _reassignPendingWork = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedSuccessorId == null)
      return;

    setState(() => _isSubmitting = true);
    try {
      final handover = await ref
          .read(academicRepositoryProvider)
          .handoverFacultyAssignment(
            assignmentId: widget.assignment.id,
            successorFacultyId: _selectedSuccessorId!,
            handoverNotes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            reassignPendingWork: _reassignPendingWork,
          );

      // Refresh assignments list
      ref.invalidate(facultyAssignmentsProvider);

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Teaching assignment successfully handed over to successor faculty.',
        );
        Navigator.of(context).pop(handover);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to complete teaching handover',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final facultyList = ref
        .watch(facultyProvider(widget.assignment.departmentId))
        .items;
    final eligibleSuccessors = facultyList
        .where((f) => f.id != widget.assignment.facultyId && f.isActive)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: AcadexRadius.borderRadiusMd,
                        ),
                        child: const Icon(
                          LucideIcons.arrowRightLeft,
                          color: AcadexColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teaching Handover',
                              style: AcadexTypography.heading2(
                                color: isDark
                                    ? AcadexColors.darkInk
                                    : AcadexColors.ink,
                              ).copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reassign course section while preserving historical records',
                              style: AcadexTypography.caption(
                                color: isDark
                                    ? AcadexColors.darkInkMuted
                                    : AcadexColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Source Assignment Overview Card
                  AcadexCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.user,
                              size: 16,
                              color: AcadexColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Teacher: ${widget.assignment.facultyName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Assignment: ${widget.assignment.academicStage ?? "Active Term"} • Section ${widget.assignment.sectionId ?? "Default"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AcadexColors.darkInkMuted
                                : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Successor Faculty Selection
                  Text(
                    'Successor Faculty Member *',
                    style: AcadexTypography.body(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedSuccessorId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select qualified successor faculty',
                      prefixIcon: Icon(LucideIcons.userCheck, size: 18),
                    ),
                    items: eligibleSuccessors.map((f) {
                      return DropdownMenuItem<String>(
                        value: f.id,
                        child: Text('${f.name} (${f.instituteId})'),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSuccessorId = val),
                    validator: (val) => val == null
                        ? 'Please select a successor faculty member'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Reassign Pending Work Checkbox
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _reassignPendingWork,
                    activeColor: AcadexColors.primary,
                    title: const Text(
                      'Reassign Pending Assignments & Attendance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Pending, unsubmitted items will be assigned to successor. Published marks & historical attendance remain attributed to original teacher.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AcadexColors.darkInkMuted
                            : AcadexColors.inkMuted,
                      ),
                    ),
                    onChanged: (val) =>
                        setState(() => _reassignPendingWork = val ?? true),
                  ),
                  const SizedBox(height: 12),

                  // Handover Notes
                  Text(
                    'Handover Notes / Audit Remarks',
                    style: AcadexTypography.body(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Faculty resignation, maternity leave handover, departmental reallocation',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      AcadexButton(
                        label: 'Execute Handover',
                        icon: LucideIcons.arrowRightLeft,
                        isLoading: _isSubmitting,
                        onPressed: _submit,
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
