import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/domain/models/role_enum.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/presentation/utils/navigation_extensions.dart';
import '../../core/presentation/providers/navigation_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/activation_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/dashboard/presentation/screens/super_admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/college_admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/hod_dashboard.dart';
import '../../features/dashboard/presentation/screens/faculty_dashboard.dart';
import '../../features/dashboard/presentation/screens/student_dashboard.dart';
import '../../features/dashboard/presentation/screens/coming_soon_screen.dart';

import '../../features/academic_structure/presentation/screens/college_screens.dart';
import '../../features/academic_structure/presentation/screens/college_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/provision_admin_screen.dart';
import '../../features/academic_structure/presentation/screens/department_screens.dart';
import '../../features/academic_structure/presentation/screens/department_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/course_screens.dart';
import '../../features/academic_structure/presentation/screens/course_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/academic_year_screens.dart';
import '../../features/academic_structure/presentation/screens/academic_year_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/semester_screens.dart';
import '../../features/academic_structure/presentation/screens/semester_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/section_screens.dart';
import '../../features/academic_structure/presentation/screens/section_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/subject_screens.dart';
import '../../features/academic_structure/presentation/screens/subject_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/hod_screens.dart';
import '../../features/academic_structure/presentation/screens/hod_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/faculty_screens.dart';
import '../../features/academic_structure/presentation/screens/faculty_detail_screen.dart';
import '../../features/academic_structure/presentation/screens/student_screens.dart';
import '../../features/academic_structure/presentation/screens/faculty_assignments_management_screen.dart';
import '../../features/academic_structure/presentation/screens/faculty_workload_screen.dart';
import '../../features/academic_structure/presentation/screens/my_assignments_screen.dart';
import '../../features/academic_structure/presentation/screens/student_profile_screen.dart';
import '../../features/academic_structure/presentation/screens/academic_structure_home_screen.dart';
import '../../features/academic_structure/presentation/screens/department_setup_screen.dart';

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
import '../../features/notifications/presentation/screens/announcement_list_screen.dart';
import '../../features/notifications/presentation/screens/announcement_detail_screen.dart';
import '../../core/presentation/screens/not_found_screen.dart';
import '../../core/presentation/screens/access_restricted_screen.dart';

import '../../features/timetable/presentation/screens/timetable_dashboard_screen.dart';
import '../../features/timetable/presentation/screens/timetable_management_screen.dart';
import '../../features/timetable/presentation/screens/timetable_setup_screen.dart';
import '../../features/timetable/presentation/screens/timetable_designer_screen.dart';

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

String _getRouteTitle(String route) {
  if (route == '/academics/courses/new') return 'Create Course';
  if (route.endsWith('/edit') && route.contains('/courses')) return 'Edit Course';
  if (RegExp(r'^/academics/courses/[^/]+$').hasMatch(route)) return 'Course Details';
  if (route.startsWith('/academics/courses')) return 'Courses';

  if (route == '/academics/semesters/new') return 'Create Semester';
  if (route.endsWith('/edit') && route.contains('/semesters')) return 'Edit Semester';
  if (RegExp(r'^/academics/semesters/[^/]+$').hasMatch(route)) return 'Semester Details';
  if (route.startsWith('/academics/semesters')) return 'Semesters';

  if (route == '/academics/sections/new') return 'Create Section';
  if (route.endsWith('/edit') && route.contains('/sections')) return 'Edit Section';
  if (RegExp(r'^/academics/sections/[^/]+$').hasMatch(route)) return 'Section Details';
  if (route.startsWith('/academics/sections')) return 'Sections';

  if (route == '/academics/subjects/new') return 'Create Subject';
  if (route.endsWith('/edit') && route.contains('/subjects')) return 'Edit Subject';
  if (RegExp(r'^/academics/subjects/[^/]+$').hasMatch(route)) return 'Subject Details';
  if (route.startsWith('/academics/subjects')) return 'Subjects';

  if (route.startsWith('/academics/academic_years')) return 'Academic Years';
  if (route.startsWith('/academics/colleges')) return 'Colleges';
  if (route.startsWith('/academics/departments')) return 'Departments';
  if (route.startsWith('/academics/setup')) return 'Department Setup';
  if (route == '/academics') return 'Academic Structure';

  if (route.startsWith('/academics/hods')) return 'Department Heads (HODs)';
  if (route.startsWith('/academics/faculty')) return 'Faculty & Staff';
  if (route.startsWith('/faculty-assignments')) return 'Faculty Assignments';
  if (route.startsWith('/faculty-workload')) return 'Faculty Workload';
  if (route.startsWith('/my-assignments')) return 'My Assignments';
  if (route.startsWith('/academics/students')) return 'Students';
  if (route.startsWith('/attendance')) return 'Attendance';
  if (route.startsWith('/timetable')) return 'Timetable';
  if (route.startsWith('/notes')) return 'Academic Notes';
  if (route.startsWith('/ai-assistant')) return 'AI Assistant';
  if (route.startsWith('/users')) return 'User Management';
  if (route.startsWith('/profile')) return 'My Profile';
  if (route.startsWith('/settings')) return 'Settings';
  if (route.startsWith('/announcements')) return 'Announcements';
  if (route.startsWith('/notifications')) return 'Notifications';
  if (route.startsWith('/analytics')) return 'Analytics & Reports';
  if (route.startsWith('/reports')) return 'Reports';
  if (route.startsWith('/search')) return 'Search';
  if (route.startsWith('/dashboard')) return 'Dashboard';
  return 'Dashboard';
}

