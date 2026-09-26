import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';

class SectionTransferStepperDialog extends ConsumerStatefulWidget {
  final List<Student> initialStudents;
  final String? sourceSectionId;

  const SectionTransferStepperDialog({
    super.key,
    this.initialStudents = const [],
    this.sourceSectionId,
  });

  static Future<void> show(
    BuildContext context, {
    List<Student> initialStudents = const [],
    String? sourceSectionId,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SectionTransferStepperDialog(
        initialStudents: initialStudents,
        sourceSectionId: sourceSectionId,
      ),
    );
  }

  @override
  ConsumerState<SectionTransferStepperDialog> createState() => _SectionTransferStepperDialogState();
}

class _SectionTransferStepperDialogState extends ConsumerState<SectionTransferStepperDialog> {
  int _currentStep = 0;
  final Set<String> _selectedStudentIds = {};
  String _studentSearchQuery = '';
  String? _targetSectionId;
  bool _isValidating = false;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = '';
  List<SectionTransferValidationResult> _validationResults = [];

  @override
  void initState() {
    super.initState();
    _selectedStudentIds.addAll(widget.initialStudents.map((s) => s.id));
    if (widget.initialStudents.isNotEmpty) {
      _currentStep = 1; // Move directly to Target Section if students pre-selected
    }
  }

  int get _eligibleCount => _validationResults.where((r) => r.canMove).length;
  int get _ineligibleCount => _validationResults.where((r) => !r.canMove).length;

