import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../domain/models/institution_config_models.dart';
import '../providers/institution_config_providers.dart';

class InstitutionConfigurationScreen extends ConsumerStatefulWidget {
  const InstitutionConfigurationScreen({super.key});

  @override
  ConsumerState<InstitutionConfigurationScreen> createState() =>
      _InstitutionConfigurationScreenState();
}

class _InstitutionConfigurationScreenState
    extends ConsumerState<InstitutionConfigurationScreen> {
  int _currentStep = 0;

  InstitutionType _selectedType = InstitutionType.engineering;
  late AcademicStructureConfig _structure;
  late TerminologyConfig _terminology;
  late AttendanceAlertsConfig _attendanceAlerts;

  // Controllers for Terminology TextFields
  late TextEditingController _programSingular;
  late TextEditingController _programPlural;
  late TextEditingController _semesterSingular;
  late TextEditingController _semesterPlural;
  late TextEditingController _sectionSingular;
  late TextEditingController _sectionPlural;
  late TextEditingController _subjectSingular;
  late TextEditingController _subjectPlural;
  late TextEditingController _deptSingular;
  late TextEditingController _deptPlural;
  late TextEditingController _buildingSingular;
  late TextEditingController _buildingPlural;
  late TextEditingController _roomSingular;
  late TextEditingController _roomPlural;

  bool _initializedFromBackend = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _structure = const AcademicStructureConfig();
    _terminology = const TerminologyConfig();
    _attendanceAlerts = const AttendanceAlertsConfig();
    _initControllers();
  }

  void _initControllers() {
    _programSingular = TextEditingController(text: _terminology.program.singular);
    _programPlural = TextEditingController(text: _terminology.program.plural);
    _semesterSingular = TextEditingController(text: _terminology.semester.singular);
    _semesterPlural = TextEditingController(text: _terminology.semester.plural);
    _sectionSingular = TextEditingController(text: _terminology.section.singular);
    _sectionPlural = TextEditingController(text: _terminology.section.plural);
    _subjectSingular = TextEditingController(text: _terminology.subject.singular);
    _subjectPlural = TextEditingController(text: _terminology.subject.plural);
    _deptSingular = TextEditingController(text: _terminology.department.singular);
    _deptPlural = TextEditingController(text: _terminology.department.plural);
    _buildingSingular = TextEditingController(text: _terminology.building.singular);
    _buildingPlural = TextEditingController(text: _terminology.building.plural);
    _roomSingular = TextEditingController(text: _terminology.room.singular);
    _roomPlural = TextEditingController(text: _terminology.room.plural);
  }

  void _updateControllersFromTerminology() {
    _programSingular.text = _terminology.program.singular;
    _programPlural.text = _terminology.program.plural;
    _semesterSingular.text = _terminology.semester.singular;
    _semesterPlural.text = _terminology.semester.plural;
    _sectionSingular.text = _terminology.section.singular;
    _sectionPlural.text = _terminology.section.plural;
    _subjectSingular.text = _terminology.subject.singular;
    _subjectPlural.text = _terminology.subject.plural;
    _deptSingular.text = _terminology.department.singular;
    _deptPlural.text = _terminology.department.plural;
    _buildingSingular.text = _terminology.building.singular;
    _buildingPlural.text = _terminology.building.plural;
    _roomSingular.text = _terminology.room.singular;
    _roomPlural.text = _terminology.room.plural;
  }

  @override
  void dispose() {
    _programSingular.dispose();
    _programPlural.dispose();
    _semesterSingular.dispose();
    _semesterPlural.dispose();
    _sectionSingular.dispose();
    _sectionPlural.dispose();
    _subjectSingular.dispose();
    _subjectPlural.dispose();
    _deptSingular.dispose();
    _deptPlural.dispose();
    _buildingSingular.dispose();
    _buildingPlural.dispose();
    _roomSingular.dispose();
    _roomPlural.dispose();
    super.dispose();
  }

  void _applyPreset(InstitutionPresetModel preset) {
    setState(() {
      _selectedType = preset.id;
      _structure = preset.suggestedStructure;
      _terminology = preset.suggestedTerminology;
      _updateControllersFromTerminology();
    });
  }

  void _syncTerminologyFromControllers() {
    _terminology = _terminology.copyWith(
      department: ConceptTerm(singular: _deptSingular.text.trim(), plural: _deptPlural.text.trim()),
      program: ConceptTerm(singular: _programSingular.text.trim(), plural: _programPlural.text.trim()),
      semester: ConceptTerm(singular: _semesterSingular.text.trim(), plural: _semesterPlural.text.trim()),
      section: ConceptTerm(singular: _sectionSingular.text.trim(), plural: _sectionPlural.text.trim()),
      subject: ConceptTerm(singular: _subjectSingular.text.trim(), plural: _subjectPlural.text.trim()),
      building: ConceptTerm(singular: _buildingSingular.text.trim(), plural: _buildingPlural.text.trim()),
      room: ConceptTerm(singular: _roomSingular.text.trim(), plural: _roomPlural.text.trim()),
    );
  }

  Future<void> _handleSave() async {
    _syncTerminologyFromControllers();

    setState(() => _isSaving = true);
    final notifier = ref.read(institutionConfigActionProvider.notifier);
    final result = await notifier.updateConfiguration(
      institutionType: _selectedType,
      academicStructure: _structure,
      terminology: _terminology,
      attendanceAlerts: _attendanceAlerts,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result != null) {
        AcadexSnackBar.showSuccess(
          context,
          'Institution configuration updated successfully.',
        );
        context.safePop(fallbackRoute: '/academics');
      } else {
        AcadexSnackBar.showError(
          context,
          "Couldn't save configuration. Please try again.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final configAsync = ref.watch(institutionConfigProvider);
    final presetsAsync = ref.watch(institutionPresetsProvider);

    // Initial load from backend
    if (!_initializedFromBackend && configAsync.hasValue) {
      final cfg = configAsync.value!;
      _selectedType = cfg.institutionType;
      _structure = cfg.academicStructure;
      _terminology = cfg.terminology;
      _attendanceAlerts = cfg.attendanceAlerts;
      _updateControllersFromTerminology();
      _initializedFromBackend = true;
    }

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics'),
        ),
        title: Text(
          'Institution Configuration',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: configAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading configuration...'),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: "Couldn't load institution configuration.",
            retryLabel: 'Retry',
            onRetry: () => ref.refresh(institutionConfigProvider),
          ),
        ),
        data: (_) {
          return Column(
            children: [
              // Progress Stepper Indicators
              _buildStepIndicator(isDark),

              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStep == 0)
                        _buildStep1Presets(presetsAsync, isDark),
                      if (_currentStep == 1)
                        _buildStep2Structure(isDark),
                      if (_currentStep == 2)
                        _buildStep3Terminology(isDark),
                      if (_currentStep == 3)
                        _buildStep4AttendanceAlerts(isDark),
                      if (_currentStep == 4)
                        _buildStep5Preview(isDark),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Bar
              _buildBottomControls(isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final steps = ['College Type', 'Structure', 'Terminology', 'Attendance Alerts', 'Preview'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (idx) {
          final isActive = idx == _currentStep;
          final isPast = idx < _currentStep;

          return InkWell(
            onTap: () {
              _syncTerminologyFromControllers();
              setState(() => _currentStep = idx);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AcadexColors.primary
                          : isPast
                              ? const Color(0xFF15803D)
                              : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
                    ),
                    child: Center(
                      child: isPast
                          ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: (isActive || isPast) ? Colors.white : AcadexColors.inkMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    steps[idx],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AcadexColors.primary
                          : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- STEP 1: PRESETS ---
  Widget _buildStep1Presets(AsyncValue<List<InstitutionPresetModel>> presetsAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 1 OF 5',
          style: AcadexTypography.eyebrow(color: AcadexColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'How does your college organize academics?',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a starter preset to apply suggested structure and terminology. You can customize every option in the next steps.',
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 18),

        presetsAsync.maybeWhen(
          data: (presets) {
            return Column(
              children: presets.map((p) {
                final isSelected = _selectedType == p.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? AcadexColors.primary
                          : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _applyPreset(p),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
                            size: 20,
                            color: isSelected ? AcadexColors.primary : AcadexColors.inkMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: AcadexTypography.title(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.description,
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _buildPill('Section: ${p.suggestedStructure.section ? "Enabled" : "Disabled"}', p.suggestedStructure.section),
                                    _buildPill('Rooms: ${p.suggestedStructure.room ? "Enabled" : "Disabled"}', p.suggestedStructure.room),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          orElse: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildPill(String label, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isEnabled ? const Color(0xFF15803D) : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  // --- STEP 2: STRUCTURE ---
  Widget _buildStep2Structure(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 2 OF 5',
          style: AcadexTypography.eyebrow(color: AcadexColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Which academic concepts does your college use?',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Disabled concepts are completely hidden from normal forms, dropdowns, navigation, and workflows.',
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 18),

        // Section Toggle
        _buildStructureToggle(
          title: 'Section / Class / Batch',
          subtitle: 'Enable if students in the same program and semester are divided into subgroups (e.g. CSE-A, CSE-B). When disabled, sections disappear entirely.',
          value: _structure.section,
          isDark: isDark,
          onChanged: (val) => setState(() => _structure = _structure.copyWith(section: val)),
        ),

        // Room Toggle
        _buildStructureToggle(
          title: 'Room / Classroom',
          subtitle: 'Enable if your college allocates specific classrooms for classes and timetable sessions.',
          value: _structure.room,
          isDark: isDark,
          onChanged: (val) => setState(() => _structure = _structure.copyWith(room: val)),
        ),

        // Building Toggle
        _buildStructureToggle(
          title: 'Building / Block',
          subtitle: 'Enable if your campus has multiple designated buildings or wings.',
          value: _structure.building,
          isDark: isDark,
          onChanged: (val) => setState(() => _structure = _structure.copyWith(building: val)),
        ),

        // Academic Year Toggle
        _buildStructureToggle(
          title: 'Academic Year Tracking',
          subtitle: 'Enable calendar session and batch tracking (e.g. 2026-2027).',
          value: _structure.academicYear,
          isDark: isDark,
          onChanged: (val) => setState(() => _structure = _structure.copyWith(academicYear: val)),
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.primaryTint,
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 18, color: AcadexColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Core academic models (Department, Program, Semester, Subject) form the academic backbone and remain safely enabled.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStructureToggle({
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AcadexTypography.title(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeColor: AcadexColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- STEP 3: TERMINOLOGY ---
  Widget _buildStep3Terminology(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 3 OF 5',
          style: AcadexTypography.eyebrow(color: AcadexColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'What do you call them?',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ACADEX speaks your college’s language. Customize the exact singular and plural terms shown across all screens.',
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 18),

        // 1. Program
        _buildConceptTerminologyCard(
          conceptName: 'Academic Program',
          hint: 'The degree or diploma program students enroll in.',
          singularController: _programSingular,
          pluralController: _programPlural,
          presetSuggestions: [
            ['Course', 'Courses'],
            ['Program', 'Programs'],
            ['Branch', 'Branches'],
            ['Degree', 'Degrees'],
          ],
          isDark: isDark,
        ),

        // 2. Semester
        _buildConceptTerminologyCard(
          conceptName: 'Semester / Term',
          hint: 'The academic session or grading period.',
          singularController: _semesterSingular,
          pluralController: _semesterPlural,
          presetSuggestions: [
            ['Semester', 'Semesters'],
            ['Term', 'Terms'],
            ['Trimester', 'Trimesters'],
          ],
          isDark: isDark,
        ),

        // 3. Section (only if enabled)
        if (_structure.section)
          _buildConceptTerminologyCard(
            conceptName: 'Section / Class',
            hint: 'The student subgroup within a semester.',
            singularController: _sectionSingular,
            pluralController: _sectionPlural,
            presetSuggestions: [
              ['Section', 'Sections'],
              ['Class', 'Classes'],
              ['Batch', 'Batches'],
              ['Division', 'Divisions'],
            ],
            isDark: isDark,
          ),

        // 4. Subject
        _buildConceptTerminologyCard(
          conceptName: 'Subject / Course Material',
          hint: 'The specific syllabus topic or paper taught.',
          singularController: _subjectSingular,
          pluralController: _subjectPlural,
          presetSuggestions: [
            ['Subject', 'Subjects'],
            ['Paper', 'Papers'],
            ['Course', 'Courses'],
            ['Module', 'Modules'],
          ],
          isDark: isDark,
        ),

        // 5. Department
        _buildConceptTerminologyCard(
          conceptName: 'Department',
          hint: 'The academic division or school.',
          singularController: _deptSingular,
          pluralController: _deptPlural,
          presetSuggestions: [
            ['Department', 'Departments'],
            ['School', 'Schools'],
            ['Faculty', 'Faculties'],
          ],
          isDark: isDark,
        ),

        // 6. Room (if enabled)
        if (_structure.room)
          _buildConceptTerminologyCard(
            conceptName: 'Room',
            hint: 'Classroom or laboratory allocation.',
            singularController: _roomSingular,
            pluralController: _roomPlural,
            presetSuggestions: [
              ['Room', 'Rooms'],
              ['Classroom', 'Classrooms'],
              ['Hall', 'Halls'],
              ['Lab', 'Labs'],
            ],
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildConceptTerminologyCard({
    required String conceptName,
    required String hint,
    required TextEditingController singularController,
    required TextEditingController pluralController,
    required List<List<String>> presetSuggestions,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conceptName,
            style: AcadexTypography.title(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 10),

          // Preset Suggestions Chips
          Wrap(
            spacing: 6,
            children: presetSuggestions.map((pair) {
              final isMatch = singularController.text.trim().toLowerCase() == pair[0].toLowerCase();
              return ActionChip(
                label: Text(pair[0], style: TextStyle(fontSize: 11, color: isMatch ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink))),
                backgroundColor: isMatch ? AcadexColors.primary : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                onPressed: () {
                  setState(() {
                    singularController.text = pair[0];
                    pluralController.text = pair[1];
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SINGULAR', style: AcadexTypography.eyebrow(color: AcadexColors.inkMuted)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: singularController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusMd),
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
                    Text('PLURAL', style: AcadexTypography.eyebrow(color: AcadexColors.inkMuted)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: pluralController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusMd),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 4: ATTENDANCE ALERTS ---
  Widget _buildStep4AttendanceAlerts(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 4 OF 5',
          style: AcadexTypography.eyebrow(color: AcadexColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Attendance Alerts & Thresholds',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Configure proactive attendance alerts and automatic warning notifications for students.',
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 20),

        // 1. Global Master Switch
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Alerts',
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enable proactive in-app notifications for absences and threshold warnings.',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _attendanceAlerts.enabled,
                activeColor: AcadexColors.primary,
                onChanged: (val) {
                  setState(() {
                    _attendanceAlerts = _attendanceAlerts.copyWith(enabled: val);
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Absence Notifications Switch
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Absence Notifications',
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notify students immediately when they are marked absent for a class.',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _attendanceAlerts.enabled && _attendanceAlerts.absenceAlertsEnabled,
                activeColor: AcadexColors.primary,
                onChanged: _attendanceAlerts.enabled
                    ? (val) {
                        setState(() {
                          _attendanceAlerts = _attendanceAlerts.copyWith(absenceAlertsEnabled: val);
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Warning Threshold Slider & Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Warning Threshold',
                    style: AcadexTypography.title(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AcadexColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_attendanceAlerts.warningPercentage.round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AcadexColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Students receive an alert when their attendance falls below this percentage.',
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: _attendanceAlerts.warningPercentage.clamp(50.0, 95.0),
                min: 50.0,
                max: 95.0,
                divisions: 45,
                label: '${_attendanceAlerts.warningPercentage.round()}%',
                activeColor: AcadexColors.warning,
                onChanged: _attendanceAlerts.enabled
                    ? (val) {
                        setState(() {
                          final newWarn = val;
                          final newCrit = _attendanceAlerts.criticalPercentage > newWarn
                              ? newWarn - 5
                              : _attendanceAlerts.criticalPercentage;
                          _attendanceAlerts = _attendanceAlerts.copyWith(
                            warningPercentage: newWarn,
                            criticalPercentage: newCrit,
                          );
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. Critical Threshold Slider & Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Critical Threshold',
                    style: AcadexTypography.title(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AcadexColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_attendanceAlerts.criticalPercentage.round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AcadexColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Critical alerts are for students whose attendance requires urgent attention.',
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: _attendanceAlerts.criticalPercentage.clamp(40.0, _attendanceAlerts.warningPercentage),
                min: 40.0,
                max: _attendanceAlerts.warningPercentage,
                divisions: ((_attendanceAlerts.warningPercentage - 40.0).round()).clamp(1, 60),
                label: '${_attendanceAlerts.criticalPercentage.round()}%',
                activeColor: AcadexColors.error,
                onChanged: _attendanceAlerts.enabled
                    ? (val) {
                        setState(() {
                          _attendanceAlerts = _attendanceAlerts.copyWith(
                            criticalPercentage: val,
                          );
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- STEP 5: PREVIEW ---
  Widget _buildStep5Preview(bool isDark) {
    _syncTerminologyFromControllers();

    final programSingular = _programSingular.text.trim().isNotEmpty ? _programSingular.text.trim() : 'Course';
    final programPlural = _programPlural.text.trim().isNotEmpty ? _programPlural.text.trim() : 'Courses';
    final semesterSingular = _semesterSingular.text.trim().isNotEmpty ? _semesterSingular.text.trim() : 'Semester';
    final semesterPlural = _semesterPlural.text.trim().isNotEmpty ? _semesterPlural.text.trim() : 'Semesters';
    final sectionSingular = _sectionSingular.text.trim().isNotEmpty ? _sectionSingular.text.trim() : 'Section';
    final sectionPlural = _sectionPlural.text.trim().isNotEmpty ? _sectionPlural.text.trim() : 'Sections';
    final subjectSingular = _subjectSingular.text.trim().isNotEmpty ? _subjectSingular.text.trim() : 'Subject';
    final subjectPlural = _subjectPlural.text.trim().isNotEmpty ? _subjectPlural.text.trim() : 'Subjects';
    final deptSingular = _deptSingular.text.trim().isNotEmpty ? _deptSingular.text.trim() : 'Department';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 5 OF 5',
          style: AcadexTypography.eyebrow(color: AcadexColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Review how ACADEX will look for your college',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Verify your academic hierarchy and terminology before committing changes.',
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 18),

        // Visual Hierarchy Flow
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR ACADEMIC HIERARCHY',
                style: AcadexTypography.eyebrow(color: AcadexColors.primary),
              ),
              const SizedBox(height: 14),

              _buildHierarchyNode(deptSingular, 'e.g. Computer Science & Eng.', LucideIcons.building2, isDark),
              _buildHierarchyArrow(isDark),
              _buildHierarchyNode(programSingular, 'e.g. B.Tech Computer Science', LucideIcons.graduationCap, isDark),
              _buildHierarchyArrow(isDark),
              _buildHierarchyNode(semesterSingular, 'e.g. $semesterSingular 3', LucideIcons.calendarDays, isDark),

              if (_structure.section) ...[
                _buildHierarchyArrow(isDark),
                _buildHierarchyNode(sectionSingular, 'e.g. $sectionSingular A', LucideIcons.layoutGrid, isDark),
              ],

              _buildHierarchyArrow(isDark),
              _buildHierarchyNode(subjectSingular, 'e.g. Data Structures', LucideIcons.bookOpen, isDark),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Real Visible Experience Previews
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKFLOW & TEACHING CONTEXT PREVIEW',
                style: AcadexTypography.eyebrow(color: AcadexColors.primary),
              ),
              const SizedBox(height: 10),

              // Assignment Card sample
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Linked List Problems', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      _structure.section
                          ? 'Data Structures · $semesterSingular 3 · $sectionSingular A'
                          : 'Data Structures · $semesterSingular 3',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'ACADEMIC TABS BAR PREVIEW',
                style: AcadexTypography.eyebrow(color: AcadexColors.inkMuted),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: [
                  _buildTabChip('Departments'),
                  _buildTabChip(programPlural),
                  _buildTabChip(semesterPlural),
                  if (_structure.section) _buildTabChip(sectionPlural),
                  _buildTabChip(subjectPlural),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                'ATTENDANCE ALERTS PREVIEW',
                style: AcadexTypography.eyebrow(color: AcadexColors.primary),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Attendance Alerts:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
                        Text(_attendanceAlerts.enabled ? 'Enabled' : 'Disabled', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _attendanceAlerts.enabled ? const Color(0xFF15803D) : AcadexColors.inkMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Absence Notifications:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
                        Text((_attendanceAlerts.enabled && _attendanceAlerts.absenceAlertsEnabled) ? 'Enabled' : 'Disabled', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: (_attendanceAlerts.enabled && _attendanceAlerts.absenceAlertsEnabled) ? const Color(0xFF15803D) : AcadexColors.inkMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Warning Threshold:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
                        Text('${_attendanceAlerts.warningPercentage.round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AcadexColors.warning)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Critical Threshold:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
                        Text('${_attendanceAlerts.criticalPercentage.round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AcadexColors.error)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHierarchyNode(String title, String example, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AcadexColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(example, style: const TextStyle(fontSize: 11, color: AcadexColors.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyArrow(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Icon(LucideIcons.arrowDown, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
      ),
    );
  }

  Widget _buildTabChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AcadexColors.primaryTint,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AcadexColors.primary,
        ),
      ),
    );
  }

  // --- BOTTOM CONTROLS ---
  Widget _buildBottomControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  _syncTerminologyFromControllers();
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AcadexColors.hairline),
                  shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: _currentStep < 4
                ? AcadexButton(
                    label: 'Continue',
                    icon: LucideIcons.arrowRight,
                    onPressed: () {
                      _syncTerminologyFromControllers();
                      setState(() => _currentStep++);
                    },
                  )
                : AcadexButton(
                    label: _isSaving ? 'Saving...' : 'Save Configuration',
                    icon: LucideIcons.check,
                    onPressed: _isSaving ? null : _handleSave,
                  ),
          ),
        ],
      ),
    );
  }
}
