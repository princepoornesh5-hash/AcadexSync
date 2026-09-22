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
import '../widgets/timetable_spreadsheet_grid.dart';
import 'timetable_designer_screen.dart';
export 'timetable_creation_screen.dart';

/// Step-by-step Timetable Creation & Setup Wizard.
/// Steps:
/// 1. Academic Context (Department, Course, Academic Year, Semester, Section, Name)
/// 2. Working Days & Timing Mode
/// 3. Periods & Schedule Timings
/// 4. Breaks Setup
/// 5. Live Preview & Confirmation -> Open Designer
class TimetableSetupScreen extends ConsumerStatefulWidget {
  final TimetableContainerModel? initialContainer;

  const TimetableSetupScreen({
    super.key,
    this.initialContainer,
  });

  @override
  ConsumerState<TimetableSetupScreen> createState() => _TimetableSetupScreenState();
}

class _TimetableSetupScreenState extends ConsumerState<TimetableSetupScreen> {
  int _currentStep = 0;
  bool _isCreating = false;

  // Step 1: Academic Context
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedAcademicYearId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  final _nameController = TextEditingController();

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

  // Existing container duplicate detection
  TimetableContainerModel? _existingDraftContainer;

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
    final sem = _selectedSemesterId != null ? 'Sem $_selectedSemesterId' : '';

