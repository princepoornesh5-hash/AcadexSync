import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/domain/models/role_enum.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/presentation/providers/navigation_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/activation_screen.dart';
import '../../features/dashboard/presentation/screens/super_admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/college_admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/hod_dashboard.dart';
import '../../features/dashboard/presentation/screens/faculty_dashboard.dart';
import '../../features/dashboard/presentation/screens/student_dashboard.dart';
import '../../features/dashboard/presentation/screens/coming_soon_screen.dart';

import '../../features/academic_structure/presentation/screens/college_screens.dart';
import '../../features/academic_structure/presentation/screens/department_screens.dart';
import '../../features/academic_structure/presentation/screens/course_screens.dart';
import '../../features/academic_structure/presentation/screens/academic_year_screens.dart';
import '../../features/academic_structure/presentation/screens/semester_screens.dart';
import '../../features/academic_structure/presentation/screens/section_screens.dart';
import '../../features/academic_structure/presentation/screens/subject_screens.dart';
import '../../features/academic_structure/presentation/screens/faculty_screens.dart';
import '../../features/academic_structure/presentation/screens/student_screens.dart';
import '../../features/academic_structure/presentation/screens/faculty_assignments_management_screen.dart';
import '../../features/academic_structure/presentation/screens/faculty_workload_screen.dart';
import '../../features/academic_structure/presentation/screens/my_assignments_screen.dart';
import '../../features/academic_structure/presentation/screens/student_profile_screen.dart';
import '../../features/academic_structure/presentation/screens/academic_structure_home_screen.dart';

import '../../features/attendance/presentation/screens/attendance_dashboard_router.dart';
import '../../features/attendance/presentation/screens/mark_attendance_screen.dart';
import '../../features/attendance/presentation/screens/student_attendance_history_screen.dart';
import '../../features/attendance/presentation/screens/faculty_attendance_history_screen.dart';
import '../../features/attendance/presentation/screens/faculty_attendance_detail_screen.dart';
import '../../features/attendance/presentation/screens/attendance_analytics_screen.dart';
import '../../features/attendance/presentation/screens/student_attendance_detail_screen.dart';
import '../../features/attendance/presentation/screens/subject_attendance_detail_screen.dart';
import '../../features/attendance/presentation/screens/section_attendance_detail_screen.dart';
import '../../features/attendance/presentation/screens/attendance_alerts_screen.dart';
import '../../features/attendance/presentation/screens/attendance_alert_detail_screen.dart';
import '../../features/attendance/presentation/screens/attendance_report_center_screen.dart';
import '../../features/attendance/presentation/screens/attendance_session_admin_screen.dart';
import '../../features/attendance/presentation/screens/attendance_admin_dashboard_screen.dart';
import '../../features/attendance/presentation/screens/student_attendance_portal_screen.dart';
import '../../features/attendance/presentation/screens/student_attendance_dashboard_screen.dart';
import '../../features/attendance/presentation/screens/student_subject_attendance_screen.dart';
import '../../features/attendance/presentation/screens/student_attendance_calendar_screen.dart';
import '../../features/attendance/presentation/screens/student_session_detail_screen.dart';
import '../../features/attendance/domain/models/attendance_alert.dart';
import '../../features/attendance/presentation/providers/attendance_alert_providers.dart';

import '../../features/users/presentation/screens/user_directory_screen.dart';
import '../../features/users/presentation/screens/user_detail_screen.dart';
import '../../features/users/presentation/screens/user_form_screen.dart';
import '../../features/users/presentation/screens/profile_screen.dart';

import '../../features/settings/presentation/screens/settings_home_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/misc_settings_screens.dart';

import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../../features/notifications/presentation/screens/create_announcement_screen.dart';

import '../../features/timetable/presentation/screens/timetable_dashboard_screen.dart';
import '../../features/timetable/presentation/screens/timetable_management_screen.dart';
import '../../features/timetable/presentation/screens/timetable_form_screen.dart';
import '../../features/timetable/presentation/screens/timetable_setup_screen.dart';
import '../../features/timetable/presentation/screens/timetable_designer_screen.dart';
import '../../features/timetable/domain/models/timetable_models.dart';

