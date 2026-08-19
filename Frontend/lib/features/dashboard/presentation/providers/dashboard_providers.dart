import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/activity_item_model.dart';
import '../../domain/models/dashboard_stat_model.dart';
import '../../domain/models/quick_action_model.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';

// ── Super Admin ──────────────────────────────────────────────────────────────

// ── Super Admin (Platform Owner) ──────────────────────────────────────────────

final superAdminStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final summary = await repo.getSuperAdminSummary();

  return [
    DashboardStatModel(
      title: 'Total Colleges',
      value: '${summary.totalColleges}',
      subtitle: '${summary.pendingColleges} on trial',
      icon: LucideIcons.building,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
      changePercent: 8.5,
    ),
    DashboardStatModel(
      title: 'Platform Users',
      value: '${summary.totalStudents + summary.totalFaculty}',
      subtitle: 'Across all colleges',
      icon: LucideIcons.users,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
      changePercent: 14.2,
    ),
    const DashboardStatModel(
      title: 'Platform Revenue',
      value: '\$48.2k',
      subtitle: 'Monthly recurring (MRR)',
      icon: LucideIcons.creditCard,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
      changePercent: 6.8,
    ),
    const DashboardStatModel(
      title: 'Storage & Health',
      value: '99.98%',
      subtitle: 'Platform SLA uptime',
      icon: LucideIcons.server,
      iconColor: DashboardColors.teal,
      iconBackground: DashboardColors.tealLight,
    ),
  ];
});

final superAdminQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Colleges',
        icon: LucideIcons.building,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/academics/colleges',
      ),
      const QuickActionModel(
        label: 'Users',
        icon: LucideIcons.users,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/users',
      ),
      const QuickActionModel(
        label: 'Analytics',
        icon: LucideIcons.barChart3,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/analytics',
      ),
      const QuickActionModel(
        label: 'Announcements',
        icon: LucideIcons.megaphone,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/notifications/create',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'Settings',
        icon: LucideIcons.settings,
        iconColor: DashboardColors.textSecondary,
        iconBackground: DashboardColors.divider,
        route: '/settings',
      ),
    ]);

final superAdminActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
      const ActivityItemModel(
        title: 'New college onboarded',
        subtitle: 'Sunrise Institute registered & activated',
        timeAgo: '2h ago',
        icon: LucideIcons.building,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
      ),
      const ActivityItemModel(
        title: 'Subscription renewed',
        subtitle: 'Global Tech annual enterprise plan active',
        timeAgo: '5h ago',
        icon: LucideIcons.checkCircle,
        iconColor: DashboardColors.success,
        iconBackground: DashboardColors.successLight,
      ),
      const ActivityItemModel(
        title: 'Global announcement published',
        subtitle: 'Scheduled maintenance notice broadcasted',
        timeAgo: 'Yesterday',
        icon: LucideIcons.megaphone,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
      ),
    ];
});

// ── College Admin (College Operational Authority) ─────────────────────────────

final collegeAdminStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final summary = await repo.getCollegeSummary();

  return [
    DashboardStatModel(
      title: 'Departments',
      value: '${summary.totalDepartments}',
      subtitle: 'Active departments',
      icon: LucideIcons.layoutGrid,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
    DashboardStatModel(
      title: 'Faculty',
      value: '${summary.totalFaculty}',
      subtitle: 'Teaching staff',
      icon: LucideIcons.userCheck,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
      changePercent: 2.5,
    ),
    DashboardStatModel(
      title: 'Students',
      value: '${summary.totalStudents}',
      subtitle: 'Enrolled across depts',
      icon: LucideIcons.users,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
      changePercent: 7.8,
    ),
    DashboardStatModel(
      title: 'Avg Attendance',
      value: '${summary.todayAttendancePercentage}%',
      subtitle: 'College-wide today',
      icon: LucideIcons.clipboardCheck,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
      changePercent: 1.2,
    ),
  ];
});

final collegeAdminQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Add Dept',
        icon: LucideIcons.plusCircle,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/academics/departments/new',
      ),
      const QuickActionModel(
        label: 'Add Course',
        icon: LucideIcons.bookMarked,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/academics/courses/new',
      ),
      const QuickActionModel(
        label: 'Add Section',
        icon: LucideIcons.layoutGrid,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/academics/sections/new',
      ),
      const QuickActionModel(
        label: 'Add Subject',
        icon: LucideIcons.bookOpen,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/academics/subjects/new',
      ),
      const QuickActionModel(
        label: 'Add Faculty',
        icon: LucideIcons.userPlus,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/academics/faculty/new',
      ),
      const QuickActionModel(
        label: 'Add Student',
        icon: LucideIcons.graduationCap,
        iconColor: DashboardColors.success,
        iconBackground: DashboardColors.successLight,
        route: '/academics/students/new',
      ),
      const QuickActionModel(
        label: 'Assignments',
        icon: LucideIcons.userCheck,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/faculty-assignments',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/timetable',
      ),
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'Analytics',
        icon: LucideIcons.barChart3,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/analytics',
      ),
    ]);

final collegeAdminActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
      const ActivityItemModel(
        title: 'Attendance report generated',
        subtitle: 'Week 3 report for all departments',
        timeAgo: '1h ago',
        icon: LucideIcons.fileBarChart,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
      ),
      const ActivityItemModel(
        title: 'New faculty onboarded',
        subtitle: 'Prof. Meena Reddy joins EEE dept',
        timeAgo: '3h ago',
        icon: LucideIcons.userPlus,
        iconColor: DashboardColors.success,
        iconBackground: DashboardColors.successLight,
      ),
      const ActivityItemModel(
        title: 'Timetable updated',
        subtitle: 'Civil dept timetable revised for Week 4',
        timeAgo: 'Yesterday',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
      ),
    ];
});

// ── HOD (Department Operational Authority) ────────────────────────────────────

final hodStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final summary = await repo.getDepartmentSummary('d1');
  return [
    DashboardStatModel(
      title: 'Dept Faculty',
      value: '${summary.totalFaculty}',
      subtitle: 'In your department',
      icon: LucideIcons.userCheck,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
    DashboardStatModel(
      title: 'Dept Students',
      value: '${summary.totalStudents}',
      subtitle: 'Enrolled this semester',
      icon: LucideIcons.users,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
      changePercent: 5.0,
    ),
    const DashboardStatModel(
      title: 'Dept Subjects',
      value: '24',
      subtitle: 'Active curriculum',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.teal,
      iconBackground: DashboardColors.tealLight,
    ),
    DashboardStatModel(
      title: 'Dept Attendance',
      value: '${summary.overallPercentage}%',
      subtitle: 'Average this week',
      icon: LucideIcons.clipboardCheck,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
      changePercent: -2.4,
    ),
  ];
});

final hodQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Add Subject',
        icon: LucideIcons.bookOpen,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/academics/subjects/new',
      ),
      const QuickActionModel(
        label: 'Add Section',
        icon: LucideIcons.layoutGrid,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/academics/sections/new',
      ),
      const QuickActionModel(
        label: 'Assign Faculty',
        icon: LucideIcons.userCheck,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/faculty-assignments',
      ),
      const QuickActionModel(
        label: 'Faculty List',
        icon: LucideIcons.users,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/academics/faculty',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/timetable',
      ),
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'Notes',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes',
      ),
      const QuickActionModel(
        label: 'Students',
        icon: LucideIcons.graduationCap,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/academics/students',
      ),
      const QuickActionModel(
        label: 'Workload',
        icon: LucideIcons.barChart3,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/faculty-workload',
      ),
    ]);

final hodActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
      const ActivityItemModel(
        title: 'Faculty meeting scheduled',
        subtitle: 'Dept review on Friday 10:00 AM',
        timeAgo: '30m ago',
        icon: LucideIcons.calendarCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
      ),
      const ActivityItemModel(
        title: 'Attendance alert',
        subtitle: '3 students below 75% in Algorithms',
        timeAgo: '2h ago',
        icon: LucideIcons.alertCircle,
        iconColor: DashboardColors.error,
        iconBackground: DashboardColors.errorLight,
      ),
      const ActivityItemModel(
        title: 'Notes uploaded',
        subtitle: 'Data Structures Unit 4 notes added',
        timeAgo: 'Yesterday',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
      ),
    ];
});

// ── Faculty (Teaching Operations Workspace) ───────────────────────────────────

final facultyStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final assignments = ref.watch(myFacultyAssignmentsProvider);
  final repo = ref.watch(attendanceRepoProvider);
  final authState = ref.watch(authProvider);
  final currentUserId = authState is AuthAuthenticated ? authState.user.id : 'f1';
  
  final classes = await repo.getAssignedClasses(currentUserId, DateTime.now());
  final uniqueSubjects = assignments.map((a) => a.subjectId).toSet().length;
  final uniqueSections = assignments.map((a) => a.sectionId).toSet().length;

  final studentsState = ref.watch(studentsProvider((sectionId: null, departmentId: null)));
  final assignedSectionIds = assignments.map((a) => a.sectionId).toSet();
  final assignedStudentsCount = studentsState.items.where((s) => assignedSectionIds.contains(s.sectionId) && s.isActive).length;

  return [
    DashboardStatModel(
      title: 'My Subjects',
      value: assignments.isNotEmpty ? '$uniqueSubjects' : '0',
      subtitle: 'Assigned courses',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
    DashboardStatModel(
      title: "Today's Classes",
      value: '${classes.isNotEmpty ? classes.length : (assignments.isNotEmpty ? assignments.length : 0)}',
      subtitle: 'Active classes',
      icon: LucideIcons.clock,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
    ),
    DashboardStatModel(
      title: 'My Sections',
      value: assignments.isNotEmpty ? '$uniqueSections' : '0',
      subtitle: 'Assigned sections',
      icon: LucideIcons.layoutGrid,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
    ),
    DashboardStatModel(
      title: 'Assigned Students',
      value: assignedStudentsCount > 0 ? '$assignedStudentsCount' : '${assignments.length * 40}',
      subtitle: 'Across assigned classes',
      icon: LucideIcons.users,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
  ];
});

final facultyQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'My Assignments',
        icon: LucideIcons.bookOpen,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/my-assignments',
      ),
      const QuickActionModel(
        label: 'Mark Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'My Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/timetable',
      ),
      const QuickActionModel(
        label: 'Upload Notes',
        icon: LucideIcons.filePlus,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes/new',
      ),
      const QuickActionModel(
        label: 'Notes & Resources',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),
    ]);

final facultyActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
      const ActivityItemModel(
        title: 'Attendance marked',
        subtitle: 'CS301 — 42/45 present',
        timeAgo: '1h ago',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
      ),
      const ActivityItemModel(
        title: 'Notes published',
        subtitle: 'OS Unit 3 PDF uploaded',
        timeAgo: '3h ago',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
      ),
      const ActivityItemModel(
        title: 'Class schedule',
        subtitle: 'DBMS lecture at 2:00 PM today',
        timeAgo: 'Upcoming',
        icon: LucideIcons.bell,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
      ),
    ];
});

// ── Student (Academic Hub) ───────────────────────────────────────────────────

final studentStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final profile = await ref.watch(currentStudentAcademicProfileProvider.future);
  final schedule = ref.watch(todayScheduleProvider).value ?? [];

  final attPercentage = profile?.overallAttendancePercentage ?? 85.0;
  final enrolledSubs = profile?.enrolledSubjects.length ?? 0;
  final notesCount = profile?.notesCount ?? 0;
  final todayClasses = schedule.length;

  return [
    DashboardStatModel(
      title: 'My Attendance',
      value: '${attPercentage.toStringAsFixed(1)}%',
      subtitle: attPercentage >= 75 ? 'Good standing' : 'Low attendance alert',
      icon: LucideIcons.clipboardCheck,
      iconColor: attPercentage >= 75 ? DashboardColors.success : DashboardColors.warning,
      iconBackground: attPercentage >= 75 ? DashboardColors.successLight : DashboardColors.warningLight,
      changePercent: 1.5,
    ),
    DashboardStatModel(
      title: "Today's Classes",
      value: '$todayClasses',
      subtitle: todayClasses > 0 ? '$todayClasses scheduled' : 'No classes today',
      icon: LucideIcons.clock,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
    DashboardStatModel(
      title: 'Study Notes',
      value: '$notesCount',
      subtitle: 'Available to study',
      icon: LucideIcons.fileText,
      iconColor: DashboardColors.teal,
      iconBackground: DashboardColors.tealLight,
    ),
    DashboardStatModel(
      title: 'Enrolled Subjects',
      value: '$enrolledSubs',
      subtitle: 'Current semester',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
  ];
});

final studentQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'My Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'My Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/timetable',
      ),
      const QuickActionModel(
        label: 'Study Notes',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes',
      ),
      const QuickActionModel(
        label: 'Official Docs',
        icon: LucideIcons.fileCheck2,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/official-certificates',
      ),
      const QuickActionModel(
        label: 'Achievements',
        icon: LucideIcons.trophy,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/achievements',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.info,
        iconBackground: DashboardColors.infoLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'My Profile',
        icon: LucideIcons.userCircle,
        iconColor: DashboardColors.orange,
        iconBackground: DashboardColors.orangeLight,
        route: '/profile',
      ),
    ]);

final studentActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
      const ActivityItemModel(
        title: 'Attendance updated',
        subtitle: 'CS301 — You were marked present',
        timeAgo: '2h ago',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.success,
        iconBackground: DashboardColors.successLight,
      ),
      const ActivityItemModel(
        title: 'New notes available',
        subtitle: 'OS Unit 4 notes by Prof. Sharma',
        timeAgo: '4h ago',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
      ),
      const ActivityItemModel(
        title: 'Campus AI Assistant',
        subtitle: 'Exam timetable and syllabus active',
        timeAgo: 'Yesterday',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
      ),
    ];
});
