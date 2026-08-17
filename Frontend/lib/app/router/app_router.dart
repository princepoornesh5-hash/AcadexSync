import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/domain/models/role_enum.dart';
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

import '../../features/attendance/presentation/screens/attendance_dashboard_router.dart';
import '../../features/attendance/presentation/screens/mark_attendance_screen.dart';
import '../../features/attendance/presentation/screens/student_attendance_history_screen.dart';
import '../../features/attendance/presentation/screens/faculty_attendance_history_screen.dart';
import '../../features/attendance/presentation/screens/faculty_attendance_detail_screen.dart';

import '../../features/users/presentation/screens/user_directory_screen.dart';
import '../../features/users/presentation/screens/user_detail_screen.dart';
import '../../features/users/presentation/screens/user_form_screen.dart';
import '../../features/users/presentation/screens/profile_screen.dart';

import '../../features/settings/presentation/screens/settings_home_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/misc_settings_screens.dart';

import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/notifications/presentation/screens/create_announcement_screen.dart';

import '../../features/timetable/presentation/screens/timetable_dashboard_screen.dart';
import '../../features/timetable/presentation/screens/timetable_management_screen.dart';
import '../../features/timetable/presentation/screens/timetable_form_screen.dart';
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
import '../theme/app_theme.dart';

class ShellWrapper extends ConsumerWidget {
  final Widget child;
  final String activeRoute;
  const ShellWrapper({super.key, required this.child, required this.activeRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 600;
    final isTablet = width > 600 && width <= 1024;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).updateRoute(activeRoute);
    });

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const Text('Acadex'),
              backgroundColor: DashboardColors.surface,
              foregroundColor: DashboardColors.textPrimary,
              elevation: 0,
              iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
            )
          : null,
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

// Fade transition helper
CustomTransitionPage<T> fadeTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
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
        // Stay on splash or loading screen
        return isGoingToAuth && state.matchedLocation != '/' ? '/' : null;
      }

      if (currentAuthState is AuthProfileError) {
        // Force to login if profile fails
        return '/login';
      }

      if (currentAuthState is! AuthAuthenticated) {
        return isGoingToAuth ? null : '/login';
      }

      // User is logged in
      final role = currentAuthState.user.role;

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

      // Admins only routes
      if (loc.startsWith('/academics')) {
        if (role != AppRole.superAdmin && role != AppRole.collegeAdmin) {
          return getHomeRouteForRole(role);
        }
      }
      
      if (loc.startsWith('/users')) {
        if (role == AppRole.student || role == AppRole.faculty) {
          return getHomeRouteForRole(role);
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

      GoRoute(path: '/academics/students', builder: (context, state) => const ShellWrapper(activeRoute: '/academics/students', child: StudentListScreen())),
      GoRoute(path: '/academics/students/new', builder: (context, state) => const StudentFormScreen()),
      GoRoute(path: '/academics/students/edit/:id', builder: (context, state) => StudentFormScreen(id: state.pathParameters['id'])),

      // Attendance Routes
      GoRoute(path: '/attendance', builder: (context, state) => const ShellWrapper(activeRoute: '/attendance', child: AttendanceDashboardRouter())),
      GoRoute(path: '/attendance/mark', builder: (context, state) => const MarkAttendanceScreen()),
      GoRoute(path: '/attendance/student/history', builder: (context, state) => const StudentAttendanceHistoryScreen()),
      GoRoute(path: '/attendance/faculty/history', builder: (context, state) => const FacultyAttendanceHistoryScreen()),
      GoRoute(path: '/attendance/faculty/detail', builder: (context, state) => const FacultyAttendanceDetailScreen()),

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
            path: 'new',
            builder: (context, state) => const TimetableFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final entry = state.extra as TimetableModel?;
              return TimetableFormScreen(existingEntry: entry);
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
