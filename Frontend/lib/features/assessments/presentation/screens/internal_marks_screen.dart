import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../domain/models/internal_assessment_models.dart';
import '../providers/assessment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';

class InternalMarksScreen extends ConsumerStatefulWidget {
  final String? sectionId;
  final String? subjectId;
  final String? academicYearId;
  final String? assessmentId;
  final String? facultyAssignmentId;

  const InternalMarksScreen({
    super.key,
    this.sectionId,
    this.subjectId,
    this.academicYearId,
    this.assessmentId,
    this.facultyAssignmentId,
  });

  @override
  ConsumerState<InternalMarksScreen> createState() =>
      _InternalMarksScreenState();
}

class _InternalMarksScreenState extends ConsumerState<InternalMarksScreen> {
  // --- Canonical Roster State ---
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, StudentMarkStatus> _statuses = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _isRosterInitialized = false;
  bool _hasUnsavedChanges = false;
  String _searchQuery = '';
  String _sortBy = 'rollNumber'; // 'rollNumber' | 'studentName'
  bool _sortAsc = true;

  // --- Legacy Context Fallback State ---
  final Map<String, Map<String, TextEditingController>> _legacyControllers = {};
  final Map<String, TextEditingController> _legacyRemarksControllers = {};
  final Map<String, double> _legacyStudentTotals = {};
  final Map<String, StudentMarkStatus> _legacyStudentStatuses = {};
  String? _activeMobileComponentKey;
  bool _isLegacyInitialized = false;

  bool _isSaving = false;

