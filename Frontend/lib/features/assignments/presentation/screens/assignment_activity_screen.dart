import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../domain/models/assignment_models.dart';
import '../providers/assignments_providers.dart';
import '../widgets/marks_slider_row.dart';

class AssignmentActivityScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentActivityScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<AssignmentActivityScreen> createState() => _AssignmentActivityScreenState();
}

class _AssignmentActivityScreenState extends ConsumerState<AssignmentActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveMarks() async {
    setState(() => _isSaving = true);
    final notifier = ref.read(assignmentActivityProvider(widget.assignmentId).notifier);
    final success = await notifier.saveMarks();
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        AcadexSnackBar.showSuccess(context, 'Marks saved successfully.');
      } else {
        AcadexSnackBar.showError(context, "Couldn't save marks. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activityAsync = ref.watch(assignmentActivityProvider(widget.assignmentId));
    final activityNotifier = ref.read(assignmentActivityProvider(widget.assignmentId).notifier);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/assignments'),
        ),
        title: Text(
          'Assignment Activity',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AcadexColors.primary,
          unselectedLabelColor: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
          indicatorColor: AcadexColors.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: activityAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading assignment activity...'),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: "Couldn't load assignment activity.",
            retryLabel: 'Retry',
            onRetry: () => ref.read(assignmentActivityProvider(widget.assignmentId).notifier).loadActivity(),
          ),
        ),
        data: (activityData) {
          final asgn = activityData.assignment;
          final summary = activityData.summary;
          final completedList = activityData.completed;
          final pendingList = activityData.pending;

          return Column(
            children: [
              // Header Summary Card (Title shown ONCE at top)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            asgn.title,
                            style: AcadexTypography.heading2(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.primaryTint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Max: ${asgn.maximumMarks} Marks',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AcadexColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Metrics Row (horizontally scrollable for small mobile viewports)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMetricChip(
                            label: '${summary.completedCount} / ${summary.totalStudents} Completed',
                            color: const Color(0xFF15803D),
                            bg: const Color(0xFFDCFCE7),
                          ),
                          const SizedBox(width: 8),
                          _buildMetricChip(
                            label: '${summary.pendingCount} Pending',
                            color: AcadexColors.primary,
                            bg: AcadexColors.primaryTint,
                          ),
                          if (summary.overdueCount > 0) ...[
                            const SizedBox(width: 8),
                            _buildMetricChip(
                              label: '${summary.overdueCount} Overdue',
                              color: const Color(0xFFDC2626),
                              bg: const Color(0xFFFEE2E2),
                            ),
                          ],
                          if (summary.averageMarks != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Avg: ${summary.averageMarks} / ${asgn.maximumMarks}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Completed Students with Single-Row Marks Sliders
                    _buildCompletedTab(
                      completedList: completedList,
                      maximumMarks: asgn.maximumMarks,
                      isDark: isDark,
                      onMarkChanged: (studentId, mark) {
                        activityNotifier.updateLocalMark(studentId, mark);
                      },
                    ),

                    // Tab 2: Pending Students (No slider)
                    _buildPendingTab(
                      pendingList: pendingList,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Bottom Save Marks Bar (only when in Completed tab and has changes or pending edits)
              if (activityNotifier.hasPendingChanges)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Text(
                          '${activityNotifier.pendingMarks.length} pending mark(s)',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 140,
                          height: 40,
                          child: AcadexButton(
                            label: _isSaving ? 'Saving...' : 'Save Marks',
                            icon: LucideIcons.check,
                            onPressed: _isSaving ? null : _handleSaveMarks,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCompletedTab({
    required List<StudentAssignmentActivityModel> completedList,
    required int maximumMarks,
    required bool isDark,
    required void Function(String studentId, double mark) onMarkChanged,
  }) {
    if (completedList.isEmpty) {
      return const Center(
        child: AcadexEmptyState(
          icon: LucideIcons.userCheck,
          title: 'No Completed Submissions',
          subtitle: 'No students have marked this assignment as done yet.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: completedList.length,
      itemBuilder: (context, index) {
        final student = completedList[index];
        return MarksSliderRow(
          student: student,
          maximumMarks: maximumMarks,
          currentMark: student.marks,
          onMarkChanged: (newMark) {
            onMarkChanged(student.studentId, newMark);
          },
          onInspect: () => _showReviewSheet(student, maximumMarks),
        );
      },
    );
  }

  void _showReviewSheet(StudentAssignmentActivityModel student, int maximumMarks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final marksController = TextEditingController(
      text: student.marks != null
          ? (student.marks! % 1 == 0 ? student.marks!.toInt().toString() : student.marks!.toString())
          : '',
    );
    final feedbackController = TextEditingController(text: student.feedback ?? '');
    FacultyReviewStatus selectedStatus = student.reviewStatus == FacultyReviewStatus.notReviewed
        ? FacultyReviewStatus.reviewed
        : student.reviewStatus;
    bool isSavingReview = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header: Student Name & Late badge
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.studentName,
                                style: AcadexTypography.heading2(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ),
                              ),
                              if (student.rollNumber != null)
                                Text(
                                  'Roll: ${student.rollNumber} • Version ${student.version}',
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (student.isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LATE SUBMISSION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Divider(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    const SizedBox(height: 10),

                    // Student Text Response
                    if (student.textResponse != null && student.textResponse!.isNotEmpty) ...[
                      Text(
                        'STUDENT RESPONSE',
                        style: AcadexTypography.eyebrow(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                          borderRadius: AcadexRadius.borderRadiusMd,
                          border: Border.all(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                        child: Text(
                          student.textResponse!,
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Student Attachments
                    if (student.attachments.isNotEmpty) ...[
                      Text(
                        'SUBMITTED FILES (${student.attachments.length})',
                        style: AcadexTypography.eyebrow(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...student.attachments.map((att) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            borderRadius: AcadexRadius.borderRadiusMd,
                            border: Border.all(
                              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.paperclip, size: 16, color: AcadexColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  att.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  try {
                                    final repo = ref.read(assignmentsRepositoryProvider);
                                    if (student.submissionId != null) {
                                      final url = await repo.getSubmissionFileDownloadUrl(
                                        submissionId: student.submissionId!,
                                        fileId: att.fileId,
                                      );
                                      if (url.isNotEmpty) {
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AcadexSnackBar.showError(context, 'Could not open file: ${e.toString()}');
                                    }
                                  }
                                },
                                icon: const Icon(LucideIcons.download, size: 14),
                                label: const Text('Download', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                    ],

                    // Marks Input
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AWARDED MARKS (Max: $maximumMarks)',
                                style: AcadexTypography.eyebrow(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: marksController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'e.g. 8.5',
                                  suffixText: '/ $maximumMarks',
                                  errorText: errorText,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: AcadexRadius.borderRadiusMd,
                                    borderSide: BorderSide(
                                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Feedback Input
                    Text(
                      'FACULTY FEEDBACK',
                      style: AcadexTypography.eyebrow(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add constructive feedback for the student...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: AcadexRadius.borderRadiusMd,
                          borderSide: BorderSide(
                            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Review status selector
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          'Status: ',
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Reviewed'),
                          selected: selectedStatus == FacultyReviewStatus.reviewed,
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedStatus = FacultyReviewStatus.reviewed);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Under Review'),
                          selected: selectedStatus == FacultyReviewStatus.underReview,
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedStatus = FacultyReviewStatus.underReview);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AcadexButton(
                            label: isSavingReview ? 'Saving...' : 'Save Review',
                            icon: LucideIcons.check,
                            onPressed: isSavingReview
                                ? null
                                : () async {
                                    final text = marksController.text.trim();
                                    double? parsedMark;
                                    if (text.isNotEmpty) {
                                      parsedMark = double.tryParse(text);
                                      if (parsedMark == null || parsedMark < 0 || parsedMark > maximumMarks) {
                                        setSheetState(() {
                                          errorText = 'Mark must be between 0 and $maximumMarks';
                                        });
                                        return;
                                      }
                                    }

                                    setSheetState(() {
                                      isSavingReview = true;
                                      errorText = null;
                                    });

                                    final notifier = ref.read(assignmentActionProvider.notifier);
                                    final res = await notifier.reviewSingleSubmission(
                                      assignmentId: widget.assignmentId,
                                      studentId: student.studentId,
                                      marks: parsedMark,
                                      feedback: feedbackController.text.trim(),
                                      reviewStatus: selectedStatus,
                                    );

                                    if (mounted) {
                                      Navigator.of(sheetContext).pop();
                                      if (res != null) {
                                        AcadexSnackBar.showSuccess(
                                          context,
                                          'Review saved for ${student.studentName}',
                                        );
                                      } else {
                                        AcadexSnackBar.showError(
                                          context,
                                          'Failed to save review',
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingTab({
    required List<StudentAssignmentActivityModel> pendingList,
    required bool isDark,
  }) {
    if (pendingList.isEmpty) {
      return const Center(
        child: AcadexEmptyState(
          icon: LucideIcons.sparkles,
          title: 'All Done!',
          subtitle: 'All enrolled students have completed this assignment.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: pendingList.length,
      itemBuilder: (context, index) {
        final student = pendingList[index];
        final isOverdue = student.status == StudentTaskStatus.overdue;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
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
                      student.studentName,
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    if (student.rollNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Roll: ${student.rollNumber}',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOverdue ? const Color(0xFFFEE2E2) : AcadexColors.primaryTint,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOverdue ? 'Overdue' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? const Color(0xFFDC2626) : AcadexColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
