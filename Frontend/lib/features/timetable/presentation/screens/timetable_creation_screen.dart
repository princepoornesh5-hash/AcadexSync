import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import '../providers/timetable_lookup_providers.dart';
import 'timetable_designer_screen.dart';

/// Dedicated screen for creating a new timetable container, configuring academic context,
/// working days, timing mode, initial bell schedule periods, and breaks before opening the designer.
class TimetableCreationScreen extends ConsumerStatefulWidget {
  final TimetableContainerModel? initialContainer;

  const TimetableCreationScreen({
    super.key,
    this.initialContainer,
  });

  @override
  ConsumerState<TimetableCreationScreen> createState() => _TimetableCreationScreenState();
}

class _TimetableCreationScreenState extends ConsumerState<TimetableCreationScreen> {
  int _currentStep = 0;
  bool _isCreating = false;
  String? _errorMessage;

  // Step 1: Academic Context
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedAcademicYearId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  final _nameController = TextEditingController();
  String _lastAutoName = '';

  // Step 2: Working Days & Timing Mode
  List<TimetableDay> _activeDays = [
    TimetableDay.monday,
    TimetableDay.tuesday,
    TimetableDay.wednesday,
    TimetableDay.thursday,
    TimetableDay.friday,
  ];
  TimetableTimingMode _timingMode = TimetableTimingMode.sameEveryDay;

  // Step 3: Periods
  List<TimetablePeriodModel> _periods = [];
  TimetableDay _periodDayTab = TimetableDay.monday;

  // Step 4: Breaks
  List<TimetableBreakModel> _breaks = [];

  // Duplicate timetable detection
  TimetableContainerModel? _existingDraftContainer;
  TimetableContainerModel? _existingPublishedContainer;

  @override
  void initState() {
    super.initState();
    _initDefaultSchedule();
    _initInitialState();
  }

  void _initDefaultSchedule() {
    _periods = [
      TimetablePeriodModel(
        id: const Uuid().v4(),
        index: 1,
        name: 'Period 1',
        startTime: '09:00',
        endTime: '10:00',
      ),
      TimetablePeriodModel(
        id: const Uuid().v4(),
        index: 2,
        name: 'Period 2',
        startTime: '10:00',
        endTime: '11:00',
      ),
      TimetablePeriodModel(
        id: const Uuid().v4(),
        index: 3,
        name: 'Period 3',
        startTime: '11:00',
        endTime: '12:00',
      ),
      TimetablePeriodModel(
        id: const Uuid().v4(),
        index: 4,
        name: 'Period 4',
        startTime: '12:00',
        endTime: '13:00',
      ),
      TimetablePeriodModel(
        id: const Uuid().v4(),
        index: 5,
        name: 'Period 5',
        startTime: '14:00',
        endTime: '15:00',
      ),
      TimetablePeriodModel(
        id: const Uuid().v4(),
        index: 6,
        name: 'Period 6',
        startTime: '15:00',
        endTime: '16:00',
      ),
    ];

    _breaks = [
      TimetableBreakModel(
        id: const Uuid().v4(),
        name: 'Lunch Break',
        startTime: '13:00',
        endTime: '14:00',
        breakType: TimetableBreakType.lunch,
        appliesToDays: List.from(_activeDays),
        isVerticalSpan: true,
      ),
    ];
  }

