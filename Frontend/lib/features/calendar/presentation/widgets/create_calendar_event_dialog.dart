import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/calendar_event_model.dart';
import '../providers/calendar_providers.dart';

class CreateCalendarEventDialog extends ConsumerStatefulWidget {
  const CreateCalendarEventDialog({super.key});

  @override
  ConsumerState<CreateCalendarEventDialog> createState() =>
      _CreateCalendarEventDialogState();
}

class _CreateCalendarEventDialogState
    extends ConsumerState<CreateCalendarEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  CalendarEventType _eventType = CalendarEventType.event;
  DateTime _startDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _allDay = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<CalendarEventType> _getAllowedEventTypes(AppRole role) {
    if (role == AppRole.collegeAdmin || role == AppRole.superAdmin) {
      return [
        CalendarEventType.event,
        CalendarEventType.holiday,
        CalendarEventType.publicHoliday,
        CalendarEventType.institutionHoliday,
        CalendarEventType.exam,
        CalendarEventType.seminar,
      ];
    } else if (role == AppRole.hod) {
      return [
        CalendarEventType.exam,
        CalendarEventType.seminar,
        CalendarEventType.workshop,
        CalendarEventType.event,
      ];
    } else {
      return [
        CalendarEventType.labViva,
        CalendarEventType.classTest,
        CalendarEventType.seminar,
        CalendarEventType.event,
      ];
    }
  }

  Future<void> _submit(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dateStr =
          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';

      String? startT;
      String? endT;
      if (!_allDay && _startTime != null) {
        startT =
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
        if (_endTime != null) {
          endT =
              '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
        }
      }

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'eventType': _eventType.value,
        'startDate': dateStr,
        'endDate': dateStr,
        'startTime': startT,
        'endTime': endT,
        'allDay': _allDay,
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
      };

      if (user.role == AppRole.hod && user.departmentId != null) {
        payload['departmentId'] = user.departmentId;
        payload['scope'] = 'DEPARTMENT';
      } else if (user.role == AppRole.faculty) {
        payload['scope'] = 'CLASS';
      } else {
        payload['scope'] = 'COLLEGE';
      }

      await ref.read(calendarEventsProvider.notifier).createEvent(payload);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calendar event created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final role = user?.role ?? AppRole.student;
    final allowedTypes = _getAllowedEventTypes(role);

    if (!allowedTypes.contains(_eventType)) {
      _eventType = allowedTypes.first;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      role == AppRole.collegeAdmin
                          ? 'Add College Event'
                          : (role == AppRole.hod
                              ? 'Add Department Event'
                              : 'Add Subject / Class Event'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Event Type Picker
                const Text(
                  'Event Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<CalendarEventType>(
                  value: _eventType,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: allowedTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _eventType = val;
                        if (val == CalendarEventType.holiday ||
                            val == CalendarEventType.publicHoliday ||
                            val == CalendarEventType.institutionHoliday) {
                          _allDay = true;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Title
                const Text(
                  'Event Title',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Annual Day, DBMS Lab Viva, Mid-Term Exam',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Title must be at least 2 characters' : null,
                ),
                const SizedBox(height: 14),

                // Date Picker Tile
                const Text(
                  'Date',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Icon(LucideIcons.calendar, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // All Day Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('All Day Event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Switch(
                      value: _allDay,
                      onChanged: (val) => setState(() => _allDay = val),
                    ),
                  ],
                ),

                // Time Pickers (if not all day)
                if (!_allDay) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
                                );
                                if (t != null) setState(() => _startTime = t);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_startTime != null ? _startTime!.format(context) : 'Select Time'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime ?? const TimeOfDay(hour: 12, minute: 0),
                                );
                                if (t != null) setState(() => _endTime = t);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_endTime != null ? _endTime!.format(context) : 'Select Time'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Location (optional)
                const Text(
                  'Location (optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Auditorium, Lab 3',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                const Text(
                  'Description (optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add details or instructions for this event...',
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || user == null ? null : () => _submit(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create & Publish Event', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
