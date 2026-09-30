import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignments_providers.dart';

class NewAssignmentScreen extends ConsumerStatefulWidget {
  final String? initialFacultyAssignmentId;

  const NewAssignmentScreen({
    super.key,
    this.initialFacultyAssignmentId,
  });

  @override
  ConsumerState<NewAssignmentScreen> createState() => _NewAssignmentScreenState();
}

class _NewAssignmentScreenState extends ConsumerState<NewAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedFacultyAssignmentId;

  @override
  void initState() {
    super.initState();
    if (widget.initialFacultyAssignmentId != null &&
        widget.initialFacultyAssignmentId!.isNotEmpty) {
      _selectedFacultyAssignmentId = widget.initialFacultyAssignmentId;
    }
  }

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMarksController = TextEditingController(text: '10');
  final _attachmentUrlController = TextEditingController();
  final _attachmentNameController = TextEditingController();

  AssignmentType _selectedType = AssignmentType.homework;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 23, minute: 59);

  final List<TextEditingController> _questionControllers = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxMarksController.dispose();
    _attachmentUrlController.dispose();
    _attachmentNameController.dispose();
    for (final c in _questionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      final removed = _questionControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSubmit({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFacultyAssignmentId == null) {
      AcadexSnackBar.showError(context, 'Please select a teaching context.');
      return;
    }

    final maxMarks = int.tryParse(_maxMarksController.text.trim()) ?? 10;
    if (maxMarks <= 0) {
      AcadexSnackBar.showError(context, 'Maximum marks must be greater than 0.');
      return;
    }

    setState(() => _isSubmitting = true);

    final questions = _questionControllers
        .map((c) => c.text.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    List<AssignmentAttachmentModel> attachments = [];
    if (_attachmentNameController.text.trim().isNotEmpty &&
        _attachmentUrlController.text.trim().isNotEmpty) {
      attachments.add(AssignmentAttachmentModel(
        name: _attachmentNameController.text.trim(),
        url: _attachmentUrlController.text.trim(),
      ));
    }

    final dueDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dueTimeStr = _selectedTime.format(context);

    final notifier = ref.read(assignmentActionProvider.notifier);
    final result = await notifier.createAssignment(
      facultyAssignmentId: _selectedFacultyAssignmentId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      questions: questions,
      assignmentType: _selectedType,
      dueDate: dueDateStr,
      dueTime: dueTimeStr,
      maximumMarks: maxMarks,
      attachments: attachments,
      status: publish ? AssignmentStatus.published : AssignmentStatus.draft,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result != null) {
        AcadexSnackBar.showSuccess(
          context,
          publish ? 'Assignment published successfully.' : 'Assignment draft saved.',
        );
        context.safePop(fallbackRoute: '/assignments');
      } else {
        AcadexSnackBar.showError(
          context,
          "Couldn't publish the assignment. Please try again.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final facultyAssignmentsAsync = ref.watch(facultyAssignmentsProvider);
    final subjectMap = ref.watch(subjectMapProvider);
    final sectionMap = ref.watch(sectionMapProvider);

    // Canonical teaching contexts based on authenticated role
    final myAssignments = ref.watch(myFacultyAssignmentsProvider);
    final isFaculty = authState is AuthAuthenticated && authState.user.role == AppRole.faculty;

    List<FacultyAssignment> userAssignments = [];
    if (isFaculty) {
      userAssignments = myAssignments;
    } else if (facultyAssignmentsAsync.hasValue) {
      final all = facultyAssignmentsAsync.value!;
      if (authState is AuthAuthenticated && authState.user.role == AppRole.hod) {
        userAssignments = all
            .where((fa) =>
                authState.user.departmentId == null ||
                fa.departmentId == authState.user.departmentId)
            .toList();
      } else {
        userAssignments = all;
      }
    }

    if (_selectedFacultyAssignmentId == null && userAssignments.isNotEmpty) {
      _selectedFacultyAssignmentId = userAssignments.first.id;
    }

    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/assignments'),
        ),
        title: Text(
          'Create Assignment',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TEACHING CONTEXT
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
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AcadexRadius.borderRadiusMd,
                    borderSide: BorderSide(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                ),
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                items: userAssignments.map((fa) {
                  final subj = subjectMap[fa.subjectId]?.name ?? 'Subject';
                  final sec = sectionMap[fa.sectionId]?.name ?? 'Section';
                  return DropdownMenuItem<String>(
                    value: fa.id,
                    child: Text(
                      '$subj ($sec)',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedFacultyAssignmentId = val);
                },
              ),

              const SizedBox(height: 18),

              // 2. ASSIGNMENT DETAILS
              Text(
                'ASSIGNMENT TITLE',
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Linked List Problems',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AcadexRadius.borderRadiusMd,
                    borderSide: BorderSide(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Title must be at least 2 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Text(
                'DESCRIPTION',
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Provide instructions or context for this assignment...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AcadexRadius.borderRadiusMd,
                    borderSide: BorderSide(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Description must be at least 2 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 3. TYPE & MAXIMUM MARKS ROW
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASSIGNMENT TYPE',
                          style: AcadexTypography.eyebrow(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<AssignmentType>(
                          value: _selectedType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                              borderSide: BorderSide(
                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              ),
                            ),
                          ),
                          dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                          items: AssignmentType.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(
                                t.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAXIMUM MARKS',
                          style: AcadexTypography.eyebrow(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _maxMarksController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '10',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                              borderSide: BorderSide(
                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              ),
                            ),
                          ),
                          validator: (val) {
                            final parsed = int.tryParse(val ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Must be > 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. DUE DATE & TIME ROW
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DUE DATE',
                          style: AcadexTypography.eyebrow(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: AcadexRadius.borderRadiusMd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              ),
                              borderRadius: AcadexRadius.borderRadiusMd,
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, size: 15, color: AcadexColors.primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    dateFormat.format(_selectedDate),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DUE TIME',
                          style: AcadexTypography.eyebrow(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: AcadexRadius.borderRadiusMd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                              ),
                              borderRadius: AcadexRadius.borderRadiusMd,
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 15, color: AcadexColors.primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _selectedTime.format(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 5. QUESTIONS (OPTIONAL)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'QUESTIONS (${_questionControllers.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AcadexTypography.eyebrow(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _addQuestion,
                    icon: const Icon(LucideIcons.plus, size: 14, color: AcadexColors.primary),
                    label: const Text(
                      'Add Question',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AcadexColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              if (_questionControllers.isNotEmpty)
                ...List.generate(_questionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Q${index + 1}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _questionControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Enter question text...',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: AcadexRadius.borderRadiusMd,
                                borderSide: BorderSide(
                                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFDC2626)),
                          onPressed: () => _removeQuestion(index),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // 6. ATTACHMENT (OPTIONAL)
              Text(
                'ATTACHMENT (OPTIONAL)',
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _attachmentNameController,
                      decoration: InputDecoration(
                        hintText: 'File name (e.g. assignment.pdf)',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: BorderSide(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _attachmentUrlController,
                      decoration: InputDecoration(
                        hintText: 'Attachment URL or key',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: BorderSide(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 7. ACTIONS: [ Publish Assignment ] and [ Save Draft ]
              SizedBox(
                width: double.infinity,
                height: 48,
                child: AcadexButton(
                  label: _isSubmitting ? 'Publishing...' : 'Publish Assignment',
                  icon: LucideIcons.send,
                  onPressed: _isSubmitting ? null : () => _handleSubmit(publish: true),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => _handleSubmit(publish: false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AcadexColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: AcadexRadius.borderRadiusMd,
                    ),
                  ),
                  child: const Text(
                    'Save Draft',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AcadexColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
