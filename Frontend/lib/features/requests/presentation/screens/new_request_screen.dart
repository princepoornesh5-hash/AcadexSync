import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/request_model.dart';
import '../providers/requests_providers.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  final RequestType? initialType;
  final String? initialSubjectId;
  final String? initialSubjectName;
  final String? initialSectionId;
  final String? initialSectionName;
  final String? initialCourseId;
  final String? initialCourseName;

  const NewRequestScreen({
    super.key,
    this.initialType,
    this.initialSubjectId,
    this.initialSubjectName,
    this.initialSectionId,
    this.initialSectionName,
    this.initialCourseId,
    this.initialCourseName,
  });

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  late RequestType _selectedType;
  final _reasonController = TextEditingController();
  final _titleController = TextEditingController();
  final _resourceNameController = TextEditingController();
  final _requestedChangeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isDateRange = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? RequestType.leave;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _titleController.dispose();
    _resourceNameController.dispose();
    _requestedChangeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AcadexColors.primary,
              onPrimary: Colors.white,
              onSurface: AcadexColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (_isDateRange) {
          if (isStart) {
            _startDate = picked;
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(const Duration(days: 1));
            }
          } else {
            _endDate = picked;
          }
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _submit({bool asDraft = false}) async {
    final reason = _reasonController.text.trim();
    if (reason.length < 3) {
      AcadexSnackBar.showError(
        context,
        'Please enter details or a reason for your request (minimum 3 characters).',
      );
      return;
    }

    if ((_selectedType == RequestType.leave || _selectedType == RequestType.onDuty) &&
        _isDateRange &&
        _endDate.isBefore(_startDate)) {
      AcadexSnackBar.showError(context, 'End date cannot be earlier than start date.');
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      AcademicContextModel? academicContext;
      if (widget.initialSubjectId != null ||
          widget.initialSectionId != null ||
          widget.initialCourseId != null) {
        academicContext = AcademicContextModel(
          subjectId: widget.initialSubjectId,
          subjectName: widget.initialSubjectName,
          sectionId: widget.initialSectionId,
          sectionName: widget.initialSectionName,
          courseId: widget.initialCourseId,
          courseName: widget.initialCourseName,
        );
      }

      RequestDetailsModel? details;
      if (_selectedType == RequestType.leave || _selectedType == RequestType.onDuty) {
        details = RequestDetailsModel(
          startDate: _isDateRange ? _startDate : _selectedDate,
          endDate: _isDateRange ? _endDate : _selectedDate,
          date: _selectedDate,
          reason: reason,
        );
      } else if (_selectedType == RequestType.attendanceCorrection) {
        details = RequestDetailsModel(
          date: _selectedDate,
          reason: reason,
        );
      } else if (_selectedType == RequestType.resourceRequest ||
          _selectedType == RequestType.facultyRequirement) {
        details = RequestDetailsModel(
          resourceName: _resourceNameController.text.trim(),
          reason: reason,
        );
      } else if (_selectedType == RequestType.timetableChange) {
        details = RequestDetailsModel(
          requestedChange: _requestedChangeController.text.trim(),
          reason: reason,
        );
      }

      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null;

      final res = await ref.read(requestActionProvider.notifier).createRequest(
            requestType: _selectedType,
            title: title,
            description: reason,
            status: asDraft ? 'DRAFT' : 'SUBMITTED',
            academicContext: academicContext,
            details: details,
          );

      if (mounted) {
        if (res != null) {
          AcadexSnackBar.showSuccess(
            context,
            asDraft ? 'Draft request saved.' : 'Your request was submitted successfully.',
          );
          context.pop();
        } else {
          final actionState = ref.read(requestActionProvider);
          String errorMsg = asDraft
              ? "Couldn't save draft. Please try again."
              : "Couldn't submit your request. Please try again.";
          if (actionState.hasError) {
            final err = actionState.error;
            if (err is AcadexException && err.userMessage.isNotEmpty) {
              errorMsg = err.userMessage;
            } else if (err != null) {
              errorMsg = err.toString();
            }
          }
          AcadexSnackBar.showError(context, errorMsg);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e is AcadexException ? e.userMessage : e.toString();
        AcadexSnackBar.showError(context, errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    AppRole role = AppRole.student;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final allowedTypes = RequestTypeExtension.allowedTypesForRole(role);
    if (!allowedTypes.contains(_selectedType)) {
      _selectedType = allowedTypes.first;
    }

    final hasAcademicContext = widget.initialSubjectName != null || widget.initialSectionName != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AcadexColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Request',
          style: AcadexTypography.heading3(color: AcadexColors.ink),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preserved Academic Context Banner
              if (hasAcademicContext) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AcadexColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.graduationCap, color: AcadexColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Context: ${[widget.initialSubjectName, widget.initialSectionName].where((s) => s != null).join(" • ")}',
                          style: AcadexTypography.caption().copyWith(
                            fontWeight: FontWeight.w600,
                            color: AcadexColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Request Type Selection
              Text(
                'What do you need?',
                style: AcadexTypography.heading3(),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AcadexColors.canvasSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AcadexColors.hairline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RequestType>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown, size: 18),
                    items: allowedTypes.map((type) {
                      return DropdownMenuItem<RequestType>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 16, color: AcadexColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                type.displayName,
                                style: AcadexTypography.bodySmall().copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AcadexColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newType) {
                      if (newType != null) {
                        setState(() => _selectedType = newType);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Conditional Fields

              // 1. Leave & On-Duty: Date or Date Range
              if (_selectedType == RequestType.leave || _selectedType == RequestType.onDuty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isDateRange ? 'Date Range' : 'Date',
                          style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          ' *',
                          style: TextStyle(color: AcadexColors.error, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _isDateRange = !_isDateRange);
                      },
                      child: Text(
                        _isDateRange ? 'Single Day' : 'Multiple Days',
                        style: AcadexTypography.caption().copyWith(
                          color: AcadexColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_isDateRange) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerTile(
                          label: 'From',
                          dateStr: _formatDate(_startDate),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DatePickerTile(
                          label: 'To',
                          dateStr: _formatDate(_endDate),
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _DatePickerTile(
                    label: 'Date',
                    dateStr: _formatDate(_selectedDate),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ],
                const SizedBox(height: 18),
              ],

              // 2. Attendance Correction: Date
              if (_selectedType == RequestType.attendanceCorrection) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Date of Class',
                      style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      ' *',
                      style: TextStyle(color: AcadexColors.error, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _DatePickerTile(
                  label: 'Class Date',
                  dateStr: _formatDate(_selectedDate),
                  onTap: () => _pickDate(isStart: false),
                ),
                const SizedBox(height: 18),
              ],

              // 3. Resource Request / Faculty Requirement: Resource Name
              if (_selectedType == RequestType.resourceRequest ||
                  _selectedType == RequestType.facultyRequirement) ...[
                Text(
                  _selectedType == RequestType.resourceRequest
                      ? 'Resource Needed'
                      : 'Faculty Position / Specialization',
                  style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _resourceNameController,
                  decoration: InputDecoration(
                    hintText: _selectedType == RequestType.resourceRequest
                        ? 'e.g. Projector for Lab 3, Whiteboard markers'
                        : 'e.g. 2 Assistant Professors for AI & ML',
                    hintStyle: AcadexTypography.bodySmall(color: AcadexColors.inkMuted),
                    filled: true,
                    fillColor: AcadexColors.canvasSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // 4. Timetable Change: Requested Change
              if (_selectedType == RequestType.timetableChange) ...[
                Text(
                  'Requested Change Details',
                  style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _requestedChangeController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Move Tuesday Period 3 to Thursday Period 2',
                    hintStyle: AcadexTypography.bodySmall(color: AcadexColors.inkMuted),
                    filled: true,
                    fillColor: AcadexColors.canvasSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // 5. Optional Title for general requests
              if (_selectedType == RequestType.generalRequest ||
                  _selectedType == RequestType.complaintIssue ||
                  _selectedType == RequestType.academicIssue ||
                  _selectedType == RequestType.documentRequest ||
                  _selectedType == RequestType.generalAdminRequest) ...[
                Text(
                  'Title (Optional)',
                  style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Brief summary of what you need...',
                    hintStyle: AcadexTypography.bodySmall(color: AcadexColors.inkMuted),
                    filled: true,
                    fillColor: AcadexColors.canvasSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Reason / Description (Required for all types)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedType == RequestType.leave ? 'Reason for Leave' : 'Details & Reason',
                    style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(color: AcadexColors.error, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _selectedType == RequestType.leave
                      ? 'I need leave tomorrow because...'
                      : 'Describe the issue or reason clearly...',
                  hintStyle: AcadexTypography.bodySmall(color: AcadexColors.inkMuted),
                  filled: true,
                  fillColor: AcadexColors.canvasSoft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AcadexColors.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AcadexColors.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),

              // Destination / Routing Summary (Prompt 28 & 29)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(LucideIcons.send, size: 16, color: AcadexColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Send to: ',
                                style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                              ),
                              Text(
                                _resolveRecipientTitle(role, _selectedType),
                                style: AcadexTypography.body(color: AcadexColors.ink).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _resolveRecipientExplanation(role, _selectedType),
                            style: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AcadexButton(
                      label: 'Save Draft',
                      icon: LucideIcons.fileEdit,
                      variant: AcadexButtonVariant.secondary,
                      isLoading: _isSubmitting,
                      onPressed: () => _submit(asDraft: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AcadexButton(
                      label: 'Submit Request',
                      icon: LucideIcons.send,
                      isLoading: _isSubmitting,
                      onPressed: () => _submit(asDraft: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveRecipientTitle(AppRole? role, RequestType type) {
    if (role == AppRole.faculty) {
      return 'Head of Department (HOD)';
    } else if (role == AppRole.student) {
      if (type == RequestType.attendanceCorrection) {
        return 'Assigned Subject Faculty';
      } else if (type == RequestType.documentRequest || type == RequestType.generalAdminRequest) {
        return 'College Administration';
      }
      return 'Head of Department (HOD)';
    } else if (role == AppRole.hod) {
      return 'College Administration';
    }
    return 'Department / College Authority';
  }

  String _resolveRecipientExplanation(AppRole? role, RequestType type) {
    if (role == AppRole.faculty) {
      return 'Your request will be routed directly to your department Head of Department for review.';
    } else if (role == AppRole.student) {
      if (type == RequestType.attendanceCorrection) {
        return 'Your request will be routed to your course faculty member to verify attendance records.';
      } else if (type == RequestType.documentRequest || type == RequestType.generalAdminRequest) {
        return 'Your request will be routed to College Admin office for processing.';
      }
      return 'Your request will be routed to your department Head of Department for official review.';
    } else if (role == AppRole.hod) {
      return 'Your request will be routed to College Administration for executive review.';
    }
    return 'Your request will be routed according to institution authority guidelines.';
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String dateStr;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.dateStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AcadexColors.canvasSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AcadexColors.hairline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AcadexTypography.caption().copyWith(
                    fontSize: 10,
                    color: AcadexColors.inkMuted,
                  ),
                ),
                Text(
                  dateStr,
                  style: AcadexTypography.bodySmall().copyWith(
                    fontWeight: FontWeight.w600,
                    color: AcadexColors.ink,
                  ),
                ),
              ],
            ),
            const Icon(LucideIcons.calendar, size: 18, color: AcadexColors.primary),
          ],
        ),
      ),
    );
  }
}