class ShellWrapper extends ConsumerWidget {
  final Widget child;
  final String activeRoute;
  const ShellWrapper({super.key, required this.child, required this.activeRoute});

  static String getHomeRouteForRole(AppRole role) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= AcadexBreakpoints.mobileMax;
    final isTablet = width > AcadexBreakpoints.mobileMax && width <= AcadexBreakpoints.tabletMax;
    final authState = ref.watch(authProvider);

    AppRole? userRole;
    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
    }

    final homeRoute = userRole != null ? getHomeRouteForRole(userRole) : '/login';
    final isAtRootDashboard = activeRoute == homeRoute || (activeRoute.startsWith('/dashboard') && !activeRoute.contains('/edit') && !activeRoute.contains('/new'));

    if (ref.read(navigationProvider).currentRoute != activeRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).updateRoute(activeRoute);
      });
    }

    final pageTitle = _getRouteTitle(activeRoute);

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: AcadexAppBar(
        title: pageTitle,
        showDrawerButton: isMobile && isAtRootDashboard,
        showBackButton: isMobile && !isAtRootDashboard,
        onBack: () => context.safePop(fallbackRoute: homeRoute),
      ),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        if (!isAtRootDashboard) {
          context.go(homeRoute);
          return;
        }
        // At root dashboard: allow system pop to cleanly exit
        SystemNavigator.pop();
      },
      child: scaffold,
    );
  }
}

// Fade + subtle slide transition helper (for detail, edit, and drill-down screens)
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

