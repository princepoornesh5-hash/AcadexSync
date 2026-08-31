ACADEX — FACULTY DASHBOARD SMALL-SCREEN OVERFLOW FIX

IMPORTANT:

The Faculty Dashboard is STILL NOT PASS.

The current problem is now clearly identified:

On the smallest mobile configuration:

- 360 × 640 dp
- font scale 1.0

the Faculty Dashboard visibly overflows / clips.

The jitter issue appears fixed, but the SMALL-SCREEN LAYOUT IS STILL BROKEN.

DO NOT mark Faculty Dashboard PASS until this is completely resolved.

============================================================
DO NOT TOUCH
============================================================

Do NOT modify:

- Super Admin Dashboard
- College Admin Dashboard
- HOD Dashboard
- Student Dashboard
- Backend
- API
- MongoDB
- Authentication
- Shared Prompt 1 foundation
- Global navigation
- Global theme

Only modify the Faculty Dashboard and, if absolutely necessary,
the specific child widget causing the overflow.

============================================================
STEP 1 — REPRODUCE EXACTLY
============================================================

Use the physical Motorola Edge 60 Fusion.

Set:

wm size 720x1280
wm density 320
font_scale 1.0

This corresponds to approximately:

360 × 640 dp

Open:

FACULTY → DASHBOARD

Visually inspect the entire screen.

Do NOT rely only on logs.

Find the exact overflowing widget.

============================================================
STEP 2 — IDENTIFY THE EXACT OFFENDING AREA
============================================================

Inspect:

faculty_dashboard.dart

Especially:

- assigned subjects grid
- assigned sections cards
- quick operations
- teaching overview
- stat cards
- action buttons
- badges
- title/subtitle rows
- icon button rows

Determine exactly which widget exceeds the available width.

Do not guess.

============================================================
STEP 3 — MEASURE AVAILABLE WIDTH
============================================================

For the 360dp viewport, calculate the REAL content width after:

- page horizontal padding
- SafeArea
- any card padding
- grid spacing
- card internal padding

Do not use the entire screen width as available card width.

Explicitly calculate:

availableWidth

Then calculate:

grid column width

Then inspect whether the child content can fit.

============================================================
STEP 4 — CHECK GRID STRATEGY
============================================================

Do NOT assume a 2-column grid is appropriate for every section.

For 360dp width:

If the content cannot safely fit in 2 columns,

switch the affected Faculty Dashboard section to:

ONE COLUMN

rather than squeezing the cards.

Preferred rule:

Very small mobile:
≤ 374dp
→ 1 column

Normal mobile:
375–599dp
→ 2 columns only when content safely fits

Tablet/Desktop:
→ existing multi-column layout

Do NOT hardcode device models.

Use available width / breakpoint.

============================================================
STEP 5 — CHECK CARD INTERNAL CONTENT
============================================================

Inspect every child inside the overflowing card.

Potential offenders:

- long subject title
- long section name
- badge
- subject code
- section count
- trailing menu
- 3 action icons
- fixed icon widths
- horizontal Rows
- `MainAxisAlignment.spaceBetween`

Replace unsafe horizontal Rows with:

Flexible
Expanded
Wrap
Overflow-safe layout

Long text should:

- wrap where appropriate
- use maxLines
- ellipsis where appropriate

============================================================
STEP 6 — ACTION BUTTONS
============================================================

If the card currently contains three or more action buttons on one row:

DO NOT force them to remain on one row on a 360dp phone.

Use one of:

- compact icon buttons
- Wrap
- overflow menu
- stacked actions
- secondary action menu

Preserve the same functionality.

Do NOT remove functionality.

============================================================
STEP 7 — CHECK CARD PADDING
============================================================

Audit:

horizontal padding
internal spacing
icon spacing
badge spacing

Do not use excessive internal padding.

But do not shrink touch targets below 44–48dp.

Touch target safety is more important than fitting everything into
one row.

