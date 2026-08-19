import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';

class StudentPromotionStepperDialog extends ConsumerStatefulWidget {
  final List<Student> initialStudents;
  final String? initialSectionId;
  final String? initialSemesterId;
  final String? initialDepartmentId;

  const StudentPromotionStepperDialog({
    super.key,
    required this.initialStudents,
    this.initialSectionId,
    this.initialSemesterId,
    this.initialDepartmentId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<Student> students,
    String? initialSectionId,
    String? initialSemesterId,
    String? initialDepartmentId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StudentPromotionStepperDialog(
        initialStudents: students,
        initialSectionId: initialSectionId,
        initialSemesterId: initialSemesterId,
        initialDepartmentId: initialDepartmentId,
      ),
    );
  }

  @override
  ConsumerState<StudentPromotionStepperDialog> createState() => _StudentPromotionStepperDialogState();
}

class _StudentPromotionStepperDialogState extends ConsumerState<StudentPromotionStepperDialog> {
  int _currentStep = 0;
  final Set<String> _selectedStudentIds = {};
  String? _targetAcademicYearId;
  String? _targetSemesterId;
  String? _targetSectionId;
  bool _isProcessing = false;
  double _progressValue = 0.0;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedStudentIds.addAll(widget.initialStudents.map((s) => s.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.lg)),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 700),
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
                    color: AcadexColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AcadexRadius.md),
                  ),
                  child: const Icon(LucideIcons.arrowUpRight, color: AcadexColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Academic Promotion Engine", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text("Promote students to next semester while preserving academic history.", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                if (!_isProcessing)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context, false),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Stepper Indicator Row
            _buildStepperHeader(theme),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Active Step Body with 180ms AnimatedSwitcher transition
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildCurrentStep(theme, isDark),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AcadexColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AcadexRadius.xs),
                  border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 16, color: AcadexColors.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AcadexColors.error, fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Navigation Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0 && !_isProcessing && _currentStep < 4)
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _errorMessage = null;
                      _currentStep--;
                    }),
                    child: const Text("Back"),
                  )
                else
                  const SizedBox.shrink(),
                if (!_isProcessing)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                    ),
                    onPressed: _onNextPressed,
                    child: Text(_getNextButtonLabel()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(ThemeData theme) {
    final steps = ["Select", "Current", "Target", "Review", "Confirm"];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isCompleted = _currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AcadexColors.primary : theme.dividerColor.withValues(alpha: 0.2),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isActive = _currentStep == stepIndex;
        final isCompleted = _currentStep > stepIndex;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AcadexColors.primary
                    : (isActive ? AcadexColors.primary.withValues(alpha: 0.15) : theme.dividerColor.withValues(alpha: 0.1)),
                border: Border.all(
                  color: isActive || isCompleted ? AcadexColors.primary : theme.dividerColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                    : Text(
                        "${stepIndex + 1}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AcadexColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              steps[stepIndex],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AcadexColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCurrentStep(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1SelectStudents(theme, isDark);
      case 1:
        return _buildStep2CurrentPlacement(theme, isDark);
      case 2:
        return _buildStep3TargetPlacement(theme, isDark);
      case 3:
        return _buildStep4Review(theme, isDark);
      case 4:
        return _buildStep5Confirm(theme, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Select Students
  Widget _buildStep1SelectStudents(ThemeData theme, bool isDark) {
    final allSelected = _selectedStudentIds.length == widget.initialStudents.length && widget.initialStudents.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Step 1: Choose Students to Promote (${_selectedStudentIds.length}/${widget.initialStudents.length} selected)",
              style: AcadexTypography.title(color: theme.colorScheme.onSurface),
            ),
            TextButton.icon(
              icon: Icon(allSelected ? LucideIcons.squareCheck : LucideIcons.square, size: 16),
              label: Text(allSelected ? "Deselect All" : "Select All"),
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedStudentIds.clear();
                  } else {
                    _selectedStudentIds.addAll(widget.initialStudents.map((s) => s.id));
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: widget.initialStudents.isEmpty
              ? const Center(child: Text("No students available for promotion in this scope."))
              : ListView.separated(
                  itemCount: widget.initialStudents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final s = widget.initialStudents[i];
                    final isChecked = _selectedStudentIds.contains(s.id);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            _selectedStudentIds.remove(s.id);
                          } else {
                            _selectedStudentIds.add(s.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(AcadexRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isChecked ? AcadexColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AcadexRadius.md),
                          border: Border.all(
                            color: isChecked ? AcadexColors.primary : theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedStudentIds.add(s.id);
                                  } else {
                                    _selectedStudentIds.remove(s.id);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AcadexColors.primary.withValues(alpha: 0.12),
                              child: Text(
                                s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AcadexColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                  Text("Roll: ${s.rollNumber} • ${s.email}", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                            AcadexBadge(
                              label: s.lifecycleState.displayName,
                              variant: AcadexBadgeVariant.success,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // STEP 2: Current Placement
  Widget _buildStep2CurrentPlacement(ThemeData theme, bool isDark) {
    final deptMap = ref.watch(departmentMapProvider);
    final courseMap = ref.watch(courseMapProvider);
    final semMap = ref.watch(semesterMapProvider);
    final secMap = ref.watch(sectionMapProvider);
    final yrMap = ref.watch(academicYearMapProvider);

    final firstStudent = widget.initialStudents.firstWhere(
      (s) => _selectedStudentIds.contains(s.id),
      orElse: () => widget.initialStudents.first,
    );

    final dept = deptMap[firstStudent.departmentId];
    final crs = courseMap[firstStudent.courseId];
    final sem = semMap[firstStudent.semesterId];
    final sec = secMap[firstStudent.sectionId];
    final yr = yrMap[firstStudent.academicYearId];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 2: Source Academic Placement", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text(
            "Verifying source parameters for the ${_selectedStudentIds.length} selected students.",
            style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
              borderRadius: BorderRadius.circular(AcadexRadius.md),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _buildInfoRow("Department", dept?.name ?? firstStudent.departmentId, LucideIcons.building, theme),
                const Divider(height: 20),
                _buildInfoRow("Course", "${crs?.name ?? firstStudent.courseId} (${crs?.code ?? ''})", LucideIcons.book, theme),
                const Divider(height: 20),
                _buildInfoRow("Current Academic Year", yr?.name ?? firstStudent.academicYearId, LucideIcons.calendar, theme),
                const Divider(height: 20),
                _buildInfoRow("Current Semester", sem?.name ?? firstStudent.semesterId, LucideIcons.layers, theme),
                const Divider(height: 20),
                _buildInfoRow("Current Section", "Section ${sec?.name ?? firstStudent.sectionId}", LucideIcons.layoutGrid, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Target Placement
  Widget _buildStep3TargetPlacement(ThemeData theme, bool isDark) {
    final academicYearsAsync = ref.watch(academicYearsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    final firstStudent = widget.initialStudents.firstWhere(
      (s) => _selectedStudentIds.contains(s.id),
      orElse: () => widget.initialStudents.first,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 3: Choose Target Academic Placement", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text(
            "Select destination academic year, semester, and section. Cross-course or cross-department placement is prevented.",
            style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),

          // Target Academic Year
          Text("Target Academic Year *", style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          academicYearsAsync.when(
            data: (years) => DropdownButtonFormField<String>(
              key: ValueKey('target_ay_$_targetAcademicYearId'),
              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.calendar, size: 18),
                hintText: "Select Target Academic Year",
              ),
              initialValue: _targetAcademicYearId,
              items: years.map((y) => DropdownMenuItem(value: y.id, child: Text(y.name))).toList(),
              onChanged: (val) => setState(() => _targetAcademicYearId = val),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
          ),
          const SizedBox(height: 16),

          // Target Semester
          Text("Target Semester *", style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          semestersAsync.when(
            data: (semesters) {
              // Filter to matching course
              final filtered = semesters.where((s) => s.courseId == firstStudent.courseId).toList();

              return DropdownButtonFormField<String>(
                key: ValueKey('target_sem_${firstStudent.courseId}_$_targetSemesterId'),
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                decoration: const InputDecoration(
                  prefixIcon: Icon(LucideIcons.layers, size: 18),
                  hintText: "Select Target Semester",
                ),
                initialValue: _targetSemesterId,
                items: filtered.map((sem) => DropdownMenuItem(value: sem.id, child: Text("${sem.name} (Course: ${firstStudent.courseId})"))).toList(),
                onChanged: (val) => setState(() {
                  _targetSemesterId = val;
                  _targetSectionId = null;
                }),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
          ),
          const SizedBox(height: 16),

          // Target Section
          Text("Target Section *", style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          sectionsAsync.when(
            data: (sections) {
              final filtered = _targetSemesterId != null
                  ? sections.where((sec) => sec.semesterId == _targetSemesterId).toList()
                  : <Section>[];

              return DropdownButtonFormField<String>(
                key: ValueKey('target_sec_${_targetSemesterId}_$_targetSectionId'),
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.layoutGrid, size: 18),
                  hintText: _targetSemesterId == null ? "Select semester first" : "Select Target Section",
                ),
                initialValue: _targetSectionId,
                items: filtered.map((sec) => DropdownMenuItem(value: sec.id, child: Text("Section ${sec.name}"))).toList(),
                onChanged: _targetSemesterId == null ? null : (val) => setState(() => _targetSectionId = val),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: AcadexColors.error)),
          ),
        ],
      ),
    );
  }

  // STEP 4: Review
  Widget _buildStep4Review(ThemeData theme, bool isDark) {
    final semMap = ref.watch(semesterMapProvider);
    final secMap = ref.watch(sectionMapProvider);
    final yrMap = ref.watch(academicYearMapProvider);

    final firstStudent = widget.initialStudents.firstWhere(
      (s) => _selectedStudentIds.contains(s.id),
      orElse: () => widget.initialStudents.first,
    );

    final currentSem = semMap[firstStudent.semesterId]?.name ?? firstStudent.semesterId;
    final currentSec = secMap[firstStudent.sectionId]?.name ?? firstStudent.sectionId;
    final targetSem = semMap[_targetSemesterId]?.name ?? _targetSemesterId ?? '';
    final targetSec = secMap[_targetSectionId]?.name ?? _targetSectionId ?? '';
    final targetYr = yrMap[_targetAcademicYearId]?.name ?? _targetAcademicYearId ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Step 4: Review Promotion Summary", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text(
            "Verify the transition details below before confirming promotion.",
            style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),

          // Comparison Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AcadexColors.primary.withValues(alpha: 0.1),
                  AcadexColors.accentPurple.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AcadexRadius.md),
              border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Selected Students", style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                    Text("${_selectedStudentIds.length} Student(s)", style: const TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.primary)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("FROM", style: AcadexTypography.eyebrow(color: AcadexColors.error)),
                          const SizedBox(height: 4),
                          Text(currentSem, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Section $currentSec", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.arrowRight, color: AcadexColors.primary, size: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("TO", style: AcadexTypography.eyebrow(color: AcadexColors.success)),
                          const SizedBox(height: 4),
                          Text(targetSem, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AcadexColors.success)),
                          Text("Section $targetSec • $targetYr", style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AcadexColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AcadexRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, size: 18, color: AcadexColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "All historical attendance, timetable, notes and certificates for previous terms remain immutably archived in StudentAcademicHistory.",
                    style: AcadexTypography.caption(color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 5: Confirm & Execute
  Widget _buildStep5Confirm(ThemeData theme, bool isDark) {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_statusMessage ?? "Processing academic promotion...", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              child: LinearProgressIndicator(value: _progressValue > 0 ? _progressValue : null),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AcadexColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.circleCheck, color: AcadexColors.success, size: 40),
          ),
          const SizedBox(height: 16),
          Text("Ready to Commit Promotion", style: AcadexTypography.heading3(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
            "Click 'Commit Promotion' below to atomically update placement and record academic history.",
            style: AcadexTypography.body(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AcadexColors.primary),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
      ],
    );
  }

  String _getNextButtonLabel() {
    switch (_currentStep) {
      case 0:
        return "Next: Source Info";
      case 1:
        return "Next: Target Selection";
      case 2:
        return "Next: Review";
      case 3:
        return "Proceed to Confirm";
      case 4:
        return "Commit Promotion";
      default:
        return "Next";
    }
  }

  Future<void> _onNextPressed() async {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      if (_selectedStudentIds.isEmpty) {
        setState(() => _errorMessage = "Please select at least one student to promote.");
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_targetAcademicYearId == null || _targetAcademicYearId!.isEmpty) {
        setState(() => _errorMessage = "Please select target academic year.");
        return;
      }
      if (_targetSemesterId == null || _targetSemesterId!.isEmpty) {
        setState(() => _errorMessage = "Please select target semester.");
        return;
      }
      if (_targetSectionId == null || _targetSectionId!.isEmpty) {
        setState(() => _errorMessage = "Please select target section.");
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      await _executePromotion();
    }
  }

  Future<void> _executePromotion() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Promoting ${_selectedStudentIds.length} student(s)...";
      _progressValue = 0.3;
    });

    try {
      await ref.read(studentsProvider((sectionId: widget.initialSectionId, departmentId: widget.initialDepartmentId)).notifier).promoteStudents(
        _selectedStudentIds.toList(),
        _targetSemesterId!,
        _targetSectionId!,
        targetAcademicYearId: _targetAcademicYearId,
      );

      setState(() {
        _progressValue = 1.0;
        _statusMessage = "Promotion completed successfully!";
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll("Exception:", "").trim();
      });
    }
  }
}
