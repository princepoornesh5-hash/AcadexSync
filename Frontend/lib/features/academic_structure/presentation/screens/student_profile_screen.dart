import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isStaff = currentUser?.role == AppRole.superAdmin ||
        currentUser?.role == AppRole.collegeAdmin ||
        currentUser?.role == AppRole.hod;

    final profileAsync = ref.watch(studentAcademicProfileProvider(widget.studentId));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Student Academic Profile",
          style: AcadexTypography.title(color: theme.colorScheme.onSurface),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: AcadexLoadingState(message: "Loading academic profile...")),
        error: (err, _) => Center(
          child: AcadexErrorState(
            title: "Profile Not Found",
            message: err.toString(),
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
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(icon: Icon(LucideIcons.graduationCap, size: 16), text: "Academic Enrollment"),
                    Tab(icon: Icon(LucideIcons.history, size: 16), text: "Timeline & History"),
                    Tab(icon: Icon(LucideIcons.user, size: 16), text: "Personal Details"),
                    Tab(icon: Icon(LucideIcons.bookOpen, size: 16), text: "Assigned Faculty & Subjects"),
                  ],
                ),
                const SizedBox(height: 20),

                // Tab Views
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Academic Enrollment Overview
                      _buildAcademicOverviewTab(profile, isDark, theme),

                      // Tab 2: Timeline & History
                      _buildTimelineTab(student, isDark, theme),

                      // Tab 3: Personal Details
                      _buildPersonalDetailsTab(student, isDark, theme),

                      // Tab 4: Assigned Faculty & Enrolled Subjects
                      _buildFacultyAndSubjectsTab(profile, isDark, theme),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAcademicOverviewTab(StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    final student = profile.student;

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AcadexStatCard(
                  title: "Current Term",
                  value: profile.semester?.name ?? "Semester",
                  subtitle: "Section ${profile.section?.name ?? '—'}",
                  icon: LucideIcons.calendar,
                  iconColor: AcadexColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AcadexStatCard(
                  title: "Enrolled Subjects",
                  value: "${profile.enrolledSubjects.length}",
                  subtitle: "Active courses",
                  icon: LucideIcons.bookOpen,
                  iconColor: AcadexColors.accentTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AcadexStatCard(
                  title: "Attendance Average",
                  value: "${profile.overallAttendancePercentage.toStringAsFixed(1)}%",
                  subtitle: profile.overallAttendancePercentage >= 75.0 ? "Good standing" : "Low attendance",
                  icon: LucideIcons.clipboardCheck,
                  iconColor: profile.overallAttendancePercentage >= 75.0 ? AcadexColors.success : AcadexColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AcadexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Academic Structure Mapping", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                _buildDetailRow("College ID", student.collegeId),
                _buildDetailRow("Department", profile.department?.name ?? student.departmentId),
                _buildDetailRow("Course", "${profile.course?.name ?? student.courseId} (${profile.course?.code ?? ''})"),
                _buildDetailRow("Academic Year", profile.academicYear?.name ?? (student.academicYearId.isNotEmpty ? student.academicYearId : 'Current')),
                _buildDetailRow("Semester", profile.semester?.name ?? student.semesterId),
                _buildDetailRow("Section", "Section ${profile.section?.name ?? student.sectionId}"),
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

  Widget _buildTimelineTab(Student student, bool isDark, ThemeData theme) {
    if (student.history.isEmpty) {
      return const Center(
        child: AcadexEmptyState(
          title: "No Academic History",
          subtitle: "Past academic milestones, promotions, and transfers will appear here.",
          icon: LucideIcons.history,
        ),
      );
    }

    return ListView.separated(
      itemCount: student.history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = student.history[i];

        return AcadexCard(
          child: Row(
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
                      "${item.semesterName.isNotEmpty ? item.semesterName : item.semesterId} • ${item.sectionName.isNotEmpty ? 'Section ' + item.sectionName : item.sectionId}",
                      style: AcadexTypography.body(color: theme.colorScheme.onSurface),
                    ),
                    if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.remarks!,
                        style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalDetailsTab(Student student, bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      child: AcadexCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Personal & Guardian Information", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            _buildDetailRow("Full Name", student.name),
            _buildDetailRow("Roll Number", student.rollNumber),
            _buildDetailRow("Email Address", student.email),
            _buildDetailRow("Phone Number", student.phone.isNotEmpty ? student.phone : "—"),
            _buildDetailRow("Parent / Guardian", student.parentName ?? "—"),
            _buildDetailRow("Parent Phone", student.parentPhone ?? "—"),
            _buildDetailRow("Blood Group", student.bloodGroup ?? "—"),
            _buildDetailRow("Address", student.address ?? "—"),
            _buildDetailRow("Date of Birth", student.dateOfBirth != null ? "${student.dateOfBirth!.day}/${student.dateOfBirth!.month}/${student.dateOfBirth!.year}" : "—"),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyAndSubjectsTab(StudentAcademicProfile profile, bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcadexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Assigned Faculty (${profile.assignedFaculty.length})", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                profile.assignedFaculty.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No faculty currently assigned to this class."),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: profile.assignedFaculty.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final f = profile.assignedFaculty[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AcadexColors.primary.withValues(alpha: 0.12),
                              child: Text(f.name.isNotEmpty ? f.name[0].toUpperCase() : 'F'),
                            ),
                            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${f.employeeId} • ${f.email}"),
                          );
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AcadexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Enrolled Subjects (${profile.enrolledSubjects.length})", style: AcadexTypography.title(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                profile.enrolledSubjects.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No active subjects in current semester syllabus."),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: profile.enrolledSubjects.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final sub = profile.enrolledSubjects[i];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AcadexColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AcadexRadius.xs),
                              ),
                              child: Text(sub.code, style: const TextStyle(fontWeight: FontWeight.bold, color: AcadexColors.primary)),
                            ),
                            title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${sub.credits} Credits • ${sub.type}"),
                          );
                        },
                      ),
              ],
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
}