============================================================
STEP 8 — CHECK QUICK ACTIONS
============================================================

Inspect Quick Operations.

If the current implementation is horizontally packed on 360dp:

Use a responsive layout.

Preferred:

360dp:
2-column compact grid OR vertical list

375dp+:
2-column grid if it fits

Do not force five buttons into a single row.

============================================================
STEP 9 — DO NOT USE FittedBox AS A BLIND FIX
============================================================

Do NOT solve the overflow by wrapping the entire dashboard in:

FittedBox

Do NOT globally reduce the font size.

Do NOT globally scale the entire dashboard.

Do NOT use arbitrary negative padding.

The solution must be structurally responsive.

============================================================
STEP 10 — TEST ALL THREE CONFIGURATIONS
============================================================

After fixing the small-device overflow, verify:

A:
360 × 640 dp
font scale 1.0

B:
390 × 844 dp
font scale 1.25

C:
412 × 915 dp
font scale 1.15

Requirements:

A must have ZERO overflow.

B must have ZERO overflow.

C must have ZERO overflow.

============================================================
STEP 11 — PHYSICAL DEVICE TEST
============================================================

On the physical Motorola:

Faculty login
→ Faculty Dashboard

Then inspect:

- header
- stats
- assigned subjects
- quick actions
- teaching sections
- every card
- bottom navigation

Do not touch the screen for 10 seconds.

Then scroll slowly from top to bottom.

There must be:

- no horizontal overflow
- no clipped card
- no text outside card
- no button outside card
- no visible RenderFlex overflow
- no horizontal scrollbar
- no layout jumping

============================================================
STEP 12 — REGRESSION
============================================================

Verify quickly:

Super Admin Dashboard      PASS
College Admin Dashboard    PASS
HOD Dashboard              PASS
Student Dashboard          PASS

Do NOT modify these dashboards.

============================================================
STEP 13 — BUILD
============================================================

Run:

flutter analyze lib/

flutter build web

flutter build apk --debug

============================================================
SUCCESS CRITERIA
============================================================

Faculty Dashboard can ONLY be marked PASS when:

360dp      → NO OVERFLOW
390dp      → NO OVERFLOW
412dp      → NO OVERFLOW

and:

- all controls remain usable
- all text readable
- all actions still available
- no clipping
- no horizontal overflow
- no jitter
- no layout jumping

============================================================
FINAL REPORT
============================================================

Report:

1. Exact widget causing the 360dp overflow
2. Why it overflowed
3. Exact width/constraint problem
4. Exact fix
5. Files changed
6. 360dp result
7. 390dp result
8. 412dp result
9. Other-role regression result
10. flutter analyze
11. web build
12. Android build

Do NOT say PASS if 360dp still has visible overflow.

STOP AFTER THIS FIX.import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/activity_item_model.dart';
import '../../domain/models/dashboard_stat_model.dart';
import '../../domain/models/quick_action_model.dart';
import '../../../attendance/domain/models/assigned_class.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

// ── Super Admin (Platform Owner) ──────────────────────────────────────────────

final superAdminStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final summary = await repo.getSuperAdminSummary();

  return [
    DashboardStatModel(
      title: 'Total Colleges',
      value: '${summary.totalColleges}',
      subtitle: 'Registered institutions',
      icon: LucideIcons.building,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
    DashboardStatModel(
      title: 'College Admins',
      value: '${summary.totalColleges}',
      subtitle: 'Active administrators',
      icon: LucideIcons.userCheck,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
    DashboardStatModel(
      title: 'Total Faculty',
      value: '${summary.totalFaculty}',
      subtitle: 'Active faculty members',
      icon: LucideIcons.users,
      iconColor: DashboardColors.teal,
      iconBackground: DashboardColors.tealLight,
    ),
    DashboardStatModel(
      title: 'Total Students',
      value: '${summary.totalStudents}',
      subtitle: 'Enrolled students',
      icon: LucideIcons.graduationCap,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
    ),
    DashboardStatModel(
      title: 'Global Attendance',
      value: '${summary.todayAttendancePercentage.toStringAsFixed(1)}%',
      subtitle: 'Platform-wide average',
      icon: LucideIcons.clipboardCheck,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
    ),
    DashboardStatModel(
      title: 'Platform Activity',
      value: '${summary.totalColleges + summary.totalDepartments} units',
      subtitle: 'Active academic units',
      icon: LucideIcons.activity,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
  ];
});

final superAdminQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Add College',
        icon: LucideIcons.building,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/academics/colleges/new',
      ),
      const QuickActionModel(
        label: 'Create User',
        icon: LucideIcons.userPlus,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/users/new',
      ),
      const QuickActionModel(
        label: 'Manage Users',
        icon: LucideIcons.users,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/users',
      ),
      const QuickActionModel(
        label: 'View Reports',
        icon: LucideIcons.barChart3,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/analytics',
      ),
      const QuickActionModel(
        label: 'Audit Logs',
        icon: LucideIcons.shieldCheck,
        iconColor: DashboardColors.success,
        iconBackground: DashboardColors.successLight,
        route: '/settings',
      ),
    ]);

final superAdminActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  final notifsAsync = ref.watch(notificationsProvider);
  final notifs = notifsAsync.value ?? [];
  if (notifs.isEmpty) return [];

  return notifs.take(5).map((n) {
    return ActivityItemModel(
      title: n.title,
      subtitle: n.message,
      timeAgo: _formatTimeAgo(n.timestamp),
      icon: LucideIcons.bell,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    );
  }).toList();
});

// ── College Admin (College Operational Authority) ─────────────────────────────

final collegeAdminStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final repo = ref.watch(attendanceRepoProvider);
  final summary = await repo.getCollegeSummary();
  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  final years = ref.watch(academicYearsProvider).valueOrNull ?? [];
  final activeYear = years.where((y) => y.isCurrent || y.status == 'active').firstOrNull;

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
    ),
    DashboardStatModel(
      title: 'Students',
      value: '${summary.totalStudents}',
      subtitle: 'Enrolled across depts',
      icon: LucideIcons.users,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
    ),
    DashboardStatModel(
      title: 'Attendance',
      value: '${summary.todayAttendancePercentage.toStringAsFixed(1)}%',
      subtitle: 'College-wide metric',
      icon: LucideIcons.clipboardCheck,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
    ),
    DashboardStatModel(
      title: 'Subjects',
      value: '${subjects.length}',
      subtitle: 'Curriculum offerings',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.teal,
      iconBackground: DashboardColors.tealLight,
    ),
    DashboardStatModel(
      title: 'Academic Year',
      value: activeYear?.name ?? 'Active',
      subtitle: 'Current cycle',
      icon: LucideIcons.calendar,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
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
        label: 'Add Faculty',
        icon: LucideIcons.userPlus,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/academics/faculty/new',
      ),
      const QuickActionModel(
        label: 'Add HOD',
        icon: LucideIcons.userCheck,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/academics/departments',
      ),
      const QuickActionModel(
        label: 'Add Student',
        icon: LucideIcons.graduationCap,
        iconColor: DashboardColors.success,
        iconBackground: DashboardColors.successLight,
        route: '/academics/students/new',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/timetable/manage',
      ),
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/attendance',
      ),
    ]);

final collegeAdminActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  final notifsAsync = ref.watch(notificationsProvider);
  final notifs = notifsAsync.value ?? [];
  if (notifs.isEmpty) return [];

  return notifs.take(5).map((n) {
    return ActivityItemModel(
      title: n.title,
      subtitle: n.message,
      timeAgo: _formatTimeAgo(n.timestamp),
      icon: LucideIcons.bell,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    );
  }).toList();
});