    if (course.isNotEmpty || section.isNotEmpty) {
      final generated = [course, sem, section.isNotEmpty ? 'Sec $section' : ''].where((s) => s.isNotEmpty).join(' - ');
      _nameController.text = generated;
      _lastAutoName = generated;
    }
  }

  String _lastAutoName = '';

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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
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
                    subtitle: 'Configure academic scope, periods, breaks and generate spreadsheet designer',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),

                // Step Progress Indicator
                _buildStepIndicator(isDark, isMobile),

                const SizedBox(height: 12),

                // Active Step Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
                    child: _buildCurrentStepView(isDark, isMobile, user),
                  ),
                ),

                // Bottom Navigation Bar
                _buildBottomNav(isDark, isMobile),
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
    final availableSemesters = semestersAsync.valueOrNull ?? [];
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
                    'Select the department, course, and section for this timetable',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Department Dropdown
          DropdownButtonFormField<String>(
            value: _selectedDepartmentId,
            decoration: const InputDecoration(labelText: 'Department *'),
            items: availableDepts.map((d) {
              return DropdownMenuItem(value: d.id, child: Text('${d.name} (${d.code})'));
            }).toList(),
            onChanged: isHod
                ? null
                : (val) {
                    setState(() {
                      _selectedDepartmentId = val;
                      _selectedCourseId = null;
                      _selectedSectionId = null;
                    });
                    _autoGenerateName();
                    _checkExistingContainers();
                  },
          ),

          const SizedBox(height: 16),

          // Course Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCourseId,
            decoration: const InputDecoration(labelText: 'Course / Degree Program *'),
            items: availableCourses.map((c) {
              return DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.code})'));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCourseId = val;
                _selectedSectionId = null;
              });
              _autoGenerateName();
              _checkExistingContainers();
            },
          ),

          const SizedBox(height: 16),

          // Academic Year Dropdown
          DropdownButtonFormField<String>(
            value: _selectedAcademicYearId,
            decoration: const InputDecoration(labelText: 'Academic Year *'),
            items: availableYears.map((y) {
              return DropdownMenuItem(value: y.id, child: Text(y.name));
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedAcademicYearId = val);
              _checkExistingContainers();
            },
          ),

          const SizedBox(height: 16),

          // Semester & Section in a Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSemesterId,
                  decoration: const InputDecoration(labelText: 'Semester *'),
                  items: availableSemesters.map((s) {
                    return DropdownMenuItem(value: s.id, child: Text('Semester ${s.number}'));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSemesterId = val;
                      _selectedSectionId = null;
                    });
                    _autoGenerateName();
                    _checkExistingContainers();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSectionId,
                  decoration: const InputDecoration(labelText: 'Section *'),
                  items: availableSections.map((s) {
                    return DropdownMenuItem(value: s.id, child: Text(s.name));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedSectionId = val);
                    _autoGenerateName();
                    _checkExistingContainers();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timetable Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Timetable Container Name *',
              hintText: 'e.g. CSE Sem 4 Sec A Master Timetable',
            ),
          ),

          // Duplicate Container Notice
          if (_existingDraftContainer != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                borderRadius: AcadexRadius.borderRadiusSm,
                border: Border.all(color: AcadexColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 20, color: AcadexColors.warningDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Draft Timetable Already Exists',
                          style: AcadexTypography.bodySmall(color: AcadexColors.warningDark).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'An active draft timetable "${_existingDraftContainer!.name}" already exists for this section.',
                          style: AcadexTypography.caption(color: AcadexColors.warningDark),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => TimetableDesignerScreen(timetableId: _existingDraftContainer!.id),
                        ),
                      );
                    },
                    child: const Text('Open Existing Draft', style: TextStyle(fontWeight: FontWeight.w700)),
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
                child: const Icon(LucideIcons.calendar, size: 20, color: AcadexColors.primary),
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
                    'Choose active academic days and schedule uniformity',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Active Working Days *',
            style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
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
                selectedColor: AcadexColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AcadexColors.primary,
                onSelected: (val) {
                  setState(() {
                    if (val) {
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

          Text(
            'Timing Mode *',
            style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                RadioListTile<TimetableTimingMode>(
                  title: const Text('Same timing every day (Standard)'),
                  subtitle: const Text('All active days follow the exact same period timings and break slots'),
                  value: TimetableTimingMode.sameEveryDay,
                  groupValue: _timingMode,
                  onChanged: (val) {
                    if (val != null) setState(() => _timingMode = val);
                  },
                ),
                RadioListTile<TimetableTimingMode>(
                  title: const Text('Different timing per day (Custom per day)'),
                  subtitle: const Text('Individual days (e.g. Friday half-day) can have distinct period schedules'),
                  value: TimetableTimingMode.differentPerDay,
                  groupValue: _timingMode,
                  onChanged: (val) {
                    if (val != null) setState(() => _timingMode = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3: PERIODS & SCHEDULE TIMINGS
  // =========================================================================
  Widget _buildStep3Periods(bool isDark, bool isMobile) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                        'Step 3: Period Slots (${_periods.length})',
                        style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                      ),
                      Text(
                        'Configure teaching periods, timeslots, and order',
                        style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPeriodDialog(isDark),
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                label: const Text('Add Period', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                ),
              ),
            ],
          ),

          if (_timingMode == TimetableTimingMode.differentPerDay) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _activeDays.map((day) {
                  final isSelected = day == _periodDayTab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
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
          ],

          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _periods.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final period = _periods[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  borderRadius: AcadexRadius.borderRadiusSm,
                  border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Text(
                        'P${period.index}',
                        style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period.name,
                            style: AcadexTypography.bodyMedium(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${period.startTime} – ${period.endTime} (${period.durationInMinutes} mins)',
                            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(LucideIcons.arrowUp, size: 16),
                      onPressed: index > 0
                          ? () {
                              setState(() {
                                final item = _periods.removeAt(index);
                                _periods.insert(index - 1, item);
                                _reindexPeriods();
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.arrowDown, size: 16),
                      onPressed: index < _periods.length - 1
                          ? () {
                              setState(() {
                                final item = _periods.removeAt(index);
                                _periods.insert(index + 1, item);
                                _reindexPeriods();
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                      onPressed: _periods.length > 1
                          ? () {
                              setState(() {
                                _periods.removeAt(index);
                                _reindexPeriods();
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _reindexPeriods() {
    for (int i = 0; i < _periods.length; i++) {
      _periods[i] = _periods[i].copyWith(index: i + 1);
    }
  }

  void _showAddPeriodDialog(bool isDark) {
    final nextIdx = _periods.length + 1;
    final lastEnd = _periods.isNotEmpty ? _periods.last.endTime : '09:00';
    final nameCtrl = TextEditingController(text: 'Period $nextIdx');
    final startCtrl = TextEditingController(text: lastEnd);
    final endCtrl = TextEditingController(text: '10:00');

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          title: const Text('Add Period'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Period Name')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time'))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty && startCtrl.text.trim().isNotEmpty && endCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _periods.add(TimetablePeriodModel(
                      id: const Uuid().v4(),
                      index: nextIdx,
                      name: nameCtrl.text.trim(),
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                    ));
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // STEP 4: BREAKS SETUP
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: const Icon(LucideIcons.coffee, size: 20, color: AcadexColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 4: Configure Breaks (${_breaks.length})',
                        style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                      ),
                      Text(
                        'Add lunch, tea, and custom breaks',
                        style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddBreakDialog(isDark),
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                label: const Text('Add Break', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_breaks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No breaks configured (Optional)', style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _breaks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final b = _breaks[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                    borderRadius: AcadexRadius.borderRadiusSm,
                    border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                          borderRadius: AcadexRadius.borderRadiusSm,
                        ),
                        child: const Icon(LucideIcons.utensils, size: 18, color: AcadexColors.warningDark),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: AcadexTypography.bodyMedium(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${b.startTime} – ${b.endTime} (${b.durationInMinutes} mins) • ${b.appliesToDays.map((d) => d.displayName.substring(0, 3)).join(', ')}',
                              style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                        onPressed: () => setState(() => _breaks.removeAt(index)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddBreakDialog(bool isDark) {
    final nameCtrl = TextEditingController(text: 'Lunch Break');
    final startCtrl = TextEditingController(text: '13:00');
    final endCtrl = TextEditingController(text: '14:00');
    var breakType = TimetableBreakType.lunch;
    var selectedDays = List<TimetableDay>.from(_activeDays);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
              title: const Text('Add Break'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Break Name')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time'))),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _breaks.add(TimetableBreakModel(
                          id: const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          startTime: startCtrl.text.trim(),
                          endTime: endCtrl.text.trim(),
                          breakType: breakType,
                          appliesToDays: selectedDays,
                          isVerticalSpan: true,
                        ));
                      });
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // STEP 5: PREVIEW & CONFIRMATION
  // =========================================================================
  Widget _buildStep5Preview(bool isDark, bool isMobile) {
    final deptMap = ref.watch(timetableDepartmentMapProvider);
    final courseMap = ref.watch(timetableCourseMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    final previewContainer = TimetableContainerModel(
      id: 'preview-container',
      collegeId: 'preview-college',
      departmentId: _selectedDepartmentId ?? '',
      courseId: _selectedCourseId ?? '',
      academicYearId: _selectedAcademicYearId ?? '',
      semesterId: _selectedSemesterId ?? '',
      sectionId: _selectedSectionId ?? '',
      name: _nameController.text.trim(),
      status: TimetableStatus.draft,
      version: 1,
      activeDays: _activeDays,
      timingMode: _timingMode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final previewState = TimetableAuthoringState(
      container: previewContainer,
      periods: _periods,
      breaks: _breaks,
      entries: const [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Card
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                  const Icon(LucideIcons.sparkles, size: 20, color: AcadexColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Timetable Configuration Summary',
                    style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  _buildSummaryBadge('Department', deptMap[_selectedDepartmentId]?.name ?? _selectedDepartmentId ?? '-', isDark),
                  _buildSummaryBadge('Course', courseMap[_selectedCourseId]?.name ?? _selectedCourseId ?? '-', isDark),
                  _buildSummaryBadge('Semester', 'Sem ${_selectedSemesterId ?? '-'}', isDark),
                  _buildSummaryBadge('Section', sectionMap[_selectedSectionId]?.name ?? _selectedSectionId ?? '-', isDark),
                  _buildSummaryBadge('Active Days', '${_activeDays.length} Days', isDark),
                  _buildSummaryBadge('Periods', '${_periods.length} Slots', isDark),
                  _buildSummaryBadge('Breaks', '${_breaks.length} Breaks', isDark),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Live Grid Preview
        Container(
          height: 380,
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          ),
          child: ClipRRect(
            borderRadius: AcadexRadius.borderRadiusLg,
            child: TimetableSpreadsheetGrid(
              authoringState: previewState,
              permissions: const TimetableAuthoringPermissions.readOnly(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBadge(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted).copyWith(fontSize: 10)),
          Text(value, style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // =========================================================================
  // BOTTOM NAVIGATION BAR
  // =========================================================================
  Widget _buildBottomNav(bool isDark, bool isMobile) {
    final canGoNext = _validateCurrentStep();

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
              label: const Text('Next Step', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            )
          else
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createAndOpenDesigner,
              icon: _isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
              label: Text(
                _isCreating ? 'Creating...' : 'Create & Open Designer',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
        ],
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedDepartmentId != null &&
            _selectedCourseId != null &&
            _selectedAcademicYearId != null &&
            _selectedSemesterId != null &&
            _selectedSectionId != null &&
            _nameController.text.trim().isNotEmpty;
      case 1:
        return _activeDays.isNotEmpty;
      case 2:
        return _periods.isNotEmpty;
      case 3:
        return true;
      default:
        return true;
    }
  }

  Future<void> _createAndOpenDesigner() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    setState(() {
      _isCreating = true;
    });

    try {
      final repo = ref.read(timetableRepositoryProvider);

      final container = TimetableContainerModel(
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

      // 1. Persist Container & obtain real server timetable ID
      final serverTimetableId = await repo.createTimetableContainer(container);

      if (serverTimetableId.trim().isEmpty) {
        throw Exception('Server returned an empty or invalid timetable ID.');
      }

      // 2. Persist Periods using real server ID
      await repo.savePeriodsBatch(serverTimetableId, _periods);

      // 3. Persist Breaks using real server ID
      if (_breaks.isNotEmpty) {
        await repo.saveBreaksBatch(serverTimetableId, _breaks);
      }

      if (mounted) {
        // Navigate to Designer using real server ID
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TimetableDesignerScreen(timetableId: serverTimetableId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create timetable: $e'), backgroundColor: AcadexColors.error),
        );
      }
    }
  }
}