  void _initInitialState() {
    final init = widget.initialContainer;
    if (init != null) {
      _selectedDepartmentId = init.departmentId;
      _selectedCourseId = init.courseId;
      _selectedAcademicYearId = init.academicYearId;
      _selectedSemesterId = init.semesterId;
      _selectedSectionId = init.sectionId;
      _nameController.text = init.name;
      _activeDays = List.from(init.activeDays);
      _timingMode = init.timingMode;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingContainers() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    if (_selectedDepartmentId == null ||
        _selectedCourseId == null ||
        _selectedSemesterId == null ||
        _selectedSectionId == null) {
      return;
    }

    final repo = ref.read(timetableRepositoryProvider);
    final containers = await repo.getTimetableContainers(
      collegeId: user.collegeId ?? '',
      departmentId: _selectedDepartmentId,
      courseId: _selectedCourseId,
      academicYearId: _selectedAcademicYearId,
      semesterId: _selectedSemesterId,
      sectionId: _selectedSectionId,
    );

    setState(() {
      _existingDraftContainer = containers.where((c) => c.status == TimetableStatus.draft).firstOrNull;
      _existingPublishedContainer = containers.where((c) => c.status == TimetableStatus.published).firstOrNull;
    });
  }

  void _autoGenerateName() {
    if (_nameController.text.trim().isNotEmpty && _nameController.text != _lastAutoName) {
      return;
    }
    final courseMap = ref.read(timetableCourseMapProvider);
    final sectionMap = ref.read(timetableSectionMapProvider);

    final course = courseMap[_selectedCourseId]?.name ?? courseMap[_selectedCourseId]?.code ?? '';
    final section = sectionMap[_selectedSectionId]?.name ?? '';
    final sem = _selectedSemesterId != null ? 'Semester $_selectedSemesterId' : '';

    if (course.isNotEmpty || section.isNotEmpty) {
      final generated = [course, sem, section.isNotEmpty ? 'Section $section' : '', 'Timetable'].where((s) => s.isNotEmpty).join(' ');
      _nameController.text = generated;
      _lastAutoName = generated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;

    // Permissions check
    if (user.role != AppRole.collegeAdmin && user.role != AppRole.hod && user.role != AppRole.faculty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: const Center(child: Text('Unauthorized: Only administrators and HODs can create timetables.')),
      );
    }

    // Lock HOD to their department
    if (user.role == AppRole.hod && _selectedDepartmentId == null) {
      _selectedDepartmentId = user.departmentId;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    16,
                    isMobile ? 16 : 24,
                    8,
                  ),
                  child: AcadexPageHeader(
                    title: 'Create Timetable',
                    subtitle: 'Configure academic scope, periods, breaks and open the spreadsheet designer',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),

                // Step Progress Indicator
                _buildStepIndicator(isDark, isMobile),

                if (_errorMessage != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AcadexColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AcadexColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertTriangle, size: 16, color: AcadexColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AcadexColors.errorDark, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 14),
                            onPressed: () => setState(() => _errorMessage = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Active Step Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
                    child: _buildCurrentStepView(isDark, isMobile, user),
                  ),
                ),

                // Bottom Navigation Bar
                _buildBottomNav(isDark, isMobile, user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // STEP PROGRESS INDICATOR
  // =========================================================================
  Widget _buildStepIndicator(bool isDark, bool isMobile) {
    final steps = [
      'Academic Context',
      'Working Days',
      'Periods',
      'Breaks',
      'Preview & Create',
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;

            Color circleColor = isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft;
            Color textColor = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
            Color iconColor = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;

            if (isCompleted) {
              circleColor = AcadexColors.success;
              iconColor = Colors.white;
              textColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
            } else if (isCurrent) {
              circleColor = AcadexColors.primary;
              iconColor = Colors.white;
              textColor = AcadexColors.primary;
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: isCompleted ? () => setState(() => _currentStep = index) : null,
                  borderRadius: AcadexRadius.borderRadiusSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                          child: isCompleted
                              ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          steps[index],
                          style: AcadexTypography.caption(color: textColor).copyWith(
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: isMobile ? 16 : 32,
                    height: 1,
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // =========================================================================
  // CURRENT STEP CONTENT SWITCHER
  // =========================================================================
  Widget _buildCurrentStepView(bool isDark, bool isMobile, dynamic user) {
    switch (_currentStep) {
      case 0:
        return _buildStep1AcademicContext(isDark, isMobile, user);
      case 1:
        return _buildStep2WorkingDays(isDark, isMobile);
      case 2:
        return _buildStep3Periods(isDark, isMobile);
      case 3:
        return _buildStep4Breaks(isDark, isMobile);
      case 4:
        return _buildStep5Preview(isDark, isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // STEP 1: ACADEMIC CONTEXT
  // =========================================================================
  Widget _buildStep1AcademicContext(bool isDark, bool isMobile, dynamic user) {
    final deptsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final academicYearsAsync = ref.watch(academicYearsProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    final isHod = user.role == AppRole.hod;

    final availableDepts = (deptsAsync.valueOrNull ?? []).where((d) {
      if (isHod) return d.id == user.departmentId;
      return true;
    }).toList();

    final availableCourses = (coursesAsync.valueOrNull ?? []).where((c) {
      if (_selectedDepartmentId != null) return c.departmentId == _selectedDepartmentId;
      return true;
    }).toList();

    final availableYears = academicYearsAsync.valueOrNull ?? [];
    final availableSemesters = (semestersAsync.valueOrNull ?? []).where((s) {
      if (_selectedCourseId != null && s.courseId != _selectedCourseId) return false;
      return true;
    }).toList();

    final availableSections = (sectionsAsync.valueOrNull ?? []).where((s) {
      if (_selectedDepartmentId != null && s.departmentId != _selectedDepartmentId) return false;
      if (_selectedSemesterId != null && s.semesterId != _selectedSemesterId) return false;
      return true;
    }).toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: const Icon(LucideIcons.graduationCap, size: 20, color: AcadexColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1: Academic Hierarchy',
                    style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  ),
                  Text(
                    'Select department, course, semester, section, and timetable name',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Department Dropdown
          _buildDropdownField<String>(
            label: 'Department *',
            hint: 'Select department',
            value: _selectedDepartmentId,
            items: availableDepts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
            onChanged: isHod
                ? null
                : (val) {
                    setState(() {
                      _selectedDepartmentId = val;
                      _selectedCourseId = null;
                      _selectedSemesterId = null;
                      _selectedSectionId = null;
                      _autoGenerateName();
                    });
                    _checkExistingContainers();
                  },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Course Dropdown
          _buildDropdownField<String>(
            label: 'Course *',
            hint: _selectedDepartmentId == null ? 'Select department first' : 'Select course',
            value: _selectedCourseId,
            items: availableCourses.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.code})'))).toList(),
            onChanged: _selectedDepartmentId == null
                ? null
                : (val) {
                    setState(() {
                      _selectedCourseId = val;
                      _selectedSemesterId = null;
                      _selectedSectionId = null;
                      _autoGenerateName();
                    });
                    _checkExistingContainers();
                  },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Academic Year Dropdown
          _buildDropdownField<String>(
            label: 'Academic Year *',
            hint: 'Select academic year',
            value: _selectedAcademicYearId,
            items: availableYears.map((ay) => DropdownMenuItem(value: ay.id, child: Text(ay.name))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedAcademicYearId = val;
              });
              _checkExistingContainers();
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Semester Dropdown
          _buildDropdownField<String>(
            label: 'Semester *',
            hint: _selectedCourseId == null ? 'Select course first' : 'Select semester',
            value: _selectedSemesterId,
            items: availableSemesters.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (Semester ${s.number})'))).toList(),
            onChanged: _selectedCourseId == null
                ? null
                : (val) {
                    setState(() {
                      _selectedSemesterId = val;
                      _selectedSectionId = null;
                      _autoGenerateName();
                    });
                    _checkExistingContainers();
                  },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Section Dropdown
          _buildDropdownField<String>(
            label: 'Section *',
            hint: _selectedSemesterId == null ? 'Select semester first' : 'Select section',
            value: _selectedSectionId,
            items: availableSections.map((s) => DropdownMenuItem(value: s.id, child: Text('Section ${s.name}'))).toList(),
            onChanged: _selectedSemesterId == null
                ? null
                : (val) {
                    setState(() {
                      _selectedSectionId = val;
                      _autoGenerateName();
                    });
                    _checkExistingContainers();
                  },
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Timetable Name Field
          Text(
            'Timetable Name *',
            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g. CSE Semester 4 Section A Timetable',
              prefixIcon: const Icon(LucideIcons.type, size: 16),
              filled: true,
              fillColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
              border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusSm),
            ),
          ),

          // Duplicate Draft Alert Card
          if (_existingDraftContainer != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: isDark ? AcadexColors.warning : AcadexColors.warningDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.alertCircle, size: 18, color: isDark ? AcadexColors.warning : AcadexColors.warningDark),
                      const SizedBox(width: 8),
                      Text(
                        'Draft timetable already exists for this section',
                        style: AcadexTypography.bodyMedium(
                          color: isDark ? AcadexColors.warning : AcadexColors.warningDark,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'An active draft "${_existingDraftContainer!.name}" (v${_existingDraftContainer!.version}) already exists. You can continue editing the draft directly in the spreadsheet designer.',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => TimetableDesignerScreen(timetableId: _existingDraftContainer!.id),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                        label: const Text('Continue Editing Existing Draft', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Existing Published Timetable Info Card
          if (_existingPublishedContainer != null && _existingDraftContainer == null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primaryLight.withValues(alpha: 0.1) : AcadexColors.primaryLight,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: AcadexColors.primary),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 18, color: AcadexColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Published version v${_existingPublishedContainer!.version} is live. Creating a new draft will prepare version v${_existingPublishedContainer!.version + 1} safely without interrupting live attendance.',
                      style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: WORKING DAYS & TIMING MODE
  // =========================================================================
  Widget _buildStep2WorkingDays(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: const Icon(LucideIcons.calendarDays, size: 20, color: AcadexColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 2: Working Days & Timing Mode',
                    style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  ),
                  Text(
                    'Define the active academic days and period schedule structure',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Working Days Selection
          Text(
            'Active Working Days (Select at least 1) *',
            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TimetableDay.values.map((day) {
              final isSelected = _activeDays.contains(day);
              return FilterChip(
                label: Text(day.displayName),
                selected: isSelected,
                selectedColor: AcadexColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _activeDays.add(day);
                      _activeDays.sort((a, b) => a.index.compareTo(b.index));
                    } else if (_activeDays.length > 1) {
                      _activeDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Timing Mode Radio Selection
          Text(
            'Bell Schedule Timing Mode *',
            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _buildTimingModeOption(
            mode: TimetableTimingMode.sameEveryDay,
            title: 'Same Timing Every Day',
            subtitle: 'Use one common bell schedule across all working days (recommended for most academic terms).',
            icon: LucideIcons.repeat,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildTimingModeOption(
            mode: TimetableTimingMode.differentPerDay,
            title: 'Different Timing Per Day',
            subtitle: 'Allow individual days to have their own unique period schedules (e.g. Half-day Friday/Saturday).',
            icon: LucideIcons.calendarClock,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTimingModeOption({
    required TimetableTimingMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _timingMode == mode;

    return InkWell(
      onTap: () => setState(() => _timingMode = mode),
      borderRadius: AcadexRadius.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight)
              : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
          borderRadius: AcadexRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AcadexTypography.bodyMedium(
                      color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Radio<TimetableTimingMode>(
              value: mode,
              groupValue: _timingMode,
              onChanged: (val) {
                if (val != null) setState(() => _timingMode = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 3: INITIAL PERIOD CONFIGURATION
  // =========================================================================
  Widget _buildStep3Periods(bool isDark, bool isMobile) {
    final displayedPeriods = _timingMode == TimetableTimingMode.sameEveryDay
        ? _periods.where((p) => p.dayOfWeek == null).toList()
        : _periods.where((p) => p.dayOfWeek == _periodDayTab).toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: const Icon(LucideIcons.clock, size: 20, color: AcadexColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 3: Periods & Bell Schedule',
                        style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                      ),
                      Text(
                        'Define start and end times for teaching periods',
                        style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _initDefaultSchedule,
                    icon: const Icon(LucideIcons.rotateCcw, size: 14),
                    label: const Text('Default Periods'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addNewPeriod,
                    icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                    label: const Text('Add Period', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_timingMode == TimetableTimingMode.differentPerDay) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _activeDays.map((day) {
                  final isSelected = _periodDayTab == day;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(day.displayName),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _periodDayTab = day);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (displayedPeriods.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No periods defined. Click "+ Add Period" or "Default Periods".',
                style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedPeriods.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = displayedPeriods.removeAt(oldIndex);
                  displayedPeriods.insert(newIndex, item);

                  // Update indices
                  for (int i = 0; i < displayedPeriods.length; i++) {
                    final idx = _periods.indexWhere((p) => p.id == displayedPeriods[i].id);
                    if (idx != -1) {
                      _periods[idx] = _periods[idx].copyWith(index: i + 1);
                    }
                  }
                });
              },
              itemBuilder: (context, index) {
                final p = displayedPeriods[index];
                return _buildPeriodListItem(p, index, isDark, key: ValueKey(p.id));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodListItem(TimetablePeriodModel period, int index, bool isDark, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.gripVertical, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AcadexColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'P${period.index}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.primary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              period.name,
              style: AcadexTypography.bodyMedium(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${period.startTime} – ${period.endTime}',
            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
            onPressed: () {
              setState(() {
                _periods.removeWhere((p) => p.id == period.id);
                // Reindex
                int cur = 1;
                for (int i = 0; i < _periods.length; i++) {
                  _periods[i] = _periods[i].copyWith(index: cur++);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  void _addNewPeriod() {
    final nextIndex = _periods.length + 1;
    final startH = (8 + nextIndex).toString().padLeft(2, '0');
    final endH = (9 + nextIndex).toString().padLeft(2, '0');

    setState(() {
      _periods.add(TimetablePeriodModel(
        id: const Uuid().v4(),
        index: nextIndex,
        name: 'Period $nextIndex',
        startTime: '$startH:00',
        endTime: '$endH:00',
        dayOfWeek: _timingMode == TimetableTimingMode.differentPerDay ? _periodDayTab : null,
      ));
    });
  }

  // =========================================================================
  // STEP 4: BREAK CONFIGURATION
  // =========================================================================
  Widget _buildStep4Breaks(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: const Icon(LucideIcons.coffee, size: 20, color: AcadexColors.warningDark),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 4: Breaks & Recesses',
                        style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                      ),
                      Text(
                        'Configure lunch, tea, and assembly intervals',
                        style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _addNewBreak,
                icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                label: const Text('Add Break', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_breaks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No breaks configured. Click "+ Add Break" if required.',
                style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
            )
          else
            Column(
              children: _breaks.map((b) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF231F17) : const Color(0xFFFFFBEB),
                    borderRadius: AcadexRadius.borderRadiusSm,
                    border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.coffee, size: 16, color: AcadexColors.warningDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: AcadexTypography.bodyMedium(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${b.startTime} – ${b.endTime} • ${b.appliesToDays.map((d) => d.shortName).join(', ')}',
                              style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                        onPressed: () => setState(() => _breaks.removeWhere((item) => item.id == b.id)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _addNewBreak() {
    setState(() {
      _breaks.add(TimetableBreakModel(
        id: const Uuid().v4(),
        name: 'Tea Break',
        breakType: TimetableBreakType.tea,
        startTime: '11:00',
        endTime: '11:15',
        appliesToDays: List.from(_activeDays),
      ));
    });
  }

  // =========================================================================
  // STEP 5: PREVIEW & CREATE CONFIRMATION
  // =========================================================================
  Widget _buildStep5Preview(bool isDark, bool isMobile) {
    final deptMap = ref.watch(timetableDepartmentMapProvider);
    final courseMap = ref.watch(timetableCourseMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);
    final yearMap = ref.watch(timetableAcademicYearMapProvider);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: const Icon(LucideIcons.checkCircle2, size: 20, color: AcadexColors.success),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 5: Review & Generate Draft',
                    style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  ),
                  Text(
                    'Verify the configuration and initialize the master timetable draft',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildReviewRow('Timetable Name', _nameController.text.trim(), isDark),
          _buildReviewRow('Department', deptMap[_selectedDepartmentId]?.name ?? _selectedDepartmentId ?? '', isDark),
          _buildReviewRow('Course', courseMap[_selectedCourseId]?.name ?? _selectedCourseId ?? '', isDark),
          _buildReviewRow('Academic Year', yearMap[_selectedAcademicYearId]?.name ?? _selectedAcademicYearId ?? '', isDark),
          _buildReviewRow('Semester', 'Semester $_selectedSemesterId', isDark),
          _buildReviewRow('Section', 'Section ${sectionMap[_selectedSectionId]?.name ?? _selectedSectionId ?? ''}', isDark),
          _buildReviewRow('Active Days', _activeDays.map((d) => d.displayName).join(', '), isDark),
          _buildReviewRow('Timing Mode', _timingMode.displayName, isDark),
          _buildReviewRow('Configured Periods', '${_periods.length} Periods', isDark),
          _buildReviewRow('Configured Breaks', '${_breaks.length} Breaks', isDark),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AcadexTypography.bodyMedium(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BOTTOM NAVIGATION
  // =========================================================================
  Widget _buildBottomNav(bool isDark, bool isMobile, dynamic user) {
    final canGoNext = _canAdvanceStep();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        border: Border(top: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Back'),
            )
          else
            const SizedBox.shrink(),

          if (_currentStep < 4)
            ElevatedButton.icon(
              onPressed: canGoNext ? () => setState(() => _currentStep++) : null,
              icon: const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
              label: const Text('Next Step', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            )
          else
            ElevatedButton.icon(
              onPressed: _isCreating ? null : () => _createTimetableAndOpenDesigner(user),
              icon: _isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
              label: Text(_isCreating ? 'Creating...' : 'Create & Open Designer', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            ),
        ],
      ),
    );
  }

  bool _canAdvanceStep() {
    if (_currentStep == 0) {
      return _selectedDepartmentId != null &&
          _selectedCourseId != null &&
          _selectedAcademicYearId != null &&
          _selectedSemesterId != null &&
          _selectedSectionId != null &&
          _nameController.text.trim().isNotEmpty;
    }
    if (_currentStep == 1) {
      return _activeDays.isNotEmpty;
    }
    if (_currentStep == 2) {
      return _periods.isNotEmpty;
    }
    return true;
  }

  Future<void> _createTimetableAndOpenDesigner(dynamic user) async {
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(timetableRepositoryProvider);
      final newContainer = TimetableContainerModel(
        id: '',
        collegeId: user.collegeId ?? '',
        departmentId: _selectedDepartmentId!,
        courseId: _selectedCourseId!,
        academicYearId: _selectedAcademicYearId!,
        semesterId: _selectedSemesterId!,
        sectionId: _selectedSectionId!,
        name: _nameController.text.trim(),
        status: TimetableStatus.draft,
        version: 1,
        activeDays: _activeDays,
        timingMode: _timingMode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final serverId = await repo.createTimetableContainer(newContainer);
      if (serverId.trim().isEmpty) {
        throw Exception('Server returned an empty or invalid timetable ID.');
      }
      if (_periods.isNotEmpty) {
        await repo.savePeriodsBatch(serverId, _periods);
      }
      if (_breaks.isNotEmpty) {
        await repo.saveBreaksBatch(serverId, _breaks);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TimetableDesignerScreen(timetableId: serverId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _errorMessage = 'Failed to create timetable: $e';
        });
      }
    }
  }

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
            border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusSm),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
