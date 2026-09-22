import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_models.dart';
import '../../domain/models/teacher_substitution.dart';
import '../providers/timetable_providers.dart';
import '../providers/timetable_lookup_providers.dart';

class TeacherSubstitutionDialog extends ConsumerStatefulWidget {
  final String timetableId;
  final String timetableEntryId;
  final TimetableDay dayOfWeek;
  final String startTime;
  final String endTime;
  final String subjectId;
  final String originalFacultyId;
  final String sectionId;
  final String? roomNumber;
  final DateTime? initialDate;
  final TeacherSubstitution? existingSubstitution;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;

  const TeacherSubstitutionDialog({
    super.key,
    required this.timetableId,
    required this.timetableEntryId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subjectId,
    required this.originalFacultyId,
    required this.sectionId,
    this.roomNumber,
    this.initialDate,
    this.existingSubstitution,
    this.onSaved,
    this.onDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required String timetableId,
    required String timetableEntryId,
    required TimetableDay dayOfWeek,
    required String startTime,
    required String endTime,
    required String subjectId,
    required String originalFacultyId,
    required String sectionId,
    String? roomNumber,
    DateTime? initialDate,
    TeacherSubstitution? existingSubstitution,
    VoidCallback? onSaved,
    VoidCallback? onDeleted,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => TeacherSubstitutionDialog(
        timetableId: timetableId,
        timetableEntryId: timetableEntryId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        subjectId: subjectId,
        originalFacultyId: originalFacultyId,
        sectionId: sectionId,
        roomNumber: roomNumber,
        initialDate: initialDate,
        existingSubstitution: existingSubstitution,
        onSaved: onSaved,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  ConsumerState<TeacherSubstitutionDialog> createState() => _TeacherSubstitutionDialogState();
}

class _TeacherSubstitutionDialogState extends ConsumerState<TeacherSubstitutionDialog> {
  late DateTime _selectedDate;
  String? _selectedSubstituteId;
  late TextEditingController _reasonController;
  bool _isLoading = false;
  bool _isCheckingExisting = false;
  String? _errorMessage;
  TeacherSubstitution? _activeSubstitution;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? _findNextOccurrence(widget.dayOfWeek);
    _activeSubstitution = widget.existingSubstitution;
    _selectedSubstituteId = widget.existingSubstitution?.substituteFacultyId;
    _reasonController = TextEditingController(text: widget.existingSubstitution?.reason ?? '');

    if (_activeSubstitution == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchExistingSubstitution());
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  DateTime _findNextOccurrence(TimetableDay day) {
    final now = DateTime.now();
    final targetWeekday = day.index + 1;
    int diff = targetWeekday - now.weekday;
    if (diff < 0) diff += 7;
    return DateTime(now.year, now.month, now.day).add(Duration(days: diff));
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _fetchExistingSubstitution() async {
    setState(() => _isCheckingExisting = true);
    try {
      final repo = ref.read(timetableRepositoryProvider);
      final list = await repo.getTeacherSubstitutions(
        date: _formatDate(_selectedDate),
        timetableId: widget.timetableId,
      );
      final match = list.where((s) => s.timetableEntryId == widget.timetableEntryId).firstOrNull;
      if (mounted) {
        setState(() {
          _activeSubstitution = match;
          if (match != null) {
            _selectedSubstituteId = match.substituteFacultyId;
            _reasonController.text = match.reason;
          } else {
            if (widget.existingSubstitution == null) {
              _selectedSubstituteId = null;
              _reasonController.text = '';
            }
          }
        });
      }
    } catch (_) {
      // Best-effort check; continue safely
    } finally {
      if (mounted) {
        setState(() => _isCheckingExisting = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (date) {
        return (date.weekday - 1) == widget.dayOfWeek.index;
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchExistingSubstitution();
    }
  }

  Future<void> _submit() async {
    if (_selectedSubstituteId == null || _selectedSubstituteId!.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a substitute faculty member.';
      });
      return;
    }

    if (_selectedSubstituteId == widget.originalFacultyId) {
      setState(() {
        _errorMessage = 'Substitute faculty cannot be the same as the original faculty.';
      });
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a reason for the substitution.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(timetableRepositoryProvider);
      final substitution = TeacherSubstitution(
        id: _activeSubstitution?.id ?? widget.existingSubstitution?.id ?? '',
        collegeId: '',
        departmentId: '',
        sectionId: widget.sectionId,
        timetableId: widget.timetableId,
        timetableEntryId: widget.timetableEntryId,
        date: _formatDate(_selectedDate),
        originalFacultyId: widget.originalFacultyId,
        substituteFacultyId: _selectedSubstituteId!,
        reason: _reasonController.text.trim(),
      );

      await repo.createTeacherSubstitution(substitution);

      // Reconcile and invalidate state from authoritative backend
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(dateScheduleProvider(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)));
      ref.invalidate(weeklyTimetableProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher substitution scheduled successfully.'),
            backgroundColor: AcadexColors.success,
          ),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _delete() async {
    final toDelete = _activeSubstitution ?? widget.existingSubstitution;
    if (toDelete == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(timetableRepositoryProvider);
      await repo.deleteTeacherSubstitution(toDelete.id);

      // Reconcile and invalidate state from authoritative backend
      ref.invalidate(todayScheduleProvider);
      ref.invalidate(dateScheduleProvider(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)));
      ref.invalidate(weeklyTimetableProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher substitution removed. Original faculty restored.'),
            backgroundColor: AcadexColors.info,
          ),
        );
        widget.onDeleted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userRole = authState is AuthAuthenticated ? authState.user.role : null;
    final isAuthorized = userRole == AppRole.hod ||
        userRole == AppRole.collegeAdmin ||
        userRole == AppRole.superAdmin;

    if (!isAuthorized) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
        title: const Text('Unauthorized'),
        content: const Text('Only HODs and administrators can manage teacher substitutions.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      );
    }

    final userDeptId = authState is AuthAuthenticated ? authState.user.departmentId : null;
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    final subject = subjectMap[widget.subjectId];
    final originalFaculty = facultyMap[widget.originalFacultyId];
    final section = sectionMap[widget.sectionId];

    // Restrict candidate faculty: HOD must only see faculty from their own department
    final candidateFaculties = facultyMap.values
        .where((f) => f.id != widget.originalFacultyId)
        .where((f) => userRole != AppRole.hod || (userDeptId != null && userDeptId.isNotEmpty && f.departmentId == userDeptId))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final hasActiveSub = _activeSubstitution != null;
    final activeSubFaculty = hasActiveSub ? facultyMap[_activeSubstitution!.substituteFacultyId] : null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AcadexColors.primary.withValues(alpha: 0.12),
              borderRadius: AcadexRadius.borderRadiusMd,
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: AcadexColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasActiveSub ? 'Manage Teacher Substitution' : 'Assign Teacher Substitute',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target class summary card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject?.name ?? widget.subjectId,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Section: ${section?.name ?? widget.sectionId}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Time: ${widget.startTime} - ${widget.endTime}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (widget.roomNumber != null && widget.roomNumber!.isNotEmpty)
                          Text(
                            'Room: ${widget.roomNumber}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Original Teacher: ${originalFaculty?.name ?? widget.originalFacultyId}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AcadexColors.primary),
                    ),
                  ],
                ),
              ),

              if (hasActiveSub) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AcadexColors.warning.withValues(alpha: 0.12),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AcadexColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Substitution on ${_activeSubstitution!.date}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Substitute: ${activeSubFaculty?.name ?? _activeSubstitution!.substituteFacultyId}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Reason: ${_activeSubstitution!.reason}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Date selection
              const Text('Substitution Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _isLoading ? null : _pickDate,
                borderRadius: AcadexRadius.borderRadiusMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatDate(_selectedDate)} (${widget.dayOfWeek.name.toUpperCase()})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (_isCheckingExisting)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        const Icon(Icons.calendar_today, size: 16, color: AcadexColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Substitute Faculty dropdown
              Text(
                hasActiveSub ? 'Replace Substitute Teacher' : 'Substitute Teacher',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedSubstituteId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusMd),
                ),
                hint: const Text('Select substitute faculty'),
                items: candidateFaculties.map((f) {
                  return DropdownMenuItem<String>(
                    value: f.id,
                    child: Text(
                      '${f.name}${f.employeeId.isNotEmpty ? ' (${f.employeeId})' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _isLoading ? null : (val) => setState(() => _selectedSubstituteId = val),
              ),
              const SizedBox(height: 16),

              // Reason
              const Text('Reason for Substitution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'e.g. Leave coverage, Faculty on duty at conference',
                  border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusMd),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AcadexColors.error.withValues(alpha: 0.1),
                    borderRadius: AcadexRadius.borderRadiusSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AcadexColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AcadexColors.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (hasActiveSub)
          TextButton(
            onPressed: _isLoading ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: AcadexColors.error),
            child: const Text('Remove Substitution'),
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AcadexColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(hasActiveSub ? 'Update / Replace' : 'Confirm Substitution'),
        ),
      ],
    );
  }
}