import '../../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/analytics/presentation/screens/reports_list_screen.dart';
import '../../features/analytics/presentation/screens/report_preview_screen.dart';
import '../../features/analytics/domain/models/analytics_models.dart';

import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';

import '../../features/notes/presentation/screens/notes_dashboard_screen.dart';
import '../../features/notes/presentation/screens/note_detail_screen.dart';
import '../../features/notes/presentation/screens/note_form_screen.dart';
import '../../features/notes/domain/models/note_model.dart';

import '../../features/dashboard/presentation/widgets/acadex_drawer.dart';
import '../../features/dashboard/presentation/widgets/acadex_bottom_nav.dart';
import '../../features/dashboard/presentation/widgets/acadex_nav_rail.dart';
import '../../features/dashboard/presentation/widgets/acadex_app_bar.dart';
import '../theme/app_theme.dart';

class ShellWrapper extends ConsumerWidget {
  final Widget child;
  final String activeRoute;
  const ShellWrapper({super.key, required this.child, required this.activeRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= AcadexBreakpoints.mobileMax;
    final isTablet = width > AcadexBreakpoints.mobileMax && width <= AcadexBreakpoints.tabletMax;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).updateRoute(activeRoute);
    });

    return Scaffold(
      appBar: isMobile ? const AcadexAppBar(showDrawerButton: true) : null,
      drawer: isMobile ? AcadexDrawer(activeRoute: activeRoute, isModal: true) : null,
      bottomNavigationBar: isMobile
          ? AcadexBottomNav(
              activeRoute: activeRoute,
              onTabSelected: (route) => context.go(route),
            )
          : null,
      body: Row(
        children: [
          if (isTablet)
            AcadexNavRail(
              activeRoute: activeRoute,
              onDestinationSelected: (route) => context.go(route),
            ),
          if (!isMobile && !isTablet)
            AcadexDrawer(activeRoute: activeRoute, isModal: false),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// Fade + subtle slide transition helper (Acadex Motion standard: 200ms ease-out)
CustomTransitionPage<T> fadeTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AcadexMotion.isReducedMotion(context)) {
        return child;
      }
      final curve = CurvedAnimation(parent: animation, curve: AcadexMotion.curveStandard);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.02),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous != next) {
        // Prevent synchronous dispatch stack overflows by deferring notifyListeners
        Future.microtask(() => notifyListeners());
      }
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.read(routerNotifierProvider);

  String getHomeRouteForRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return '/dashboard/super_admin';
      case AppRole.collegeAdmin:
        return '/dashboard/college_admin';
      case AppRole.hod:
        return '/dashboard/hod';
      case AppRole.faculty:
        return '/dashboard/faculty';
      case AppRole.student:
        return '/dashboard/student';
    }
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final currentAuthState = ref.read(authProvider);
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/activate' ||
          state.matchedLocation == '/';

      developer.log(
        'Router redirect decision: path=${state.matchedLocation}, authState=${currentAuthState.runtimeType}',
        name: 'Acadex.Router',
      );

      if (currentAuthState is AuthProfileLoading) {
        // Stay on splash or loading screen if trying to access auth screens,
        // otherwise block access to protected routes while loading.
        return isGoingToAuth && state.matchedLocation != '/' ? '/' : (isGoingToAuth ? null : '/');
      }

      if (currentAuthState is AuthProfileError) {
        // Force to login if profile fails, but avoid infinite redirect loop if already on an auth route
        return isGoingToAuth ? null : '/login';
      }

      if (currentAuthState is! AuthAuthenticated) {
        return isGoingToAuth ? null : '/login';
      }

      // User is logged in
      final role = currentAuthState.user.role;
      final status = currentAuthState.user.accountStatus;

      // Inactive/suspended users should not access protected routes
      if (status != AccountStatus.active) {
        // We'll log them out automatically via authProvider logic if needed, 
        // but for router level, if they are inactive, redirect to login
        return isGoingToAuth ? null : '/login';
      }

      if (isGoingToAuth) {
        return getHomeRouteForRole(role);
      }

      final loc = state.matchedLocation;

      // Role guards
      if (loc.startsWith('/dashboard/')) {
        final expectedRoute = getHomeRouteForRole(role);
        if (loc != expectedRoute) {
          return expectedRoute;
        }
      }

      // Normalize /academic singular aliases to /academics canonical routes
      if (loc.startsWith('/academic/')) {
        final rest = loc.substring('/academic/'.length);
        if (rest == 'years') return '/academics/academic_years';
        if (rest == 'assignments' || rest == 'faculty/assignments') return '/faculty-assignments';
        if (rest == 'workload' || rest == 'faculty/workload') return '/faculty-workload';
        if (rest == 'assignments/my') return '/my-assignments';
        return '/academics/$rest';
      }

      // Academic routes & role protection
      if (loc.startsWith('/academics') || loc.startsWith('/academic')) {
        if (loc.startsWith('/academics/assignments/my') || loc.startsWith('/academic/assignments/my') || loc == '/my-assignments') {
          if (role != AppRole.faculty && role != AppRole.hod && role != AppRole.collegeAdmin) {
            return getHomeRouteForRole(role);
          }
        } else if (loc.startsWith('/academics/workload') || loc.startsWith('/academic/workload') || loc == '/faculty-workload') {
          if (role != AppRole.faculty && role != AppRole.hod && role != AppRole.collegeAdmin && role != AppRole.superAdmin) {
            return getHomeRouteForRole(role);
          }
        } else if (loc.startsWith('/academics/colleges') || loc.startsWith('/academic/colleges')) {
          if (role != AppRole.superAdmin) {
            return getHomeRouteForRole(role);
          }
        } else if (loc.startsWith('/academics/departments') || loc.startsWith('/academic/departments') ||
                   loc.startsWith('/academics/courses') || loc.startsWith('/academic/courses') ||
                   loc.startsWith('/academics/academic_years') || loc.startsWith('/academic/years') ||
                   loc.startsWith('/academics/semesters') || loc.startsWith('/academic/semesters')) {
          if (role != AppRole.superAdmin && role != AppRole.collegeAdmin) {
            return getHomeRouteForRole(role);
          }
        } else {
          // Subjects, Sections, Faculty, Students, Assignments (HOD, College Admin, Super Admin)
          if (role == AppRole.student) {
            return getHomeRouteForRole(role);
          }
        }
      }
      
      if (loc.startsWith('/users')) {
        if (role == AppRole.student || role == AppRole.faculty) {
          return getHomeRouteForRole(role);
        }
      }

      // Timetable management routes (HOD, College Admin, Super Admin only)
      if (loc.startsWith('/timetable/manage') || loc.startsWith('/timetable/new') || loc.startsWith('/timetable/edit')) {
        if (role == AppRole.student || role == AppRole.faculty) {
          return '/timetable';
        }
      }

      // Notes authoring routes (Faculty, HOD, Super Admin only; Students and College Admins redirected)
      if (loc.startsWith('/notes/new') || loc.startsWith('/notes/edit')) {
        if (role == AppRole.student || role == AppRole.collegeAdmin) {
          return '/notes';
        }
      }

      // Attendance administrative route protection (Students redirected to student portal)
      if (loc.startsWith('/attendance/mark') ||
          loc.startsWith('/attendance/admin') ||
          loc.startsWith('/attendance/sessions/admin') ||
          loc.startsWith('/attendance/faculty')) {
        if (role == AppRole.student) {
          return '/attendance';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) => const ActivationScreen(),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const GlobalSearchScreen(),
        ),
      ),
      
      // Dashboards
      GoRoute(
        path: '/dashboard/super_admin',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/super_admin', child: SuperAdminDashboard()),
        ),
      ),
      GoRoute(
        path: '/dashboard/college_admin',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/college_admin', child: CollegeAdminDashboard()),
        ),
      ),
      GoRoute(
        path: '/dashboard/hod',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/hod', child: HodDashboard()),
        ),
      ),
      GoRoute(
        path: '/dashboard/faculty',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/faculty', child: FacultyDashboard()),
        ),
      ),
      GoRoute(
        path: '/dashboard/student',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/student', child: StudentDashboard()),
        ),
      ),
      
      // Academic Structure Routes
      GoRoute(
        path: '/academics',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics', child: AcademicStructureHomeScreen()),
        ),
      ),
      GoRoute(
        path: '/academic-structure',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics', child: AcademicStructureHomeScreen()),
        ),
      ),
      GoRoute(path: '/academics/colleges', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/colleges', child: CollegeListScreen())),
      GoRoute(path: '/academics/colleges/new', builder: (context, state) => const CollegeFormScreen()),
      GoRoute(path: '/academics/colleges/edit/:id', builder: (context, state) => CollegeFormScreen(collegeId: state.pathParameters['id'])),

      GoRoute(path: '/academics/departments', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/departments', child: DepartmentListScreen())),
      GoRoute(path: '/academics/departments/new', builder: (context, state) => const DepartmentFormScreen()),
      GoRoute(path: '/academics/departments/edit/:id', builder: (context, state) => DepartmentFormScreen(id: state.pathParameters['id'])),

      GoRoute(path: '/academics/courses', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/courses', child: CourseListScreen())),
      GoRoute(path: '/academics/courses/new', builder: (context, state) => const CourseFormScreen()),
      GoRoute(path: '/academics/courses/edit/:id', builder: (context, state) => CourseFormScreen(id: state.pathParameters['id'])),

      GoRoute(path: '/academics/academic_years', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/academic_years', child: AcademicYearListScreen())),
      GoRoute(path: '/academics/academic_years/new', builder: (context, state) => const AcademicYearFormScreen()),
      GoRoute(path: '/academics/academic_years/edit/:id', builder: (context, state) => AcademicYearFormScreen(id: state.pathParameters['id'])),

      GoRoute(path: '/academics/semesters', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/semesters', child: SemesterListScreen())),
      GoRoute(path: '/academics/semesters/new', builder: (context, state) => const SemesterFormScreen()),
      GoRoute(path: '/academics/semesters/edit/:id', builder: (context, state) => SemesterFormScreen(id: state.pathParameters['id'])),

      GoRoute(path: '/academics/sections', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/sections', child: SectionListScreen())),
      GoRoute(path: '/academics/sections/new', builder: (context, state) => const SectionFormScreen()),
      GoRoute(path: '/academics/sections/edit/:id', builder: (context, state) => SectionFormScreen(id: state.pathParameters['id'])),

      GoRoute(path: '/academics/subjects', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/subjects', child: SubjectListScreen())),
      GoRoute(path: '/academics/subjects/new', builder: (context, state) => const SubjectFormScreen()),
      GoRoute(path: '/academics/subjects/edit/:id', builder: (context, state) => SubjectFormScreen(id: state.pathParameters['id'])),

      GoRoute(path: '/academics/faculty', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/faculty', child: FacultyListScreen())),
      GoRoute(path: '/academics/faculty/new', builder: (context, state) => const FacultyFormScreen()),
      GoRoute(path: '/academics/faculty/edit/:id', builder: (context, state) => FacultyFormScreen(id: state.pathParameters['id'])),

      // Faculty Assignments & Workload Routes
      GoRoute(
        path: '/faculty-assignments',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/faculty-assignments', child: FacultyAssignmentsManagementScreen()),
        ),
      ),
      GoRoute(
        path: '/academics/faculty/assignments',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/faculty-assignments', child: FacultyAssignmentsManagementScreen()),
        ),
      ),
      GoRoute(
        path: '/faculty-workload',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/faculty-workload', child: FacultyWorkloadScreen()),
        ),
      ),
      GoRoute(
        path: '/academics/faculty/workload',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/faculty-workload', child: FacultyWorkloadScreen()),
        ),
      ),
      GoRoute(
        path: '/my-assignments',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/my-assignments', child: MyAssignmentsScreen()),
        ),
      ),

      GoRoute(path: '/academics/students', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/students', child: StudentListScreen())),
      GoRoute(path: '/academics/students/new', builder: (context, state) => const StudentFormScreen()),
      GoRoute(path: '/academics/students/edit/:id', builder: (context, state) => StudentFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/students/:id', builder: (context, state) => StudentProfileScreen(studentId: state.pathParameters['id']!)),

      // Attendance Routes
      GoRoute(path: '/attendance', builder: (context, state) => const ShellWrapper(activeRoute: '/attendance', child: AttendanceDashboardRouter())),
      GoRoute(path: '/attendance/student', builder: (context, state) => const ShellWrapper(activeRoute: '/attendance', child: StudentAttendancePortalScreen())),
      GoRoute(path: '/attendance/student/dashboard', builder: (context, state) => const ShellWrapper(activeRoute: '/attendance', child: StudentAttendanceDashboardScreen())),
      GoRoute(path: '/attendance/student/subjects', builder: (context, state) => const ShellWrapper(activeRoute: '/attendance', child: StudentAttendancePortalScreen(initialTab: 1))),
      GoRoute(
        path: '/attendance/student/subject/:id',
        builder: (context, state) => ShellWrapper(
          activeRoute: '/attendance',
          child: StudentSubjectAttendanceScreen(subjectId: state.pathParameters['id']),
        ),
      ),
      GoRoute(path: '/attendance/student/calendar', builder: (context, state) => const ShellWrapper(activeRoute: '/attendance', child: StudentAttendanceCalendarScreen())),
      GoRoute(path: '/attendance/student/insights', builder: (context, state) => const ShellWrapper(activeRoute: '/attendance', child: StudentAttendancePortalScreen(initialTab: 3))),
      GoRoute(
        path: '/attendance/student/sessions/:id',
        builder: (context, state) => ShellWrapper(
          activeRoute: '/attendance',
          child: StudentSessionDetailScreen(sessionId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/attendance/mark', builder: (context, state) => const MarkAttendanceScreen()),
      GoRoute(path: '/attendance/student/history', builder: (context, state) => const StudentAttendanceHistoryScreen()),
      GoRoute(path: '/attendance/faculty/history', builder: (context, state) => const FacultyAttendanceHistoryScreen()),
      GoRoute(path: '/attendance/faculty/detail', builder: (context, state) => const FacultyAttendanceDetailScreen()),
      GoRoute(path: '/attendance/analytics', builder: (context, state) => const ShellWrapper(activeRoute: '/attendance/analytics', child: AttendanceAnalyticsScreen())),
      GoRoute(
        path: '/attendance/analytics/student/:id',
        builder: (context, state) => ShellWrapper(
          activeRoute: '/attendance/analytics',
          child: StudentAttendanceDetailScreen(studentId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/attendance/analytics/subject/:id',
        builder: (context, state) => ShellWrapper(
          activeRoute: '/attendance/analytics',
          child: SubjectAttendanceDetailScreen(subjectId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/attendance/analytics/section/:id',
        builder: (context, state) => ShellWrapper(
          activeRoute: '/attendance/analytics',
          child: SectionAttendanceDetailScreen(sectionId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/attendance/alerts',
        builder: (context, state) => const ShellWrapper(
          activeRoute: '/attendance/alerts',
          child: AttendanceAlertsScreen(),
        ),
      ),
      GoRoute(
        path: '/attendance/alerts/:id',
        builder: (context, state) {
          final alertExtra = state.extra as AttendanceAlert?;
          final alertId = state.pathParameters['id']!;
          if (alertExtra != null) {
            return ShellWrapper(
              activeRoute: '/attendance/alerts',
              child: AttendanceAlertDetailScreen(alert: alertExtra),
            );
          }
          return ShellWrapper(
            activeRoute: '/attendance/alerts',
            child: Consumer(
              builder: (context, ref, _) {
                final alertAsync = ref.watch(attendanceAlertDetailProvider(alertId));
                return alertAsync.when(
                  data: (a) => a != null
                      ? AttendanceAlertDetailScreen(alert: a)
                      : const Scaffold(body: Center(child: Text('Alert not found'))),
                  loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
                );
              },
            ),
          );
        },
      ),
      GoRoute(
        path: '/attendance/reports',
        builder: (context, state) => const ShellWrapper(
          activeRoute: '/attendance/reports',
          child: AttendanceReportCenterScreen(),
        ),
      ),
      GoRoute(
        path: '/attendance/admin',
        builder: (context, state) => const ShellWrapper(
          activeRoute: '/attendance/admin',
          child: AttendanceAdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/attendance/sessions/admin',
        builder: (context, state) => const ShellWrapper(
          activeRoute: '/attendance/sessions/admin',
          child: AttendanceSessionAdminScreen(),
        ),
      ),

      // Notification Center Route
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(
            activeRoute: '/notifications',
            child: NotificationCenterScreen(),
          ),
        ),
        routes: [
          GoRoute(
            path: 'preferences',
            builder: (context, state) => const NotificationPreferencesScreen(),
          ),
        ],
      ),

      // User Management Routes
      GoRoute(path: '/users', builder: (context, state) => const ShellWrapper(activeRoute: '/users', child: UserDirectoryScreen())),
      GoRoute(path: '/users/new', builder: (context, state) => const UserFormScreen()),
      GoRoute(path: '/users/edit/:id', builder: (context, state) => UserFormScreen(userId: state.pathParameters['id'])),
      GoRoute(path: '/users/:id', builder: (context, state) => UserDetailScreen(userId: state.pathParameters['id']!)),

      // Profile & Settings Placeholders
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/profile', child: ProfileScreen()),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/settings', child: SettingsHomeScreen()),
        ),
        routes: [
          GoRoute(
            path: 'appearance',
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/settings', child: AppearanceScreen())),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/notifications', child: NotificationCenterScreen())),
            routes: [
              GoRoute(
                path: 'preferences',
                builder: (context, state) => const NotificationPreferencesScreen(),
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateAnnouncementScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'language',
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/settings', child: LanguageScreen())),
          ),
          GoRoute(
            path: 'analytics',
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/analytics', child: AnalyticsDashboardScreen())),
            routes: [
              GoRoute(
                path: 'reports',
                pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/analytics', child: ReportsListScreen())),
              ),
              GoRoute(
                path: 'report_preview',
                pageBuilder: (context, state) {
                  final report = state.extra as AttendanceReport;
                  return fadeTransitionPage(context: context, state: state, child: ShellWrapper(activeRoute: '/analytics', child: ReportPreviewScreen(report: report)));
                },
              ),
            ],
          ),
          GoRoute(
            path: 'security',
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/settings', child: SecurityScreen())),
          ),
          GoRoute(
            path: 'support',
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/settings', child: SupportScreen())),
          ),
          GoRoute(
            path: 'about',
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/settings', child: AboutScreen())),
          ),
        ],
      ),

      // AI Assistant module
      GoRoute(
        path: '/ai-assistant',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/ai-assistant', child: AiAssistantScreen()),
        ),
      ),

      // Timetable module
      GoRoute(
        path: '/timetable',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/timetable', child: TimetableDashboardScreen()),
        ),
        routes: [
          GoRoute(
            path: 'manage',
            pageBuilder: (context, state) => fadeTransitionPage(
              context: context,
              state: state,
              child: const ShellWrapper(activeRoute: '/timetable/manage', child: TimetableManagementScreen()),
            ),
          ),
          GoRoute(
            path: 'setup',
            pageBuilder: (context, state) => fadeTransitionPage(
              context: context,
              state: state,
              child: const TimetableSetupScreen(),
            ),
          ),
          GoRoute(
            path: 'designer/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return fadeTransitionPage(
                context: context,
                state: state,
                child: TimetableDesignerScreen(timetableId: id),
              );
            },
          ),
          GoRoute(
            path: 'new',
            pageBuilder: (context, state) => fadeTransitionPage(
              context: context,
              state: state,
              child: const TimetableFormScreen(),
            ),
          ),
          GoRoute(
            path: 'edit/:id',
            pageBuilder: (context, state) {
              final entry = state.extra as TimetableModel?;
              return fadeTransitionPage(
                context: context,
                state: state,
                child: TimetableFormScreen(existingEntry: entry),
              );
            },
          ),
        ],
      ),

      // Notes module
      GoRoute(
        path: '/notes',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/notes', child: NotesDashboardScreen()),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const NoteFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final note = state.extra as NoteModel?;
              return NoteFormScreen(existingNote: note);
            },
          ),
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) {
              final note = state.extra as NoteModel;
              return fadeTransitionPage(
                context: context,
                state: state,
                child: NoteDetailScreen(note: note),
              );
            },
          ),
        ],
      ),

      // Placeholder route for all future modules
      GoRoute(
        path: '/module/:moduleName',
        builder: (context, state) {
          final moduleName = state.pathParameters['moduleName'] ?? 'Module';
          return ComingSoonScreen(moduleName: moduleName);
        },
      ),
    ],
  );
});