// Instant transition helper for primary navigation (0ms duration, no slide/push animation)
CustomTransitionPage<T> noTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<T>(
    key: state.pageKey,
    name: state.name,
    child: child,
  );
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous != next) {
        // Prevent synchronous dispatch stack overflows by deferring notifyListeners
        Future.microtask(() {
          notifyListeners();
        });
      }
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.read(routerNotifierProvider);
  debugPrint('[ROUTER_INIT]');

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
    errorBuilder: (context, state) => AcadexNotFoundScreen(
      location: state.uri.toString(),
      error: state.error,
    ),
    redirect: (context, state) {
      final currentAuthState = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isGoingToAuth = loc == '/login' ||
          loc == '/forgot-password' ||
          loc == '/verify-otp' ||
          loc == '/reset-password' ||
          loc == '/activate';
      final isSplash = loc == '/';

      if (currentAuthState is AuthProfileLoading || currentAuthState is AuthInitial) {
        // Stay on splash or loading screen if trying to access auth screens or splash,
        // otherwise block access to protected routes while loading.
        return (isGoingToAuth || isSplash) ? null : '/';
      }

      if (currentAuthState is AuthProfileError || currentAuthState is AuthError) {
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

      if (loc == '/access-restricted') return null;

      if (isGoingToAuth || isSplash) {
        return getHomeRouteForRole(role);
      }

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

      // Normalize hyphenated academic-years alias
      if (loc.startsWith('/academics/academic-years')) {
        return loc.replaceFirst('/academics/academic-years', '/academics/academic_years');
      }

      if (loc == '/department/setup' || loc.startsWith('/department/setup?')) {
        return loc.replaceFirst('/department/setup', '/academics/setup');
      }

      // Academic routes & role protection
      if (loc.startsWith('/academics') || loc.startsWith('/academic')) {
        if (loc.startsWith('/academics/assignments/my') || loc.startsWith('/academic/assignments/my') || loc == '/my-assignments') {
          if (role != AppRole.faculty && role != AppRole.hod && role != AppRole.collegeAdmin) {
            return '/access-restricted';
          }
        } else if (loc.startsWith('/academics/workload') || loc.startsWith('/academic/workload') || loc == '/faculty-workload') {
          if (role != AppRole.faculty && role != AppRole.hod && role != AppRole.collegeAdmin && role != AppRole.superAdmin) {
            return '/access-restricted';
          }
        } else if (loc.startsWith('/academics/colleges') || loc.startsWith('/academic/colleges')) {
          if (role != AppRole.superAdmin) {
            return '/access-restricted';
          }
        } else if (loc.startsWith('/academics/departments') || loc.startsWith('/academic/departments')) {
          if (role != AppRole.superAdmin && role != AppRole.collegeAdmin) {
            return '/access-restricted';
          }
        } else if (loc.startsWith('/academics/academic_years') || loc.startsWith('/academic/years') ||
                   loc.startsWith('/academics/academic-years')) {
          if (role != AppRole.superAdmin && role != AppRole.collegeAdmin && role != AppRole.hod) {
            return '/access-restricted';
          }
        } else if (loc.startsWith('/academics/courses') || loc.startsWith('/academic/courses') ||
                   loc.startsWith('/academics/semesters') || loc.startsWith('/academic/semesters')) {
          if (role != AppRole.superAdmin && role != AppRole.collegeAdmin && role != AppRole.hod) {
            return '/access-restricted';
          }
        } else {
          // Subjects, Sections, Faculty, Students, Assignments (HOD, College Admin, Super Admin)
          if (role == AppRole.student) {
            return '/access-restricted';
          }
        }
      }
      
      if (loc.startsWith('/users')) {
        if (role == AppRole.student || role == AppRole.faculty) {
          return '/access-restricted';
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

      // Global Analytics route protection
      if (loc.startsWith('/analytics')) {
        if (role == AppRole.student) {
          return getHomeRouteForRole(role);
        }
      }

      // Announcement creation route protection (Super Admin, College Admin, HOD only)
      if (loc == '/announcements/create' || loc.startsWith('/announcements/create')) {
        if (role != AppRole.superAdmin && role != AppRole.collegeAdmin && role != AppRole.hod) {
          return '/announcements';
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
        path: '/verify-otp',
        builder: (context, state) => ForgotPasswordScreen(
          initialStep: 1,
          initialIdentifier: state.uri.queryParameters['identifier'],
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ForgotPasswordScreen(
          initialStep: 2,
          initialIdentifier: state.uri.queryParameters['identifier'],
          initialResetToken: state.uri.queryParameters['resetToken'],
        ),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) => const ActivationScreen(),
      ),
      GoRoute(
        path: '/change-password',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const ChangePasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: const GlobalSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/access-restricted',
        pageBuilder: (context, state) => fadeTransitionPage(
          context: context,
          state: state,
          child: AcadexAccessRestrictedScreen(
            message: state.uri.queryParameters['message'],
          ),
        ),
      ),
      
      // Dashboards (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/dashboard/super_admin',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/super_admin', child: SuperAdminDashboard()),
        ),
      ),
      GoRoute(
        path: '/dashboard/college_admin',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/college_admin', child: CollegeAdminDashboard()),
        ),
      ),
      GoRoute(
        path: '/dashboard/hod',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/hod', child: HodDashboard()),
        ),
      ),
      GoRoute(
        path: '/dashboard/faculty',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/faculty', child: FacultyDashboard()),
        ),
      ),
      GoRoute(
        path: '/dashboard/student',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/dashboard/student', child: StudentDashboard()),
        ),
      ),
      
      // Academic Structure Routes (Primary Navigation List Screens: Instant Replacement)
      GoRoute(
        path: '/academics',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics', child: AcademicStructureHomeScreen()),
        ),
      ),
      GoRoute(
        path: '/academic-structure',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics', child: AcademicStructureHomeScreen()),
        ),
      ),
      GoRoute(
        path: '/academics/colleges',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/colleges', child: CollegeListScreen()),
        ),
      ),
      GoRoute(path: '/academics/colleges/new', builder: (context, state) => const CollegeFormScreen()),
      GoRoute(path: '/academics/colleges/edit/:id', builder: (context, state) => CollegeFormScreen(collegeId: state.pathParameters['id'])),
      GoRoute(path: '/academics/colleges/:id', builder: (context, state) => CollegeDetailScreen(collegeId: state.pathParameters['id']!)),
      GoRoute(path: '/academics/colleges/:id/provision-admin', builder: (context, state) => ProvisionAdminScreen(collegeId: state.pathParameters['id']!)),

      GoRoute(
        path: '/academics/departments',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/departments', child: DepartmentListScreen()),
        ),
      ),
      GoRoute(path: '/academics/departments/new', builder: (context, state) => const DepartmentFormScreen()),
      GoRoute(path: '/academics/departments/edit/:id', builder: (context, state) => DepartmentFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/departments/:id', builder: (context, state) => DepartmentDetailScreen(departmentId: state.pathParameters['id']!)),

      // Department Setup Workspace
      GoRoute(
        path: '/academics/setup',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: ShellWrapper(
            activeRoute: '/academics/setup',
            child: DepartmentSetupScreen(
              initialDepartmentId: state.uri.queryParameters['departmentId'],
            ),
          ),
        ),
      ),

      GoRoute(
        path: '/academics/courses',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/courses', child: CourseListScreen()),
        ),
      ),
      GoRoute(
        path: '/academics/courses/new',
        builder: (context, state) => CourseFormScreen(
          initialDepartmentId: state.uri.queryParameters['departmentId'],
        ),
      ),
      GoRoute(path: '/academics/courses/edit/:id', builder: (context, state) => CourseFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/courses/:id', builder: (context, state) => CourseDetailScreen(courseId: state.pathParameters['id']!)),

      GoRoute(
        path: '/academics/academic_years',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/academic_years', child: AcademicYearListScreen()),
        ),
      ),
      GoRoute(path: '/academics/academic_years/new', builder: (context, state) => const AcademicYearFormScreen()),
      GoRoute(path: '/academics/academic_years/edit/:id', builder: (context, state) => AcademicYearFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/academic_years/:id', builder: (context, state) => AcademicYearDetailScreen(academicYearId: state.pathParameters['id']!)),

      GoRoute(
        path: '/academics/semesters',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/semesters', child: SemesterListScreen()),
        ),
      ),
      GoRoute(
        path: '/academics/semesters/new',
        builder: (context, state) => SemesterFormScreen(
          initialCourseId: state.uri.queryParameters['courseId'],
          initialAcademicYearId: state.uri.queryParameters['academicYearId'],
        ),
      ),
      GoRoute(path: '/academics/semesters/edit/:id', builder: (context, state) => SemesterFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/semesters/:id', builder: (context, state) => SemesterDetailScreen(semesterId: state.pathParameters['id']!)),

      GoRoute(
        path: '/academics/sections',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/sections', child: SectionListScreen()),
        ),
      ),
      GoRoute(
        path: '/academics/sections/new',
        builder: (context, state) => SectionFormScreen(
          initialCourseId: state.uri.queryParameters['courseId'],
          initialSemesterId: state.uri.queryParameters['semesterId'],
        ),
      ),
      GoRoute(path: '/academics/sections/edit/:id', builder: (context, state) => SectionFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/sections/:id', builder: (context, state) => SectionDetailScreen(sectionId: state.pathParameters['id']!)),

      GoRoute(
        path: '/academics/subjects',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/subjects', child: SubjectListScreen()),
        ),
      ),
      GoRoute(path: '/academics/subjects/new', builder: (context, state) => SubjectFormScreen(initialCourseId: state.uri.queryParameters['courseId'], initialSemesterId: state.uri.queryParameters['semesterId'])),
      GoRoute(path: '/academics/subjects/edit/:id', builder: (context, state) => SubjectFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/subjects/:id', builder: (context, state) => SubjectDetailScreen(subjectId: state.pathParameters['id']!)),

      GoRoute(
        path: '/academics/hods',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/hods', child: HodListScreen()),
        ),
      ),
      GoRoute(path: '/academics/hods/provision', builder: (context, state) => ProvisionHodScreen(initialDepartmentId: state.uri.queryParameters['departmentId'])),
      GoRoute(path: '/academics/hods/edit/:id', builder: (context, state) => HodEditScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/academics/hods/:id', builder: (context, state) => HodDetailScreen(hodId: state.pathParameters['id']!)),

      GoRoute(
        path: '/academics/faculty',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/faculty', child: FacultyListScreen()),
        ),
      ),
      GoRoute(path: '/academics/faculty/new', builder: (context, state) => FacultyFormScreen(initialDepartmentId: state.uri.queryParameters['departmentId'])),
      GoRoute(path: '/academics/faculty/edit/:id', builder: (context, state) => FacultyFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/faculty/:id', builder: (context, state) => FacultyDetailScreen(facultyId: state.pathParameters['id']!)),

      // Faculty Assignments & Workload Routes (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/faculty-assignments',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: ShellWrapper(
            activeRoute: '/faculty-assignments',
            child: FacultyAssignmentsManagementScreen(
              initialSubjectId: state.uri.queryParameters['subjectId'],
              initialCourseId: state.uri.queryParameters['courseId'],
              initialSemesterId: state.uri.queryParameters['semesterId'],
              initialSectionId: state.uri.queryParameters['sectionId'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/academics/faculty/assignments',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: ShellWrapper(
            activeRoute: '/faculty-assignments',
            child: FacultyAssignmentsManagementScreen(
              initialSubjectId: state.uri.queryParameters['subjectId'],
              initialCourseId: state.uri.queryParameters['courseId'],
              initialSemesterId: state.uri.queryParameters['semesterId'],
              initialSectionId: state.uri.queryParameters['sectionId'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/faculty-workload',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/faculty-workload', child: FacultyWorkloadScreen()),
        ),
      ),
      GoRoute(
        path: '/academics/faculty/workload',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/faculty-workload', child: FacultyWorkloadScreen()),
        ),
      ),
      GoRoute(
        path: '/my-assignments',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/my-assignments', child: MyAssignmentsScreen()),
        ),
      ),

      GoRoute(
        path: '/academics/students',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/academics/students', child: StudentListScreen()),
        ),
      ),
      GoRoute(path: '/academics/students/new', builder: (context, state) => StudentFormScreen(initialDepartmentId: state.uri.queryParameters['departmentId'])),
      GoRoute(path: '/academics/students/edit/:id', builder: (context, state) => StudentFormScreen(id: state.pathParameters['id'])),
      GoRoute(path: '/academics/students/:id', builder: (context, state) => StudentProfileScreen(studentId: state.pathParameters['id']!)),

      // Attendance Routes (Primary Portals & Dashboards: Instant Replacement)
      GoRoute(
        path: '/attendance',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/attendance', child: AttendanceDashboardRouter()),
        ),
      ),
      GoRoute(
        path: '/attendance/student',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/attendance', child: StudentAttendancePortalScreen()),
        ),
      ),
      GoRoute(
        path: '/attendance/student/dashboard',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/attendance', child: StudentAttendanceDashboardScreen()),
        ),
      ),
      GoRoute(
        path: '/attendance/student/subjects',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/attendance', child: StudentAttendancePortalScreen(initialTab: 1)),
        ),
      ),
      GoRoute(
        path: '/attendance/student/subject/:id',
        builder: (context, state) => ShellWrapper(
          activeRoute: '/attendance',
          child: StudentSubjectAttendanceScreen(subjectId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/attendance/student/calendar',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/attendance', child: StudentAttendanceCalendarScreen()),
        ),
      ),
      GoRoute(
        path: '/attendance/student/insights',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/attendance', child: StudentAttendancePortalScreen(initialTab: 3)),
        ),
      ),
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
      GoRoute(
        path: '/attendance/analytics',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/attendance/analytics', child: AttendanceAnalyticsScreen()),
        ),
      ),
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
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(
            activeRoute: '/attendance/alerts',
            child: AttendanceAlertsScreen(),
          ),
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
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(
            activeRoute: '/attendance/reports',
            child: AttendanceReportCenterScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/attendance/admin',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(
            activeRoute: '/attendance/admin',
            child: AttendanceAdminDashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/attendance/sessions/admin',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(
            activeRoute: '/attendance/sessions/admin',
            child: AttendanceSessionAdminScreen(),
          ),
        ),
      ),

      // Notification Center Route (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => noTransitionPage(
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
          GoRoute(
            path: 'create',
            redirect: (context, state) => '/announcements/create',
          ),
        ],
      ),

      // Announcements Module (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/announcements',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(
            activeRoute: '/announcements',
            child: AnnouncementListScreen(),
          ),
        ),
        routes: [
          GoRoute(
            path: 'create',
            pageBuilder: (context, state) => fadeTransitionPage(
              context: context,
              state: state,
              child: const ShellWrapper(
                activeRoute: '/announcements',
                child: CreateAnnouncementScreen(),
              ),
            ),
          ),
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) => fadeTransitionPage(
              context: context,
              state: state,
              child: ShellWrapper(
                activeRoute: '/announcements',
                child: AnnouncementDetailScreen(
                  announcementId: state.pathParameters['id'] ?? '',
                ),
              ),
            ),
          ),
        ],
      ),

      // User Management Routes (Primary Navigation List Screen: Instant Replacement)
      GoRoute(
        path: '/users',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/users', child: UserDirectoryScreen()),
        ),
      ),
      GoRoute(path: '/users/new', builder: (context, state) => const UserFormScreen()),
      GoRoute(path: '/users/edit/:id', builder: (context, state) => UserFormScreen(userId: state.pathParameters['id'])),
      GoRoute(path: '/users/:id', builder: (context, state) => UserDetailScreen(userId: state.pathParameters['id']!)),

      // Profile (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/profile', child: ProfileScreen()),
        ),
      ),

      // Settings (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => noTransitionPage(
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
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/settings', child: NotificationPreferencesScreen())),
          ),
          GoRoute(
            path: 'language',
            pageBuilder: (context, state) => fadeTransitionPage(context: context, state: state, child: const ShellWrapper(activeRoute: '/settings', child: LanguageScreen())),
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

      // Global Analytics Top-Level Route (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/analytics',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/analytics', child: AnalyticsDashboardScreen()),
        ),
        routes: [
          GoRoute(
            path: 'reports',
            pageBuilder: (context, state) => noTransitionPage(
              context: context,
              state: state,
              child: const ShellWrapper(activeRoute: '/analytics', child: ReportsListScreen()),
            ),
          ),
          GoRoute(
            path: 'report_preview',
            pageBuilder: (context, state) {
              final report = state.extra as AttendanceReport;
              return fadeTransitionPage(
                context: context,
                state: state,
                child: ShellWrapper(activeRoute: '/analytics', child: ReportPreviewScreen(report: report)),
              );
            },
          ),
        ],
      ),

      // AI Assistant module (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/ai-assistant',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/ai-assistant', child: AiAssistantScreen()),
        ),
      ),

      // Timetable module (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/timetable',
        pageBuilder: (context, state) => noTransitionPage(
          context: context,
          state: state,
          child: const ShellWrapper(activeRoute: '/timetable', child: TimetableDashboardScreen()),
        ),
        routes: [
          GoRoute(
            path: 'manage',
            pageBuilder: (context, state) => noTransitionPage(
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
            redirect: (context, state) => '/timetable/setup',
          ),
          GoRoute(
            path: 'edit/:id',
            redirect: (context, state) => '/timetable/manage',
          ),
        ],
      ),

      // Notes module (Primary Navigation: Instant Replacement)
      GoRoute(
        path: '/notes',
        pageBuilder: (context, state) => noTransitionPage(
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
