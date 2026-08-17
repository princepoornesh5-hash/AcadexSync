import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import 'timetable_management_screen.dart';

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
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _validateFacultyAssignment() {
    setState(() {
      _assignmentError = null;
    });

    if (_facultyId == null || _subjectId == null || _sectionId == null) return;

    final facultyList = ref.read(facultyProvider).value ?? [];
    final faculty = facultyList.firstWhere((f) => f.id == _facultyId, orElse: () => throw Exception('Faculty not found'));

    if (!faculty.subjectIds.contains(_subjectId) || !faculty.sectionIds.contains(_sectionId)) {
      setState(() {
        _assignmentError = "This faculty member is not assigned to the selected subject and section.";
      });
    }
  }

  Future<void> _submit() async {
    _validateFacultyAssignment();
    
    if (!_formKey.currentState!.validate() || _assignmentError != null) return;

    if (_startTime.hour > _endTime.hour || (_startTime.hour == _endTime.hour && _startTime.minute >= _endTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final entry = TimetableModel(
      id: widget.existingEntry?.id ?? '', // Will be generated in repo if empty
      collegeId: authState.user.collegeId ?? '',
      departmentId: _departmentId!,
      courseId: _courseId!,
      academicYearId: _academicYearId!,
      semesterId: _semesterId!,
      sectionId: _sectionId!,
      subjectId: _subjectId!,
      facultyId: _facultyId!,
      dayOfWeek: _dayOfWeek,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      roomNumber: _roomController.text,
      building: _buildingController.text.isEmpty ? null : _buildingController.text,
      sessionType: _sessionType,
      createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.existingEntry == null) {
        await ref.read(timetableManagementProvider.notifier).createEntry(entry);
      } else {
        await ref.read(timetableManagementProvider.notifier).updateEntry(entry);
      }
      
      // Refresh management screen if needed, though streams might auto-update or FutureProvider needs refresh
      ref.refresh(managementTimetableProvider);
      
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Schedule Conflict Detected', style: TextStyle(color: DashboardColors.error)),
            content: Text(e.toString()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgtState = ref.watch(timetableManagementProvider);
    final isLoading = mgtState.isLoading;

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text(widget.existingEntry == null ? 'Create Timetable Entry' : 'Edit Timetable Entry', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            margin: const EdgeInsets.all(24),
            color: DashboardColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dynamic Dropdowns
                    _buildDropdowns(),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    // Schedule Details
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TimetableDay>(
                            value: _dayOfWeek,
                            decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
                            items: TimetableDay.values.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))).toList(),
                            onChanged: (val) => setState(() => _dayOfWeek = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<TimetableSessionType>(
                            value: _sessionType,
                            decoration: const InputDecoration(labelText: 'Session Type', border: OutlineInputBorder()),
                            items: TimetableSessionType.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                            onChanged: (val) => setState(() => _sessionType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Start Time'),
                            subtitle: Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(LucideIcons.clock),
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: _startTime);
                              if (time != null) setState(() => _startTime = time);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('End Time'),
                            subtitle: Text(_endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(LucideIcons.clock),
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: _endTime);
                              if (time != null) setState(() => _endTime = time);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roomController,
                            decoration: const InputDecoration(labelText: 'Room Number', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _buildingController,
                            decoration: const InputDecoration(labelText: 'Building (Optional)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (mgtState.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(mgtState.error.toString(), style: const TextStyle(color: DashboardColors.error)),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(widget.existingEntry == null ? 'Create Schedule' : 'Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
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

  Widget _buildDropdowns() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Consumer(builder: (ctx, ref, _) {
                final deptsAsync = ref.watch(departmentsProvider);
                return deptsAsync.maybeWhen(
                  data: (depts) => DropdownButtonFormField<String>(
                    value: _departmentId,
                    decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                    items: depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                    onChanged: (val) => setState(() {
                      _departmentId = val;
                      _courseId = null;
                      _subjectId = null;
                      _facultyId = null;
                    }),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  orElse: () => const CircularProgressIndicator(),
                );
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Consumer(builder: (ctx, ref, _) {
                final coursesAsync = ref.watch(coursesProvider);
                return coursesAsync.maybeWhen(
                  data: (courses) {
                    final filtered = courses.where((c) => c.departmentId == _departmentId).toList();
                    return DropdownButtonFormField<String>(
                      value: _courseId,
                      decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
                      items: filtered.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => setState(() {
                        _courseId = val;
                        _semesterId = null;
                      }),
                      validator: (val) => val == null ? 'Required' : null,
                    );
                  },
                  orElse: () => const CircularProgressIndicator(),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Consumer(builder: (ctx, ref, _) {
                final ayAsync = ref.watch(academicYearsProvider);
                return ayAsync.maybeWhen(
                  data: (ays) => DropdownButtonFormField<String>(
                    value: _academicYearId,
                    decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder()),
                    items: ays.map((ay) => DropdownMenuItem(value: ay.id, child: Text(ay.name))).toList(),
                    onChanged: (val) => setState(() => _academicYearId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  orElse: () => const CircularProgressIndicator(),
                );
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Consumer(builder: (ctx, ref, _) {
                final semsAsync = ref.watch(semestersProvider);
                return semsAsync.maybeWhen(
                  data: (sems) {
                    final filtered = sems.where((s) => s.courseId == _courseId && s.academicYearId == _academicYearId).toList();
                    return DropdownButtonFormField<String>(
                      value: _semesterId,
                      decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                      items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setState(() {
                        _semesterId = val;
                        _sectionId = null;
                        _subjectId = null;
                      }),
                      validator: (val) => val == null ? 'Required' : null,
                    );
                  },
                  orElse: () => const CircularProgressIndicator(),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Consumer(builder: (ctx, ref, _) {
                final secsAsync = ref.watch(sectionsProvider);
                return secsAsync.maybeWhen(
                  data: (secs) {
                    final filtered = secs.where((s) => s.semesterId == _semesterId).toList();
                    return DropdownButtonFormField<String>(
                      value: _sectionId,
                      decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                      items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        setState(() => _sectionId = val);
                        _validateFacultyAssignment();
                      },
                      validator: (val) => val == null ? 'Required' : null,
                    );
                  },
                  orElse: () => const CircularProgressIndicator(),
                );
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Consumer(builder: (ctx, ref, _) {
                final subsAsync = ref.watch(subjectsProvider);
                return subsAsync.maybeWhen(
                  data: (subs) {
                    final filtered = subs.where((s) => s.semesterId == _semesterId).toList();
                    return DropdownButtonFormField<String>(
                      value: _subjectId,
                      decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                      items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        setState(() => _subjectId = val);
                        _validateFacultyAssignment();
                      },
                      validator: (val) => val == null ? 'Required' : null,
                    );
                  },
                  orElse: () => const CircularProgressIndicator(),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer(builder: (ctx, ref, _) {
          final facsAsync = ref.watch(facultyProvider);
          return facsAsync.maybeWhen(
            data: (facs) {
              final filtered = facs.where((f) => f.departmentId == _departmentId).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _facultyId,
                    decoration: const InputDecoration(labelText: 'Faculty', border: OutlineInputBorder()),
                    items: filtered.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                    onChanged: (val) {
                      setState(() => _facultyId = val);
                      _validateFacultyAssignment();
                    },
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  if (_assignmentError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_assignmentError!, style: const TextStyle(color: DashboardColors.error, fontSize: 12)),
                    ),
                ],
              );
            },
            orElse: () => const CircularProgressIndicator(),
          );
        }),
      ],
    );
  }
}
