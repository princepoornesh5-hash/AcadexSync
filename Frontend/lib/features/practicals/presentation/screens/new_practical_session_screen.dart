import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../providers/practicals_providers.dart';

class NewPracticalSessionScreen extends ConsumerStatefulWidget {
  final String? initialFacultyAssignmentId;

  const NewPracticalSessionScreen({
    super.key,
    this.initialFacultyAssignmentId,
  });

  @override
  ConsumerState<NewPracticalSessionScreen> createState() => _NewPracticalSessionScreenState();
}

class _NewPracticalSessionScreenState extends ConsumerState<NewPracticalSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedFacultyAssignmentId;
  final _topicController = TextEditingController();
  final _sessionNumberController = TextEditingController(text: '1');
  final _startTimeController = TextEditingController(text: '10:00');
  final _endTimeController = TextEditingController(text: '12:00');
  final _instructionsController = TextEditingController();

  DateTime _scheduledDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFacultyAssignmentId != null &&
        widget.initialFacultyAssignmentId!.isNotEmpty) {
      _selectedFacultyAssignmentId = widget.initialFacultyAssignmentId;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _sessionNumberController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFacultyAssignmentId == null) {
      AcadexSnackBar.showError(context, 'Please select a teaching assignment for this practical');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final sessNum = int.tryParse(_sessionNumberController.text.trim()) ?? 1;

      final session = await ref.read(practicalActionProvider.notifier).createSession({
        'facultyAssignmentId': _selectedFacultyAssignmentId,
        'topic': _topicController.text.trim(),
        'sessionNumber': sessNum,
        'scheduledDate': _scheduledDate.toIso8601String(),
        'startTime': _startTimeController.text.trim().isNotEmpty ? _startTimeController.text.trim() : null,
        'endTime': _endTimeController.text.trim().isNotEmpty ? _endTimeController.text.trim() : null,
        'instructions': _instructionsController.text.trim().isNotEmpty ? _instructionsController.text.trim() : null,
      });

      if (mounted) {
        AcadexSnackBar.showSuccess(context, 'Practical lab session scheduled successfully!');
        if (session != null) {
          context.pushReplacement('/practicals/${session.id}');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myAssignments = ref.watch(myFacultyAssignmentsProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    // Filter to practical or all active teaching assignments
    final List<FacultyAssignment> availableAssignments = myAssignments.isNotEmpty
        ? myAssignments
        : (ref.watch(facultyAssignmentsProvider).valueOrNull ?? []);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/practicals'),
        ),
        title: Text(
          'Schedule Practical Lab',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Subject / Class Selection
              Text(
                'TEACHING CONTEXT',
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedFacultyAssignmentId,
                isExpanded: true,
                hint: const Text('Select Practical Class / Subject'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AcadexRadius.borderRadiusMd,
                    borderSide: BorderSide(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                ),
                items: availableAssignments.map((fa) {
                  final sub = subjects.where((s) => s.id == fa.subjectId).firstOrNull;
                  final label = sub != null ? '${sub.code} - ${sub.name}' : 'Subject (${fa.subjectId})';
                  return DropdownMenuItem<String>(
                    value: fa.id,
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedFacultyAssignmentId = val),
                validator: (val) => val == null ? 'Please select a subject' : null,
              ),

              const SizedBox(height: 16),

              // Section 2: Session Details
              Text(
                'PRACTICAL DETAILS',
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _topicController,
                decoration: InputDecoration(
                  labelText: 'Topic / Experiment Title *',
                  hintText: 'e.g. Experiment 3: Stacks & Queues Implementation',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Topic is required';
                  if (val.trim().length < 2) return 'Topic must be at least 2 characters';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sessionNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Session #',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: AcadexRadius.borderRadiusMd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          border: Border.all(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 16, color: AcadexColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _scheduledDate.toLocal().toString().substring(0, 10),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        hintText: '10:00',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        hintText: '12:00',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Section 3: Instructions & Notes
              Text(
                'INSTRUCTIONS & OBJECTIVES',
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _instructionsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add lab instructions, prerequisites, or experiment guidelines for students...',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: AcadexButton(
                  label: _isSaving ? 'Scheduling...' : 'Schedule Practical Session',
                  icon: LucideIcons.calendarCheck,
                  onPressed: _isSaving ? null : _handleSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
