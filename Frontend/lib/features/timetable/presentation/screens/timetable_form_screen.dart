import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../data/repositories/timetable_repository.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import 'timetable_management_screen.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';

class TimetableFormScreen extends ConsumerStatefulWidget {
  final TimetableModel? existingEntry;

  const TimetableFormScreen({super.key, this.existingEntry});

  @override
  ConsumerState<TimetableFormScreen> createState() => _TimetableFormScreenState();
}

class _TimetableFormScreenState extends ConsumerState<TimetableFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _departmentId;
  String? _courseId;
  String? _academicYearId;
  String? _semesterId;
  String? _sectionId;
  String? _subjectId;
  String? _facultyId;
  TimetableDay _dayOfWeek = TimetableDay.monday;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final _roomController = TextEditingController();
  final _buildingController = TextEditingController();
  TimetableSessionType _sessionType = TimetableSessionType.lecture;

  String? _assignmentError;
  String? _conflictErrorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      final e = widget.existingEntry!;
      _departmentId = e.departmentId;
      _courseId = e.courseId;
      _academicYearId = e.academicYearId;
      _semesterId = e.semesterId;
      _sectionId = e.sectionId;
      _subjectId = e.subjectId;
      _facultyId = e.facultyId;
      _dayOfWeek = e.dayOfWeek;
      _startTime = _parseTime(e.startTime);
      _endTime = _parseTime(e.endTime);
      _roomController.text = e.roomNumber;
      _buildingController.text = e.building ?? '';
      _sessionType = e.sessionType;
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _validateFacultyAssignment() {
    setState(() {
      _assignmentError = null;
    });

    if (_facultyId == null || _subjectId == null || _sectionId == null) return;

    try {
      final assignments = ref.read(facultyAssignmentsProvider).valueOrNull ?? [];
      final activeForFaculty = assignments.where((a) => a.facultyId == _facultyId && a.isActive).toList();
      if (activeForFaculty.isNotEmpty) {
        final matches = activeForFaculty.where((a) => a.subjectId == _subjectId && a.sectionId == _sectionId);
        if (matches.isEmpty) {
          setState(() {
            _assignmentError = "Faculty is not assigned to the selected subject and section.";
          });
          return;
        }
      } else {
        final facultyList = ref.read(facultyProvider(null)).items;
        final faculty = facultyList.where((f) => f.id == _facultyId).firstOrNull;

        if (faculty != null) {
          final hasSubject = faculty.subjectIds.isEmpty || faculty.subjectIds.contains(_subjectId);
          final hasSection = faculty.sectionIds.isEmpty || faculty.sectionIds.contains(_sectionId);
          if (!hasSubject || !hasSection) {
            setState(() {
              _assignmentError = "Faculty is not assigned to the selected subject and section.";
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _conflictErrorMessage = null;
    });

    _validateFacultyAssignment();
    
    if (!_formKey.currentState!.validate() || _assignmentError != null) return;

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (startMinutes >= endMinutes) {
      AcadexSnackBar.showError(
        context,
        'Invalid Time Range: End time must be strictly after start time.',
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final isEdit = widget.existingEntry != null && widget.existingEntry!.id.isNotEmpty;
    final entry = TimetableModel(
      id: isEdit ? widget.existingEntry!.id : '',
      collegeId: authState.user.collegeId ?? '',
      departmentId: _departmentId!,
      courseId: _courseId!,
      academicYearId: _academicYearId ?? 'ay-current',
      semesterId: _semesterId!,
      sectionId: _sectionId!,
      subjectId: _subjectId!,
      facultyId: _facultyId!,
      dayOfWeek: _dayOfWeek,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      roomNumber: _roomController.text.trim(),
      building: _buildingController.text.trim().isEmpty ? null : _buildingController.text.trim(),
      sessionType: _sessionType,
      createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (isEdit) {
        await ref.read(timetableManagementProvider.notifier).updateEntry(entry);
      } else {
        await ref.read(timetableManagementProvider.notifier).createEntry(entry);
      }
      
      // ignore: unused_result
      ref.refresh(weeklyTimetableProvider);
      // ignore: unused_result
      ref.refresh(managementTimetableProvider);
      
      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          isEdit ? 'Timetable schedule updated successfully.' : 'Timetable schedule created successfully.',
        );
        context.safePop(fallbackRoute: '/timetable/manage');
      }
    } on TimetableConflictException catch (conflict) {
      if (mounted) {
        setState(() {
          _conflictErrorMessage = conflict.message;
        });
        _showConflictDialog(conflict);
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Error saving schedule',
        );
      }
    }
  }

  void _showConflictDialog(TimetableConflictException conflict) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusXl),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AcadexColors.error, size: 20),
            SizedBox(width: 8),
            Text('Schedule Conflict Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conflict.message,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            if (conflict.conflictingEntry != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcadexColors.error.withValues(alpha: 0.08),
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: AcadexColors.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conflicting Slot: ${conflict.conflictingEntry!.startTime} – ${conflict.conflictingEntry!.endTime}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AcadexColors.error),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Day: ${conflict.conflictingEntry!.dayOfWeek.displayName}',
                      style: AcadexTypography.caption(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    if (conflict.conflictingEntry!.roomNumber.isNotEmpty)
                      Text(
                        'Room: ${conflict.conflictingEntry!.roomNumber}',
                        style: AcadexTypography.caption(color: Theme.of(context).colorScheme.onSurface),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Adjust Schedule'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    
    final user = authState.user;
    if (user.role == AppRole.student || user.role == AppRole.faculty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: const Center(child: Text('Unauthorized: Only administrators and HODs can create or edit timetable entries.')),
      );
    }

    final mgtState = ref.watch(timetableManagementProvider);
    final isLoading = mgtState.isLoading;
    final isEdit = widget.existingEntry != null && widget.existingEntry!.id.isNotEmpty;
    final isHod = user.role == AppRole.hod;

    // Pre-populate department for HOD
    if (isHod && _departmentId == null && user.departmentId != null) {
      _departmentId = user.departmentId;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    AcadexPageHeader(
                      title: isEdit ? 'Edit Timetable Schedule' : 'Create Timetable Schedule',
                      subtitle: isEdit
                          ? 'Modify slot details, timings, or assigned faculty'
                          : 'Configure academic parameters, faculty assignment, and timings',
                    ),
                    const SizedBox(height: 16),

                    // Conflict Banner with smooth animated expansion
                    AnimatedSize(
                      duration: AcadexMotion.resolveDuration(context, AcadexMotion.normal),
                      curve: AcadexMotion.curveStandard,
                      child: _conflictErrorMessage != null
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AcadexColors.error.withValues(alpha: 0.1),
                                borderRadius: AcadexRadius.borderRadiusMd,
                                border: Border.all(color: AcadexColors.error),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertTriangle, color: AcadexColors.error, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _conflictErrorMessage!,
                                      style: const TextStyle(color: AcadexColors.error, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Section 1: Academic Information
                    _buildSectionCard(
                      title: '1. Academic Information',
                      icon: LucideIcons.graduationCap,
                      children: [
                        // Department (Locked for HOD, Dropdown for Admins)
                        if (!isHod)
                          Consumer(
                            builder: (context, ref, _) {
                              final deptsAsync = ref.watch(departmentsProvider);
                              return deptsAsync.maybeWhen(
                                data: (depts) => DropdownButtonFormField<String>(
                                  initialValue: _departmentId,
                                  decoration: const InputDecoration(
                                    labelText: 'Department *',
                                    prefixIcon: Icon(LucideIcons.building2, size: 18),
                                  ),
                                  items: depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name.isNotEmpty ? d.name : d.code))).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _departmentId = val;
                                      _courseId = null;
                                      _semesterId = null;
                                      _sectionId = null;
                                      _subjectId = null;
                                    });
                                  },
                                  validator: (v) => v == null ? 'Please select a department' : null,
                                ),
                                orElse: () => const LinearProgressIndicator(),
                              );
                            },
                          ),
                        const SizedBox(height: 14),

                        // Course
                        Consumer(
                          builder: (context, ref, _) {
                            final coursesAsync = ref.watch(coursesProvider);
                            return coursesAsync.maybeWhen(
                              data: (courses) {
                                final filtered = _departmentId != null
                                    ? courses.where((c) => c.departmentId == _departmentId).toList()
                                    : courses;
                                return DropdownButtonFormField<String>(
                                  initialValue: _courseId,
                                  decoration: const InputDecoration(
                                    labelText: 'Course *',
                                    prefixIcon: Icon(LucideIcons.bookMarked, size: 18),
                                  ),
                                  items: filtered.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.isNotEmpty ? c.name : c.code))).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _courseId = val;
                                      _semesterId = null;
                                      _sectionId = null;
                                      _subjectId = null;
                                      _facultyId = null;
                                    });
                                  },
                                  validator: (v) => v == null ? 'Please select a course' : null,
                                );
                              },
                              orElse: () => const LinearProgressIndicator(),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Semester & Section in a Row
                        Row(
                          children: [
                            // Semester
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final semestersAsync = ref.watch(semestersProvider);
                                  return semestersAsync.maybeWhen(
                                    data: (semesters) {
                                      final filtered = _courseId != null
                                          ? semesters.where((s) => s.courseId == _courseId).toList()
                                          : semesters;
                                      return DropdownButtonFormField<String>(
                                        initialValue: _semesterId,
                                        decoration: const InputDecoration(
                                          labelText: 'Semester *',
                                          prefixIcon: Icon(LucideIcons.calendarRange, size: 18),
                                        ),
                                        items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name.isNotEmpty ? s.name : 'Semester ${s.number}'))).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _semesterId = val;
                                            _sectionId = null;
                                            _subjectId = null;
                                            _facultyId = null;
                                          });
                                        },
                                        validator: (v) => v == null ? 'Select semester' : null,
                                      );
                                    },
                                    orElse: () => const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Section
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final sectionsAsync = ref.watch(sectionsProvider);
                                  return sectionsAsync.maybeWhen(
                                    data: (sections) {
                                      final filtered = _semesterId != null
                                          ? sections.where((s) => s.semesterId == _semesterId).toList()
                                          : sections;
                                      return DropdownButtonFormField<String>(
                                        initialValue: _sectionId,
                                        decoration: const InputDecoration(
                                          labelText: 'Section *',
                                          prefixIcon: Icon(LucideIcons.layoutGrid, size: 18),
                                        ),
                                        items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _sectionId = val;
                                            _facultyId = null;
                                          });
                                          _validateFacultyAssignment();
                                        },
                                        validator: (v) => v == null ? 'Select section' : null,
                                      );
                                    },
                                    orElse: () => const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Teaching Assignment
                    _buildSectionCard(
                      title: '2. Teaching Assignment',
                      icon: LucideIcons.userCheck,
                      children: [
                        // Subject
                        Consumer(
                          builder: (context, ref, _) {
                            final subjectsAsync = ref.watch(subjectsProvider);
                            return subjectsAsync.maybeWhen(
                              data: (subjects) {
                                final filtered = _semesterId != null
                                    ? subjects.where((s) => s.semesterId == _semesterId).toList()
                                    : (_departmentId != null ? subjects.where((s) => s.departmentId == _departmentId).toList() : subjects);
                                return DropdownButtonFormField<String>(
                                  initialValue: _subjectId,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject *',
                                    prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
                                  ),
                                  items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.code})'))).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _subjectId = val;
                                      _facultyId = null;
                                    });
                                    _validateFacultyAssignment();
                                  },
                                  validator: (v) => v == null ? 'Please select a subject' : null,
                                );
                              },
                              orElse: () => const LinearProgressIndicator(),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Faculty (Directly connected to Faculty Assignments for chosen subject & section)
                        Consumer(
                          builder: (context, ref, _) {
                            List<Faculty> candidateFaculty = [];
                            if (_subjectId != null && _sectionId != null) {
                              candidateFaculty = ref.watch(assignedFacultyForSubjectSectionProvider((subjectId: _subjectId!, sectionId: _sectionId!)));
                            }
                            if (candidateFaculty.isEmpty) {
                              final facultyState = ref.watch(facultyProvider(_departmentId));
                              candidateFaculty = facultyState.items;
                            }

                            return DropdownButtonFormField<String>(
                              initialValue: _facultyId,
                              decoration: InputDecoration(
                                labelText: 'Assigned Faculty *',
                                prefixIcon: const Icon(LucideIcons.user, size: 18),
                                helperText: _subjectId != null && _sectionId != null
                                    ? (candidateFaculty.isNotEmpty ? "Filtering assigned faculty for this subject & section" : "No faculty assignment found; showing department faculty")
                                    : null,
                                errorText: _assignmentError,
                              ),
                              items: candidateFaculty.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name.isNotEmpty ? f.name : f.email))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _facultyId = val;
                                });
                                _validateFacultyAssignment();
                              },
                              validator: (v) => v == null ? 'Please assign a faculty member' : null,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Schedule & Timing
                    _buildSectionCard(
                      title: '3. Schedule & Timing',
                      icon: LucideIcons.clock,
                      children: [
                        Row(
                          children: [
                            // Day of Week
                            Expanded(
                              child: DropdownButtonFormField<TimetableDay>(
                                initialValue: _dayOfWeek,
                                decoration: const InputDecoration(
                                  labelText: 'Day of Week *',
                                  prefixIcon: Icon(LucideIcons.calendar, size: 18),
                                ),
                                items: TimetableDay.values.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _dayOfWeek = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Session Type
                            Expanded(
                              child: DropdownButtonFormField<TimetableSessionType>(
                                initialValue: _sessionType,
                                decoration: const InputDecoration(
                                  labelText: 'Session Type *',
                                  prefixIcon: Icon(LucideIcons.tag, size: 18),
                                ),
                                items: TimetableSessionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _sessionType = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Time Range Selectors
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Time *',
                                    prefixIcon: Icon(LucideIcons.clock4, size: 18),
                                  ),
                                  child: Text(_formatTime(_startTime), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Time *',
                                    prefixIcon: Icon(LucideIcons.clock9, size: 18),
                                  ),
                                  child: Text(_formatTime(_endTime), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Location & Classroom
                    _buildSectionCard(
                      title: '4. Classroom & Location',
                      icon: LucideIcons.mapPin,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _roomController,
                                decoration: const InputDecoration(
                                  labelText: 'Room Number *',
                                  hintText: 'e.g. C-204, Lab-1',
                                  prefixIcon: Icon(LucideIcons.doorOpen, size: 18),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter room number' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _buildingController,
                                decoration: const InputDecoration(
                                  labelText: 'Building / Block (Optional)',
                                  hintText: 'e.g. Main Block, Science Wing',
                                  prefixIcon: Icon(LucideIcons.building, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 5: Audit & Distribution Status
                    _buildSectionCard(
                      title: '5. Audit & Distribution Status',
                      icon: LucideIcons.shieldCheck,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AcadexColors.success.withValues(alpha: 0.15),
                                borderRadius: AcadexRadius.borderRadiusXs,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.checkCircle2, size: 14, color: AcadexColors.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(color: AcadexColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Realtime schedule distribution to enrolled students and assigned faculty.',
                                style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit & Cancel Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isLoading ? null : () => context.safePop(fallbackRoute: '/timetable/manage'),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 14),
                        AcadexButton(
                          label: isEdit ? 'Save Changes' : 'Create Schedule',
                          icon: isEdit ? LucideIcons.save : LucideIcons.plus,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                          variant: AcadexButtonVariant.primary,
                          size: AcadexButtonSize.md,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}
