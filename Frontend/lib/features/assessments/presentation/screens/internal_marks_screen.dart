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
  final String sectionId;
  final String subjectId;
  final String? academicYearId;

  const InternalMarksScreen({
    super.key,
    required this.sectionId,
    required this.subjectId,
    this.academicYearId,
  });

  @override
  ConsumerState<InternalMarksScreen> createState() => _InternalMarksScreenState();
}

class _InternalMarksScreenState extends ConsumerState<InternalMarksScreen> {
  // Local state for editing marks: studentId -> (componentKey -> TextEditingController)
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, double> _studentTotals = {};
  final Map<String, StudentMarkStatus> _studentStatuses = {};
  String? _activeMobileComponentKey;
  bool _isSaving = false;
  bool _isInitialized = false;

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
    for (final map in _controllers.values) {
      for (final ctrl in map.values) {
        ctrl.dispose();
      }
    }
    for (final ctrl in _remarksControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _initControllers(AssessmentContextModel contextData) {
    if (_isInitialized) return;
    final assessment = contextData.assessment;
    if (assessment == null) return;

    for (final entry in assessment.entries) {
      final sMap = <String, TextEditingController>{};
      double total = 0;

      for (final comp in contextData.components) {
        final val = entry.componentMarks[comp.key];
        final text = val != null ? (val % 1 == 0 ? val.toInt().toString() : val.toString()) : '';
        final ctrl = TextEditingController(text: text);
        sMap[comp.key] = ctrl;
        if (val != null) total += val;
      }
      _controllers[entry.studentId] = sMap;
      _remarksControllers[entry.studentId] = TextEditingController(text: entry.remarks ?? '');
      _studentTotals[entry.studentId] = total;
      _studentStatuses[entry.studentId] = entry.status;
    }
    if (_activeMobileComponentKey == null && contextData.components.isNotEmpty) {
      _activeMobileComponentKey = contextData.components.first.key;
    }
    _isInitialized = true;
  }

  void _recalculateStudentTotal(String studentId, List<AssessmentComponentModel> comps) {
    final sMap = _controllers[studentId];
    if (sMap == null) return;

    double sum = 0;
    for (final comp in comps) {
      final ctrl = sMap[comp.key];
      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
        final val = double.tryParse(ctrl.text.trim());
        if (val != null && val >= 0) {
          sum += val;
        }
      }
    }
    setState(() {
      _studentTotals[studentId] = MathUtils.round1(sum);
    });
  }

