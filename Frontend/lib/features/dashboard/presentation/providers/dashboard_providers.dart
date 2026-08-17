import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/activity_item_model.dart';
import '../../domain/models/dashboard_stat_model.dart';
import '../../domain/models/quick_action_model.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';

// ── Super Admin ──────────────────────────────────────────────────────────────

final superAdminStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final summary = await repo.getSuperAdminSummary();

  return [
    DashboardStatModel(
      title: 'Total Colleges',
      value: '${summary.totalColleges}',
      subtitle: '${summary.pendingColleges} pending',
      icon: LucideIcons.building,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
      changePercent: 8.5,
    ),
    DashboardStatModel(
      title: 'Total Students',
      value: '${summary.totalStudents}',
      subtitle: 'Across all campuses',
      icon: LucideIcons.users,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
      changePercent: 12.3,
    ),
    DashboardStatModel(
      title: 'Total Faculty',
      value: '${summary.totalFaculty}',
      subtitle: 'Active this semester',
      icon: LucideIcons.userCheck,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
      changePercent: 3.1,
    ),
    DashboardStatModel(
      title: 'Total Depts',
      value: '${summary.totalDepartments}',
      subtitle: 'Across all colleges',
      icon: LucideIcons.shieldCheck,
      iconColor: DashboardColors.orange,
      iconBackground: DashboardColors.orangeLight,
    ),
  ];
});

final superAdminQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/module/Timetable',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'Notes',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes',
      ),
      const QuickActionModel(
        label: 'Profile',
        icon: LucideIcons.userCircle,
        iconColor: DashboardColors.orange,
        iconBackground: DashboardColors.orangeLight,
        route: '/profile',
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
        title: 'New college registered',
        subtitle: 'Sunrise Engineering College added',
        timeAgo: '2h ago',
        icon: LucideIcons.building,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
      ),
      const ActivityItemModel(
        title: 'Bulk student upload',
        subtitle: '320 students imported to CS dept',
        timeAgo: '5h ago',
        icon: LucideIcons.upload,
        iconColor: DashboardColors.success,
        iconBackground: DashboardColors.successLight,
      ),
      const ActivityItemModel(
        title: 'Faculty account created',
        subtitle: 'Dr. Arjun Sharma assigned to MECH',
        timeAgo: 'Yesterday',
        icon: LucideIcons.userPlus,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
      ),
    ];
});

// ── College Admin ─────────────────────────────────────────────────────────────

final collegeAdminStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final summary = await repo.getCollegeSummary();

  return [
    DashboardStatModel(
      title: 'Departments',
      value: '${summary.totalDepartments}',
      subtitle: 'Active this semester',
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
      subtitle: 'Enrolled this semester',
      icon: LucideIcons.users,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
      changePercent: 7.8,
    ),
    DashboardStatModel(
      title: 'Avg Attendance',
      value: '${summary.todayAttendancePercentage}%',
      subtitle: 'College-wide average',
      icon: LucideIcons.clipboardCheck,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
      changePercent: -1.2,
    ),
  ];
});

final collegeAdminQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/module/Timetable',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'Notes',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes',
      ),
      const QuickActionModel(
        label: 'Profile',
        icon: LucideIcons.userCircle,
        iconColor: DashboardColors.orange,
        iconBackground: DashboardColors.orangeLight,
        route: '/profile',
      ),
      const QuickActionModel(
        label: 'Settings',
        icon: LucideIcons.settings,
        iconColor: DashboardColors.textSecondary,
        iconBackground: DashboardColors.divider,
        route: '/settings',
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

// ── HOD ───────────────────────────────────────────────────────────────────────

final hodStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final summary = await repo.getDepartmentSummary('d1');
  return [
    DashboardStatModel(
      title: 'Faculty',
      value: '${summary.totalFaculty}',
      subtitle: 'In your department',
      icon: LucideIcons.userCheck,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
    DashboardStatModel(
      title: 'Students',
      value: '${summary.totalStudents}',
      subtitle: 'Enrolled this semester',
      icon: LucideIcons.users,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
      changePercent: 5.0,
    ),
    const DashboardStatModel(
      title: 'Subjects',
      value: '24',
      subtitle: 'Active subjects',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.teal,
      iconBackground: DashboardColors.tealLight,
    ),
    DashboardStatModel(
      title: 'Attendance',
      value: '${summary.overallPercentage}%',
      subtitle: 'Dept avg completion',
      icon: LucideIcons.clipboardCheck,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
      changePercent: -2.4,
    ),
  ];
});

final hodQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/module/Timetable',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'Notes',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes',
      ),
      const QuickActionModel(
        label: 'Profile',
        icon: LucideIcons.userCircle,
        iconColor: DashboardColors.orange,
        iconBackground: DashboardColors.orangeLight,
        route: '/profile',
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
        subtitle: '3 students below 60% in Algorithms',
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

// ── Faculty ───────────────────────────────────────────────────────────────────

final facultyStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final classes = await repo.getAssignedClasses('f1', DateTime.now());
  return [
    const DashboardStatModel(
      title: 'Subjects',
      value: '4',
      subtitle: 'Assigned this semester',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
    DashboardStatModel(
      title: "Today's Classes",
      value: '${classes.length}',
      subtitle: 'Next at 11:00 AM',
      icon: LucideIcons.clock,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
    ),
    const DashboardStatModel(
      title: 'Pending Tasks',
      value: '7',
      subtitle: 'Attendance & notes',
      icon: LucideIcons.listTodo,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
    ),
    const DashboardStatModel(
      title: 'Students',
      value: '180',
      subtitle: 'Across all subjects',
      icon: LucideIcons.users,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
  ];
});

final facultyQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/module/Timetable',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'Notes',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes',
      ),
      const QuickActionModel(
        label: 'Profile',
        icon: LucideIcons.userCircle,
        iconColor: DashboardColors.orange,
        iconBackground: DashboardColors.orangeLight,
        route: '/profile',
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
        title: 'Notes uploaded',
        subtitle: 'OS Unit 3 PDF published',
        timeAgo: '3h ago',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
      ),
      const ActivityItemModel(
        title: 'Class reminder',
        subtitle: 'DBMS lecture at 2:00 PM today',
        timeAgo: 'Upcoming',
        icon: LucideIcons.bell,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
      ),
    ];
});

// ── Student ───────────────────────────────────────────────────────────────────

final studentStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final overview = await repo.getStudentAttendanceOverview('s1');

  return [
    DashboardStatModel(
      title: 'Attendance',
      value: '${overview.overallPercentage}%',
      subtitle: 'Semester average',
      icon: LucideIcons.clipboardCheck,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
      changePercent: 1.5,
    ),
    const DashboardStatModel(
      title: "Today's Classes",
      value: '4',
      subtitle: 'Next: OS at 10:00 AM',
      icon: LucideIcons.clock,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
    const DashboardStatModel(
      title: 'AI Assistant',
      value: 'Ready',
      subtitle: 'Your campus guide',
      icon: LucideIcons.bot,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
    ),
    const DashboardStatModel(
      title: 'Notes',
      value: '28',
      subtitle: 'Available to download',
      icon: LucideIcons.fileText,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
  ];
});

final studentQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/module/Timetable',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),
      const QuickActionModel(
        label: 'Notes',
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
      const QuickActionModel(
        label: 'Profile',
        icon: LucideIcons.userCircle,
        iconColor: DashboardColors.orange,
        iconBackground: DashboardColors.orangeLight,
        route: '/profile',
      ),
      const QuickActionModel(
        label: 'Settings',
        icon: LucideIcons.settings,
        iconColor: DashboardColors.textSecondary,
        iconBackground: DashboardColors.divider,
        route: '/settings',
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
        title: 'Asked Campus AI',
        subtitle: 'Question about hostel fees answered',
        timeAgo: 'Yesterday',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
      ),
    ];
});
