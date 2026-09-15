import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_authoring_providers.dart';
import '../providers/timetable_lookup_providers.dart';
import 'timetable_widgets.dart';

/// Clean, responsive modal dialog for creating and editing timetable class assignments.
/// Supports single-period and multi-period merged horizontal classes with real-time local conflict validation.
class TimetableClassEditorDialog extends ConsumerStatefulWidget {
  final String timetableId;
  final TimetableDay day;
  final int startPeriodIndex;
  final TimetableGridEntryModel? existingEntry;
  final bool isBottomSheet;

  const TimetableClassEditorDialog({
    super.key,
    required this.timetableId,
    required this.day,
    required this.startPeriodIndex,
    this.existingEntry,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<TimetableClassEditorDialog> createState() => _TimetableClassEditorDialogState();
}

class _TimetableClassEditorDialogState extends ConsumerState<TimetableClassEditorDialog> {
  late String _subjectId;
  late String _facultyId;
  String? _facultyAssignmentId;
  late TimetableSessionType _sessionType;
  late int _periodSpan;
  late TextEditingController _roomController;
  late TextEditingController _buildingController;
  late TimetableDay _day;
  late int _startPeriodIndex;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    _subjectId = entry?.subjectId ?? '';
    _facultyId = entry?.facultyId ?? '';
    _facultyAssignmentId = entry?.facultyAssignmentId;
    _sessionType = entry?.sessionType ?? TimetableSessionType.lecture;
    _periodSpan = entry?.periodSpan ?? 1;
    _roomController = TextEditingController(text: entry?.roomNumber ?? '');
    _buildingController = TextEditingController(text: entry?.building ?? '');
    _day = entry?.dayOfWeek ?? widget.day;
    _startPeriodIndex = entry?.startPeriodIndex ?? widget.startPeriodIndex;
  }

  @override
  void dispose() {
    _roomController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final authoringState = ref.watch(timetableAuthoringProvider(widget.timetableId));
    final container = authoringState.container;
    final periods = authoringState.getPeriodsForDay(_day);

    // Section-scoped active faculty assignments
    final sectionAssignments = container != null
        ? ref.watch(facultyAssignmentsBySectionProvider(container.sectionId))
        : <FacultyAssignment>[];

    // Auto-resolve faculty assignment ID if not explicitly set
    if (_facultyAssignmentId == null && _subjectId.isNotEmpty && _facultyId.isNotEmpty && sectionAssignments.isNotEmpty) {
      final match = sectionAssignments.where((a) => a.subjectId == _subjectId && a.facultyId == _facultyId).firstOrNull;
      if (match != null) {
        _facultyAssignmentId = match.id;
      }
    }

    final selectedAssignment = sectionAssignments.where((a) => a.id == _facultyAssignmentId).firstOrNull;
    if (selectedAssignment != null) {
      _subjectId = selectedAssignment.subjectId;
      _facultyId = selectedAssignment.facultyId;
    }

    // Academic Lookups
    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final deptMap = ref.watch(timetableDepartmentMapProvider);
    final courseMap = ref.watch(timetableCourseMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);
    final yearMap = ref.watch(timetableAcademicYearMapProvider);
    final semMap = ref.watch(timetableSemesterMapProvider);

    // Calculate max available span
    final maxAvailableSpan = (periods.length - _startPeriodIndex + 1).clamp(1, 12);
    if (_periodSpan > maxAvailableSpan) {
      _periodSpan = maxAvailableSpan;
    }

    // Calculate start & end times based on span
    final startPeriod = periods.where((p) => p.index == _startPeriodIndex).firstOrNull;
    final endPeriodIndex = _startPeriodIndex + _periodSpan - 1;
    final endPeriod = periods.where((p) => p.index == endPeriodIndex).firstOrNull;

    final startTime = startPeriod?.startTime ?? '00:00';
    final endTime = endPeriod?.endTime ?? '00:00';

    // Calculate real-time local conflicts
    final validationErrors = _validateLocally(
      authoringState: authoringState,
      day: _day,
      startPeriodIndex: _startPeriodIndex,
      periodSpan: _periodSpan,
      startTime: startTime,
      endTime: endTime,
      facultyAssignmentId: _facultyAssignmentId,
      subjectId: _subjectId,
      facultyId: _facultyId,
      roomNumber: _roomController.text,
      existingEntryId: widget.existingEntry?.id,
      facultyMap: facultyMap,
      subjectMap: subjectMap,
      sectionAssignments: sectionAssignments,
    );

    // Resolve context names
    final deptName = container != null ? (deptMap[container.departmentId]?.name ?? container.departmentId) : '';
    final courseName = container != null ? (courseMap[container.courseId]?.name ?? container.courseId) : '';
    final sectionName = container != null ? (sectionMap[container.sectionId]?.name ?? container.sectionId) : '';

    final content = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =============================================================
            // 1. DIALOG HEADER & FIXED CONTEXT INFO
            // =============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                  child: Icon(
                    _isEditing ? LucideIcons.pencil : LucideIcons.bookOpen,
                    size: 22,
                    color: AcadexColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Class' : 'Add Class',
                        style: AcadexTypography.heading2(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_day.displayName} • Period $_startPeriodIndex ($startTime)',
                        style: AcadexTypography.bodySmall(
                          color: AcadexColors.primary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (container != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$deptName • $courseName • Sem ${container.semesterId} • Sec $sectionName',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(
              height: 1,
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
            const SizedBox(height: 20),

            // =============================================================
            // 2. AUTHORITATIVE FACULTY ASSIGNMENT SELECTION
            // =============================================================
            _buildFieldLabel('Faculty Assignment *', isDark),
            const SizedBox(height: 6),
            if (sectionAssignments.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                  border: Border.all(
                    color: AcadexColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 18, color: AcadexColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No active faculty assignments found for this section. Please assign faculty to subjects in Academic Structure first.',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.warning : AcadexColors.warningDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _facultyAssignmentId != null && sectionAssignments.any((a) => a.id == _facultyAssignmentId)
                    ? _facultyAssignmentId
                    : null,
                decoration: _buildInputDecoration(
                  hintText: 'Select Faculty Assignment',
                  prefixIcon: LucideIcons.badgeCheck,
                  isDark: isDark,
                ),
                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                items: sectionAssignments.map((a) {
                  final subName = subjectMap[a.subjectId]?.name ?? a.subjectId;
                  final subCode = subjectMap[a.subjectId]?.code ?? '';
                  final facName = facultyMap[a.facultyId]?.name ?? a.facultyName;
                  final codeText = subCode.isNotEmpty ? ' ($subCode)' : '';
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text(
                      '$subName$codeText — $facName',
                      style: AcadexTypography.bodyMedium(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _facultyAssignmentId = val;
                    if (val != null) {
                      final match = sectionAssignments.where((a) => a.id == val).firstOrNull;
                      if (match != null) {
                        _subjectId = match.subjectId;
                        _facultyId = match.facultyId;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              // READ-ONLY ASSIGNMENT SUMMARY (Section 5 requirement)
              if (selectedAssignment != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.info, size: 14, color: AcadexColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Authoritative Assignment Summary',
                            style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Faculty:',
                        facultyMap[selectedAssignment.facultyId]?.name ?? selectedAssignment.facultyName,
                        isDark,
                      ),
                      _buildSummaryRow(
                        'Subject:',
                        '${subjectMap[selectedAssignment.subjectId]?.name ?? selectedAssignment.subjectId}${subjectMap[selectedAssignment.subjectId]?.code != null ? ' (${subjectMap[selectedAssignment.subjectId]!.code})' : ''}',
                        isDark,
                      ),
                      _buildSummaryRow(
                        'Section:',
                        sectionMap[selectedAssignment.sectionId]?.name ?? (container?.sectionId ?? ''),
                        isDark,
                      ),
                      _buildSummaryRow(
                        'Course:',
                        courseMap[selectedAssignment.courseId]?.name ?? (container?.courseId ?? ''),
                        isDark,
                      ),
                      _buildSummaryRow(
                        'Academic Year:',
                        yearMap[selectedAssignment.academicYearId]?.name ?? (container?.academicYearId ?? ''),
                        isDark,
                      ),
                      _buildSummaryRow(
                        'Semester:',
                        semMap[selectedAssignment.semesterId]?.name ?? (container != null ? 'Semester ${container.semesterId}' : ''),
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

                // =============================================================
                // 4. SESSION TYPE SELECTION
                // =============================================================
                _buildFieldLabel('Session Type', isDark),
                const SizedBox(height: 6),
                DropdownButtonFormField<TimetableSessionType>(
                  isExpanded: true,
                  value: _sessionType,
                  decoration: _buildInputDecoration(
                    hintText: 'Select session type',
                    prefixIcon: getSessionTypeIcon(_sessionType),
                    isDark: isDark,
                  ),
                  dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                  items: TimetableSessionType.values.map((type) {
                    return DropdownMenuItem<TimetableSessionType>(
                      value: type,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: getSessionTypeColor(type),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              type.displayName,
                              style: AcadexTypography.bodyMedium(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _sessionType = val;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // =============================================================
                // 5. DURATION & MULTI-PERIOD MERGE SELECTOR
                // =============================================================
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Duration (Consecutive Periods)', isDark),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: _periodSpan,
                            decoration: _buildInputDecoration(
                              hintText: 'Select duration',
                              prefixIcon: LucideIcons.clock,
                              isDark: isDark,
                            ),
                            dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                            items: List.generate(maxAvailableSpan, (i) => i + 1).map((span) {
                              final endIdx = widget.startPeriodIndex + span - 1;
                              final endP = periods.where((p) => p.index == endIdx).firstOrNull;
                              final endT = endP?.endTime ?? '';
                              final label = span == 1
                                  ? '1 Period ($startTime - $endT)'
                                  : '$span Periods ($startTime - $endT) [Merged]';
                              return DropdownMenuItem<int>(
                                value: span,
                                child: Text(
                                  label,
                                  style: AcadexTypography.bodyMedium(
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _periodSpan = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Multi-Period Live Calculation Preview
                if (_periodSpan > 1) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight,
                      borderRadius: AcadexRadius.borderRadiusSm,
                      border: Border.all(
                        color: AcadexColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.arrowRightLeft, size: 14, color: AcadexColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Merged Entry: Spans Period ${widget.startPeriodIndex} to $endPeriodIndex ($startTime – $endTime)',
                            style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // =============================================================
                // 6. LOCATION DETAILS (ROOM & BUILDING)
                // =============================================================
                if (isMobile) ...[
                  _buildFieldLabel('Room Number', isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _roomController,
                    decoration: _buildInputDecoration(
                      hintText: 'e.g. LH-101, Lab-2',
                      prefixIcon: LucideIcons.doorOpen,
                      isDark: isDark,
                    ),
                    style: AcadexTypography.bodyMedium(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildFieldLabel('Building (Optional)', isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _buildingController,
                    decoration: _buildInputDecoration(
                      hintText: 'e.g. Main Block',
                      prefixIcon: LucideIcons.building,
                      isDark: isDark,
                    ),
                    style: AcadexTypography.bodyMedium(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Room Number', isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _roomController,
                              decoration: _buildInputDecoration(
                                hintText: 'e.g. LH-101, Lab-2',
                                prefixIcon: LucideIcons.doorOpen,
                                isDark: isDark,
                              ),
                              style: AcadexTypography.bodyMedium(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Building (Optional)', isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _buildingController,
                              decoration: _buildInputDecoration(
                                hintText: 'e.g. Main Block',
                                prefixIcon: LucideIcons.building,
                                isDark: isDark,
                              ),
                              style: AcadexTypography.bodyMedium(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // =============================================================
                // 7. REAL-TIME LOCAL CONFLICT VALIDATION BANNER
                // =============================================================
                if (validationErrors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(
                        color: AcadexColors.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.alertTriangle, size: 16, color: AcadexColors.error),
                            const SizedBox(width: 8),
                            Text(
                              'Validation Conflicts (${validationErrors.length})',
                              style: AcadexTypography.bodySmall(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final err in validationErrors) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: TextStyle(color: AcadexColors.error, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    err,
                                    style: AcadexTypography.caption(
                                      color: isDark ? Colors.red.shade200 : AcadexColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Divider(
                  height: 1,
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
                const SizedBox(height: 20),

                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (_isEditing)
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(LucideIcons.trash2, size: 16, color: AcadexColors.error),
                        label: Text(
                          'Delete Class',
                          style: AcadexTypography.bodySmall(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AcadexColors.error),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: AcadexTypography.bodySmall(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: validationErrors.isEmpty
                              ? () => _saveClass(context, startTime, endTime)
                              : null,
                          icon: Icon(
                            _isEditing ? LucideIcons.check : LucideIcons.plus,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isEditing ? 'Update Class' : 'Add Class',
                            style: AcadexTypography.bodySmall(color: Colors.white).copyWith(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.primary,
                            disabledBackgroundColor: isDark
                                ? AcadexColors.darkHairline
                                : AcadexColors.inkFaint.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusSm),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

    if (widget.isBottomSheet) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: content,
      );
    }

    return Dialog(
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: content,
      ),
    );
  }

  // =========================================================================
  // HELPER: LOCAL CONFLICT VALIDATION
  // =========================================================================
  List<String> _validateLocally({
    required TimetableAuthoringState authoringState,
    required TimetableDay day,
    required int startPeriodIndex,
    required int periodSpan,
    required String startTime,
    required String endTime,
    String? facultyAssignmentId,
    required String subjectId,
    required String facultyId,
    required String roomNumber,
    String? existingEntryId,
    required Map<String, Faculty> facultyMap,
    required Map<String, Subject> subjectMap,
    required List<FacultyAssignment> sectionAssignments,
  }) {
    final errors = <String>[];

    // 1. Authoritative Faculty Assignment Check
    if (facultyAssignmentId == null || facultyAssignmentId.trim().isEmpty) {
      errors.add('Please select an authoritative Faculty Assignment.');
    } else if (sectionAssignments.isNotEmpty && !sectionAssignments.any((a) => a.id == facultyAssignmentId)) {
      errors.add('Selected faculty assignment is not valid for this section context.');
    }

    // 2. Check Break Conflicts
    for (final b in authoringState.breaks) {
      if (b.appliesTo(day) && b.overlapsWithTime(startTime, endTime)) {
        errors.add('Break Conflict: Timeslot ($startTime - $endTime) overlaps with ${b.name} (${b.startTime} - ${b.endTime}).');
      }
    }

    // 3. Check Section, Faculty, and Room Conflicts against existing entries in this timetable
    final endPeriodIndex = startPeriodIndex + periodSpan - 1;

    for (final other in authoringState.entries) {
      if (other.id == existingEntryId) continue; // Skip self when editing
      if (other.dayOfWeek != day) continue;

      final isPeriodOverlap = startPeriodIndex <= other.endPeriodIndex && endPeriodIndex >= other.startPeriodIndex;
      final isTimeOverlap = startTime.compareTo(other.endTime) < 0 && endTime.compareTo(other.startTime) > 0;

      if (isPeriodOverlap || isTimeOverlap) {
        final otherSubject = subjectMap[other.subjectId]?.name ?? other.subjectId;
        errors.add('Section Conflict: Timeslot overlaps with existing class ($otherSubject, ${other.startTime} - ${other.endTime}).');
      }

      // Faculty Conflict (same faculty booked at overlapping time on the same day)
      if (facultyId.isNotEmpty && other.facultyId == facultyId) {
        if (isPeriodOverlap || isTimeOverlap) {
          final facName = facultyMap[facultyId]?.name ?? 'Selected Faculty';
          errors.add('Faculty Conflict: $facName is already scheduled on ${day.displayName} (${other.startTime} - ${other.endTime}).');
        }
      }

      // Room Conflict (same room booked at overlapping time on the same day)
      if (roomNumber.trim().isNotEmpty && other.roomNumber.trim().toLowerCase() == roomNumber.trim().toLowerCase()) {
        if (isPeriodOverlap || isTimeOverlap) {
          errors.add('Room Conflict: Room ${roomNumber.trim()} is already booked on ${day.displayName} (${other.startTime} - ${other.endTime}).');
        }
      }
    }

    return errors;
  }

  // =========================================================================
  // HELPER: SAVE CLASS TO LOCAL RIVERPOD AUTHORING STATE
  // =========================================================================
  void _saveClass(BuildContext context, String startTime, String endTime) {
    final notifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);

    if (_isEditing) {
      final updated = widget.existingEntry!.copyWith(
        dayOfWeek: _day,
        startPeriodIndex: _startPeriodIndex,
        periodSpan: _periodSpan,
        startTime: startTime,
        endTime: endTime,
        subjectId: _subjectId,
        facultyId: _facultyId,
        facultyAssignmentId: _facultyAssignmentId,
        roomNumber: _roomController.text.trim(),
        building: _buildingController.text.trim().isEmpty ? null : _buildingController.text.trim(),
        sessionType: _sessionType,
      );
      notifier.updateEntry(updated);
    } else {
      final newEntry = TimetableGridEntryModel(
        id: const Uuid().v4(),
        dayOfWeek: _day,
        startPeriodIndex: _startPeriodIndex,
        periodSpan: _periodSpan,
        startTime: startTime,
        endTime: endTime,
        subjectId: _subjectId,
        facultyId: _facultyId,
        facultyAssignmentId: _facultyAssignmentId,
        roomNumber: _roomController.text.trim(),
        building: _buildingController.text.trim().isEmpty ? null : _buildingController.text.trim(),
        sessionType: _sessionType,
      );
      notifier.createEntry(newEntry);
    }

    Navigator.of(context).pop();
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER: DELETE CLASS WITH CONFIRMATION
  // =========================================================================
  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectMap = ref.read(timetableSubjectMapProvider);
    final subjectName = subjectMap[widget.existingEntry?.subjectId]?.name ?? widget.existingEntry?.subjectId ?? 'this class';
    final spanText = widget.existingEntry != null && widget.existingEntry!.periodSpan > 1
        ? 'P${widget.startPeriodIndex}–P${widget.existingEntry!.endPeriodIndex}'
        : 'P${widget.startPeriodIndex}';

    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
          title: Text(
            'Delete Class',
            style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          ),
          content: Text(
            'Remove $subjectName from ${widget.day.displayName} $spanText? This change will take effect locally in your draft.',
            style: AcadexTypography.bodyMedium(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.error,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        final notifier = ref.read(timetableAuthoringProvider(widget.timetableId).notifier);
        notifier.deleteEntry(widget.existingEntry!.id);
        Navigator.of(context).pop();
      }
    });
  }

  // =========================================================================
  // UI STYLING HELPERS
  // =========================================================================
  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: AcadexTypography.caption(
        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
      ).copyWith(fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AcadexTypography.bodySmall(
        color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 18,
        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
      ),
      filled: true,
      fillColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: AcadexRadius.borderRadiusSm,
        borderSide: BorderSide(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AcadexRadius.borderRadiusSm,
        borderSide: BorderSide(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AcadexRadius.borderRadiusSm,
        borderSide: const BorderSide(
          color: AcadexColors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}

/// Helper function to display the class editor dialog.
Future<void> showTimetableClassEditorDialog({
  required BuildContext context,
  required String timetableId,
  required TimetableDay day,
  required int startPeriodIndex,
  TimetableGridEntryModel? existingEntry,
}) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  if (isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: TimetableClassEditorDialog(
            timetableId: timetableId,
            day: day,
            startPeriodIndex: startPeriodIndex,
            existingEntry: existingEntry,
            isBottomSheet: true,
          ),
        );
      },
    );
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return TimetableClassEditorDialog(
        timetableId: timetableId,
        day: day,
        startPeriodIndex: startPeriodIndex,
        existingEntry: existingEntry,
      );
    },
  );
}