  List<StudentAssessmentEntryModel> _buildEntriesFromControllers(AssessmentContextModel data) {
    final entries = <StudentAssessmentEntryModel>[];
    final originalEntries = data.assessment?.entries ?? [];
    final originalMap = {for (final e in originalEntries) e.studentId: e};

    for (final sEntry in _controllers.entries) {
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
          status: _studentStatuses[sId] ?? (marks.values.any((m) => m != null) ? StudentMarkStatus.entered : StudentMarkStatus.notEntered),
          remarks: _remarksControllers[sId]?.text.trim(),
        ),
      );
    }
    return entries;
  }

  bool _validateAllMarks(List<AssessmentComponentModel> comps) {
    final compMap = {for (final c in comps) c.key: c};
    for (final sEntry in _controllers.entries) {
      for (final cEntry in sEntry.value.entries) {
        final text = cEntry.value.text.trim();
        if (text.isNotEmpty) {
          final val = double.tryParse(text);
          if (val == null || val < 0) {
            _showToast('Invalid negative or non-numeric mark entered.', isError: true);
            return false;
          }
          final comp = compMap[cEntry.key];
          if (comp != null && val > comp.maxMarks) {
            _showToast(
              'Mark $val for ${comp.name} exceeds max allowed (${comp.maxMarks.toInt()}).',
              isError: true,
            );
            return false;
          }
        }
      }
    }
    return true;
  }

  Future<void> _handleSaveDraft(AssessmentContextModel data) async {
    if (!_validateAllMarks(data.components)) return;

    setState(() => _isSaving = true);
    try {
      final entries = _buildEntriesFromControllers(data);
      await ref.read(assessmentRepositoryProvider).saveDraftMarks(
            sectionId: widget.sectionId,
            subjectId: widget.subjectId,
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

  Future<void> _handleReviewMarks(AssessmentContextModel data) async {
    if (!_validateAllMarks(data.components)) return;

    setState(() => _isSaving = true);
    try {
      final entries = _buildEntriesFromControllers(data);
      await ref.read(assessmentRepositoryProvider).saveDraftMarks(
            sectionId: widget.sectionId,
            subjectId: widget.subjectId,
            entries: entries,
          );

      await ref.read(assessmentRepositoryProvider).reviewMarks(
            sectionId: widget.sectionId,
            subjectId: widget.subjectId,
          );

      _showToast('Assessment marked as reviewed.');
      ref.invalidate(assessmentContextProvider(_params));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePublishMarks(AssessmentContextModel data) async {
    if (!_validateAllMarks(data.components)) return;

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
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publish & Lock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      // Save any pending edits first
      final entries = _buildEntriesFromControllers(data);
      await ref.read(assessmentRepositoryProvider).saveDraftMarks(
            sectionId: widget.sectionId,
            subjectId: widget.subjectId,
            entries: entries,
          );

      await ref.read(assessmentRepositoryProvider).publishMarks(
            sectionId: widget.sectionId,
            subjectId: widget.subjectId,
          );

      _showToast('Internal marks finalized, locked, and published.');
      ref.invalidate(assessmentContextProvider(_params));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleUnlockMarks() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock Assessment Marks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the administrative reason for unlocking these published marks. This reason will be recorded in the audit trail.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Revision',
                hintText: 'e.g. Approved re-evaluation request for Section A',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.accentOrange),
            onPressed: () {
              if (reasonController.text.trim().length < 5) {
                _showToast('Please enter a valid reason (at least 5 characters).', isError: true);
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Unlock for Editing', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(assessmentRepositoryProvider).unlockMarks(
            sectionId: widget.sectionId,
            subjectId: widget.subjectId,
            reason: reasonController.text.trim(),
          );

      _showToast('Assessment unlocked for editing.');
      ref.invalidate(assessmentContextProvider(_params));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSyncLab() async {
    setState(() => _isSaving = true);
    try {
      final res = await ref.read(assessmentRepositoryProvider).syncLabScores(
            sectionId: widget.sectionId,
            subjectId: widget.subjectId,
          );
      _showToast(res['message']?.toString() ?? 'Lab scores synced successfully.');
      _isInitialized = false;
      ref.invalidate(assessmentContextProvider(_params));
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final contextAsync = ref.watch(assessmentContextProvider(_params));
    final authState = ref.watch(authProvider);

    final isHODOrAdmin = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.superAdmin);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/my-assignments'),
        ),
        title: Text(
          'Internal Assessment',
          style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Context',
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () {
              _isInitialized = false;
              ref.invalidate(assessmentContextProvider(_params));
            },
          ),
        ],
      ),
      body: contextAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading assessment roster and configuration...'),
        error: (err, _) => Center(
          child: AcadexErrorState(
            message: err.toString(),
            retryLabel: 'Retry',
            onRetry: () => ref.refresh(assessmentContextProvider(_params)),
          ),
        ),
        data: (data) {
          _initControllers(data);
          final assessment = data.assessment;
          final isLocked = data.isLocked;
          final entries = assessment?.entries ?? [];
          final components = data.components;
          final subjectName = data.subject['name']?.toString() ?? 'Subject';
          final subjectCode = data.subject['code']?.toString() ?? '';
          final sectionName = data.section['name']?.toString() ?? 'Section';
          final isPractical = (data.subject['type']?.toString().toLowerCase().contains('lab') ?? false) ||
              (data.subject['type']?.toString().toLowerCase().contains('practical') ?? false);

          return AcadexPageContainer(
            maxWidth: 1400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Card with Context & Status Badge
                AcadexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMobile) ...[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AcadexColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                  ),
                                  child: Text(
                                    subjectCode.isNotEmpty ? subjectCode : 'SUBJECT',
                                    style: const TextStyle(
                                      color: AcadexColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                                    borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                  ),
                                  child: Text(
                                    sectionName.toLowerCase().startsWith('section') ? sectionName : 'Section $sectionName',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            _buildStatusPill(assessment?.status ?? InternalAssessmentStatus.draft),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subjectName,
                          style: AcadexTypography.heading2(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                        ),
                        if (data.facultyAssignment?['facultyName'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Teaching Faculty: ${data.facultyAssignment!['facultyName']}',
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                          ),
                      ] else ...[
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AcadexColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                        ),
                                        child: Text(
                                          subjectCode.isNotEmpty ? subjectCode : 'SUBJECT',
                                          style: const TextStyle(
                                            color: AcadexColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                                          borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                        ),
                                        child: Text(
                                          sectionName.toLowerCase().startsWith('section') ? sectionName : 'Section $sectionName',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subjectName,
                                    style: AcadexTypography.heading2(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                  ),
                                  if (data.facultyAssignment?['facultyName'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Teaching Faculty: ${data.facultyAssignment!['facultyName']}',
                                        style: AcadexTypography.caption(
                                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Lifecycle Status Pill
                            _buildStatusPill(assessment?.status ?? InternalAssessmentStatus.draft),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Action buttons bar
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!isLocked) ...[
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : () => _handleSaveDraft(data),
                              icon: const Icon(LucideIcons.save, size: 16),
                              label: const Text('Save Draft'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : () => _handleReviewMarks(data),
                              icon: const Icon(LucideIcons.checkSquare, size: 16),
                              label: const Text('Mark as Reviewed'),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcadexColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isSaving ? null : () => _handlePublishMarks(data),
                              icon: const Icon(LucideIcons.lock, size: 16),
                              label: const Text('Finalize & Publish'),
                            ),
                            if (isPractical)
                              OutlinedButton.icon(
                                onPressed: _isSaving ? null : () => _handleSyncLab(),
                                icon: const Icon(LucideIcons.flaskConical, size: 16, color: AcadexColors.accentPurple),
                                label: const Text('Sync Lab Scores'),
                              ),
                          ] else ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.lock, size: 16, color: AcadexColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'Assessment marks finalized and locked.',
                                  style: AcadexTypography.body(color: AcadexColors.success).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (isHODOrAdmin)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AcadexColors.accentOrange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isSaving ? null : () => _handleUnlockMarks(),
                                icon: const Icon(LucideIcons.unlock, size: 16),
                                label: const Text('Unlock for Revisions'),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Marks Entry Matrix
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: AcadexEmptyState(
                        title: 'No Students Enrolled',
                        subtitle: 'No active student enrollments were found for this section.',
                        icon: LucideIcons.users,
                      ),
                    ),
                  )
                else if (isMobile)
                  _buildMobileMarksView(data, isDark, isLocked)
                else
                  AcadexCard(
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
                                      isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
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
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                      final sMap = _controllers[entry.studentId] ?? {};
                                      final total = _studentTotals[entry.studentId] ?? entry.totalMarks;

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
                                                  keyboardType: const TextInputKeybTypeWithOptions(decimal: true),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                    filled: true,
                                                    fillColor: isLocked
                                                        ? (isDark ? Colors.black12 : Colors.grey.shade100)
                                                        : (isDark ? AcadexColors.darkSurfaceCard : Colors.white),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                                    ),
                                                  ),
                                                  onChanged: (_) => _recalculateStudentTotal(entry.studentId, components),
                                                ),
                                              ),
                                            ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AcadexColors.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                              ),
                                              child: Text(
                                                total % 1 == 0 ? total.toInt().toString() : total.toString(),
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
                                                controller: _remarksControllers[entry.studentId],
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
                                                      ? (isDark ? Colors.black12 : Colors.grey.shade100)
                                                      : (isDark ? AcadexColors.darkSurfaceCard : Colors.white),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(AcadexRadius.xs),
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
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileMarksView(
    AssessmentContextModel data,
    bool isDark,
    bool isLocked,
  ) {
    final components = data.components;
    final entries = data.assessment?.entries ?? [];
    if (components.isEmpty) {
      return const AcadexEmptyState(
        title: 'No Assessment Components',
        subtitle: 'No assessment components (assignments, midterms) have been configured.',
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
        // Component selector chips
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
                    if (selected) setState(() => _activeMobileComponentKey = comp.key);
                  },
                  selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Component title & max marks indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                activeComp.name,
                style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Max: ${activeComp.maxMarks.toInt()}',
                style: const TextStyle(
                  color: AcadexColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of student cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final sMap = _controllers[entry.studentId] ?? {};
            final ctrl = sMap[activeComp.key];
            final total = _studentTotals[entry.studentId] ?? entry.totalMarks;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
                boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
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
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              entry.rollNumber ?? 'Roll —',
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                            Text(
                              '• Total: ${total % 1 == 0 ? total.toInt().toString() : total.toString()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AcadexColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Marks input
                  SizedBox(
                    width: 70,
                    height: 44,
                    child: TextFormField(
                      controller: ctrl,
                      enabled: !isLocked,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        filled: true,
                        fillColor: isLocked
                            ? (isDark ? Colors.black12 : Colors.grey.shade100)
                            : (isDark ? AcadexColors.darkSurface : Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AcadexRadius.xs),
                          borderSide: BorderSide(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                      ),
                      onChanged: (_) => _recalculateStudentTotal(entry.studentId, components),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${activeComp.maxMarks.toInt()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Mobile Save Action
        if (!isLocked) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
              ),
              onPressed: _isSaving ? null : () => _handleSaveDraft(data),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.save, size: 18),
              label: Text(_isSaving ? 'Saving Marks...' : 'Save Marks'),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
