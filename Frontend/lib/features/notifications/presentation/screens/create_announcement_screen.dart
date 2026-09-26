import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/announcement_model.dart';
import '../providers/notification_providers.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  ConsumerState<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _targetUserIdController = TextEditingController();

  AnnouncementAudienceScope _scope = AnnouncementAudienceScope.college;
  String _category = 'GENERAL';
  String _priority = 'NORMAL';
  bool _isPinned = false;
  DateTime? _expiresAt;

  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  AppRole? _selectedTargetRole;

  String? _errorMessage;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'GENERAL',
    'ACADEMIC',
    'EXAM',
    'EVENT',
    'EMERGENCY',
    'ADMINISTRATIVE',
  ];

  final List<String> _priorities = [
    'LOW',
    'NORMAL',
    'HIGH',
    'URGENT',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth is AuthAuthenticated) {
        if (auth.user.role == AppRole.hod) {
          setState(() {
            _scope = AnnouncementAudienceScope.department;
            _selectedDepartmentId = auth.user.departmentId;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _targetUserIdController.dispose();
    super.dispose();
  }

  Future<void> _submit(String status) async {
    if (_isSubmitting) return;

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final user = auth.user;

    // Audience targeting validation
    if (_scope == AnnouncementAudienceScope.department && _selectedDepartmentId == null) {
      setState(() => _errorMessage = 'Please select a target department');
      return;
    }
    if (_scope == AnnouncementAudienceScope.course && _selectedCourseId == null) {
      setState(() => _errorMessage = 'Please select a target course');
      return;
    }
    if (_scope == AnnouncementAudienceScope.semester && _selectedSemesterId == null) {
      setState(() => _errorMessage = 'Please select a target semester');
      return;
    }
    if (_scope == AnnouncementAudienceScope.section && _selectedSectionId == null) {
      setState(() => _errorMessage = 'Please select a target section');
      return;
    }
    if (_scope == AnnouncementAudienceScope.role && _selectedTargetRole == null) {
      setState(() => _errorMessage = 'Please select a target role');
      return;
    }
    if (_scope == AnnouncementAudienceScope.individual && _targetUserIdController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a target recipient User ID');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'category': _category,
        'audienceScope': _scope.apiValue,
        'priority': _priority,
        'isPinned': _isPinned,
        'status': status,
        'publishNow': status == 'PUBLISHED',
      };

      if (_expiresAt != null) {
        payload['expiresAt'] = _expiresAt!.toIso8601String();
      }

      if (_scope == AnnouncementAudienceScope.department) {
        payload['departmentId'] = _selectedDepartmentId ?? user.departmentId;
      } else if (_scope == AnnouncementAudienceScope.course) {
        payload['targetCourseId'] = _selectedCourseId;
        if (_selectedDepartmentId != null) payload['departmentId'] = _selectedDepartmentId;
      } else if (_scope == AnnouncementAudienceScope.semester) {
        payload['targetCourseId'] = _selectedCourseId;
        payload['targetSemesterId'] = _selectedSemesterId;
        if (_selectedDepartmentId != null) payload['departmentId'] = _selectedDepartmentId;
      } else if (_scope == AnnouncementAudienceScope.section) {
        payload['targetCourseId'] = _selectedCourseId;
        payload['targetSemesterId'] = _selectedSemesterId;
        payload['targetSectionId'] = _selectedSectionId;
        if (_selectedDepartmentId != null) payload['departmentId'] = _selectedDepartmentId;
      } else if (_scope == AnnouncementAudienceScope.role) {
        payload['targetRole'] = _selectedTargetRole!.value;
        if (_selectedDepartmentId != null) payload['departmentId'] = _selectedDepartmentId;
      } else if (_scope == AnnouncementAudienceScope.individual) {
        final targetId = _targetUserIdController.text.trim();
        payload['targetUserId'] = targetId;
        payload['targetUserIds'] = [targetId];
        if (_selectedDepartmentId != null) payload['departmentId'] = _selectedDepartmentId;
      }

      await ref.read(announcementCreationProvider.notifier).createAnnouncement(payload);

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          status == 'PUBLISHED'
              ? 'Announcement published and notifications sent successfully!'
              : 'Announcement draft saved successfully!',
        );
        context.safePop(fallbackRoute: '/announcements');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '').trim();
        if (msg.contains('Only administrators and HODs')) {
          msg = 'You do not have permission to publish announcements.';
        } else if (msg.contains('HOD is not authorized to publish college-wide')) {
          msg = 'HODs cannot publish college-wide announcements. Please select your department.';
        } else if (msg.contains('HOD can only target announcements within their assigned department')) {
          msg = 'You can only publish announcements for your assigned department.';
        } else if (msg.contains('HOD cannot target courses outside their department')) {
          msg = 'You cannot target courses outside your department.';
        } else if (msg.contains('HOD cannot target sections outside their department')) {
          msg = 'You cannot target sections outside your department.';
        } else if (msg.contains('HOD cannot target users outside their department')) {
          msg = 'You cannot target users outside your department.';
        }
        setState(() {
          _errorMessage = msg;
          _isSubmitting = false;
        });
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: msg,
        );
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AcadexColors.primary,
              onPrimary: Colors.white,
              surface: AcadexColors.surface,
              onSurface: AcadexColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expiresAt ?? now.add(const Duration(hours: 1))),
      );

      if (pickedTime != null) {
        setState(() {
          _expiresAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _expiresAt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated) return const SizedBox.shrink();
    final user = auth.user;

    // Check authority: Only SuperAdmin, CollegeAdmin, and HOD can access
    final isAuthorized = user.role == AppRole.superAdmin ||
        user.role == AppRole.collegeAdmin ||
        user.role == AppRole.hod;

    if (!isAuthorized) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Create Announcement', style: AcadexTypography.heading3(color: AcadexColors.ink)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'You do not have permission to create announcements.',
            style: AcadexTypography.body(color: AcadexColors.error),
          ),
        ),
      );
    }

    final isHod = user.role == AppRole.hod;

    // Available audience scopes
    final availableScopes = <AnnouncementAudienceScope>[
      if (!isHod) AnnouncementAudienceScope.college,
      AnnouncementAudienceScope.department,
      AnnouncementAudienceScope.course,
      AnnouncementAudienceScope.semester,
      AnnouncementAudienceScope.section,
      AnnouncementAudienceScope.role,
      AnnouncementAudienceScope.individual,
    ];

    if (!availableScopes.contains(_scope)) {
      _scope = isHod ? AnnouncementAudienceScope.department : availableScopes.first;
      if (isHod && _selectedDepartmentId == null) {
        _selectedDepartmentId = user.departmentId;
      }
    }

    // Data for dropdowns
    final deptsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    final departments = deptsAsync.valueOrNull ?? [];
    final allCourses = coursesAsync.valueOrNull ?? [];
    final allSemesters = semestersAsync.valueOrNull ?? [];
    final allSections = sectionsAsync.valueOrNull ?? [];

    // Filter courses by department if selected or if HOD
    final deptId = isHod ? user.departmentId : _selectedDepartmentId;
    final filteredCourses = deptId != null
        ? allCourses.where((c) => c.departmentId == deptId).toList()
        : allCourses;

    // Filter semesters by course
    final filteredSemesters = _selectedCourseId != null
        ? allSemesters.where((s) => s.courseId == _selectedCourseId).toList()
        : allSemesters;

    // Filter sections by semester
    final filteredSections = _selectedSemesterId != null
        ? allSections.where((s) => s.semesterId == _selectedSemesterId).toList()
        : allSections;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Create Announcement',
          style: AcadexTypography.heading3(color: AcadexColors.ink),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/announcements'),
        ),
      ),
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(color: AcadexColors.hairline),
              boxShadow: AcadexShadows.lightSm,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Announcement Details',
                    style: AcadexTypography.heading3(color: AcadexColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isHod
                        ? 'Publish an official department announcement or target specific courses/sections.'
                        : 'Broadcast an official announcement across your institution or targeted audience.',
                    style: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AcadexColors.errorLight,
                        borderRadius: AcadexRadius.borderRadiusMd,
                        border: Border.all(color: AcadexColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AcadexTypography.bodySmall(color: AcadexColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    style: AcadexTypography.body(color: AcadexColors.ink),
                    decoration: InputDecoration(
                      labelText: 'Announcement Title *',
                      labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                      hintText: 'e.g., End Semester Examination Schedule Published',
                      hintStyle: AcadexTypography.body(color: AcadexColors.inkFaint),
                      filled: true,
                      fillColor: AcadexColors.canvas,
                      border: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.hairline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.hairline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Title is required';
                      if (val.trim().length < 3) return 'Title must be at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Body Field
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 5,
                    style: AcadexTypography.body(color: AcadexColors.ink),
                    decoration: InputDecoration(
                      labelText: 'Announcement Body *',
                      labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                      hintText: 'Write the complete announcement details, instructions, or notes...',
                      hintStyle: AcadexTypography.body(color: AcadexColors.inkFaint),
                      filled: true,
                      fillColor: AcadexColors.canvas,
                      border: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.hairline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.hairline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Body is required';
                      if (val.trim().length < 5) return 'Body must be at least 5 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Audience Scope Dropdown
                  DropdownButtonFormField<AnnouncementAudienceScope>(
                    value: _scope,
                    dropdownColor: AcadexColors.surface,
                    style: AcadexTypography.body(color: AcadexColors.ink),
                    iconEnabledColor: AcadexColors.inkSecondary,
                    decoration: InputDecoration(
                      labelText: 'Audience Scope *',
                      labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                      filled: true,
                      fillColor: AcadexColors.canvas,
                      border: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.hairline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.hairline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AcadexRadius.borderRadiusMd,
                        borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                      ),
                    ),
                    items: availableScopes.map((scope) {
                      return DropdownMenuItem(
                        value: scope,
                        child: Text(scope.displayName, style: AcadexTypography.body(color: AcadexColors.ink)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _scope = val;
                          _selectedCourseId = null;
                          _selectedSemesterId = null;
                          _selectedSectionId = null;
                          _selectedTargetRole = null;
                          if (!isHod) _selectedDepartmentId = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // Dynamic Target Selectors
                  if (_scope == AnnouncementAudienceScope.college) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AcadexColors.primaryLight,
                        borderRadius: AcadexRadius.borderRadiusMd,
                        border: Border.all(color: AcadexColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.globe, color: AcadexColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This announcement will be broadcast college-wide to all students, faculty, and administrators.',
                              style: AcadexTypography.bodySmall(color: AcadexColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (_scope == AnnouncementAudienceScope.department ||
                      _scope == AnnouncementAudienceScope.course ||
                      _scope == AnnouncementAudienceScope.semester ||
                      _scope == AnnouncementAudienceScope.section) ...[
                    if (!isHod) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedDepartmentId,
                        dropdownColor: AcadexColors.surface,
                        style: AcadexTypography.body(color: AcadexColors.ink),
                        iconEnabledColor: AcadexColors.inkSecondary,
                        decoration: InputDecoration(
                          labelText: 'Select Department *',
                          labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                          filled: true,
                          fillColor: AcadexColors.canvas,
                          border: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusMd,
                            borderSide: const BorderSide(color: AcadexColors.hairline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusMd,
                            borderSide: const BorderSide(color: AcadexColors.hairline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusMd,
                            borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                          ),
                        ),
                        items: departments.map((d) {
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text('${d.name} (${d.code})', style: AcadexTypography.body(color: AcadexColors.ink)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDepartmentId = val;
                            _selectedCourseId = null;
                            _selectedSemesterId = null;
                            _selectedSectionId = null;
                          });
                        },
                        validator: (val) => val == null ? 'Please select a department' : null,
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AcadexColors.canvas,
                          borderRadius: AcadexRadius.borderRadiusMd,
                          border: Border.all(color: AcadexColors.hairline),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.building, color: AcadexColors.inkSecondary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Department: Your assigned department (ID: ${user.departmentId ?? 'Default'})',
                                style: AcadexTypography.body(color: AcadexColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],

                  if (_scope == AnnouncementAudienceScope.course ||
                      _scope == AnnouncementAudienceScope.semester ||
                      _scope == AnnouncementAudienceScope.section) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      dropdownColor: AcadexColors.surface,
                      style: AcadexTypography.body(color: AcadexColors.ink),
                      iconEnabledColor: AcadexColors.inkSecondary,
                      decoration: InputDecoration(
                        labelText: 'Select Course *',
                        labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                        filled: true,
                        fillColor: AcadexColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                        ),
                      ),
                      items: filteredCourses.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.code})', style: AcadexTypography.body(color: AcadexColors.ink)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCourseId = val;
                          _selectedSemesterId = null;
                          _selectedSectionId = null;
                        });
                      },
                      validator: (val) => val == null ? 'Please select a course' : null,
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (_scope == AnnouncementAudienceScope.semester ||
                      _scope == AnnouncementAudienceScope.section) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSemesterId,
                      dropdownColor: AcadexColors.surface,
                      style: AcadexTypography.body(color: AcadexColors.ink),
                      iconEnabledColor: AcadexColors.inkSecondary,
                      decoration: InputDecoration(
                        labelText: 'Select Semester *',
                        labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                        filled: true,
                        fillColor: AcadexColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                        ),
                      ),
                      items: filteredSemesters.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name.isNotEmpty ? s.name : 'Semester ${s.number}', style: AcadexTypography.body(color: AcadexColors.ink)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSemesterId = val;
                          _selectedSectionId = null;
                        });
                      },
                      validator: (val) => val == null ? 'Please select a semester' : null,
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (_scope == AnnouncementAudienceScope.section) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSectionId,
                      dropdownColor: AcadexColors.surface,
                      style: AcadexTypography.body(color: AcadexColors.ink),
                      iconEnabledColor: AcadexColors.inkSecondary,
                      decoration: InputDecoration(
                        labelText: 'Select Section *',
                        labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                        filled: true,
                        fillColor: AcadexColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                        ),
                      ),
                      items: filteredSections.map((sec) {
                        return DropdownMenuItem(
                          value: sec.id,
                          child: Text('Section ${sec.name}', style: AcadexTypography.body(color: AcadexColors.ink)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSectionId = val),
                      validator: (val) => val == null ? 'Please select a section' : null,
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (_scope == AnnouncementAudienceScope.role) ...[
                    DropdownButtonFormField<AppRole>(
                      value: _selectedTargetRole,
                      dropdownColor: AcadexColors.surface,
                      style: AcadexTypography.body(color: AcadexColors.ink),
                      iconEnabledColor: AcadexColors.inkSecondary,
                      decoration: InputDecoration(
                        labelText: 'Target Role *',
                        labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                        filled: true,
                        fillColor: AcadexColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: AppRole.student, child: Text('Students', style: AcadexTypography.body(color: AcadexColors.ink))),
                        DropdownMenuItem(value: AppRole.faculty, child: Text('Faculty', style: AcadexTypography.body(color: AcadexColors.ink))),
                        DropdownMenuItem(value: AppRole.hod, child: Text('Heads of Department', style: AcadexTypography.body(color: AcadexColors.ink))),
                      ],
                      onChanged: (val) => setState(() => _selectedTargetRole = val),
                      validator: (val) => val == null ? 'Please select a target role' : null,
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (_scope == AnnouncementAudienceScope.individual) ...[
                    TextFormField(
                      controller: _targetUserIdController,
                      style: AcadexTypography.body(color: AcadexColors.ink),
                      decoration: InputDecoration(
                        labelText: 'Recipient User ID *',
                        labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                        hintText: 'Enter user ID / registration ID',
                        hintStyle: AcadexTypography.body(color: AcadexColors.inkFaint),
                        filled: true,
                        fillColor: AcadexColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'User ID is required' : null,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Category & Priority row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category,
                          dropdownColor: AcadexColors.surface,
                          style: AcadexTypography.body(color: AcadexColors.ink),
                          iconEnabledColor: AcadexColors.inkSecondary,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                            filled: true,
                            fillColor: AcadexColors.canvas,
                            border: OutlineInputBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                              borderSide: const BorderSide(color: AcadexColors.hairline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                              borderSide: const BorderSide(color: AcadexColors.hairline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                              borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                            ),
                          ),
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c, style: AcadexTypography.body(color: AcadexColors.ink)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _category = val ?? 'GENERAL'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _priority,
                          dropdownColor: AcadexColors.surface,
                          style: AcadexTypography.body(color: AcadexColors.ink),
                          iconEnabledColor: AcadexColors.inkSecondary,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            labelStyle: AcadexTypography.bodySmall(color: AcadexColors.inkSecondary),
                            filled: true,
                            fillColor: AcadexColors.canvas,
                            border: OutlineInputBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                              borderSide: const BorderSide(color: AcadexColors.hairline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                              borderSide: const BorderSide(color: AcadexColors.hairline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                              borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                            ),
                          ),
                          items: _priorities.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p, style: AcadexTypography.body(color: AcadexColors.ink)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _priority = val ?? 'NORMAL'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Expiry Date Picker & Pin Toggle
                  InkWell(
                    onTap: _pickExpiryDate,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AcadexColors.canvas,
                        borderRadius: AcadexRadius.borderRadiusMd,
                        border: Border.all(color: AcadexColors.hairline),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 20, color: AcadexColors.inkSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expires At (Optional)', style: AcadexTypography.caption(color: AcadexColors.inkSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  _expiresAt != null
                                      ? DateFormat('EEE, d MMM yyyy, h:mm a').format(_expiresAt!)
                                      : 'No expiration set (Never expires)',
                                  style: AcadexTypography.body(color: AcadexColors.ink),
                                ),
                              ],
                            ),
                          ),
                          if (_expiresAt != null)
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 16, color: AcadexColors.inkSecondary),
                              onPressed: () => setState(() => _expiresAt = null),
                              tooltip: 'Clear expiry',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: Text('Pin Announcement', style: AcadexTypography.body(color: AcadexColors.ink)),
                      subtitle: Text('Keep this announcement prominently at top of feeds', style: AcadexTypography.caption(color: AcadexColors.inkSecondary)),
                      value: _isPinned,
                      activeColor: AcadexColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _isPinned = val),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(LucideIcons.fileText, size: 18),
                          label: const Text('Save Draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AcadexColors.ink,
                            side: const BorderSide(color: AcadexColors.hairline),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                          ),
                          onPressed: _isSubmitting ? null : () => _submit('DRAFT'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AcadexButton(
                          label: 'Publish Now',
                          icon: LucideIcons.send,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : () => _submit('PUBLISHED'),
                          isFullWidth: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
