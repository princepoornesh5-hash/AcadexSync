import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/design_system/acadex_breakpoints.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

class RoleDashboardScreen extends ConsumerWidget {
  const RoleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final dashboardAsync = ref.watch(roleDashboardReportProvider);

    if (currentUser == null) {
      return const AcadexPageContainer(
        child: AcadexLoadingState(message: 'Loading user profile...'),
      );
    }

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(roleDashboardReportProvider);
      },
      child: dashboardAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading dashboard metrics...'),
        error: (err, _) => AcadexErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(roleDashboardReportProvider),
        ),
        data: (dashboard) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcadexPageHeader(
                title: 'ACADEX Dashboard',
                subtitle: 'Welcome back, ${currentUser.name}',
              ),
              _buildRoleDashboard(context, ref, currentUser.role, dashboard?.metrics ?? {}),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleDashboard(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    Map<String, dynamic> metrics,
  ) {
    switch (role) {
      case AppRole.superAdmin:
        return _buildSuperAdminDashboard(context, metrics);
      case AppRole.collegeAdmin:
        return _buildCollegeAdminDashboard(context, metrics);
      case AppRole.hod:
        return _buildHodDashboard(context, metrics);
      case AppRole.faculty:
        return _buildFacultyDashboard(context, metrics);
      case AppRole.student:
        return _buildStudentDashboard(context, metrics);
    }
  }

  // --- 1. Super Admin View ---
  Widget _buildSuperAdminDashboard(BuildContext context, Map<String, dynamic> m) {
    final columns = AcadexBreakpoints.getGridColumnCount(context, mobile: 2, tablet: 2, desktop: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AcadexSectionHeader(title: 'Platform Overview', subtitle: 'Global ACADEX network health'),
        const SizedBox(height: AcadexSpacing.sm),
        GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AcadexSpacing.md,
          mainAxisSpacing: AcadexSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AcadexStatCard(
              title: 'Colleges',
              value: (m['totalColleges'] ?? '12').toString(),
              subtitle: 'Active campuses',
              icon: Icons.account_balance,
              iconColor: AcadexColors.superAdminBadge,
            ),
            AcadexStatCard(
              title: 'Total Users',
              value: (m['totalUsers'] ?? '4,850').toString(),
              subtitle: 'Students & Staff',
              icon: Icons.people_outline,
              iconColor: AcadexColors.skyInfo,
            ),
            AcadexStatCard(
              title: 'Attendance Rate',
              value: '${(m['overallAttendance'] ?? 88.5)}%',
              subtitle: 'Across all colleges',
              icon: Icons.check_circle_outline,
              iconColor: AcadexColors.present,
            ),
            AcadexStatCard(
              title: 'Storage Used',
              value: '${(m['storageUsedMB'] ?? 1420)} MB',
              subtitle: 'ImageKit media',
              icon: Icons.cloud_outlined,
              iconColor: AcadexColors.amberAccent,
            ),
          ],
        ),
        const SizedBox(height: AcadexSpacing.xl),
        const AcadexSectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AcadexSpacing.sm),
        _buildActionRow(context, [
          const _ActionItem(label: 'Campuses', icon: Icons.domain, route: '/academics/colleges'),
          const _ActionItem(label: 'Global Users', icon: Icons.group, route: '/users'),
          const _ActionItem(label: 'Security & Logs', icon: Icons.shield_outlined, route: '/settings'),
          const _ActionItem(label: 'Platform Reports', icon: Icons.analytics_outlined, route: '/analytics'),
        ]),
      ],
    );
  }

  // --- 2. College Admin View ---
  Widget _buildCollegeAdminDashboard(BuildContext context, Map<String, dynamic> m) {
    final columns = AcadexBreakpoints.getGridColumnCount(context, mobile: 2, tablet: 2, desktop: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AcadexSectionHeader(title: 'College Overview', subtitle: 'Campus administrative pulse'),
        const SizedBox(height: AcadexSpacing.sm),
        GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AcadexSpacing.md,
          mainAxisSpacing: AcadexSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AcadexStatCard(
              title: 'Departments',
              value: (m['totalDepartments'] ?? '6').toString(),
              subtitle: 'Academic divisions',
              icon: Icons.business_outlined,
              iconColor: AcadexColors.collegeAdminBadge,
            ),
            AcadexStatCard(
              title: 'Faculty',
              value: (m['totalFaculty'] ?? '48').toString(),
              subtitle: 'Teaching staff',
              icon: Icons.school_outlined,
              iconColor: AcadexColors.facultyBadge,
            ),
            AcadexStatCard(
              title: 'Students',
              value: (m['totalStudents'] ?? '1,240').toString(),
              subtitle: 'Enrolled students',
              icon: Icons.groups_outlined,
              iconColor: AcadexColors.studentBadge,
            ),
            AcadexStatCard(
              title: 'Today Attendance',
              value: '${(m['todayAttendance'] ?? 86.4)}%',
              subtitle: 'Campus average',
              icon: Icons.fact_check_outlined,
              iconColor: AcadexColors.present,
            ),
          ],
        ),
        const SizedBox(height: AcadexSpacing.xl),
        const AcadexSectionHeader(title: 'Administrative Tools'),
        const SizedBox(height: AcadexSpacing.sm),
        _buildActionRow(context, [
          const _ActionItem(label: 'Departments', icon: Icons.account_tree_outlined, route: '/academics/departments'),
          const _ActionItem(label: 'Faculty Directory', icon: Icons.badge_outlined, route: '/academics/faculty'),
          const _ActionItem(label: 'Timetable Manager', icon: Icons.schedule_outlined, route: '/timetable/manage'),
          const _ActionItem(label: 'Attendance Analytics', icon: Icons.bar_chart_outlined, route: '/attendance'),
        ]),
      ],
    );
  }

  // --- 3. HOD View ---
  Widget _buildHodDashboard(BuildContext context, Map<String, dynamic> m) {
    final columns = AcadexBreakpoints.getGridColumnCount(context, mobile: 2, tablet: 2, desktop: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AcadexSectionHeader(title: 'Department Overview', subtitle: 'Academic operations'),
        const SizedBox(height: AcadexSpacing.sm),
        GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AcadexSpacing.md,
          mainAxisSpacing: AcadexSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AcadexStatCard(
              title: 'Dept Faculty',
              value: (m['deptFacultyCount'] ?? '12').toString(),
              subtitle: 'Assigned teachers',
              icon: Icons.person_outline,
              iconColor: AcadexColors.hodBadge,
            ),
            AcadexStatCard(
              title: 'Active Sections',
              value: (m['activeSections'] ?? '6').toString(),
              subtitle: 'Current semesters',
              icon: Icons.meeting_room_outlined,
              iconColor: AcadexColors.skyInfo,
            ),
            AcadexStatCard(
              title: 'Dept Attendance',
              value: '${(m['deptAttendance'] ?? 89.2)}%',
              subtitle: 'Today rate',
              icon: Icons.how_to_reg_outlined,
              iconColor: AcadexColors.present,
            ),
            AcadexStatCard(
              title: 'Published Notes',
              value: (m['publishedNotes'] ?? '34').toString(),
              subtitle: 'Study materials',
              icon: Icons.menu_book_outlined,
              iconColor: AcadexColors.amberAccent,
            ),
          ],
        ),
        const SizedBox(height: AcadexSpacing.xl),
        const AcadexSectionHeader(title: 'Department Actions'),
        const SizedBox(height: AcadexSpacing.sm),
        _buildActionRow(context, [
          const _ActionItem(label: 'Class Schedules', icon: Icons.calendar_today_outlined, route: '/timetable/manage'),
          const _ActionItem(label: 'Attendance Logs', icon: Icons.checklist_outlined, route: '/attendance'),
          const _ActionItem(label: 'Students at Risk', icon: Icons.warning_amber_outlined, route: '/academics/students'),
          const _ActionItem(label: 'Department Notes', icon: Icons.library_books_outlined, route: '/notes'),
        ]),
      ],
    );
  }

  // --- 4. Faculty View ---
  Widget _buildFacultyDashboard(BuildContext context, Map<String, dynamic> m) {
    final columns = AcadexBreakpoints.getGridColumnCount(context, mobile: 2, tablet: 2, desktop: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AcadexSectionHeader(title: 'Teaching Overview', subtitle: 'Your daily schedule & classes'),
        const SizedBox(height: AcadexSpacing.sm),
        GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AcadexSpacing.md,
          mainAxisSpacing: AcadexSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AcadexStatCard(
              title: "Today's Classes",
              value: (m['todayClassesCount'] ?? '3').toString(),
              subtitle: 'Scheduled periods',
              icon: Icons.access_time_outlined,
              iconColor: AcadexColors.facultyBadge,
            ),
            AcadexStatCard(
              title: 'Assigned Subjects',
              value: (m['assignedSubjectsCount'] ?? '2').toString(),
              subtitle: 'Active courses',
              icon: Icons.auto_stories_outlined,
              iconColor: AcadexColors.skyInfo,
            ),
            AcadexStatCard(
              title: 'Attendance Marked',
              value: '${(m['attendanceCompletionRate'] ?? 100)}%',
              subtitle: 'This week',
              icon: Icons.task_alt_outlined,
              iconColor: AcadexColors.present,
            ),
            AcadexStatCard(
              title: 'My Notes',
              value: (m['myNotesCount'] ?? '14').toString(),
              subtitle: 'Shared files',
              icon: Icons.note_alt_outlined,
              iconColor: AcadexColors.purpleAccent,
            ),
          ],
        ),
        const SizedBox(height: AcadexSpacing.xl),
        const AcadexSectionHeader(title: 'Quick Tools'),
        const SizedBox(height: AcadexSpacing.sm),
        _buildActionRow(context, [
          const _ActionItem(label: 'Mark Attendance', icon: Icons.how_to_reg_outlined, route: '/attendance'),
          const _ActionItem(label: 'Upload Notes', icon: Icons.upload_file_outlined, route: '/notes/new'),
          const _ActionItem(label: 'My Timetable', icon: Icons.calendar_month_outlined, route: '/timetable'),
          const _ActionItem(label: 'Student Records', icon: Icons.people_alt_outlined, route: '/my-assignments'),
        ]),
      ],
    );
  }

  // --- 5. Student View ---
  Widget _buildStudentDashboard(BuildContext context, Map<String, dynamic> m) {
    final columns = AcadexBreakpoints.getGridColumnCount(context, mobile: 2, tablet: 2, desktop: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AcadexSectionHeader(title: 'Student Portal', subtitle: 'Academic progress & timetable'),
        const SizedBox(height: AcadexSpacing.sm),
        GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AcadexSpacing.md,
          mainAxisSpacing: AcadexSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AcadexStatCard(
              title: 'My Attendance',
              value: '${(m['overallAttendance'] ?? 87.2)}%',
              subtitle: 'Requirement: >=75%',
              icon: Icons.pie_chart_outline,
              iconColor: AcadexColors.present,
            ),
            AcadexStatCard(
              title: "Today's Periods",
              value: (m['todayClassesCount'] ?? '4').toString(),
              subtitle: 'Next: 10:30 AM',
              icon: Icons.schedule_outlined,
              iconColor: AcadexColors.studentBadge,
            ),
            AcadexStatCard(
              title: 'Course Notes',
              value: (m['availableNotesCount'] ?? '28').toString(),
              subtitle: 'Available to download',
              icon: Icons.download_for_offline_outlined,
              iconColor: AcadexColors.emeraldTeal,
            ),
            AcadexStatCard(
              title: 'Announcements',
              value: (m['unreadAnnouncements'] ?? '2').toString(),
              subtitle: 'Unread updates',
              icon: Icons.notifications_none_outlined,
              iconColor: AcadexColors.amberAccent,
            ),
          ],
        ),
        const SizedBox(height: AcadexSpacing.xl),
        const AcadexSectionHeader(title: 'Student Hub'),
        const SizedBox(height: AcadexSpacing.sm),
        _buildActionRow(context, [
          const _ActionItem(label: 'My Schedule', icon: Icons.calendar_view_week_outlined, route: '/timetable'),
          const _ActionItem(label: 'Subject Attendance', icon: Icons.assessment_outlined, route: '/attendance'),
          const _ActionItem(label: 'Download Notes', icon: Icons.menu_book_outlined, route: '/notes'),
          const _ActionItem(label: 'Campus Notices', icon: Icons.campaign_outlined, route: '/notifications'),
        ]),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, List<_ActionItem> actions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AcadexSpacing.md,
          runSpacing: AcadexSpacing.md,
          children: actions.map((act) {
            return SizedBox(
              width: (constraints.maxWidth - AcadexSpacing.md * 3) / 4 > 120
                  ? (constraints.maxWidth - AcadexSpacing.md * 3) / 4
                  : (constraints.maxWidth - AcadexSpacing.md) / 2,
              child: AcadexCard(
                onTap: act.route != null ? () => context.push(act.route!) : null,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(act.icon, size: 24, color: AcadexColors.primaryNavy),
                    const SizedBox(height: AcadexSpacing.sm),
                    Text(
                      act.label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AcadexColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final String? route;

  const _ActionItem({required this.label, required this.icon, this.route});
}