// ── HOD (Department Operational Authority) ────────────────────────────────────

final hodStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final departmentId = authState is AuthAuthenticated ? (authState.user.departmentId ?? '') : '';

  final repo = ref.watch(attendanceRepoProvider);
  final summary = departmentId.isNotEmpty
      ? await repo.getDepartmentSummary(departmentId)
      : null;

  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  final subjectsCount = subjects.where((s) => departmentId.isEmpty || s.departmentId == departmentId).length;

  return [
    DashboardStatModel(
      title: 'Dept Faculty',
      value: '${summary?.totalFaculty ?? 0}',
      subtitle: 'In your department',
      icon: LucideIcons.userCheck,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
    DashboardStatModel(
      title: 'Dept Students',
      value: '${summary?.totalStudents ?? 0}',
      subtitle: 'Enrolled this semester',
      icon: LucideIcons.users,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
    DashboardStatModel(
      title: 'Dept Subjects',
      value: '$subjectsCount',
      subtitle: 'Active curriculum',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.teal,
      iconBackground: DashboardColors.tealLight,
    ),
    DashboardStatModel(
      title: 'Dept Attendance',
      value: '${(summary?.overallPercentage ?? 0.0).toStringAsFixed(1)}%',
      subtitle: 'Department average',
      icon: LucideIcons.clipboardCheck,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
    ),
  ];
});

final hodQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Faculty',
        icon: LucideIcons.userCheck,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/academics/faculty',
      ),
      const QuickActionModel(
        label: 'Students',
        icon: LucideIcons.graduationCap,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/academics/students',
      ),
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/timetable/manage',
      ),
      const QuickActionModel(
        label: 'Notes',
        icon: LucideIcons.fileText,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/notes',
      ),
    ]);

final hodActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  final notifsAsync = ref.watch(notificationsProvider);
  final notifs = notifsAsync.value ?? [];
  if (notifs.isEmpty) return [];

  return notifs.take(5).map((n) {
    return ActivityItemModel(
      title: n.title,
      subtitle: n.message,
      timeAgo: _formatTimeAgo(n.timestamp),
      icon: LucideIcons.bell,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    );
  }).toList();
});

// ── Faculty (Teaching Operations Workspace) ───────────────────────────────────

final facultyStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final assignments = ref.watch(myFacultyAssignmentsProvider);
  final repo = ref.watch(attendanceRepoProvider);
  final authState = ref.watch(authProvider);
  final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';
  
  final classes = currentUserId.isNotEmpty
      ? await repo.getAssignedClasses(currentUserId, DateTime.now()).catchError((_) => <AssignedClass>[])
      : <AssignedClass>[];
  final uniqueSubjects = assignments.map((a) => a.subjectId).toSet().length;
  final uniqueSections = assignments.map((a) => a.sectionId).toSet().length;

  final sections = ref.watch(sectionsProvider).valueOrNull ?? [];
  final assignedSectionIds = assignments.map((a) => a.sectionId).toSet();
  final assignedStudentsCount = sections
      .where((s) => assignedSectionIds.contains(s.id))
      .fold<int>(0, (sum, s) => sum + (s.capacity > 0 ? s.capacity : 0));

  return [
    DashboardStatModel(
      title: 'My Subjects',
      value: '$uniqueSubjects',
      subtitle: 'Assigned courses',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    ),
    DashboardStatModel(
      title: "Today's Classes",
      value: '${classes.length}',
      subtitle: 'Active classes',
      icon: LucideIcons.clock,
      iconColor: DashboardColors.success,
      iconBackground: DashboardColors.successLight,
    ),
    DashboardStatModel(
      title: 'My Sections',
      value: '$uniqueSections',
      subtitle: 'Assigned sections',
      icon: LucideIcons.layoutGrid,
      iconColor: DashboardColors.warning,
      iconBackground: DashboardColors.warningLight,
    ),
    DashboardStatModel(
      title: 'Assigned Students',
      value: '$assignedStudentsCount',
      subtitle: 'Across assigned classes',
      icon: LucideIcons.users,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
  ];
});

final facultyQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Mark Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.teal,
        iconBackground: DashboardColors.tealLight,
        route: '/attendance',
      ),
      const QuickActionModel(
        label: 'My Classes',
        icon: LucideIcons.bookOpen,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
        route: '/my-assignments',
      ),
      const QuickActionModel(
        label: 'Upload Note',
        icon: LucideIcons.filePlus,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/notes/new',
      ),
      const QuickActionModel(
        label: "Today's Timetable",
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/timetable',
      ),
    ]);

final facultyActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  final notifsAsync = ref.watch(notificationsProvider);
  final notifs = notifsAsync.value ?? [];
  if (notifs.isEmpty) return [];

  return notifs.take(5).map((n) {
    return ActivityItemModel(
      title: n.title,
      subtitle: n.message,
      timeAgo: _formatTimeAgo(n.timestamp),
      icon: LucideIcons.bell,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    );
  }).toList();
});

// ── Student (Academic Hub) ───────────────────────────────────────────────────

final studentStatsProvider = FutureProvider<List<DashboardStatModel>>((ref) async {
  final profile = await ref.watch(currentStudentAcademicProfileProvider.future).catchError((_) => null);
  final schedule = ref.watch(todayScheduleProvider).value ?? [];
  final notes = ref.watch(userNotesProvider).value ?? [];

  final attPercentage = profile?.overallAttendancePercentage ?? 0.0;
  final enrolledSubs = profile?.enrolledSubjects.length ?? 0;
  final notesCount = notes.length;
  final todayClasses = schedule.length;

  return [
    DashboardStatModel(
      title: 'Overall Attendance',
      value: '${attPercentage.toStringAsFixed(1)}%',
      subtitle: attPercentage >= 75 ? 'Good standing' : (attPercentage > 0 ? 'Low attendance alert' : 'No records yet'),
      icon: LucideIcons.clipboardCheck,
      iconColor: attPercentage >= 75 ? DashboardColors.success : (attPercentage > 0 ? DashboardColors.warning : DashboardColors.textSecondary),
      iconBackground: attPercentage >= 75 ? DashboardColors.successLight : (attPercentage > 0 ? DashboardColors.warningLight : DashboardColors.divider),
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
      title: 'Subjects',
      value: '$enrolledSubs',
      subtitle: 'Enrolled courses',
      icon: LucideIcons.bookOpen,
      iconColor: DashboardColors.purple,
      iconBackground: DashboardColors.purpleLight,
    ),
    DashboardStatModel(
      title: 'New Notes',
      value: '$notesCount',
      subtitle: 'Study materials',
      icon: LucideIcons.fileText,
      iconColor: DashboardColors.teal,
      iconBackground: DashboardColors.tealLight,
    ),
  ];
});

final studentQuickActionsProvider = Provider<List<QuickActionModel>>((ref) => [
      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/timetable',
      ),
      const QuickActionModel(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        iconColor: DashboardColors.primary,
        iconBackground: DashboardColors.primaryLight,
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
        label: 'Subjects',
        icon: LucideIcons.bookOpen,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/academics/subjects',
      ),
    ]);

final studentActivityProvider = FutureProvider<List<ActivityItemModel>>((ref) async {
  final notifsAsync = ref.watch(notificationsProvider);
  final notifs = notifsAsync.value ?? [];
  if (notifs.isEmpty) return [];

  return notifs.take(5).map((n) {
    return ActivityItemModel(
      title: n.title,
      subtitle: n.message,
      timeAgo: _formatTimeAgo(n.timestamp),
      icon: LucideIcons.bell,
      iconColor: DashboardColors.primary,
      iconBackground: DashboardColors.primaryLight,
    );
  }).toList();
});

String _formatTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays}d ago';
}
