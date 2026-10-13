import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../widgets/student_bulk_action_dialogs.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AcadexBadgeVariant _getBadgeVariant(StudentLifecycleState state) {
    switch (state) {
      case StudentLifecycleState.active:
        return AcadexBadgeVariant.success;
      case StudentLifecycleState.admitted:
      case StudentLifecycleState.applicant:
        return AcadexBadgeVariant.neutral;
      case StudentLifecycleState.onLeave:
        return AcadexBadgeVariant.warning;
      case StudentLifecycleState.suspended:
        return AcadexBadgeVariant.danger;
      case StudentLifecycleState.transferred:
        return AcadexBadgeVariant.neutral;
      case StudentLifecycleState.graduated:
      case StudentLifecycleState.alumni:
        return AcadexBadgeVariant.success;
    }
  }

  void _showStatusDialog(Student student) async {
    final result = await showDialog<StudentLifecycleState>(
      context: context,
      builder: (ctx) => StudentStatusChangeDialog(student: student),
    );
    if (result != null && mounted) {
      await ref.read(studentsProvider((sectionId: null, departmentId: null)).notifier).updateLifecycleState(
        studentId: student.id,
        newState: result,
      );
      ref.invalidate(studentAcademicProfileProvider(widget.studentId));
    }
  }

  void _showPromotionDialog(Student student) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => StudentPromotionDialog(studentIds: [student.id]),
    );
    if (result == true && mounted) {
      ref.invalidate(studentAcademicProfileProvider(widget.studentId));
    }
  }

  void _showTransferDialog(Student student) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => StudentTransferDialog(studentIds: [student.id]),
    );
    if (result == true && mounted) {
      ref.invalidate(studentAcademicProfileProvider(widget.studentId));
    }
  }

  void _showDepartmentTransferDialog(Student student) async {
    final deptsAsync = await ref.read(departmentsProvider.future);
    final activeDepts = deptsAsync.where((d) => d.id != student.departmentId && d.isActive).toList();
    if (!mounted) return;
    if (activeDepts.isEmpty) {
      AcadexSnackBar.showWarning(context, "No other active departments available for transfer");
      return;
    }

    String? selectedDeptId = activeDepts.first.id;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Transfer Department"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select the destination department for ${student.name}:"),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDeptId,
                items: activeDepts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                onChanged: (val) => setDialogState(() => selectedDeptId = val),
                decoration: const InputDecoration(labelText: "Destination Department"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary, foregroundColor: Colors.white),
              child: const Text("Transfer"),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedDeptId != null && mounted) {
      try {
        await ref.read(academicRepositoryProvider).transferStudentDepartment(student.id, selectedDeptId!);
        ref.invalidate(studentAcademicProfileProvider(widget.studentId));
        ref.invalidate(studentsProvider);
        if (mounted) {
          AcadexSnackBar.showSuccess(context, "Student transferred to new department successfully");
        }
      } catch (e) {
        if (mounted) {
          AcadexSnackBar.showError(
            context,
            e,
            fallbackMessage: "Department transfer failed",
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isStaff = currentUser?.role == AppRole.superAdmin ||
        currentUser?.role == AppRole.collegeAdmin ||
        currentUser?.role == AppRole.hod;
    final isCollegeAdmin = currentUser?.role == AppRole.superAdmin ||
        currentUser?.role == AppRole.collegeAdmin;

    final profileAsync = ref.watch(studentAcademicProfileProvider(widget.studentId));
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = profileAsync.when(
      loading: () => const Center(child: AcadexLoadingState(message: "Loading academic profile...")),
      error: (err, _) => Center(
        child: AcadexErrorState.fromError(
          error: err,
          title: "Unable to load student profile",
          onRetry: () => ref.invalidate(studentAcademicProfileProvider(widget.studentId)),
        ),
      ),
      data: (profile) {
        final student = profile.student;
        final dept = profile.department;
        final crs = profile.course;
        final sem = profile.semester;
        final sec = profile.section;
        final yr = profile.academicYear;

        return AcadexPageContainer(
          backgroundColor: Colors.white,
          maxWidth: 1400,
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Header Card
                AcadexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AcadexColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AcadexColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student.name,
                                        style: AcadexTypography.heading2(color: theme.colorScheme.onSurface),
                                      ),
                                    ),
                                    AcadexBadge(
                                      label: student.lifecycleState.displayName,
                                      variant: _getBadgeVariant(student.lifecycleState),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      "Roll No: ${student.rollNumber}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.primary),
                                    ),
                                    Text("•", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                    Text(dept?.name ?? "Department"),
                                    Text("•", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                    Text("${crs?.code ?? 'Course'} (${sem?.name ?? 'Sem'} - Sec ${sec?.name ?? 'Sec'} • ${yr?.name ?? ''})"),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${student.email} • ${student.phone}",
                                  style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isStaff) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showStatusDialog(student),
                              icon: const Icon(LucideIcons.userCog, size: 15),
                              label: const Text("Change Status"),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcadexColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: student.isActive ? () => _showPromotionDialog(student) : null,
                              icon: const Icon(LucideIcons.arrowUpRight, size: 15),
                              label: const Text("Promote Student"),
                            ),
                            OutlinedButton.icon(
                              onPressed: student.isActive ? () => _showTransferDialog(student) : null,
                              icon: const Icon(LucideIcons.arrowRightLeft, size: 15),
                              label: const Text("Transfer Section"),
                            ),
                            if (isCollegeAdmin)
                              OutlinedButton.icon(
                                onPressed: () => _showDepartmentTransferDialog(student),
                                icon: const Icon(LucideIcons.building, size: 15),
                                label: const Text("Transfer Department"),
                              ),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/academics/students/edit/${student.id}'),
                              icon: const Icon(LucideIcons.edit, size: 15),
                              label: const Text("Edit Student"),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (profile.facultyPriorityContext != null)
                  _buildFacultyPriorityContextCard(profile.facultyPriorityContext!, isDark, theme),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AcadexColors.primary,
                  labelColor: AcadexColors.primary,
                  unselectedLabelColor: AcadexColors.inkMuted,
                  tabs: const [
                    Tab(icon: Icon(LucideIcons.layoutDashboard, size: 16), text: "Overview"),
                    Tab(icon: Icon(LucideIcons.clipboardCheck, size: 16), text: "Attendance"),
                    Tab(icon: Icon(LucideIcons.award, size: 16), text: "Assessments"),
                    Tab(icon: Icon(LucideIcons.fileText, size: 16), text: "Assignments"),
                    Tab(icon: Icon(LucideIcons.bookOpen, size: 16), text: "Subjects"),
                    Tab(icon: Icon(LucideIcons.stickyNote, size: 16), text: "Notes"),
                    Tab(icon: Icon(LucideIcons.inbox, size: 16), text: "Requests"),
                    Tab(icon: Icon(LucideIcons.graduationCap, size: 16), text: "Academic Records"),
                    Tab(icon: Icon(LucideIcons.history, size: 16), text: "Activity & History"),
                  ],
                ),
                const SizedBox(height: 20),

                // Tab Views
                SizedBox(
                  height: 650,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Overview
                      _buildAcademicOverviewTab(context, profile, isDark, theme),

                      // Tab 2: Attendance
                      _buildAttendanceTab(context, profile, isDark, theme),

                      // Tab 3: Assessments & Performance
                      _buildAssessmentsTab(context, profile, isDark, theme),

                      // Tab 4: Assignments
                      _buildAssignmentsTab(context, profile, isDark, theme),

                      // Tab 5: Subjects
                      _buildSubjectsTab(profile, isDark, theme),

                      // Tab 6: Notes
                      _buildNotesTab(profile, isDark, theme),

                      // Tab 7: Requests
                      _buildRequestsTab(profile, isDark, theme),

                      // Tab 8: Academic Records & Results
                      _buildAcademicRecordsTab(profile, isDark, theme),

                      // Tab 9: Timeline & History
                      _buildTimelineTab(student, profile, isDark, theme),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

    if (hasEnclosingScaffold) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.safePop(fallbackRoute: '/academics/students'),
        ),
        title: Text(
          "Student Academic Profile",
          style: AcadexTypography.title(color: Colors.white),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildAcademicOverviewTab(BuildContext context, StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    final student = profile.student;
    final isMobile = AcadexBreakpoints.isMobile(context);

    final termCard = AcadexStatCard(
      title: "Current Term",
      value: profile.semester?.name ?? "Semester",
      subtitle: "Section ${profile.section?.name ?? '—'}",
      icon: LucideIcons.calendar,
      iconColor: AcadexColors.primary,
    );
    final subjectCard = AcadexStatCard(
      title: "Enrolled Subjects",
      value: "${profile.enrolledSubjects.length}",
      subtitle: "Active courses",
      icon: LucideIcons.bookOpen,
      iconColor: AcadexColors.accentTeal,
    );
    final attCard = AcadexStatCard(
      title: "Attendance Average",
      value: "${profile.overallAttendancePercentage.toStringAsFixed(1)}%",
      subtitle: profile.overallAttendancePercentage >= 75.0 ? "Good standing" : "Low attendance",
      icon: LucideIcons.clipboardCheck,
      iconColor: profile.overallAttendancePercentage >= 75.0 ? AcadexColors.success : AcadexColors.warning,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          if (isMobile) ...[
            termCard,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: subjectCard),
                const SizedBox(width: 10),
                Expanded(child: attCard),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: termCard),
                const SizedBox(width: 16),
                Expanded(child: subjectCard),
                const SizedBox(width: 16),
                Expanded(child: attCard),
              ],
            ),
          ],
          const SizedBox(height: 20),
          AcadexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Academic Structure Mapping", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                _buildDetailRow("College ID", student.collegeId),
                _buildDetailRow("Department", AcadexEntityFormatters.formatDepartmentLabel(profile.department?.name, rawId: student.departmentId)),
                _buildDetailRow("Course", "${AcadexEntityFormatters.formatCourseLabel(profile.course?.name, rawId: student.courseId)}${profile.course?.code != null && !AcadexEntityFormatters.isRawIdentifier(profile.course!.code) ? ' (${profile.course!.code})' : ''}"),
                _buildDetailRow("Academic Year", AcadexEntityFormatters.formatAcademicYearLabel(profile.academicYear?.name, rawId: student.academicYearId)),
                _buildDetailRow("Semester", AcadexEntityFormatters.formatSemesterLabel(profile.semester?.name, semesterNumber: profile.semester?.semesterNumber, rawId: student.semesterId)),
                _buildDetailRow("Section", AcadexEntityFormatters.formatSectionLabel(profile.section?.name, rawId: student.sectionId, fallback: 'Section Not Assigned')),
                _buildDetailRow("Admission Date", student.admissionDate != null ? "${student.admissionDate!.day}/${student.admissionDate!.month}/${student.admissionDate!.year}" : "—"),
                if (student.graduationDate != null)
                  _buildDetailRow("Graduation Date", "${student.graduationDate!.day}/${student.graduationDate!.month}/${student.graduationDate!.year}"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AcadexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Connected Academic Modules", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.calendar, size: 16),
                      label: const Text("View Timetable"),
                      onPressed: () => context.push('/timetable'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.clipboardCheck, size: 16),
                      label: const Text("View Attendance"),
                      onPressed: () => context.push('/attendance'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.bookOpen, size: 16),
                      label: const Text("View Notes"),
                      onPressed: () => context.push('/notes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context, StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    final metrics = profile.attendanceMetrics;
    final hasDetailed = profile.hasDetailedAttendance;
    final hasPctOnly = profile.hasPercentageOnlyAttendance;
    final pctMetrics = profile.historicalPercentageMetrics;

    if (!hasDetailed && !hasPctOnly) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Attendance Records",
          subtitle: "No attendance sessions or historical summaries recorded for this student.",
          icon: LucideIcons.clipboardCheck,
        ),
      );
    }

    final int totalHeld = metrics != null && metrics['totalHeld'] != null ? (metrics['totalHeld'] as num).toInt() : 0;
    final int totalPresent = metrics != null && metrics['totalPresent'] != null ? (metrics['totalPresent'] as num).toInt() : 0;
    final int liveHeld = metrics != null && metrics['liveHeld'] != null ? (metrics['liveHeld'] as num).toInt() : 0;
    final int livePresent = metrics != null && metrics['livePresent'] != null ? (metrics['livePresent'] as num).toInt() : 0;
    final int histDetailedHeld = metrics != null && metrics['historicalDetailedHeld'] != null ? (metrics['historicalDetailedHeld'] as num).toInt() : 0;
    final int histDetailedPresent = metrics != null && metrics['historicalDetailedPresent'] != null ? (metrics['historicalDetailedPresent'] as num).toInt() : 0;
    final double pct = metrics != null && metrics['percentage'] != null ? (metrics['percentage'] as num).toDouble() : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDetailed) ...[
            Row(
              children: [
                Expanded(
                  child: AcadexStatCard(
                    title: "Calculated Attendance",
                    value: "$pct%",
                    subtitle: "$totalPresent / $totalHeld sessions attended",
                    icon: LucideIcons.clipboardCheck,
                    iconColor: pct >= 75 ? AcadexColors.success : AcadexColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AcadexStatCard(
                    title: "Live Attendance",
                    value: liveHeld > 0 ? "$livePresent / $liveHeld" : "None",
                    subtitle: "Recorded in Acadex",
                    icon: LucideIcons.radio,
                    iconColor: AcadexColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AcadexStatCard(
                    title: "Imported Detailed",
                    value: histDetailedHeld > 0 ? "$histDetailedPresent / $histDetailedHeld" : "None",
                    subtitle: "Ingested historical sessions",
                    icon: LucideIcons.fileSpreadsheet,
                    iconColor: AcadexColors.accentTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (hasPctOnly) ...[
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.history, size: 18, color: AcadexColors.inkMuted),
                      const SizedBox(width: 8),
                      Text("Historical Percentage Records (Non-denominator)", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "These records represent historical percentage metrics that lack total session denominators. Per academic data integrity policy, they are kept distinct from calculated session totals.",
                    style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                  ),
                  const SizedBox(height: 12),
                  ...pctMetrics.map((pm) {
                    final label = pm['periodLabel'] ?? 'Historical Term';
                    final percentage = pm['percentage'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("$label", style: AcadexTypography.body(color: theme.colorScheme.onSurface)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AcadexRadius.xs),
                            ),
                            child: Text("$percentage% (Imported Metric)", style: const TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.primary, fontSize: 13)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessmentsTab(BuildContext context, StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    if (profile.assessments.isEmpty) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Assessments Available",
          subtitle: "No published assessment marks or evaluation history found for this student.",
          icon: LucideIcons.award,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AcadexStatCard(
                  title: "Total Assessments",
                  value: "${profile.assessments.length}",
                  subtitle: "Syllabus assessments evaluated",
                  icon: LucideIcons.award,
                  iconColor: AcadexColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AcadexStatCard(
                  title: "Pass / Standing",
                  value: "${profile.assessments.where((a) => a['isPassed'] == true).length} Passed",
                  subtitle: "${profile.assessments.where((a) => a['status'] == 'ABSENT').length} Absent",
                  icon: LucideIcons.checkCircle2,
                  iconColor: AcadexColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AcadexCard(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profile.assessments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = profile.assessments[i];
                final title = a['title'] ?? 'Assessment';
                final subjectName = a['subjectName'] ?? 'Subject';
                final status = a['status'] ?? 'NOT_ENTERED';
                final rawScore = a['rawScore'];
                final maxMarks = a['maximumMarks'] ?? 0;
                final isPassed = a['isPassed'];
                final isImported = a['sourceType'] == 'IMPORTED';
                final isHistoricalManual = a['sourceType'] == 'HISTORICAL_MANUAL';
                final importBatch = a['importBatchId'];

                Widget marksDisplay;
                if (status == 'ABSENT') {
                  marksDisplay = const AcadexBadge(label: "ABSENT", variant: AcadexBadgeVariant.danger);
                } else if (status == 'EXEMPTED') {
                  marksDisplay = const AcadexBadge(label: "EXEMPTED", variant: AcadexBadgeVariant.neutral);
                } else if (status == 'NOT_ENTERED') {
                  marksDisplay = const AcadexBadge(label: "PENDING", variant: AcadexBadgeVariant.warning);
                } else {
                  marksDisplay = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$rawScore / $maxMarks",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (isPassed != null) ...[
                        const SizedBox(width: 8),
                        AcadexBadge(
                          label: isPassed == true ? "PASS" : "FAIL",
                          variant: isPassed == true ? AcadexBadgeVariant.success : AcadexBadgeVariant.danger,
                        ),
                      ],
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                if (isImported) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AcadexColors.inkMuted.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                    ),
                                    child: Text(
                                      importBatch != null ? "Imported ($importBatch)" : "Imported",
                                      style: const TextStyle(fontSize: 10, color: AcadexColors.inkMuted, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ] else if (isHistoricalManual) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AcadexColors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                    ),
                                    child: const Text(
                                      "Historical Manual",
                                      style: TextStyle(fontSize: 10, color: AcadexColors.warning, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "$subjectName • ${a['assessmentType'] ?? 'Internal'}",
                              style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      marksDisplay,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab(BuildContext context, StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    if (profile.assignments.isEmpty) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Coursework Assignments",
          subtitle: "No published assignments found for this class section.",
          icon: LucideIcons.fileText,
        ),
      );
    }

    return SingleChildScrollView(
      child: AcadexCard(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profile.assignments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final asg = profile.assignments[i];
            final title = asg['title'] ?? 'Assignment';
            final dueDate = asg['dueDate'] ?? '—';
            final maxMarks = asg['maximumMarks'] ?? 0;
            final isSubmitted = asg['isSubmitted'] == true;
            final marks = asg['marks'];

            return ListTile(
              leading: Icon(
                isSubmitted ? LucideIcons.fileCheck : LucideIcons.fileClock,
                color: isSubmitted ? AcadexColors.success : AcadexColors.warning,
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Due: $dueDate • Max Marks: $maxMarks"),
              trailing: marks != null
                  ? Text("Score: $marks / $maxMarks", style: const TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.primary))
                  : AcadexBadge(
                      label: isSubmitted ? "SUBMITTED" : "PENDING",
                      variant: isSubmitted ? AcadexBadgeVariant.success : AcadexBadgeVariant.warning,
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubjectsTab(StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    final subjects = profile.subjectsWithFaculty.isNotEmpty
        ? profile.subjectsWithFaculty
        : profile.enrolledSubjects.map((s) => {'name': s.name, 'code': s.code, 'credits': s.credits, 'facultyName': null}).toList();

    if (subjects.isEmpty) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Enrolled Subjects",
          subtitle: "No syllabus subjects mapped for current academic term.",
          icon: LucideIcons.bookOpen,
        ),
      );
    }

    return SingleChildScrollView(
      child: AcadexCard(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final sub = subjects[i];
            final name = sub['name'] ?? 'Subject';
            final code = sub['code'] ?? '';
            final credits = sub['credits'] ?? 0;
            final faculty = sub['facultyName'];

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AcadexRadius.xs),
                ),
                child: Text("$code", style: const TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.primary)),
              ),
              title: Text("$name", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(faculty != null ? "$credits Credits • Instructor: $faculty" : "$credits Credits"),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesTab(StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    if (profile.notesCount == 0) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Notes Available",
          subtitle: "No course notes or lecture slides uploaded for enrolled subjects.",
          icon: LucideIcons.stickyNote,
        ),
      );
    }

    return SingleChildScrollView(
      child: AcadexCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.stickyNote, color: AcadexColors.primary),
                const SizedBox(width: 8),
                Text("Subject Notes & Materials", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "There are ${profile.notesCount} shared notes available for this student's enrolled courses.",
              style: AcadexTypography.body(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/notes'),
              icon: const Icon(LucideIcons.externalLink, size: 16),
              label: const Text("Open Notes Library"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    if (profile.contactRequests.isEmpty) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Contact Requests",
          subtitle: "No student profile or contact update requests on file.",
          icon: LucideIcons.inbox,
        ),
      );
    }

    return SingleChildScrollView(
      child: AcadexCard(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profile.contactRequests.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final req = profile.contactRequests[i];
            final status = req['status'] ?? 'PENDING';
            final phone = req['requestedPhone'] ?? '—';
            final reason = req['reason'] ?? 'Contact update';

            AcadexBadgeVariant variant = AcadexBadgeVariant.warning;
            if (status == 'APPROVED') variant = AcadexBadgeVariant.success;
            if (status == 'REJECTED') variant = AcadexBadgeVariant.danger;

            return ListTile(
              leading: const Icon(LucideIcons.phoneCall, color: AcadexColors.primary),
              title: Text("Requested Phone: $phone", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(reason),
              trailing: AcadexBadge(label: status, variant: variant),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAcademicRecordsTab(StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    final hasRecords = profile.academicRecords.isNotEmpty || profile.officialResults.isNotEmpty;

    if (!hasRecords) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Certified Academic Records",
          subtitle: "No semester records or official certified results published yet.",
          icon: LucideIcons.graduationCap,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.officialResults.isNotEmpty) ...[
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Official Published Results", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  ...profile.officialResults.map((r) {
                    final sem = r['semester'] ?? 'Semester';
                    final sgpa = r['sgpa'] ?? '—';
                    final resultStatus = r['resultStatus'] ?? 'PUBLISHED';
                    return ListTile(
                      title: Text("$sem", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("SGPA: $sgpa"),
                      trailing: AcadexBadge(label: "$resultStatus", variant: AcadexBadgeVariant.success),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (profile.academicRecords.isNotEmpty) ...[
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Academic Records Registry", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  ...profile.academicRecords.map((ar) {
                    return ListTile(
                      leading: const Icon(LucideIcons.award, color: AcadexColors.primary),
                      title: Text("${ar['recordType'] ?? 'Term Record'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${ar['details'] ?? 'Academic Registry Entry'}"),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineTab(Student student, StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    final hasHistory = student.history.isNotEmpty || profile.enrollmentHistory.isNotEmpty;

    if (!hasHistory) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Academic History",
          subtitle: "Past academic milestones, promotions, and transfers will appear here.",
          icon: LucideIcons.history,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.enrollmentHistory.isNotEmpty) ...[
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Enrollment History", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  ...profile.enrollmentHistory.map((eh) {
                    final sem = eh['semesterId'] != null ? "Semester ${eh['semesterId']['number'] ?? ''}" : "Term";
                    final yr = eh['academicYearId'] != null ? "${eh['academicYearId']['name'] ?? ''}" : "";
                    final status = eh['status'] ?? 'active';
                    return ListTile(
                      leading: const Icon(LucideIcons.milestone, color: AcadexColors.primary),
                      title: Text("$sem • $yr", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Section: ${eh['sectionId']?['name'] ?? '—'}"),
                      trailing: AcadexBadge(
                        label: status.toUpperCase(),
                        variant: status == 'active' ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (student.history.isNotEmpty)
            AcadexCard(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: student.history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = student.history[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.milestone, size: 20, color: AcadexColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.status,
                                  style: AcadexTypography.title(color: theme.colorScheme.onSurface).copyWith(fontSize: 15),
                                ),
                                if (item.termEndDate != null || item.termStartDate != null)
                                  Text(
                                    item.termEndDate != null
                                        ? "${item.termEndDate!.day}/${item.termEndDate!.month}/${item.termEndDate!.year}"
                                        : "${item.termStartDate!.day}/${item.termStartDate!.month}/${item.termStartDate!.year}",
                                    style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AcadexEntityFormatters.formatAcademicContext(
                                semester: AcadexEntityFormatters.formatSemesterLabel(item.semesterName, rawId: item.semesterId),
                                section: AcadexEntityFormatters.formatSectionLabel(item.sectionName, rawId: item.sectionId, fallback: 'Section Not Assigned'),
                              ),
                              style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AcadexColors.inkMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFacultyPriorityContextCard(FacultyPriorityContext ctx, bool isDark, ThemeData theme) {
    final borderColor = isDark
        ? const Color(0xFF3B82F6).withValues(alpha: 0.45)
        : const Color(0xFF2563EB).withValues(alpha: 0.35);
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.25) : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(AcadexRadius.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 13,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "YOUR TEACHING CONTEXT",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (ctx.attendancePercentage >= 75
                          ? AcadexColors.success
                          : AcadexColors.warning)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AcadexRadius.xs),
                ),
                child: Text(
                  ctx.attendancePercentage >= 75 ? "Good Attendance" : "Attention Needed",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ctx.attendancePercentage >= 75
                        ? AcadexColors.success
                        : AcadexColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${ctx.subjectName} • ${ctx.subjectCode}",
                      style: AcadexTypography.title(color: theme.colorScheme.onSurface).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Section ${ctx.sectionName}",
                      style: AcadexTypography.body(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _buildPriorityMetric(
                label: "Attendance",
                value: "${ctx.attendedSessions} / ${ctx.totalSessions}",
                percentage: "${ctx.attendancePercentage.toStringAsFixed(0)}%",
                icon: LucideIcons.clipboardCheck,
                color: ctx.attendancePercentage >= 75 ? AcadexColors.success : AcadexColors.warning,
              ),
              _buildPriorityMetric(
                label: "Assignments",
                value: "${ctx.submittedAssignments} / ${ctx.totalAssignments}",
                percentage: ctx.totalAssignments > 0
                    ? "${((ctx.submittedAssignments / ctx.totalAssignments) * 100).toStringAsFixed(0)}%"
                    : "N/A",
                icon: LucideIcons.fileCheck,
                color: AcadexColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityMetric({
    required String label,
    required String value,
    required String percentage,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AcadexRadius.xs),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AcadexColors.inkMuted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  "•  $percentage",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