  AssessmentContextParams get _params => (
    sectionId: widget.sectionId,
    subjectId: widget.subjectId,
    academicYearId: widget.academicYearId,
  );

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AcadexColors.error : AcadexColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    for (final ctrl in _marksControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in _remarksControllers.values) {
      ctrl.dispose();
    }
    for (final fn in _focusNodes.values) {
      fn.dispose();
    }
    for (final map in _legacyControllers.values) {
      for (final ctrl in map.values) {
        ctrl.dispose();
      }
    }
    for (final ctrl in _legacyRemarksControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ==========================================
  // CANONICAL ROSTER WORKFLOW
  // ==========================================

  void _initRoster(MarksRosterResponseModel rosterData) {
    if (_isRosterInitialized) return;
    for (final item in rosterData.roster) {
      final markText = item.marks != null
          ? (item.marks! % 1 == 0
                ? item.marks!.toInt().toString()
                : item.marks!.toString())
          : '';
      _marksControllers[item.studentEnrollmentId] = TextEditingController(
        text: markText,
      );
      _remarksControllers[item.studentEnrollmentId] = TextEditingController(
        text: item.remarks ?? '',
      );
      _statuses[item.studentEnrollmentId] = item.status;
      _focusNodes[item.studentEnrollmentId] = FocusNode();
    }
    _isRosterInitialized = true;
  }

  void _onStatusChanged(String enrollmentId, StudentMarkStatus newStatus) {
    setState(() {
      _statuses[enrollmentId] = newStatus;
      _hasUnsavedChanges = true;
      if (newStatus != StudentMarkStatus.present) {
        _marksControllers[enrollmentId]?.text = '';
      }
    });
  }

  bool _validateRosterMarks(double maximumMarks) {
    for (final entry in _marksControllers.entries) {
      final enrollmentId = entry.key;
      final status = _statuses[enrollmentId] ?? StudentMarkStatus.notEntered;
      if (status == StudentMarkStatus.present) {
        final text = entry.value.text.trim();
        if (text.isNotEmpty) {
          final val = double.tryParse(text);
          if (val == null || val < 0) {
            _showToast(
              'Invalid negative or non-numeric mark entered.',
              isError: true,
            );
            return false;
          }
          if (val > maximumMarks) {
            _showToast(
              'Mark $val exceeds maximum allowed marks ($maximumMarks).',
              isError: true,
            );
            return false;
          }
        }
      }
    }
    return true;
  }

  Future<void> _handleSaveRosterDraft(
    MarksRosterResponseModel rosterData,
  ) async {
    final maxMarks =
        (rosterData.assessment['maximumMarks'] as num?)?.toDouble() ?? 25.0;
    if (!_validateRosterMarks(maxMarks)) return;

    setState(() => _isSaving = true);
    try {
      final entries = <StudentAssessmentEntryModel>[];
      for (final item in rosterData.roster) {
        final enrollmentId = item.studentEnrollmentId;
        final status = _statuses[enrollmentId] ?? item.status;
        final markText = _marksControllers[enrollmentId]?.text.trim() ?? '';
        final double? markVal =
            (status == StudentMarkStatus.present && markText.isNotEmpty)
            ? double.tryParse(markText)
            : null;

        entries.add(
          StudentAssessmentEntryModel(
            studentId: item.studentId,
            studentEnrollmentId: enrollmentId,
            studentName: item.studentName,
            rollNumber: item.rollNumber,
            admissionNumber: item.admissionNumber,
            componentMarks: {},
            marks: markVal,
            totalMarks: markVal ?? 0.0,
            status: status,
            remarks: _remarksControllers[enrollmentId]?.text.trim(),
          ),
        );
      }

      await ref
          .read(assessmentRepositoryProvider)
          .saveDraftMarks(assessmentId: widget.assessmentId, entries: entries);

      _showToast('Draft marks saved successfully.');
      setState(() => _hasUnsavedChanges = false);
      if (widget.assessmentId != null) {
        ref.invalidate(assessmentRosterProvider(widget.assessmentId!));
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSubmitRoster(MarksRosterResponseModel rosterData) async {
    final maxMarks =
        (rosterData.assessment['maximumMarks'] as num?)?.toDouble() ?? 25.0;
    if (!_validateRosterMarks(maxMarks)) return;

    // Calculate live confirmation stats from current local state
    int present = 0;
    int absent = 0;
    int exempted = 0;
    int notAppeared = 0;
    int unresolved = 0;

    for (final item in rosterData.roster) {
      final s =
          _statuses[item.studentEnrollmentId] ?? StudentMarkStatus.notEntered;
      final markText =
          _marksControllers[item.studentEnrollmentId]?.text.trim() ?? '';
      if (s == StudentMarkStatus.present) {
        if (markText.isNotEmpty && double.tryParse(markText) != null) {
          present++;
        } else {
          unresolved++;
        }
      } else if (s == StudentMarkStatus.absent) {
        absent++;
      } else if (s == StudentMarkStatus.exempted) {
        exempted++;
      } else if (s == StudentMarkStatus.notAppeared) {
        notAppeared++;
      } else {
        unresolved++;
      }
    }

    final total = rosterData.roster.length;
    final entered = total - unresolved;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Marks Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please verify the marks entry summary before final submission. Once submitted, marks become locked and require an authorized administrative request for any corrections.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AcadexColors.canvasSoft,
                borderRadius: BorderRadius.circular(AcadexRadius.xs),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Enrolled Students', '$total'),
                  _buildSummaryRow('Entered Outcomes', '$entered'),
                  _buildSummaryRow('Present', '$present'),
                  _buildSummaryRow('Absent', '$absent'),
                  _buildSummaryRow('Exempted', '$exempted'),
                  _buildSummaryRow('Not Appeared', '$notAppeared'),
                  _buildSummaryRow(
                    'Unresolved (Pending)',
                    '$unresolved',
                    isWarning: unresolved > 0,
                  ),
                  _buildSummaryRow('Maximum Marks', '${maxMarks.toInt()}'),
                ],
              ),
            ),
            if (unresolved > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Note: All active students must have an explicit outcome before submission. Submission will be rejected if unresolved students remain.',
                style: TextStyle(
                  fontSize: 12,
                  color: AcadexColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
            ),
            onPressed: unresolved > 0
                ? null
                : () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Confirm & Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      // Save pending draft first to guarantee latest values on backend
      await _handleSaveRosterDraft(rosterData);

      // Submit marks
      await ref
          .read(assessmentRepositoryProvider)
          .submitMarks(assessmentId: widget.assessmentId!);
      _showToast('Assessment marks submitted successfully and locked.');
      ref.invalidate(assessmentRosterProvider(widget.assessmentId!));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isWarning ? AcadexColors.error : AcadexColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompleteAssessment() async {
    if (widget.assessmentId == null) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(assessmentRepositoryProvider)
          .completeAssessment(widget.assessmentId!);
      _showToast('Assessment exam completed. Marks entry is now open.');
      ref.invalidate(assessmentRosterProvider(widget.assessmentId!));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleRequestCorrectionDialog(
    MarksRosterResponseModel rosterData,
  ) async {
    final reasonController = TextEditingController();
    final markController = TextEditingController();
    String? selectedEnrollmentId = rosterData.roster.isNotEmpty
        ? rosterData.roster.first.studentEnrollmentId
        : null;
    StudentMarkStatus proposedStatus = StudentMarkStatus.present;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request Marks Correction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Once submitted or locked, mark changes require an authorized review request routed to the HOD/Admin.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedEnrollmentId,
                  decoration: const InputDecoration(
                    labelText: 'Target Student',
                  ),
                  items: rosterData.roster.map((s) {
                    final roll = s.rollNumber != null
                        ? '[${s.rollNumber}] '
                        : '';
                    return DropdownMenuItem(
                      value: s.studentEnrollmentId,
                      child: Text(
                        '$roll${s.studentName}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedEnrollmentId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StudentMarkStatus>(
                  value: proposedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Proposed Status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: StudentMarkStatus.present,
                      child: Text('Present'),
                    ),
                    DropdownMenuItem(
                      value: StudentMarkStatus.absent,
                      child: Text('Absent'),
                    ),
                    DropdownMenuItem(
                      value: StudentMarkStatus.exempted,
                      child: Text('Exempted'),
                    ),
                    DropdownMenuItem(
                      value: StudentMarkStatus.notAppeared,
                      child: Text('Not Appeared'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => proposedStatus = val);
                  },
                ),
                if (proposedStatus == StudentMarkStatus.present) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: markController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Proposed Marks',
                      hintText: 'e.g. 22.5',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Correction *',
                    hintText:
                        'e.g. Evaluator recalculation error on question 3',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.primary,
              ),
              onPressed: () {
                if (selectedEnrollmentId == null) {
                  _showToast('Please select a student.', isError: true);
                  return;
                }
                if (reasonController.text.trim().length < 5) {
                  _showToast(
                    'Please provide a descriptive reason (at least 5 characters).',
                    isError: true,
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text(
                'Submit Request',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final double? markVal =
          proposedStatus == StudentMarkStatus.present &&
              markController.text.trim().isNotEmpty
          ? double.tryParse(markController.text.trim())
          : null;

      await ref
          .read(assessmentRepositoryProvider)
          .requestCorrection(
            assessmentId: widget.assessmentId!,
            studentEnrollmentId: selectedEnrollmentId!,
            reason: reasonController.text.trim(),
            newMark: markVal,
            newStatus: proposedStatus,
          );

      _showToast('Correction request submitted to HOD/Admin for review.');
      ref.invalidate(assessmentRosterProvider(widget.assessmentId!));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleCreateHistoricalAssessmentDialog({
    String? prefillSectionId,
    String? prefillSubjectId,
    String? prefillFacultyAssignmentId,
    String? prefillAcademicYearId,
  }) async {
    final titleController = TextEditingController(text: 'Unit Test 1');
    final maxMarksController = TextEditingController(text: '25');
    final passMarksController = TextEditingController(text: '10');
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 30));

    final targetSectionId = prefillSectionId ?? widget.sectionId;
    final targetSubjectId = prefillSubjectId ?? widget.subjectId;
    final targetAssignmentId =
        prefillFacultyAssignmentId ?? widget.facultyAssignmentId;
    final targetYearId = prefillAcademicYearId ?? widget.academicYearId;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(LucideIcons.history, size: 20, color: AcadexColors.primary),
              SizedBox(width: 8),
              Text('Create Historical Unit Test'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter historical unit test marks manually. The canonical student roster will be resolved automatically for this academic period.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Assessment Title *',
                    hintText: 'e.g. Unit Test 1, Unit Test 2, Midterm',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxMarksController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Max Marks *',
                          hintText: 'e.g. 25',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: passMarksController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Pass Marks',
                          hintText: 'e.g. 10',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historical Exam Date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.calendar, size: 16),
                      label: const Text('Pick Date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final title = titleController.text.trim();
                final maxMarks = double.tryParse(
                  maxMarksController.text.trim(),
                );
                if (title.isEmpty) {
                  _showToast('Assessment title is required.', isError: true);
                  return;
                }
                if (maxMarks == null || maxMarks <= 0) {
                  _showToast(
                    'Maximum marks must be greater than zero.',
                    isError: true,
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Create & Load Roster'),
            ),
          ],
        ),
      ),
    );

    if (created != true) return;

    setState(() => _isSaving = true);
    try {
      final title = titleController.text.trim();
      final maxMarks = double.parse(maxMarksController.text.trim());
      final passMarks = double.tryParse(passMarksController.text.trim()) ?? 0.0;

      final newAssessment = await ref
          .read(assessmentRepositoryProvider)
          .createAssessment(
            title: title,
            maximumMarks: maxMarks,
            passMarks: passMarks,
            assessmentDate: selectedDate,
            sectionId: targetSectionId,
            subjectId: targetSubjectId,
            facultyAssignmentId: targetAssignmentId,
            academicYearId: targetYearId,
            sourceType: 'HISTORICAL_MANUAL',
            isHistorical: true,
            assessmentType: 'INTERNAL_EXAM',
          );

      _showToast('Historical unit test "$title" created successfully.');
      if (mounted && newAssessment.id != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => InternalMarksScreen(
              assessmentId: newAssessment.id,
              sectionId: targetSectionId,
              subjectId: targetSubjectId,
              academicYearId: targetYearId,
              facultyAssignmentId: targetAssignmentId,
            ),
          ),
        );
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      titleController.dispose();
      maxMarksController.dispose();
      passMarksController.dispose();
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==========================================
  // LEGACY CONTEXT FALLBACK LOGIC
  // ==========================================

  void _initLegacyControllers(AssessmentContextModel contextData) {
    if (_isLegacyInitialized) return;
    final assessment = contextData.assessment;
    if (assessment == null) return;

    for (final entry in assessment.entries) {
      final sMap = <String, TextEditingController>{};
      double total = 0;

      for (final comp in contextData.components) {
        final val = entry.componentMarks[comp.key];
        final text = val != null
            ? (val % 1 == 0 ? val.toInt().toString() : val.toString())
            : '';
        final ctrl = TextEditingController(text: text);
        sMap[comp.key] = ctrl;
        if (val != null) total += val;
      }
      _legacyControllers[entry.studentId] = sMap;
      _legacyRemarksControllers[entry.studentId] = TextEditingController(
        text: entry.remarks ?? '',
      );
      _legacyStudentTotals[entry.studentId] = total;
      _legacyStudentStatuses[entry.studentId] = entry.status;
    }
    if (_activeMobileComponentKey == null &&
        contextData.components.isNotEmpty) {
      _activeMobileComponentKey = contextData.components.first.key;
    }
    _isLegacyInitialized = true;
  }

  void _recalculateLegacyTotal(
    String studentId,
    List<AssessmentComponentModel> comps,
  ) {
    final sMap = _legacyControllers[studentId];
    if (sMap == null) return;

    double sum = 0;
    for (final comp in comps) {
      final ctrl = sMap[comp.key];
      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
        final val = double.tryParse(ctrl.text.trim());
        if (val != null && val >= 0) sum += val;
      }
    }
    setState(() {
      _legacyStudentTotals[studentId] = MathUtils.round1(sum);
    });
  }

  List<StudentAssessmentEntryModel> _buildLegacyEntries(
    AssessmentContextModel data,
  ) {
    final entries = <StudentAssessmentEntryModel>[];
    final originalEntries = data.assessment?.entries ?? [];
    final originalMap = {for (final e in originalEntries) e.studentId: e};

    for (final sEntry in _legacyControllers.entries) {
      final sId = sEntry.key;
      final compMap = sEntry.value;
      final orig = originalMap[sId];

      final marks = <String, double?>{};
      double total = 0;
      for (final cEntry in compMap.entries) {
        final text = cEntry.value.text.trim();
        if (text.isEmpty) {
          marks[cEntry.key] = null;
        } else {
          final val = double.tryParse(text);
          marks[cEntry.key] = val;
          if (val != null) total += val;
        }
      }

      entries.add(
        StudentAssessmentEntryModel(
          studentId: sId,
          studentName: orig?.studentName ?? 'Student',
          rollNumber: orig?.rollNumber,
          admissionNumber: orig?.admissionNumber,
          componentMarks: marks,
          totalMarks: MathUtils.round1(total),
          status:
              _legacyStudentStatuses[sId] ??
              (marks.values.any((m) => m != null)
                  ? StudentMarkStatus.entered
                  : StudentMarkStatus.notEntered),
          remarks: _legacyRemarksControllers[sId]?.text.trim(),
        ),
      );
    }
    return entries;
  }

  String? _resolveSectionId(AssessmentContextModel? data) =>
      widget.sectionId ??
      (data?.section['id']?.toString() ?? data?.section['_id']?.toString());

  String? _resolveSubjectId(AssessmentContextModel? data) =>
      widget.subjectId ??
      (data?.subject['id']?.toString() ?? data?.subject['_id']?.toString());

  Future<void> _handleSaveLegacyDraft(AssessmentContextModel data) async {
    setState(() => _isSaving = true);
    try {
      final entries = _buildLegacyEntries(data);
      await ref
          .read(assessmentRepositoryProvider)
          .saveDraftMarks(
            assessmentId: widget.assessmentId ?? data.assessment?.id,
            sectionId: _resolveSectionId(data),
            subjectId: _resolveSubjectId(data),
            entries: entries,
            academicYearId: widget.academicYearId,
          );

      _showToast('Draft marks saved successfully.');
      ref.invalidate(assessmentContextProvider(_params));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleReviewLegacyMarks(AssessmentContextModel data) async {
    setState(() => _isSaving = true);
    try {
      final entries = _buildLegacyEntries(data);
      await ref
          .read(assessmentRepositoryProvider)
          .saveDraftMarks(
            assessmentId: widget.assessmentId ?? data.assessment?.id,
            sectionId: _resolveSectionId(data),
            subjectId: _resolveSubjectId(data),
            entries: entries,
          );

      await ref
          .read(assessmentRepositoryProvider)
          .reviewMarks(
            assessmentId: widget.assessmentId ?? data.assessment?.id,
            sectionId: _resolveSectionId(data),
            subjectId: _resolveSubjectId(data),
          );

      _showToast('Assessment marked as reviewed.');
      ref.invalidate(assessmentContextProvider(_params));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePublishLegacyMarks(AssessmentContextModel data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalize and Publish Marks?'),
        content: const Text(
          'Publishing marks will LOCK them against further regular edits and immediately make them visible to enrolled students.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Publish & Lock',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final entries = _buildLegacyEntries(data);
      await ref
          .read(assessmentRepositoryProvider)
          .saveDraftMarks(
            assessmentId: widget.assessmentId ?? data.assessment?.id,
            sectionId: _resolveSectionId(data),
            subjectId: _resolveSubjectId(data),
            entries: entries,
          );

      await ref
          .read(assessmentRepositoryProvider)
          .publishMarks(
            assessmentId: widget.assessmentId ?? data.assessment?.id,
            sectionId: _resolveSectionId(data),
            subjectId: _resolveSubjectId(data),
          );

      _showToast('Internal marks finalized, locked, and published.');
      ref.invalidate(assessmentContextProvider(_params));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==========================================
  // MAIN BUILD DISPATCHER
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    final isHODOrAdmin =
        authState is AuthAuthenticated &&
        (authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.superAdmin);

    // If assessmentId is present, prioritize canonical Assessment Roster flow
    if (widget.assessmentId != null && widget.assessmentId!.isNotEmpty) {
      final rosterAsync = ref.watch(
        assessmentRosterProvider(widget.assessmentId!),
      );

      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          backgroundColor: isDark
              ? AcadexColors.darkSurface
              : AcadexColors.surface,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            onPressed: () => context.safePop(fallbackRoute: '/my-assignments'),
          ),
          title: Text(
            'Marks Entry Register',
            style: AcadexTypography.title(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          actions: [
            if (!isHODOrAdmin)
              IconButton(
                tooltip: 'Create Historical Unit Test',
                icon: const Icon(LucideIcons.history, size: 18),
                onPressed: () => _handleCreateHistoricalAssessmentDialog(
                  prefillSectionId: widget.sectionId,
                  prefillSubjectId: widget.subjectId,
                  prefillFacultyAssignmentId: widget.facultyAssignmentId,
                  prefillAcademicYearId: widget.academicYearId,
                ),
              ),
            IconButton(
              tooltip: 'Refresh Roster',
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              onPressed: () {
                _isRosterInitialized = false;
                ref.invalidate(assessmentRosterProvider(widget.assessmentId!));
              },
            ),
          ],
        ),
        body: rosterAsync.when(
          loading: () => const AcadexLoadingState(
            message: 'Loading enrolled students marks roster...',
          ),
          error: (err, _) => Center(
            child: AcadexErrorState(
              message: err.toString(),
              retryLabel: 'Retry',
              onRetry: () {
                _isRosterInitialized = false;
                ref.invalidate(assessmentRosterProvider(widget.assessmentId!));
              },
            ),
          ),
          data: (rosterData) {
            _initRoster(rosterData);
            return _buildCanonicalRosterView(rosterData, isDark, isHODOrAdmin);
          },
        ),
      );
    }

    // Otherwise fallback to legacy context flow
    return _buildLegacyContextScaffold(isDark, isHODOrAdmin);
  }

  // ==========================================
  // CANONICAL ROSTER UI BUILDER
  // ==========================================

  Widget _buildCanonicalRosterView(
    MarksRosterResponseModel rosterData,
    bool isDark,
    bool isHODOrAdmin,
  ) {
    final isMobile = AcadexBreakpoints.isMobile(context);
    final assessment = rosterData.assessment;
    final summary = rosterData.summary;
    final title = assessment['title']?.toString() ?? 'Assessment';
    final statusStr = assessment['status']?.toString() ?? 'DRAFT';
    final status = InternalAssessmentStatus.fromValue(statusStr);
    final maxMarks = (assessment['maximumMarks'] as num?)?.toDouble() ?? 25.0;

    final subject = assessment['subjectId'] is Map
        ? assessment['subjectId'] as Map
        : {};
    final subjectName = subject['name']?.toString() ?? 'Subject';
    final subjectCode = subject['code']?.toString() ?? '';

    final section = assessment['sectionId'] is Map
        ? assessment['sectionId'] as Map
        : {};
    final sectionName = section['name']?.toString() ?? 'Section';

    final faculty = assessment['facultyId'] is Map
        ? assessment['facultyId'] as Map
        : {};
    final facultyName = faculty['name']?.toString() ?? 'Assigned Faculty';

    final schedule = assessment['schedule'] is Map
        ? assessment['schedule'] as Map
        : null;

    final isLocked =
        status == InternalAssessmentStatus.locked ||
        status == InternalAssessmentStatus.published ||
        status == InternalAssessmentStatus.closed;
    final isSubmitted = status == InternalAssessmentStatus.submitted;
    final isScheduled = status == InternalAssessmentStatus.scheduled;

    // Filter & Sort roster list
    final filteredRoster = rosterData.roster.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = item.studentName.toLowerCase();
      final roll = (item.rollNumber ?? '').toLowerCase();
      final adm = (item.admissionNumber ?? '').toLowerCase();
      return name.contains(q) || roll.contains(q) || adm.contains(q);
    }).toList();

    filteredRoster.sort((a, b) {
      int cmp = 0;
      if (_sortBy == 'rollNumber') {
        cmp = (a.rollNumber ?? '').compareTo(b.rollNumber ?? '');
      } else {
        cmp = a.studentName.compareTo(b.studentName);
      }
      return _sortAsc ? cmp : -cmp;
    });

    return AcadexPageContainer(
      maxWidth: 1400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Card with Academic Context and State Badge
          AcadexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AcadexColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AcadexRadius.xs,
                                  ),
                                ),
                                child: Text(
                                  subjectCode.isNotEmpty
                                      ? subjectCode
                                      : 'ASSESSMENT',
                                  style: const TextStyle(
                                    color: AcadexColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AcadexColors.darkSurfaceCard
                                      : AcadexColors.canvasSoft,
                                  borderRadius: BorderRadius.circular(
                                    AcadexRadius.xs,
                                  ),
                                ),
                                child: Text(
                                  sectionName.toLowerCase().startsWith(
                                        'section',
                                      )
                                      ? sectionName
                                      : 'Section $sectionName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AcadexColors.darkSurfaceCard
                                      : AcadexColors.canvasSoft,
                                  borderRadius: BorderRadius.circular(
                                    AcadexRadius.xs,
                                  ),
                                ),
                                child: Text(
                                  'Max: ${maxMarks.toInt()} Marks',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (_hasUnsavedChanges)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AcadexColors.accentOrange.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AcadexRadius.xs,
                                    ),
                                  ),
                                  child: const Text(
                                    '● Unsaved Changes',
                                    style: TextStyle(
                                      color: AcadexColors.accentOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if ((assessment['sourceType']?.toString() ??
                                      '') ==
                                  'HISTORICAL_MANUAL')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AcadexColors.warning.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AcadexRadius.xs,
                                    ),
                                    border: Border.all(
                                      color: AcadexColors.warning.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.history,
                                        size: 12,
                                        color: AcadexColors.warning,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'HISTORICAL UNIT TEST',
                                        style: TextStyle(
                                          color: AcadexColors.warning,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: AcadexTypography.heading2(
                              color: isDark
                                  ? AcadexColors.darkInk
                                  : AcadexColors.ink,
                            ),
                          ),
                          Text(
                            '$subjectName • Assigned Faculty: $facultyName',
                            style: AcadexTypography.caption(
                              color: isDark
                                  ? AcadexColors.darkInkMuted
                                  : AcadexColors.inkMuted,
                            ),
                          ),
                          if (assessment['assessmentDate'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Exam Date: ${DateTime.tryParse(assessment['assessmentDate'].toString())?.toLocal().toString().split(' ')[0] ?? assessment['assessmentDate']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (schedule != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Scheduled: ${schedule['dateString'] ?? ''} (${schedule['startTime'] ?? ''} - ${schedule['endTime'] ?? ''})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusPill(status),
                  ],
                ),

                // Review banner if user is HOD/Admin
                if (isHODOrAdmin) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AcadexColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AcadexRadius.xs),
                      border: Border.all(
                        color: AcadexColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.shieldAlert,
                          size: 16,
                          color: AcadexColors.info,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Administrative Review Mode: Marks are owned by teaching faculty ($facultyName). Editing is restricted.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AcadexColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Action Bar
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Exam completion action if scheduled
                    if (isScheduled && !isHODOrAdmin)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AcadexColors.accentPurple,
                        ),
                        onPressed: _isSaving ? null : _handleCompleteAssessment,
                        icon: const Icon(
                          LucideIcons.checkCircle2,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Complete Exam & Open Entry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                    // Faculty Editing buttons (only if not locked, not submitted, and not HOD/Admin)
                    if (!isLocked && !isSubmitted && !isHODOrAdmin) ...[
                      OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _handleSaveRosterDraft(rosterData),
                        icon: const Icon(LucideIcons.save, size: 16),
                        label: const Text('Save Draft'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AcadexColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => _handleSubmitRoster(rosterData),
                        icon: const Icon(LucideIcons.send, size: 16),
                        label: const Text('Submit Marks'),
                      ),
                    ],

                    if (!isHODOrAdmin)
                      OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _handleCreateHistoricalAssessmentDialog(
                                prefillSectionId:
                                    (assessment['sectionId'] is Map
                                            ? assessment['sectionId']['_id'] ??
                                                  assessment['sectionId']['id']
                                            : assessment['sectionId'])
                                        ?.toString(),
                                prefillSubjectId:
                                    (assessment['subjectId'] is Map
                                            ? assessment['subjectId']['_id'] ??
                                                  assessment['subjectId']['id']
                                            : assessment['subjectId'])
                                        ?.toString(),
                                prefillFacultyAssignmentId:
                                    (assessment['facultyAssignmentId'] is Map
                                            ? assessment['facultyAssignmentId']['_id'] ??
                                                  assessment['facultyAssignmentId']['id']
                                            : assessment['facultyAssignmentId'])
                                        ?.toString(),
                                prefillAcademicYearId:
                                    (assessment['academicYearId'] is Map
                                            ? assessment['academicYearId']['_id'] ??
                                                  assessment['academicYearId']['id']
                                            : assessment['academicYearId'])
                                        ?.toString(),
                              ),
                        icon: const Icon(LucideIcons.history, size: 16),
                        label: const Text('+ Historical Unit Test'),
                      ),

                    // Locked / Submitted state indicator & Correction Request
                    if (isLocked || isSubmitted) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.lock,
                            size: 16,
                            color: AcadexColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSubmitted
                                ? 'Marks submitted (Read-only)'
                                : 'Assessment locked against direct edits',
                            style: AcadexTypography.body(
                              color: AcadexColors.success,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AcadexColors.accentOrange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => _handleRequestCorrectionDialog(rosterData),
                        icon: const Icon(LucideIcons.filePenLine, size: 16),
                        label: const Text('Request Correction'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Summary Statistics Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatPill(
                  'Total Enrolled',
                  '${summary.totalStudents}',
                  LucideIcons.users,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'Entered',
                  '${summary.enteredCount}',
                  LucideIcons.check,
                  isDark,
                  color: AcadexColors.primary,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'Present',
                  '${summary.presentCount}',
                  LucideIcons.userCheck,
                  isDark,
                  color: AcadexColors.success,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'Absent',
                  '${summary.absentCount}',
                  LucideIcons.userX,
                  isDark,
                  color: AcadexColors.accentOrange,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'Exempted',
                  '${summary.exemptedCount}',
                  LucideIcons.shieldCheck,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'Not Appeared',
                  '${summary.notAppearedCount}',
                  LucideIcons.clock,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'Unresolved',
                  '${summary.unresolvedCount}',
                  LucideIcons.alertCircle,
                  isDark,
                  color: summary.unresolvedCount > 0
                      ? AcadexColors.error
                      : AcadexColors.inkMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Search and Sort Toolbar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by student name, roll number...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? AcadexColors.darkSurfaceCard
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AcadexRadius.xs),
                        borderSide: BorderSide(
                          color: isDark
                              ? AcadexColors.darkHairline
                              : AcadexColors.hairline,
                        ),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Sort Roster',
                onSelected: (val) {
                  setState(() {
                    if (_sortBy == val) {
                      _sortAsc = !_sortAsc;
                    } else {
                      _sortBy = val;
                      _sortAsc = true;
                    }
                  });
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(AcadexRadius.xs),
                    border: Border.all(
                      color: isDark
                          ? AcadexColors.darkHairline
                          : AcadexColors.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.arrowUpDown, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _sortBy == 'rollNumber'
                            ? 'Sort: Roll No.'
                            : 'Sort: Name',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _sortAsc ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                        size: 14,
                        color: AcadexColors.inkMuted,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rollNumber',
                    child: Text('Roll Number'),
                  ),
                  const PopupMenuItem(
                    value: 'studentName',
                    child: Text('Student Name'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Roster List / Table
          if (filteredRoster.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: AcadexEmptyState(
                  title: 'No Matching Students',
                  subtitle:
                      'No student enrolled in this section matches your search criteria.',
                  icon: LucideIcons.users,
                ),
              ),
            )
          else if (isMobile)
            _buildCanonicalMobileList(
              filteredRoster,
              isDark,
              isLocked || isSubmitted || isHODOrAdmin,
              maxMarks,
            )
          else
            _buildCanonicalDesktopTable(
              filteredRoster,
              isDark,
              isLocked || isSubmitted || isHODOrAdmin,
              maxMarks,
            ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(AcadexRadius.xs),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                color ??
                (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color:
                  color ?? (isDark ? AcadexColors.darkInk : AcadexColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanonicalDesktopTable(
    List<MarksRosterItemModel> roster,
    bool isDark,
    bool isReadOnly,
    double maxMarks,
  ) {
    return AcadexCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(
                    isDark
                        ? AcadexColors.darkSurfaceCard
                        : AcadexColors.canvasSoft,
                  ),
                  columns: [
                    const DataColumn(
                      label: Text(
                        'Roll No.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        'Student Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Marks (Max: ${maxMarks.toInt()})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        'Remarks',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: roster.asMap().entries.map((entryIndex) {
                    final index = entryIndex.key;
                    final item = entryIndex.value;
                    final enrollmentId = item.studentEnrollmentId;
                    final markCtrl = _marksControllers[enrollmentId];
                    final remarksCtrl = _remarksControllers[enrollmentId];
                    final currentStatus =
                        _statuses[enrollmentId] ?? StudentMarkStatus.notEntered;
                    final focusNode = _focusNodes[enrollmentId];

                    // Check for invalid mark in local state
                    final markText = markCtrl?.text.trim() ?? '';
                    final markNum = double.tryParse(markText);
                    final isInvalid =
                        currentStatus == StudentMarkStatus.present &&
                        markText.isNotEmpty &&
                        (markNum == null || markNum < 0 || markNum > maxMarks);

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item.rollNumber ?? '—',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (item.admissionNumber != null)
                                Text(
                                  item.admissionNumber!,
                                  style: AcadexTypography.caption(
                                    color: isDark
                                        ? AcadexColors.darkInkMuted
                                        : AcadexColors.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(
                          _buildStatusSelector(
                            currentStatus: currentStatus,
                            isReadOnly: isReadOnly,
                            onChanged: (newStatus) =>
                                _onStatusChanged(enrollmentId, newStatus),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: markCtrl,
                              focusNode: focusNode,
                              enabled:
                                  !isReadOnly &&
                                  currentStatus == StudentMarkStatus.present,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              textInputAction: index < roster.length - 1
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (index < roster.length - 1) {
                                  _focusNodes[roster[index + 1]
                                          .studentEnrollmentId]
                                      ?.requestFocus();
                                }
                              },
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isInvalid
                                    ? AcadexColors.error
                                    : (isDark
                                          ? AcadexColors.darkInk
                                          : AcadexColors.ink),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor:
                                    isReadOnly ||
                                        currentStatus !=
                                            StudentMarkStatus.present
                                    ? (isDark
                                          ? Colors.black12
                                          : Colors.grey.shade100)
                                    : (isDark
                                          ? AcadexColors.darkSurfaceCard
                                          : Colors.white),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AcadexRadius.xs,
                                  ),
                                  borderSide: BorderSide(
                                    color: isInvalid
                                        ? AcadexColors.error
                                        : (isDark
                                              ? AcadexColors.darkHairline
                                              : AcadexColors.hairline),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AcadexRadius.xs,
                                  ),
                                  borderSide: BorderSide(
                                    color: isInvalid
                                        ? AcadexColors.error
                                        : (isDark
                                              ? AcadexColors.darkHairline
                                              : AcadexColors.hairline),
                                  ),
                                ),
                              ),
                              onChanged: (_) =>
                                  setState(() => _hasUnsavedChanges = true),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 160,
                            child: TextFormField(
                              controller: remarksCtrl,
                              enabled: !isReadOnly,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                hintText: 'Optional remark',
                                filled: true,
                                fillColor: isReadOnly
                                    ? (isDark
                                          ? Colors.black12
                                          : Colors.grey.shade100)
                                    : (isDark
                                          ? AcadexColors.darkSurfaceCard
                                          : Colors.white),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AcadexRadius.xs,
                                  ),
                                ),
                              ),
                              onChanged: (_) =>
                                  setState(() => _hasUnsavedChanges = true),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCanonicalMobileList(
    List<MarksRosterItemModel> roster,
    bool isDark,
    bool isReadOnly,
    double maxMarks,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: roster.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = roster[index];
        final enrollmentId = item.studentEnrollmentId;
        final markCtrl = _marksControllers[enrollmentId];
        final remarksCtrl = _remarksControllers[enrollmentId];
        final currentStatus =
            _statuses[enrollmentId] ?? StudentMarkStatus.notEntered;

        final markText = markCtrl?.text.trim() ?? '';
        final markNum = double.tryParse(markText);
        final isInvalid =
            currentStatus == StudentMarkStatus.present &&
            markText.isNotEmpty &&
            (markNum == null || markNum < 0 || markNum > maxMarks);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(
              color: isInvalid
                  ? AcadexColors.error
                  : (isDark
                        ? AcadexColors.darkHairline
                        : AcadexColors.hairline),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.studentName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark
                                ? AcadexColors.darkInk
                                : AcadexColors.ink,
                          ),
                        ),
                        Text(
                          item.rollNumber != null
                              ? 'Roll: ${item.rollNumber}'
                              : 'Roll: —',
                          style: AcadexTypography.caption(
                            color: isDark
                                ? AcadexColors.darkInkMuted
                                : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusSelector(
                    currentStatus: currentStatus,
                    isReadOnly: isReadOnly,
                    onChanged: (newStatus) =>
                        _onStatusChanged(enrollmentId, newStatus),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Marks: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    height: 38,
                    child: TextFormField(
                      controller: markCtrl,
                      enabled:
                          !isReadOnly &&
                          currentStatus == StudentMarkStatus.present,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isInvalid
                            ? AcadexColors.error
                            : (isDark
                                  ? AcadexColors.darkInk
                                  : AcadexColors.ink),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor:
                            isReadOnly ||
                                currentStatus != StudentMarkStatus.present
                            ? (isDark ? Colors.black12 : Colors.grey.shade100)
                            : (isDark
                                  ? AcadexColors.darkSurface
                                  : Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AcadexRadius.xs),
                        ),
                      ),
                      onChanged: (_) =>
                          setState(() => _hasUnsavedChanges = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/ ${maxMarks.toInt()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 38,
                      child: TextFormField(
                        controller: remarksCtrl,
                        enabled: !isReadOnly,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Remarks',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: isReadOnly
                              ? (isDark ? Colors.black12 : Colors.grey.shade100)
                              : (isDark
                                    ? AcadexColors.darkSurface
                                    : Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AcadexRadius.xs,
                            ),
                          ),
                        ),
                        onChanged: (_) =>
                            setState(() => _hasUnsavedChanges = true),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusSelector({
    required StudentMarkStatus currentStatus,
    required bool isReadOnly,
    required ValueChanged<StudentMarkStatus> onChanged,
  }) {
    if (isReadOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(currentStatus).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AcadexRadius.xs),
        ),
        child: Text(
          currentStatus.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(currentStatus),
          ),
        ),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<StudentMarkStatus>(
        value: currentStatus == StudentMarkStatus.notEntered
            ? StudentMarkStatus.present
            : currentStatus,
        isDense: true,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        items: const [
          DropdownMenuItem(
            value: StudentMarkStatus.present,
            child: Text(
              'Present',
              style: TextStyle(color: AcadexColors.success),
            ),
          ),
          DropdownMenuItem(
            value: StudentMarkStatus.absent,
            child: Text(
              'Absent',
              style: TextStyle(color: AcadexColors.accentOrange),
            ),
          ),
          DropdownMenuItem(
            value: StudentMarkStatus.exempted,
            child: Text(
              'Exempted',
              style: TextStyle(color: AcadexColors.accentPurple),
            ),
          ),
          DropdownMenuItem(
            value: StudentMarkStatus.notAppeared,
            child: Text(
              'Not Appeared',
              style: TextStyle(color: AcadexColors.inkMuted),
            ),
          ),
        ],
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Color _getStatusColor(StudentMarkStatus status) {
    switch (status) {
      case StudentMarkStatus.present:
      case StudentMarkStatus.entered:
        return AcadexColors.success;
      case StudentMarkStatus.absent:
        return AcadexColors.accentOrange;
      case StudentMarkStatus.exempted:
        return AcadexColors.accentPurple;
      case StudentMarkStatus.notAppeared:
      case StudentMarkStatus.notEntered:
      case StudentMarkStatus.excused:
        return AcadexColors.inkMuted;
    }
  }

  // ==========================================
  // LEGACY CONTEXT SCAFFOLD
  // ==========================================

  Widget _buildLegacyContextScaffold(bool isDark, bool isHODOrAdmin) {
    final contextAsync = ref.watch(assessmentContextProvider(_params));
    final isMobile = AcadexBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark
            ? AcadexColors.darkSurface
            : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.safePop(fallbackRoute: '/my-assignments'),
        ),
        title: Text(
          'Internal Assessment',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        actions: [
          if (!isHODOrAdmin)
            IconButton(
              tooltip: 'Enter Historical Unit Test Marks',
              icon: const Icon(LucideIcons.history, size: 18),
              onPressed: () => _handleCreateHistoricalAssessmentDialog(
                prefillSectionId: widget.sectionId,
                prefillSubjectId: widget.subjectId,
                prefillFacultyAssignmentId: widget.facultyAssignmentId,
                prefillAcademicYearId: widget.academicYearId,
              ),
            ),
          IconButton(
            tooltip: 'Refresh Context',
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () {
              _isLegacyInitialized = false;
              ref.invalidate(assessmentContextProvider(_params));
            },
          ),
        ],
      ),
      body: contextAsync.when(
        loading: () => const AcadexLoadingState(
          message: 'Loading assessment roster and configuration...',
        ),
        error: (err, _) => Center(
          child: AcadexErrorState(
            message: err.toString(),
            retryLabel: 'Retry',
            onRetry: () => ref.refresh(assessmentContextProvider(_params)),
          ),
        ),
        data: (data) {
          _initLegacyControllers(data);
          final assessment = data.assessment;
          final isLocked = data.isLocked;
          final entries = assessment?.entries ?? [];
          final subjectName = data.subject['name']?.toString() ?? 'Subject';
          final subjectCode = data.subject['code']?.toString() ?? '';
          final sectionName = data.section['name']?.toString() ?? 'Section';

          return AcadexPageContainer(
            maxWidth: 1400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcadexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AcadexColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AcadexRadius.xs,
                                        ),
                                      ),
                                      child: Text(
                                        subjectCode.isNotEmpty
                                            ? subjectCode
                                            : 'SUBJECT',
                                        style: const TextStyle(
                                          color: AcadexColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AcadexColors.darkSurfaceCard
                                            : AcadexColors.canvasSoft,
                                        borderRadius: BorderRadius.circular(
                                          AcadexRadius.xs,
                                        ),
                                      ),
                                      child: Text(
                                        sectionName.toLowerCase().startsWith(
                                              'section',
                                            )
                                            ? sectionName
                                            : 'Section $sectionName',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subjectName,
                                  style: AcadexTypography.heading2(
                                    color: isDark
                                        ? AcadexColors.darkInk
                                        : AcadexColors.ink,
                                  ),
                                ),
                                if (data.facultyAssignment?['facultyName'] !=
                                    null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Teaching Faculty: ${data.facultyAssignment!['facultyName']}',
                                      style: AcadexTypography.caption(
                                        color: isDark
                                            ? AcadexColors.darkInkMuted
                                            : AcadexColors.inkMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _buildStatusPill(
                            assessment?.status ??
                                InternalAssessmentStatus.draft,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!isLocked) ...[
                            OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _handleSaveLegacyDraft(data),
                              icon: const Icon(LucideIcons.save, size: 16),
                              label: const Text('Save Draft'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _handleReviewLegacyMarks(data),
                              icon: const Icon(
                                LucideIcons.checkSquare,
                                size: 16,
                              ),
                              label: const Text('Mark as Reviewed'),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcadexColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isSaving
                                  ? null
                                  : () => _handlePublishLegacyMarks(data),
                              icon: const Icon(LucideIcons.lock, size: 16),
                              label: const Text('Finalize & Publish'),
                            ),
                          ],

                          if (!isHODOrAdmin)
                            OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () =>
                                        _handleCreateHistoricalAssessmentDialog(
                                          prefillSectionId:
                                              widget.sectionId ??
                                              data.section['id']?.toString() ??
                                              data.section['_id']?.toString(),
                                          prefillSubjectId:
                                              widget.subjectId ??
                                              data.subject['id']?.toString() ??
                                              data.subject['_id']?.toString(),
                                          prefillFacultyAssignmentId:
                                              widget.facultyAssignmentId ??
                                              data.facultyAssignment?['id']
                                                  ?.toString() ??
                                              data.facultyAssignment?['_id']
                                                  ?.toString(),
                                          prefillAcademicYearId:
                                              widget.academicYearId,
                                        ),
                              icon: const Icon(LucideIcons.history, size: 16),
                              label: const Text(
                                '+ Enter Historical Unit Test Marks',
                              ),
                            ),
                          if (isLocked) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.lock,
                                  size: 16,
                                  color: AcadexColors.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Assessment marks finalized and locked.',
                                  style: AcadexTypography.body(
                                    color: AcadexColors.success,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: AcadexEmptyState(
                        title: 'No Students Enrolled',
                        subtitle:
                            'No active student enrollments were found for this section.',
                        icon: LucideIcons.users,
                      ),
                    ),
                  )
                else if (isMobile)
                  _buildLegacyMobileView(data, isDark, isLocked)
                else
                  _buildLegacyDesktopView(data, isDark, isLocked),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegacyDesktopView(
    AssessmentContextModel data,
    bool isDark,
    bool isLocked,
  ) {
    final entries = data.assessment?.entries ?? [];
    final components = data.components;

    return AcadexCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(
                    isDark
                        ? AcadexColors.darkSurfaceCard
                        : AcadexColors.canvasSoft,
                  ),
                  columns: [
                    const DataColumn(
                      label: Text(
                        'Roll No.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        'Student Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    for (final comp in components)
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comp.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Max: ${comp.maxMarks.toInt()}',
                              style: const TextStyle(
                                color: AcadexColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const DataColumn(
                      label: Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AcadexColors.success,
                        ),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        'Remarks',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: entries.map((entry) {
                    final sMap = _legacyControllers[entry.studentId] ?? {};
                    final total =
                        _legacyStudentTotals[entry.studentId] ??
                        entry.totalMarks;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            entry.rollNumber ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DataCell(
                          Text(
                            entry.studentName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        for (final comp in components)
                          DataCell(
                            SizedBox(
                              width: 72,
                              child: TextFormField(
                                controller: sMap[comp.key],
                                enabled: !isLocked,
                                keyboardType:
                                    const TextInputKeybTypeWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: isLocked
                                      ? (isDark
                                            ? Colors.black12
                                            : Colors.grey.shade100)
                                      : (isDark
                                            ? AcadexColors.darkSurfaceCard
                                            : Colors.white),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AcadexRadius.xs,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => _recalculateLegacyTotal(
                                  entry.studentId,
                                  components,
                                ),
                              ),
                            ),
                          ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AcadexColors.success.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(
                                AcadexRadius.xs,
                              ),
                            ),
                            child: Text(
                              total % 1 == 0
                                  ? total.toInt().toString()
                                  : total.toString(),
                              style: const TextStyle(
                                color: AcadexColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: TextFormField(
                              controller:
                                  _legacyRemarksControllers[entry.studentId],
                              enabled: !isLocked,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                hintText: 'Optional',
                                filled: true,
                                fillColor: isLocked
                                    ? (isDark
                                          ? Colors.black12
                                          : Colors.grey.shade100)
                                    : (isDark
                                          ? AcadexColors.darkSurfaceCard
                                          : Colors.white),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AcadexRadius.xs,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegacyMobileView(
    AssessmentContextModel data,
    bool isDark,
    bool isLocked,
  ) {
    final components = data.components;
    final entries = data.assessment?.entries ?? [];
    if (components.isEmpty) {
      return const AcadexEmptyState(
        title: 'No Assessment Components',
        subtitle: 'No assessment components have been configured.',
        icon: LucideIcons.layers,
      );
    }

    final activeCompKey = _activeMobileComponentKey ?? components.first.key;
    final activeComp = components.firstWhere(
      (c) => c.key == activeCompKey,
      orElse: () => components.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: components.map((comp) {
              final isSelected = comp.key == activeCompKey;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${comp.name} (Max: ${comp.maxMarks.toInt()})'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected)
                      setState(() => _activeMobileComponentKey = comp.key);
                  },
                  selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AcadexColors.primary
                        : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final sMap = _legacyControllers[entry.studentId] ?? {};
            final ctrl = sMap[activeComp.key];
            final total =
                _legacyStudentTotals[entry.studentId] ?? entry.totalMarks;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AcadexColors.darkSurfaceCard
                    : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : AcadexColors.hairline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.studentName,
                          style: AcadexTypography.body(
                            color: isDark
                                ? AcadexColors.darkInk
                                : AcadexColors.ink,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${entry.rollNumber ?? 'Roll —'} • Total: ${total % 1 == 0 ? total.toInt().toString() : total.toString()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AcadexColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    height: 44,
                    child: TextFormField(
                      controller: ctrl,
                      enabled: !isLocked,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: isLocked
                            ? (isDark ? Colors.black12 : Colors.grey.shade100)
                            : (isDark
                                  ? AcadexColors.darkSurface
                                  : Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AcadexRadius.xs),
                        ),
                      ),
                      onChanged: (_) =>
                          _recalculateLegacyTotal(entry.studentId, components),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${activeComp.maxMarks.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusPill(InternalAssessmentStatus status) {
    switch (status) {
      case InternalAssessmentStatus.published:
        return const AcadexBadge(
          label: 'Published & Locked',
          variant: AcadexBadgeVariant.success,
        );
      case InternalAssessmentStatus.closed:
        return const AcadexBadge(
          label: 'Closed & Locked',
          variant: AcadexBadgeVariant.neutral,
        );
      case InternalAssessmentStatus.reviewed:
        return const AcadexBadge(
          label: 'Reviewed',
          variant: AcadexBadgeVariant.info,
        );
      case InternalAssessmentStatus.open:
        return const AcadexBadge(
          label: 'Open for Entry',
          variant: AcadexBadgeVariant.info,
        );
      case InternalAssessmentStatus.marksEntry:
        return const AcadexBadge(
          label: 'Marks Entry Open',
          variant: AcadexBadgeVariant.info,
        );
      case InternalAssessmentStatus.submitted:
        return const AcadexBadge(
          label: 'Submitted',
          variant: AcadexBadgeVariant.warning,
        );
      case InternalAssessmentStatus.completed:
        return const AcadexBadge(
          label: 'Exam Completed',
          variant: AcadexBadgeVariant.info,
        );
      case InternalAssessmentStatus.scheduled:
        return const AcadexBadge(
          label: 'Scheduled',
          variant: AcadexBadgeVariant.info,
        );
      case InternalAssessmentStatus.locked:
        return const AcadexBadge(
          label: 'Locked',
          variant: AcadexBadgeVariant.neutral,
        );
      case InternalAssessmentStatus.archived:
        return const AcadexBadge(
          label: 'Archived',
          variant: AcadexBadgeVariant.neutral,
        );
      case InternalAssessmentStatus.draft:
        return const AcadexBadge(
          label: 'Draft',
          variant: AcadexBadgeVariant.warning,
        );
    }
  }
}

class TextInputKeybTypeWithOptions extends TextInputType {
  const TextInputKeybTypeWithOptions({bool decimal = false})
    : super.numberWithOptions(decimal: decimal, signed: false);
}

class MathUtils {
  static double round1(double value) => (value * 10).round() / 10;
}