  Future<void> _runValidation() async {
    if (_targetSectionId == null || _selectedStudentIds.isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    try {
      final repo = ref.read(academicRepositoryProvider);
      final results = await repo.validateBulkSectionTransfer(
        _selectedStudentIds.toList(),
        _targetSectionId!,
      );
      if (mounted) {
        setState(() {
          _validationResults = results;
          _isValidating = false;
          _currentStep = 2; // Move to Validation Results step
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Transfer validation failed',
        );
      }
    }
  }

  Future<void> _executeTransfer() async {
    final eligibleIds = _validationResults.where((r) => r.canMove).map((r) => r.studentId).toList();
    if (eligibleIds.isEmpty || _targetSectionId == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.1;
      _statusMessage = 'Initiating transfer for ${eligibleIds.length} students...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _progress = 0.5;
        _statusMessage = 'Updating section rosters & preserving academic history...';
      });

      await ref.read(sectionsProvider.notifier).executeBulkTransfer(
        eligibleIds,
        _targetSectionId!,
      );

      setState(() {
        _progress = 1.0;
        _statusMessage = 'Transfer completed successfully!';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
        AcadexSnackBar.showSuccess(
          context,
          'Successfully transferred ${eligibleIds.length} students to target section.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Section transfer failed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AcadexColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AcadexRadius.md),
                  ),
                  child: const Icon(LucideIcons.arrowRightLeft, color: AcadexColors.secondary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Section Transfer Engine", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text("Move students between sections with automatic capacity validation.", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                if (!_isProcessing)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Stepper Indicator
            _buildStepperIndicator(theme),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Body (Animated Switcher)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _buildCurrentStepView(theme),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Footer Actions
            _buildFooterActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperIndicator(ThemeData theme) {
    final steps = ['Select', 'Target', 'Validation', 'Confirm'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIdx = index ~/ 2;
          final isCompleted = _currentStep > stepIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AcadexColors.secondary : theme.dividerColor,
            ),
          );
        }

        final stepIdx = index ~/ 2;
        final isActive = _currentStep == stepIdx;
        final isCompleted = _currentStep > stepIdx;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AcadexColors.secondary
                    : isActive
                        ? AcadexColors.secondary.withValues(alpha: 0.15)
                        : theme.dividerColor.withValues(alpha: 0.5),
                border: Border.all(
                  color: (isActive || isCompleted) ? AcadexColors.secondary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                    : Text(
                        "${stepIdx + 1}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AcadexColors.secondary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              steps[stepIdx],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCurrentStepView(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1SelectStudents(theme);
      case 1:
        return _buildStep2TargetSection(theme);
      case 2:
        return _buildStep3ValidationResults(theme);
      case 3:
        return _buildStep4ConfirmExecute(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Select Students
  Widget _buildStep1SelectStudents(ThemeData theme) {
    final studentState = ref.watch(studentsProvider((sectionId: widget.sourceSectionId, departmentId: null)));
    final allStudents = studentState.items;
    final filtered = allStudents.where((s) {
      if (widget.sourceSectionId != null && s.sectionId != widget.sourceSectionId) return false;
      if (_studentSearchQuery.isNotEmpty) {
        final q = _studentSearchQuery.toLowerCase();
        return s.name.toLowerCase().contains(q) || s.rollNumber.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search students by name or roll number...",
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                ),
                onChanged: (v) => setState(() => _studentSearchQuery = v),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              icon: Icon(
                _selectedStudentIds.length == filtered.length ? LucideIcons.checkSquare : LucideIcons.square,
                size: 18,
              ),
              label: Text(_selectedStudentIds.length == filtered.length ? "Deselect All" : "Select All"),
              onPressed: () {
                setState(() {
                  if (_selectedStudentIds.length == filtered.length) {
                    _selectedStudentIds.clear();
                  } else {
                    _selectedStudentIds.addAll(filtered.map((s) => s.id));
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "${_selectedStudentIds.length} student(s) selected",
            style: AcadexTypography.caption(color: AcadexColors.secondary).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text("No matching students found.", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final student = filtered[i];
                    final isSelected = _selectedStudentIds.contains(student.id);

                    return CheckboxListTile(
                      value: isSelected,
                      dense: true,
                      activeColor: AcadexColors.secondary,
                      title: Text(student.name, style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text("Roll: ${student.rollNumber} • Section: ${student.sectionId}", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedStudentIds.add(student.id);
                          } else {
                            _selectedStudentIds.remove(student.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // STEP 2: Target Section
  Widget _buildStep2TargetSection(ThemeData theme) {
    final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
    final eligibleSections = sections.where((s) => s.isActive && s.id != widget.sourceSectionId).toList();

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Target Section", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 6),
        Text("Students will be moved to this section after validating capacity.", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 16),
        Expanded(
          child: eligibleSections.isEmpty
              ? Center(child: Text("No alternative sections available.", style: AcadexTypography.body(color: theme.colorScheme.onSurface)))
              : ListView.builder(
                  itemCount: eligibleSections.length,
                  itemBuilder: (context, index) {
                    final sec = eligibleSections[index];
                    final isSelected = _targetSectionId == sec.id;

                    return Consumer(
                      builder: (context, ref, _) {
                        final capAsync = ref.watch(sectionCapacityInfoProvider(sec.id));

                        return capAsync.when(
                          loading: () => const ListTile(title: Text("Loading section capacity...")),
                          error: (_, __) => ListTile(title: Text(sec.name)),
                          data: (capInfo) {
                            final isFull = capInfo.isFull;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AcadexColors.secondary.withValues(alpha: 0.08)
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(AcadexRadius.md),
                                border: Border.all(
                                  color: isSelected ? AcadexColors.secondary : theme.dividerColor.withValues(alpha: 0.6),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Radio<String>(
                                  value: sec.id,
                                  groupValue: _targetSectionId,
                                  activeColor: AcadexColors.secondary,
                                  onChanged: isFull ? null : (val) => setState(() => _targetSectionId = val),
                                ),
                                title: Row(
                                  children: [
                                    Text("Section ${sec.name}", style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 10),
                                    if (isFull)
                                      const AcadexBadge(label: "FULL", variant: AcadexBadgeVariant.warning)
                                    else
                                      AcadexBadge(label: "${capInfo.availableSeats} seats left", variant: AcadexBadgeVariant.success),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("Enrolled: ${capInfo.enrolledCount} / ${capInfo.capacity} students (${capInfo.utilizationPercentage.toStringAsFixed(1)}% full)", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: capInfo.capacity > 0 ? (capInfo.enrolledCount / capInfo.capacity).clamp(0.0, 1.0) : 0.0,
                                        backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          capInfo.utilizationPercentage > 90 ? AcadexColors.warning : AcadexColors.secondary,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: isFull ? null : () => setState(() => _targetSectionId = sec.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // STEP 3: Pre-Flight Validation Results
  Widget _buildStep3ValidationResults(ThemeData theme) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pre-Flight Validation Breakdown", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text("${_selectedStudentIds.length} selected • $_eligibleCount eligible • $_ineligibleCount rejected", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _ineligibleCount == 0 ? AcadexColors.success.withValues(alpha: 0.12) : AcadexColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AcadexRadius.md),
              ),
              child: Text(
                _ineligibleCount == 0 ? "ALL APPROVED" : "$_ineligibleCount REJECTED",
                style: TextStyle(
                  color: _ineligibleCount == 0 ? AcadexColors.success : AcadexColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _validationResults.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final result = _validationResults[index];
              return ListTile(
                dense: true,
                leading: Icon(
                  result.canMove ? LucideIcons.checkCircle : LucideIcons.xCircle,
                  color: result.canMove ? AcadexColors.success : AcadexColors.warning,
                  size: 20,
                ),
                title: Text(result.studentName, style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text("Roll: ${result.rollNumber}", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                trailing: result.canMove
                    ? const AcadexBadge(label: "Eligible", variant: AcadexBadgeVariant.success)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AcadexColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AcadexRadius.sm),
                        ),
                        child: Text(
                          result.reason ?? "Ineligible",
                          style: const TextStyle(color: AcadexColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  // STEP 4: Confirm & Execute
  Widget _buildStep4ConfirmExecute(ThemeData theme) {
    if (_isProcessing) {
      return Center(
        key: const ValueKey('processing'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AcadexColors.secondary),
            const SizedBox(height: 20),
            Text(_statusMessage, style: AcadexTypography.body(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            SizedBox(
              width: 320,
              child: LinearProgressIndicator(
                value: _progress,
                color: AcadexColors.secondary,
                backgroundColor: theme.dividerColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Confirm Section Transfer", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 6),
        Text("Please review the final transfer cohort before committing changes.", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AcadexRadius.md),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              _buildSummaryRow(theme, "Transferring Students", "$_eligibleCount active student(s)"),
              const Divider(height: 20),
              _buildSummaryRow(theme, "Target Section", "Section $_targetSectionId"),
              const Divider(height: 20),
              _buildSummaryRow(theme, "Historical Roster Status", "Preserved immutably in Timeline"),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AcadexColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AcadexRadius.md),
            border: Border.all(color: AcadexColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, color: AcadexColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Historical attendance, notes, and timetable entries will NOT be corrupted. They remain locked to the original section context.",
                  style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        Text(value, style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFooterActions(ThemeData theme) {
    if (_isProcessing) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text("Back"),
            onPressed: () => setState(() => _currentStep--),
          )
        else
          const SizedBox.shrink(),

        Row(
          children: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
            if (_currentStep == 0)
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.arrowRight, size: 16),
                label: const Text("Next: Target Section"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _selectedStudentIds.isEmpty
                    ? null
                    : () => setState(() => _currentStep = 1),
              )
            else if (_currentStep == 1)
              ElevatedButton.icon(
                icon: _isValidating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.shieldCheck, size: 16),
                label: Text(_isValidating ? "Validating..." : "Validate Transfer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _targetSectionId == null || _isValidating ? null : _runValidation,
              )
            else if (_currentStep == 2)
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.arrowRight, size: 16),
                label: const Text("Review Transfer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _eligibleCount == 0 ? null : () => setState(() => _currentStep = 3),
              )
            else if (_currentStep == 3)
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.check, size: 16),
                label: Text("Transfer $_eligibleCount Students"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _executeTransfer,
              ),
          ],
        ),
      ],
    );
  }
}
