import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
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

  // Scope Selection State
  String _selectedScopeType = 'SECTION'; // COLLEGE, DEPARTMENT, SEMESTER, SECTION, SUBJECT
  String? _selectedFacultyAssignmentId;
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  // Assignment fields
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
  void initState() {
    super.initState();
    if (widget.initialFacultyAssignmentId != null &&
        widget.initialFacultyAssignmentId!.isNotEmpty) {
      _selectedFacultyAssignmentId = widget.initialFacultyAssignmentId;
    }
  }

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

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final role = authState.user.role;

    if (role == AppRole.student) {
      AcadexSnackBar.showError(context, 'Students are not authorized to create assignments.');
      return;
    }

    final isFaculty = role == AppRole.faculty;

    // Validate scope selections
    if (isFaculty) {
      if (_selectedFacultyAssignmentId == null || _selectedFacultyAssignmentId!.isEmpty) {
        AcadexSnackBar.showError(context, 'Please select an authorized teaching context.');
        return;
      }
    } else {
      switch (_selectedScopeType) {
        case 'COLLEGE':
          // College wide requires no further hierarchy
          break;
        case 'DEPARTMENT':
          if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
            AcadexSnackBar.showError(context, 'Please select a department.');
            return;
          }
          break;
        case 'SEMESTER':
          if (_selectedSemesterId == null || _selectedSemesterId!.isEmpty) {
            AcadexSnackBar.showError(context, 'Please select a course and semester.');
            return;
          }
          break;
        case 'SECTION':
          if (_selectedSectionId == null || _selectedSectionId!.isEmpty) {
            AcadexSnackBar.showError(context, 'Please select a section.');
            return;
          }
          break;
        case 'SUBJECT':
          if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
            AcadexSnackBar.showError(context, 'Please select a subject.');
            return;
          }
          break;
      }
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

    // Resolve academic year if applicable
    final semesterMap = ref.read(semesterMapProvider);
    String? academicYearId;
    if (_selectedSemesterId != null) {
      academicYearId = semesterMap[_selectedSemesterId]?.academicYearId;
    }
    if (academicYearId == null) {
      final currentAy = ref.read(currentAcademicYearProvider);
      academicYearId = currentAy?.id;
    }

    final notifier = ref.read(assignmentActionProvider.notifier);
    final result = await notifier.createAssignment(
      facultyAssignmentId: isFaculty ? _selectedFacultyAssignmentId : null,
      scope: isFaculty
          ? (_selectedSectionId != null ? 'SECTION' : 'SEMESTER')
          : _selectedScopeType,
      departmentId: _selectedDepartmentId,
      courseId: _selectedCourseId,
      academicYearId: academicYearId,
      semesterId: _selectedSemesterId,
      sectionId: _selectedSectionId,
      subjectId: _selectedSubjectId,
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
          "Couldn't publish the assignment. Please check all scope selections and try again.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    final role = user.role;

    if (role == AppRole.student) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          title: const Text('Create Assignment'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shieldAlert, size: 56, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: AcadexTypography.h3(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Students are not permitted to create assignments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 20),
                AcadexButton(
                  label: 'Back to Assignments',
                  icon: LucideIcons.arrowLeft,
                  onPressed: () => context.safePop(fallbackRoute: '/assignments'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isFaculty = role == AppRole.faculty;
    final isHod = role == AppRole.hod;
    final isAdmin = role == AppRole.collegeAdmin ||
        role == AppRole.superAdmin;

    // Academic Structure Watchers
    final departments = ref.watch(departmentsProvider).valueOrNull ?? [];
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
    final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    final subjectMap = ref.watch(subjectMapProvider);
    final sectionMap = ref.watch(sectionMapProvider);
    final departmentMap = ref.watch(departmentMapProvider);

    final myAssignments = ref.watch(myFacultyAssignmentsProvider);

    // Initial setup for HOD: lock department
    if (isHod && user.departmentId != null && _selectedDepartmentId != user.departmentId) {
      _selectedDepartmentId = user.departmentId;
      if (_selectedScopeType == 'COLLEGE') {
        _selectedScopeType = 'DEPARTMENT';
      }
    }

    // Auto-select first faculty assignment for faculty if none selected
    if (isFaculty && _selectedFacultyAssignmentId == null && myAssignments.isNotEmpty) {
      final first = myAssignments.first;
      _selectedFacultyAssignmentId = first.id;
      _selectedDepartmentId = first.departmentId;
      _selectedCourseId = first.courseId;
      _selectedSemesterId = first.semesterId;
      _selectedSectionId = first.sectionId;
      _selectedSubjectId = first.subjectId;
      _selectedScopeType = first.sectionId != null ? 'SECTION' : 'SEMESTER';
    }

    // Filter dependent dropdowns
    final effectiveDeptId = isHod ? (user.departmentId ?? _selectedDepartmentId) : _selectedDepartmentId;

    final filteredCourses = courses.where((c) {
      if (effectiveDeptId == null || effectiveDeptId.isEmpty) return true;
      return c.departmentId == effectiveDeptId;
    }).toList();

    final filteredSemesters = semesters.where((s) {
      if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
        return s.courseId == _selectedCourseId;
      }
      if (effectiveDeptId != null && effectiveDeptId.isNotEmpty) {
        return s.departmentId == effectiveDeptId;
      }
      return true;
    }).toList();

    final filteredSections = sections.where((sec) {
      if (_selectedSemesterId != null && _selectedSemesterId!.isNotEmpty) {
        return sec.semesterId == _selectedSemesterId;
      }
      if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
        return sec.courseId == _selectedCourseId;
      }
      return true;
    }).toList();

    final filteredSubjects = subjects.where((sub) {
      if (_selectedSemesterId != null && _selectedSemesterId!.isNotEmpty) {
        return sub.semesterId == _selectedSemesterId || sub.courseId == _selectedCourseId;
      }
      if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
        return sub.courseId == _selectedCourseId;
      }
      if (effectiveDeptId != null && effectiveDeptId.isNotEmpty) {
        return sub.departmentId == effectiveDeptId;
      }
      return true;
    }).toList();

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
              // ─────────────────────────────────────────────────────────
              // 1. ACADEMIC SCOPE & AUDIENCE SELECTION
              // ─────────────────────────────────────────────────────────
              Text(
                isFaculty ? 'TEACHING CONTEXT' : 'ACADEMIC AUDIENCE & SCOPE',
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),

              if (isFaculty) ...[
                // Faculty: strictly choose from authorized teaching assignments
                if (myAssignments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 18, color: Colors.amber.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No active teaching assignments found for your account. You cannot publish assignments until classes are assigned.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
                    items: myAssignments.map((fa) {
                      final subj = subjectMap[fa.subjectId]?.name ?? 'Subject';
                      final sec = sectionMap[fa.sectionId]?.name;
                      final label = sec != null ? '$subj ($sec)' : subj;
                      return DropdownMenuItem<String>(
                        value: fa.id,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final fa = myAssignments.firstWhere((a) => a.id == val);
                      setState(() {
                        _selectedFacultyAssignmentId = fa.id;
                        _selectedDepartmentId = fa.departmentId;
                        _selectedCourseId = fa.courseId;
                        _selectedSemesterId = fa.semesterId;
                        _selectedSectionId = fa.sectionId;
                        _selectedSubjectId = fa.subjectId;
                        _selectedScopeType = fa.sectionId != null ? 'SECTION' : 'SEMESTER';
                      });
                    },
                    validator: (val) => val == null ? 'Please select an authorized teaching context.' : null,
                  ),
              ] else ...[
                // HOD & College Admin: Role-based scope selector
                DropdownButtonFormField<String>(
                  value: _selectedScopeType,
                  decoration: InputDecoration(
                    labelText: 'Scope Level *',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: AcadexRadius.borderRadiusMd,
                      borderSide: BorderSide(
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      ),
                    ),
                  ),
                  dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                  items: [
                    if (isAdmin)
                      const DropdownMenuItem(value: 'COLLEGE', child: Text('Entire College')),
                    const DropdownMenuItem(value: 'DEPARTMENT', child: Text('Department Wide')),
                    const DropdownMenuItem(value: 'SEMESTER', child: Text('Semester / Class')),
                    const DropdownMenuItem(value: 'SECTION', child: Text('Specific Section')),
                    const DropdownMenuItem(value: 'SUBJECT', child: Text('Specific Subject')),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedScopeType = val;
                      if (val == 'COLLEGE') {
                        if (!isHod) _selectedDepartmentId = null;
                        _selectedCourseId = null;
                        _selectedSemesterId = null;
                        _selectedSectionId = null;
                        _selectedSubjectId = null;
                      } else if (val == 'DEPARTMENT') {
                        _selectedCourseId = null;
                        _selectedSemesterId = null;
                        _selectedSectionId = null;
                        _selectedSubjectId = null;
                      } else if (val == 'SEMESTER') {
                        _selectedSectionId = null;
                        _selectedSubjectId = null;
                      } else if (val == 'SECTION') {
                        _selectedSubjectId = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Department Selection (Editable for Admin, Locked for HOD)
                if (_selectedScopeType != 'COLLEGE') ...[
                  if (isHod)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.darkSurfaceCard : const Color(0xFFF1F5F9),
                        borderRadius: AcadexRadius.borderRadiusMd,
                        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.building, size: 16, color: AcadexColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Department: ${departmentMap[user.departmentId]?.name ?? user.departmentId ?? "Your Department"} (Locked)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedDepartmentId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Department / Branch *',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                        ),
                      ),
                      dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                      items: departments.map((d) {
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text('${d.name} (${d.code})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDepartmentId = val;
                          _selectedCourseId = null;
                          _selectedSemesterId = null;
                          _selectedSectionId = null;
                          _selectedSubjectId = null;
                        });
                      },
                      validator: (val) {
                        if (_selectedScopeType != 'COLLEGE' && (val == null || val.isEmpty)) {
                          return 'Please select a department.';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 12),
                ],

                // Program / Course Selection (for SEMESTER, SECTION, SUBJECT)
                if (_selectedScopeType == 'SEMESTER' ||
                    _selectedScopeType == 'SECTION' ||
                    _selectedScopeType == 'SUBJECT') ...[
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Program / Course *',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                    ),
                    dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                    items: filteredCourses.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.name} (${c.code})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCourseId = val;
                        _selectedSemesterId = null;
                        _selectedSectionId = null;
                        _selectedSubjectId = null;
                      });
                    },
                    validator: (val) => val == null ? 'Please select a course/program.' : null,
                  ),
                  const SizedBox(height: 12),

                  // Semester Selection
                  DropdownButtonFormField<String>(
                    value: _selectedSemesterId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Semester / Class *',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                    ),
                    dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                    items: filteredSemesters.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSemesterId = val;
                        _selectedSectionId = null;
                        _selectedSubjectId = null;
                      });
                    },
                    validator: (val) => val == null ? 'Please select a semester.' : null,
                  ),
                  const SizedBox(height: 12),
                ],

                // Section Selection (for SECTION or SUBJECT)
                if (_selectedScopeType == 'SECTION' || _selectedScopeType == 'SUBJECT') ...[
                  DropdownButtonFormField<String>(
                    value: _selectedSectionId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _selectedScopeType == 'SECTION' ? 'Section *' : 'Section (Optional)',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                    ),
                    dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                    items: [
                      if (_selectedScopeType == 'SUBJECT')
                        const DropdownMenuItem<String>(value: null, child: Text('All Sections')),
                      ...filteredSections.map((sec) {
                        return DropdownMenuItem(
                          value: sec.id,
                          child: Text('Section ${sec.name}', overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedSectionId = val;
                      });
                    },
                    validator: (val) {
                      if (_selectedScopeType == 'SECTION' && (val == null || val.isEmpty)) {
                        return 'Please select a section.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Subject Selection (for SUBJECT)
                if (_selectedScopeType == 'SUBJECT') ...[
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Subject *',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                    ),
                    dropdownColor: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                    items: filteredSubjects.map((sub) {
                      return DropdownMenuItem(
                        value: sub.id,
                        child: Text('${sub.name} (${sub.code})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSubjectId = val;
                      });
                    },
                    validator: (val) {
                      if (_selectedScopeType == 'SUBJECT' && (val == null || val.isEmpty)) {
                        return 'Please select a subject.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: AcadexColors.hairline),
              const SizedBox(height: 18),

              // ─────────────────────────────────────────────────────────
              // 2. ASSIGNMENT DETAILS
              // ─────────────────────────────────────────────────────────
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

              // ─────────────────────────────────────────────────────────
              // 3. TYPE & MAXIMUM MARKS ROW
              // ─────────────────────────────────────────────────────────
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

              // ─────────────────────────────────────────────────────────
              // 4. DUE DATE & TIME ROW
              // ─────────────────────────────────────────────────────────
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

              // ─────────────────────────────────────────────────────────
              // 5. QUESTIONS (OPTIONAL)
              // ─────────────────────────────────────────────────────────
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

              // ─────────────────────────────────────────────────────────
              // 6. ATTACHMENT (OPTIONAL)
              // ─────────────────────────────────────────────────────────
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

              // ─────────────────────────────────────────────────────────
              // 7. ACTIONS: [ Publish Assignment ] and [ Save Draft ]
              // ─────────────────────────────────────────────────────────
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
