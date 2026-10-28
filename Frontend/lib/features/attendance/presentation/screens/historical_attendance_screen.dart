import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/attendance_status.dart';
import '../providers/attendance_providers.dart';

/// Screen for recording manual historical academic attendance.
/// Supports:
/// - Mode A: Detailed Historical Attendance (date, period, student-level status)
/// - Mode B: Historical Attendance Summaries (accumulated counts or percentage-only)
/// - Mode C: Student-Specific Historical Attendance Correction (audit-logged override)
class HistoricalAttendanceScreen extends ConsumerStatefulWidget {
  const HistoricalAttendanceScreen({super.key});

  @override
  ConsumerState<HistoricalAttendanceScreen> createState() =>
      _HistoricalAttendanceScreenState();
}

class _HistoricalAttendanceScreenState
    extends ConsumerState<HistoricalAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Academic Context Selection ---
  String? _selectedAcademicYearId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  // --- Common Roster State ---
  bool _isLoadingRoster = false;
  List<Map<String, dynamic>> _roster = [];
  String? _facultyAssignmentId;
  String _searchFilter = '';

  // --- Mode A State (Detailed Historical Session) ---
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 1));
  String _selectedPeriod = 'Period 1 (09:00 - 10:00)';
  final TextEditingController _customPeriodController = TextEditingController();
  final TextEditingController _sessionRemarksController =
      TextEditingController();
  final Map<String, AttendanceStatus?> _detailedStatuses = {};
  final Map<String, String> _detailedRemarks = {};
  bool _isSavingDetailed = false;

  // --- Mode B State (Historical Summaries) ---
  final TextEditingController _summaryPeriodLabelController =
      TextEditingController(text: 'Term Consolidated Aggregate');
  DateTime? _summaryPeriodStart;
  DateTime? _summaryPeriodEnd;
  bool _isPercentageOnlyMode = false;
  final TextEditingController _bulkClassesHeldController =
      TextEditingController(text: '40');
  final Map<String, TextEditingController> _heldControllers = {};
  final Map<String, TextEditingController> _presentControllers = {};
  final Map<String, TextEditingController> _percentageControllers = {};
  final Map<String, TextEditingController> _summaryRemarksControllers = {};
  bool _isSavingSummaries = false;

  // --- Mode C State (Student Correction) ---
  final TextEditingController _correctionSessionIdController =
      TextEditingController();
  final TextEditingController _correctionEnrollmentIdController =
      TextEditingController();
  final TextEditingController _correctionReasonController =
      TextEditingController();
  final TextEditingController _correctionRemarksController =
      TextEditingController();
  AttendanceStatus _correctionStatus = AttendanceStatus.present;
  bool _isSubmittingCorrection = false;

  final List<String> _standardPeriods = [
    'Period 1 (09:00 - 10:00)',
    'Period 2 (10:00 - 11:00)',
    'Period 3 (11:15 - 12:15)',
    'Period 4 (12:15 - 01:15)',
    'Period 5 (02:00 - 03:00)',
    'Period 6 (03:00 - 04:00)',
    'Custom Period / Lab Slot',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customPeriodController.dispose();
    _sessionRemarksController.dispose();
    _summaryPeriodLabelController.dispose();
    _bulkClassesHeldController.dispose();
    _correctionSessionIdController.dispose();
    _correctionEnrollmentIdController.dispose();
    _correctionReasonController.dispose();
    _correctionRemarksController.dispose();
    for (final c in _heldControllers.values) {
      c.dispose();
    }
    for (final c in _presentControllers.values) {
      c.dispose();
    }
    for (final c in _percentageControllers.values) {
      c.dispose();
    }
    for (final c in _summaryRemarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================
  // ROSTER RESOLUTION
  // ==========================================

  Future<void> _fetchRoster() async {
    if (_selectedAcademicYearId == null ||
        _selectedSemesterId == null ||
        _selectedSectionId == null ||
        _selectedSubjectId == null) {
      AcadexSnackBar.showWarning(
        context,
        'Please select Academic Year, Semester, Section, and Subject first.',
      );
      return;
    }

    setState(() {
      _isLoadingRoster = true;
    });

    try {
      final repo = ref.read(attendanceRepoProvider);
      final result = await repo.getHistoricalRoster(
        academicYearId: _selectedAcademicYearId!,
        semesterId: _selectedSemesterId!,
        sectionId: _selectedSectionId!,
        subjectId: _selectedSubjectId,
      );

      final rawList = result['roster'] as List<dynamic>? ?? [];
      final parsedRoster = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Sort roster alphabetically by rollNumber / name
      parsedRoster.sort((a, b) {
        final rA = a['rollNumber']?.toString() ?? '';
        final rB = b['rollNumber']?.toString() ?? '';
        if (rA.isNotEmpty && rB.isNotEmpty) return rA.compareTo(rB);
        return (a['studentName']?.toString() ?? '').compareTo(
          b['studentName']?.toString() ?? '',
        );
      });

      // Clear & initialize Mode A detailed controllers
      _detailedStatuses.clear();
      _detailedRemarks.clear();
      for (final s in parsedRoster) {
        final id = s['enrollmentId']?.toString() ?? '';
        _detailedStatuses[id] =
            AttendanceStatus.present; // Default to present for convenience
      }

      // Clear & initialize Mode B summary controllers
      for (final c in _heldControllers.values) {
        c.dispose();
      }
      for (final c in _presentControllers.values) {
        c.dispose();
      }
      for (final c in _percentageControllers.values) {
        c.dispose();
      }
      for (final c in _summaryRemarksControllers.values) {
        c.dispose();
      }
      _heldControllers.clear();
      _presentControllers.clear();
      _percentageControllers.clear();
      _summaryRemarksControllers.clear();

      for (final s in parsedRoster) {
        final id = s['enrollmentId']?.toString() ?? '';
        _heldControllers[id] = TextEditingController(
          text: _bulkClassesHeldController.text,
        );
        _presentControllers[id] = TextEditingController(
          text: _bulkClassesHeldController.text,
        );
        _percentageControllers[id] = TextEditingController(text: '100');
        _summaryRemarksControllers[id] = TextEditingController();
      }

      final fa = result['facultyAssignment'] as Map<String, dynamic>?;
      _facultyAssignmentId = fa?['id']?.toString();

      setState(() {
        _roster = parsedRoster;
        _isLoadingRoster = false;
      });

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Resolved ${parsedRoster.length} active enrollments for this historical context.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingRoster = false;
      });
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          'Failed to resolve historical roster: $e',
        );
      }
    }
  }

  // ==========================================
  // MODE A: DETAILED SUBMISSION
  // ==========================================

  Future<void> _submitDetailedSession() async {
    if (_roster.isEmpty) {
      AcadexSnackBar.showWarning(context, 'No student roster loaded.');
      return;
    }
    if (_isSavingDetailed) return;

    final period = _selectedPeriod == 'Custom Period / Lab Slot'
        ? _customPeriodController.text.trim()
        : _selectedPeriod;

    if (period.isEmpty) {
      AcadexSnackBar.showWarning(context, 'Please specify the class period.');
      return;
    }

    // Verify date is not in the future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (targetDate.isAfter(today)) {
      AcadexSnackBar.showError(
        context,
        'Historical attendance cannot be marked for future dates.',
      );
      return;
    }

    // Check for unmarked
    final unmarkedCount = _roster.where((s) {
      final id = s['enrollmentId']?.toString() ?? '';
      return _detailedStatuses[id] == null;
    }).length;

    if (unmarkedCount > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Unmarked Students ($unmarkedCount)',
            style: AcadexTypography.heading3,
          ),
          content: Text(
            'There are $unmarkedCount students without an attendance status. Would you like to mark them absent and proceed?',
            style: AcadexTypography.body(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Review Roster'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.primary,
              ),
              child: const Text(
                'Mark Absent & Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // Confirmation dialog with summary breakdown
    int present = 0, absent = 0, late = 0, excused = 0;
    for (final s in _roster) {
      final id = s['enrollmentId']?.toString() ?? '';
      final status = _detailedStatuses[id] ?? AttendanceStatus.absent;
      switch (status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
        case AttendanceStatus.excused:
          excused++;
          break;
        default:
          break;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              LucideIcons.history,
              color: AcadexColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Confirm Historical Session',
              style: AcadexTypography.heading3,
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are creating an immutable historical attendance session with the following audit parameters:',
                style: AcadexTypography.caption(),
              ),
              const SizedBox(height: 12),
              _buildAuditRow(
                'Historical Date',
                DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
              ),
              _buildAuditRow('Class Period', period),
              _buildAuditRow('Total Students', '${_roster.length}'),
              _buildAuditRow('Present / Late', '$present / $late'),
              _buildAuditRow('Absent / Excused', '$absent / $excused'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AcadexColors.warning.withValues(alpha: 0.1),
                  borderRadius: AcadexRadius.borderRadiusSm,
                  border: Border.all(
                    color: AcadexColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: AcadexColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This record will be saved with sourceType: HISTORICAL_MANUAL and will appear in Student 360 history.',
                        style: AcadexTypography.caption(
                          color: AcadexColors.warning,
                        ),
                      ),
                    ),
                  ],
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
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
            ),
            child: const Text(
              'Save Historical Session',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSavingDetailed = true);

    try {
      final records = _roster.map((s) {
        final id = s['enrollmentId']?.toString() ?? '';
        final status = _detailedStatuses[id] ?? AttendanceStatus.absent;
        final rem = _detailedRemarks[id];
        return {
          'studentEnrollmentId': id,
          'status': status.name,
          if (rem != null && rem.trim().isNotEmpty) 'remarks': rem.trim(),
        };
      }).toList();

      final repo = ref.read(attendanceRepoProvider);
      final session = await repo.createDetailedHistoricalSession(
        academicYearId: _selectedAcademicYearId!,
        semesterId: _selectedSemesterId!,
        sectionId: _selectedSectionId,
        subjectId: _selectedSubjectId!,
        facultyAssignmentId: _facultyAssignmentId,
        date: _selectedDate,
        timeSlot: period,
        records: records,
        remarks: _sessionRemarksController.text.trim().isNotEmpty
            ? _sessionRemarksController.text.trim()
            : null,
      );

      setState(() => _isSavingDetailed = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  LucideIcons.checkCircle2,
                  color: AcadexColors.success,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Historical Session Recorded',
                  style: AcadexTypography.heading3,
                ),
              ],
            ),
            content: Text(
              'Session ID: ${session.id}\n'
              'Records Saved: ${session.presentCount + session.absentCount + session.lateCount + session.excusedCount}\n'
              'Status: LOCKED (Historical Archive)',
              style: AcadexTypography.body(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/attendance/faculty/history');
                },
                child: const Text('View Sessions History'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Reset state for another entry
                  setState(() {
                    _roster.clear();
                    _detailedStatuses.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSavingDetailed = false);
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          'Failed to save historical session: $e',
        );
      }
    }
  }

  // ==========================================
  // MODE B: SUMMARY SUBMISSION
  // ==========================================

  Future<void> _submitSummaries() async {
    if (_roster.isEmpty) {
      AcadexSnackBar.showWarning(context, 'No student roster loaded.');
      return;
    }
    if (_isSavingSummaries) return;

    final periodLabel = _summaryPeriodLabelController.text.trim();
    if (periodLabel.isEmpty) {
      AcadexSnackBar.showWarning(
        context,
        'Please specify the period label (e.g. "Term 1 Aggregate").',
      );
      return;
    }

    final entries = <Map<String, dynamic>>[];

    for (final s in _roster) {
      final id = s['enrollmentId']?.toString() ?? '';
      final remarks = _summaryRemarksControllers[id]?.text.trim();

      if (_isPercentageOnlyMode) {
        final pctStr = _percentageControllers[id]?.text.trim() ?? '';
        final pct = double.tryParse(pctStr);
        if (pct == null || pct < 0 || pct > 100) {
          AcadexSnackBar.showError(
            context,
            'Invalid percentage for student ${s['studentName']} (${s['rollNumber']}). Must be 0 to 100.',
          );
          return;
        }
        entries.add({
          'studentEnrollmentId': id,
          'classesHeld': null,
          'presentCount': null,
          'attendancePercentage': pct,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        });
      } else {
        final heldStr = _heldControllers[id]?.text.trim() ?? '';
        final presentStr = _presentControllers[id]?.text.trim() ?? '';
        final held = int.tryParse(heldStr);
        final present = int.tryParse(presentStr);

        if (held == null || held < 0) {
          AcadexSnackBar.showError(
            context,
            'Classes Held must be >= 0 for student ${s['studentName']}.',
          );
          return;
        }
        if (present == null || present < 0) {
          AcadexSnackBar.showError(
            context,
            'Classes Attended must be >= 0 for student ${s['studentName']}.',
          );
          return;
        }
        if (present > held) {
          AcadexSnackBar.showError(
            context,
            'Classes attended ($present) cannot exceed classes held ($held) for ${s['studentName']}.',
          );
          return;
        }

        entries.add({
          'studentEnrollmentId': id,
          'classesHeld': held,
          'presentCount': present,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        });
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              LucideIcons.calculator,
              color: AcadexColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text('Save Historical Summaries', style: AcadexTypography.heading3),
          ],
        ),
        content: Text(
          'Record historical ${_isPercentageOnlyMode ? "percentage summaries" : "period counts"} for ${entries.length} students under label "$periodLabel"?\n\n'
          'Note: Summaries retain summary-only identity and do not fabricate individual session dates.',
          style: AcadexTypography.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
            ),
            child: const Text(
              'Save Summaries',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSavingSummaries = true);

    try {
      final repo = ref.read(attendanceRepoProvider);
      final results = await repo.createHistoricalSummaries(
        academicYearId: _selectedAcademicYearId!,
        semesterId: _selectedSemesterId!,
        sectionId: _selectedSectionId,
        subjectId: _selectedSubjectId!,
        periodLabel: periodLabel,
        periodStart: _summaryPeriodStart,
        periodEnd: _summaryPeriodEnd,
        entries: entries,
      );

      setState(() => _isSavingSummaries = false);

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Successfully recorded ${results.length} historical attendance summaries.',
        );
      }
    } catch (e) {
      setState(() => _isSavingSummaries = false);
      if (mounted) {
        AcadexSnackBar.showError(context, 'Failed to save summaries: $e');
      }
    }
  }

  // ==========================================
  // MODE C: CORRECTION SUBMISSION
  // ==========================================

  Future<void> _submitCorrection() async {
    final sessionId = _correctionSessionIdController.text.trim();
    final enrollmentId = _correctionEnrollmentIdController.text.trim();
    final reason = _correctionReasonController.text.trim();

    if (sessionId.isEmpty) {
      AcadexSnackBar.showWarning(context, 'Session ID is required.');
      return;
    }
    if (enrollmentId.isEmpty) {
      AcadexSnackBar.showWarning(context, 'Student Enrollment ID is required.');
      return;
    }
    if (reason.length < 5) {
      AcadexSnackBar.showWarning(
        context,
        'Mandatory justification reason must be at least 5 characters.',
      );
      return;
    }

    setState(() => _isSubmittingCorrection = true);

    try {
      final repo = ref.read(attendanceRepoProvider);
      final record = await repo.correctHistoricalStudentAttendance(
        sessionId: sessionId,
        studentEnrollmentId: enrollmentId,
        newStatus: _correctionStatus,
        reason: reason,
      );

      setState(() => _isSubmittingCorrection = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  color: AcadexColors.success,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Correction Applied & Audited',
                  style: AcadexTypography.heading3,
                ),
              ],
            ),
            content: Text(
              'Record ID: ${record.id}\n'
              'Updated Status: ${record.status?.displayName ?? 'Recorded'}\n'
              'Source: HISTORICAL_MANUAL\n'
              'Audit Reason: "$reason"',
              style: AcadexTypography.body(),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        _correctionReasonController.clear();
      }
    } catch (e) {
      setState(() => _isSubmittingCorrection = false);
      if (mounted) {
        AcadexSnackBar.showError(context, 'Correction failed: $e');
      }
    }
  }

  // ==========================================
  // BATCH ACTIONS (MODE A)
  // ==========================================

  void _markAll(AttendanceStatus status) {
    setState(() {
      for (final s in _roster) {
        final id = s['enrollmentId']?.toString() ?? '';
        _detailedStatuses[id] = status;
      }
    });
  }

  void _applyBulkClassesHeld() {
    final val = _bulkClassesHeldController.text.trim();
    if (int.tryParse(val) == null) {
      AcadexSnackBar.showWarning(
        context,
        'Please enter a valid integer for Classes Held.',
      );
      return;
    }
    setState(() {
      for (final s in _roster) {
        final id = s['enrollmentId']?.toString() ?? '';
        _heldControllers[id]?.text = val;
        _presentControllers[id]?.text = val;
      }
    });
    AcadexSnackBar.showSuccess(
      context,
      'Applied $val classes held to all students.',
    );
  }

  // ==========================================
  // UI BUILDERS
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.safePop(fallbackRoute: '/attendance'),
        ),
        title: Text(
          'Historical Attendance Entry',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AcadexColors.primary,
          unselectedLabelColor: isDark
              ? AcadexColors.darkInkMuted
              : AcadexColors.inkMuted,
          indicatorColor: AcadexColors.primary,
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.calendarCheck2, size: 18),
              text: 'Detailed Session',
            ),
            Tab(
              icon: Icon(LucideIcons.calculator, size: 18),
              text: 'Historical Summary',
            ),
            Tab(
              icon: Icon(LucideIcons.userCog, size: 18),
              text: 'Student Correction',
            ),
          ],
        ),
      ),
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.contentMaxWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHistoricalArchiveBanner(isDark),
              const SizedBox(height: 16),
              SizedBox(
                height: 1000,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildModeADetailedTab(isDark),
                    _buildModeBSummaryTab(isDark),
                    _buildModeCCorrectionTab(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoricalArchiveBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AcadexColors.primary.withValues(alpha: 0.12)
            : const Color(0xFFEFF6FF),
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark
              ? AcadexColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.archive,
            color: AcadexColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'HISTORICAL ACADEMIC ARCHIVE WORKFLOW',
                      style:
                          AcadexTypography.caption(
                            color: AcadexColors.primary,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const AcadexBadge(
                      label: 'AUDITED',
                      variant: AcadexBadgeVariant.info,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Record past class attendance sessions and accumulated totals. All records are tagged with sourceType: HISTORICAL_MANUAL and recorded in the audit log. Live attendance period timing rules are not modified.',
                  style: AcadexTypography.caption(
                    color: isDark
                        ? AcadexColors.darkInkSecondary
                        : AcadexColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACADEMIC CONTEXT SELECTORS WIDGET
  // ==========================================

  Widget _buildAcademicContextSelectors(bool isDark) {
    final academicYears = ref.watch(academicYearsProvider).valueOrNull ?? [];
    final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
    final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    // Filter semesters by academic year
    final filteredSemesters = _selectedAcademicYearId != null
        ? semesters
              .where((s) => s.academicYearId == _selectedAcademicYearId)
              .toList()
        : semesters;

    // Filter sections by semester
    final filteredSections = _selectedSemesterId != null
        ? sections
              .where((sec) => sec.semesterId == _selectedSemesterId)
              .toList()
        : sections;

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.graduationCap,
                size: 18,
                color: AcadexColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Academic Context & Scope',
                style: AcadexTypography.heading3,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AcadexDropdown<String>(
                      label: 'Academic Year',
                      hint: 'Select Year',
                      value: _selectedAcademicYearId,
                      items: academicYears
                          .map(
                            (y) => DropdownMenuItem(
                              value: y.id,
                              child: Text(y.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAcademicYearId = val;
                          _selectedSemesterId = null;
                          _selectedSectionId = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AcadexDropdown<String>(
                      label: 'Semester / Term',
                      hint: 'Select Semester',
                      value: _selectedSemesterId,
                      items: filteredSemesters
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSemesterId = val;
                          _selectedSectionId = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AcadexDropdown<String>(
                      label: 'Section / Cohort',
                      hint: 'Select Section',
                      value: _selectedSectionId,
                      items: filteredSections
                          .map(
                            (sec) => DropdownMenuItem(
                              value: sec.id,
                              child: Text(sec.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedSectionId = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AcadexDropdown<String>(
                      label: 'Subject / Course Unit',
                      hint: 'Select Subject',
                      value: _selectedSubjectId,
                      items: subjects
                          .map(
                            (sub) => DropdownMenuItem(
                              value: sub.id,
                              child: Text(
                                '${sub.code} - ${sub.name}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedSubjectId = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: AcadexButton(
              label: _isLoadingRoster
                  ? 'Resolving Roster...'
                  : 'Load Historical Roster',
              icon: LucideIcons.users,
              variant: AcadexButtonVariant.secondary,
              onPressed: _isLoadingRoster ? null : _fetchRoster,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: MODE A (DETAILED SESSION)
  // ==========================================

  Widget _buildModeADetailedTab(bool isDark) {
    final filteredRoster = _roster.where((s) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      final name = (s['studentName']?.toString() ?? '').toLowerCase();
      final roll = (s['rollNumber']?.toString() ?? '').toLowerCase();
      return name.contains(q) || roll.contains(q);
    }).toList();

    int present = 0, absent = 0, late = 0, excused = 0, unmarked = 0;
    for (final s in _roster) {
      final id = s['enrollmentId']?.toString() ?? '';
      final st = _detailedStatuses[id];
      if (st == null) {
        unmarked++;
      } else {
        switch (st) {
          case AttendanceStatus.present:
            present++;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
          case AttendanceStatus.late:
            late++;
            break;
          case AttendanceStatus.excused:
            excused++;
            break;
          default:
            break;
        }
      }
    }

    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        _buildAcademicContextSelectors(isDark),
        const SizedBox(height: 16),

        // Session Parameters Card
        AcadexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.calendarClock,
                    size: 18,
                    color: AcadexColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Session Date & Period',
                    style: AcadexTypography.heading3,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historical Date (Past Only)',
                          style: AcadexTypography.caption().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AcadexColors.darkSurface
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
                                const Icon(
                                  LucideIcons.calendar,
                                  size: 16,
                                  color: AcadexColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'EEEE, MMM d, yyyy',
                                    ).format(_selectedDate),
                                    style: AcadexTypography.body(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AcadexDropdown<String>(
                      label: 'Class Period / Time Slot',
                      value: _selectedPeriod,
                      items: _standardPeriods
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPeriod = val);
                      },
                    ),
                  ),
                ],
              ),
              if (_selectedPeriod == 'Custom Period / Lab Slot') ...[
                const SizedBox(height: 12),
                AcadexTextField(
                  controller: _customPeriodController,
                  label: 'Custom Period Specification',
                  hint: 'e.g., Practical Lab Slot A (02:00 - 04:30)',
                ),
              ],
              const SizedBox(height: 12),
              AcadexTextField(
                controller: _sessionRemarksController,
                label: 'Session Remarks / Archival Note (Optional)',
                hint:
                    'e.g., Recorded from historical attendance register Book #4, Page 22',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Roster Register Card
        if (_roster.isEmpty)
          const AcadexCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: AcadexEmptyState(
                title: 'No Historical Roster Loaded',
                subtitle:
                    'Select the academic context above and click "Load Historical Roster" to view enrolled students.',
                icon: LucideIcons.users,
              ),
            ),
          )
        else ...[
          AcadexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Summary Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Student Attendance Register (${_roster.length})',
                      style: AcadexTypography.heading3,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        AcadexButton(
                          label: 'All Present',
                          icon: LucideIcons.checkCheck,
                          variant: AcadexButtonVariant.secondary,
                          onPressed: () => _markAll(AttendanceStatus.present),
                        ),
                        AcadexButton(
                          label: 'All Absent',
                          icon: LucideIcons.xCircle,
                          variant: AcadexButtonVariant.secondary,
                          onPressed: () => _markAll(AttendanceStatus.absent),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status Breakdown Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildStatPill('Present', '$present', AcadexColors.success),
                    _buildStatPill('Absent', '$absent', AcadexColors.error),
                    _buildStatPill('Late', '$late', AcadexColors.warning),
                    _buildStatPill(
                      'Excused',
                      '$excused',
                      const Color(0xFF6366F1),
                    ),
                    if (unmarked > 0)
                      _buildStatPill(
                        'Unmarked',
                        '$unmarked',
                        AcadexColors.inkMuted,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                AcadexSearchField(
                  hint: 'Search by roll number or student name...',
                  onChanged: (val) => setState(() => _searchFilter = val),
                ),
                const SizedBox(height: 12),

                // Student List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRoster.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark
                        ? AcadexColors.darkHairline
                        : AcadexColors.hairline,
                  ),
                  itemBuilder: (ctx, idx) {
                    final s = filteredRoster[idx];
                    final enrollmentId = s['enrollmentId']?.toString() ?? '';
                    final currentStatus = _detailedStatuses[enrollmentId];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AcadexColors.darkSurface
                                  : const Color(0xFFF1F5F9),
                              borderRadius: AcadexRadius.borderRadiusSm,
                            ),
                            child: Text(
                              s['rollNumber']?.toString().isNotEmpty == true
                                  ? s['rollNumber'].toString()
                                  : 'No Roll #',
                              style: AcadexTypography.caption().copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['studentName']?.toString() ??
                                      'Unknown Student',
                                  style: AcadexTypography.body().copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Enrollment: $enrollmentId',
                                  style: AcadexTypography.caption(
                                    color: isDark
                                        ? AcadexColors.darkInkMuted
                                        : AcadexColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Buttons
                          _buildStatusButton(
                            enrollmentId,
                            AttendanceStatus.present,
                            'P',
                            currentStatus,
                          ),
                          const SizedBox(width: 4),
                          _buildStatusButton(
                            enrollmentId,
                            AttendanceStatus.absent,
                            'A',
                            currentStatus,
                          ),
                          const SizedBox(width: 4),
                          _buildStatusButton(
                            enrollmentId,
                            AttendanceStatus.late,
                            'L',
                            currentStatus,
                          ),
                          const SizedBox(width: 4),
                          _buildStatusButton(
                            enrollmentId,
                            AttendanceStatus.excused,
                            'E',
                            currentStatus,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: AcadexButton(
                    label: _isSavingDetailed
                        ? 'Saving Session...'
                        : 'Confirm & Save Historical Session',
                    icon: LucideIcons.save,
                    variant: AcadexButtonVariant.primary,
                    onPressed: _isSavingDetailed
                        ? null
                        : _submitDetailedSession,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusButton(
    String enrollmentId,
    AttendanceStatus status,
    String label,
    AttendanceStatus? currentStatus,
  ) {
    final isSelected = currentStatus == status;
    return InkWell(
      borderRadius: AcadexRadius.borderRadiusSm,
      onTap: () {
        setState(() {
          _detailedStatuses[enrollmentId] = status;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? status.color : Colors.transparent,
          borderRadius: AcadexRadius.borderRadiusSm,
          border: Border.all(
            color: isSelected ? status.color : AcadexColors.hairline,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : status.color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: MODE B (HISTORICAL SUMMARIES)
  // ==========================================

  Widget _buildModeBSummaryTab(bool isDark) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        _buildAcademicContextSelectors(isDark),
        const SizedBox(height: 16),

        // Summary Meta Card
        AcadexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.barChart2,
                    size: 18,
                    color: AcadexColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Summary Aggregation Specification',
                    style: AcadexTypography.heading3,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AcadexTextField(
                      controller: _summaryPeriodLabelController,
                      label: 'Summary Period Designation',
                      hint: 'e.g., Odd Semester 2024 Cumulative',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entry Precision Mode',
                          style: AcadexTypography.caption().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            ChoiceChip(
                              label: const Text('Classes Count'),
                              selected: !_isPercentageOnlyMode,
                              onSelected: (val) {
                                if (val)
                                  setState(() => _isPercentageOnlyMode = false);
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Percentage Only (%)'),
                              selected: _isPercentageOnlyMode,
                              onSelected: (val) {
                                if (val)
                                  setState(() => _isPercentageOnlyMode = true);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_isPercentageOnlyMode && _roster.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: AcadexTextField(
                        controller: _bulkClassesHeldController,
                        label: 'Default Classes Held',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: AcadexButton(
                        label: 'Apply to All',
                        variant: AcadexButtonVariant.secondary,
                        onPressed: _applyBulkClassesHeld,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Students Summary Table Card
        if (_roster.isEmpty)
          const AcadexCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: AcadexEmptyState(
                title: 'No Historical Roster Loaded',
                subtitle:
                    'Select the academic context above and load the roster to record accumulated totals.',
                icon: LucideIcons.calculator,
              ),
            ),
          )
        else
          AcadexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Summary Records (${_roster.length})',
                  style: AcadexTypography.heading3,
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _roster.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark
                        ? AcadexColors.darkHairline
                        : AcadexColors.hairline,
                  ),
                  itemBuilder: (ctx, idx) {
                    final s = _roster[idx];
                    final id = s['enrollmentId']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['studentName']?.toString() ?? 'Student',
                                  style: AcadexTypography.body().copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Roll: ${s['rollNumber'] ?? 'N/A'}',
                                  style: AcadexTypography.caption(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isPercentageOnlyMode) ...[
                            Expanded(
                              flex: 2,
                              child: AcadexTextField(
                                controller: _percentageControllers[id],
                                label: 'Attendance %',
                                hint: '0 - 100',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              flex: 2,
                              child: AcadexTextField(
                                controller: _heldControllers[id],
                                label: 'Held',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: AcadexTextField(
                                controller: _presentControllers[id],
                                label: 'Attended',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: AcadexButton(
                    label: _isSavingSummaries
                        ? 'Saving Summaries...'
                        : 'Save Historical Summaries',
                    icon: LucideIcons.save,
                    variant: AcadexButtonVariant.primary,
                    onPressed: _isSavingSummaries ? null : _submitSummaries,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // TAB 3: MODE C (STUDENT CORRECTION)
  // ==========================================

  Widget _buildModeCCorrectionTab(bool isDark) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        AcadexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.userCog,
                    size: 20,
                    color: AcadexColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Student-Specific Historical Correction',
                    style: AcadexTypography.heading3,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Correct an individual student attendance record from a past session. This operation requires an explicit justification reason and is recorded in the immutable audit log.',
                style: AcadexTypography.body(
                  color: isDark
                      ? AcadexColors.darkInkSecondary
                      : AcadexColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 16),

              AcadexTextField(
                controller: _correctionSessionIdController,
                label: 'Historical Session ID',
                hint: 'e.g., 65f2a1b9c8d7e6f5a4b3c2d1',
                prefixIcon: LucideIcons.hash,
              ),
              const SizedBox(height: 12),

              AcadexTextField(
                controller: _correctionEnrollmentIdController,
                label: 'Student Enrollment ID',
                hint: 'e.g., 65f2a1b9c8d7e6f5a4b3c2d2',
                prefixIcon: LucideIcons.user,
              ),
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Attendance Status',
                    style: AcadexTypography.caption().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildCorrectionStatusChip(AttendanceStatus.present),
                      _buildCorrectionStatusChip(AttendanceStatus.absent),
                      _buildCorrectionStatusChip(AttendanceStatus.late),
                      _buildCorrectionStatusChip(AttendanceStatus.excused),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              AcadexTextField(
                controller: _correctionReasonController,
                label: 'Audit Justification Reason (Mandatory)',
                hint:
                    'e.g., Medical exemption certificate submitted & verified by HOD',
                maxLines: 2,
                prefixIcon: LucideIcons.fileText,
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: AcadexButton(
                  label: _isSubmittingCorrection
                      ? 'Applying Correction...'
                      : 'Submit Audited Correction',
                  icon: LucideIcons.shieldCheck,
                  variant: AcadexButtonVariant.primary,
                  onPressed: _isSubmittingCorrection ? null : _submitCorrection,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectionStatusChip(AttendanceStatus status) {
    final isSelected = _correctionStatus == status;
    return ChoiceChip(
      label: Text(
        status.displayName,
        style: TextStyle(
          color: isSelected ? Colors.white : status.color,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      selectedColor: status.color,
      onSelected: (val) {
        if (val) setState(() => _correctionStatus = status);
      },
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AcadexTypography.caption(color: color)),
          Text(
            value,
            style: AcadexTypography.caption(
              color: color,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AcadexTypography.caption())),
          const SizedBox(width: 8),
          Text(
            value,
            style: AcadexTypography.caption().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
