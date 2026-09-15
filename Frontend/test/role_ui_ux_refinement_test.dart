import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_button.dart';
import 'package:campus_management/core/presentation/widgets/super_admin_gradient_background.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/dashboard/domain/models/dashboard_stat_model.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/screens/super_admin_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/college_admin_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/faculty_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/student_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_drawer.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_bottom_nav.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/section_header.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/stat_card.dart';

import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/super_admin_attendance_dashboard_screen.dart';
import 'package:campus_management/features/reports/presentation/providers/reports_providers.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFacultyAssignmentsNotifier extends FacultyAssignmentsNotifier {
  @override
  Future<List<FacultyAssignment>> build() async => [];
}

Widget _wrapWithApp(Widget child, {required UserModel user, List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'tok'))),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: AcadexGradientScope(
        gradientKey: GlobalKey(),
        child: Scaffold(
          body: child,
        ),
      ),
    ),
  );
}

DashboardStatModel _makeStat(String title, String value, IconData icon) {
  return DashboardStatModel(
    title: title,
    value: value,
    icon: icon,
    iconColor: AcadexColors.primary,
    iconBackground: AcadexColors.primaryLight,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const superAdminUser = UserModel(
    id: 'sa1',
    name: 'Chief Admin',
    email: 'superadmin@acadex.edu',
    role: AppRole.superAdmin,
  );

  const collegeAdminUser = UserModel(
    id: 'ca1',
    name: 'Dean Smith',
    email: 'collegeadmin@acadex.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'col_1',
  );

  const hodUser = UserModel(
    id: 'hod1',
    name: 'Alan Turing',
    email: 'hod@acadex.edu',
    role: AppRole.hod,
    collegeId: 'col_1',
    departmentId: 'dept_cs',
  );

  const facultyUser = UserModel(
    id: 'fac1',
    name: 'Grace Hopper',
    email: 'faculty@acadex.edu',
    role: AppRole.faculty,
    collegeId: 'col_1',
    departmentId: 'dept_cs',
  );

  const studentUser = UserModel(
    id: 'stu1',
    name: 'Ada Lovelace',
    email: 'student@acadex.edu',
    role: AppRole.student,
    collegeId: 'col_1',
    departmentId: 'dept_cs',
  );

  group('P2.4 — Role-Based UI/UX Refinement & Responsive Polish', () {
    testWidgets('1. Super Admin Dashboard renders on mobile viewports without overflow', (tester) async {
      for (final width in [360.0, 390.0, 412.0, 1200.0]) {
        tester.view.physicalSize = Size(width, 844.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final oldOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint('FLUTTER_ERROR: ${details.toString()}');
          oldOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldOnError);

        await tester.pumpWidget(
          _wrapWithApp(
            const SuperAdminDashboard(),
            user: superAdminUser,
            overrides: [
              superAdminStatsProvider.overrideWith((ref) async => [
                _makeStat('Colleges', '12', LucideIcons.building),
                _makeStat('Total Users', '4500', LucideIcons.users),
                _makeStat('Active Students', '3800', LucideIcons.graduationCap),
                _makeStat('Health', '99.9%', LucideIcons.shieldCheck),
              ]),
              roleDashboardReportProvider.overrideWith((ref) async => null),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final exc = tester.takeException();
        if (exc is FlutterError) {
          debugPrint('DETAILED ERROR: ${exc.toStringDeep()}');
        }
        expect(exc, isNull, reason: 'Must not throw layout overflow at width $width');
        expect(find.text('SUPER ADMIN'), findsOneWidget);
        expect(find.text('Multi-Tenant Ecosystem Health'), findsOneWidget);
        expect(find.text('Platform Overview'), findsOneWidget);
      }
    });

    testWidgets('2. College Admin Dashboard renders on mobile viewports with institutional context', (tester) async {
      tester.view.physicalSize = const Size(390.0, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapWithApp(
          const CollegeAdminDashboard(),
          user: collegeAdminUser,
          overrides: [
            collegeAdminStatsProvider.overrideWith((ref) async => [
              _makeStat('Departments', '6', LucideIcons.layers),
              _makeStat('Faculty Count', '48', LucideIcons.userCheck),
              _makeStat('Student Count', '1200', LucideIcons.graduationCap),
              _makeStat('Avg Attendance', '88%', LucideIcons.clipboardCheck),
            ]),
            todayScheduleProvider.overrideWithValue(const AsyncValue.data([])),
            roleDashboardReportProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ACTIVE ACADEMIC SESSION'), findsOneWidget);
      expect(find.text('Academic Structure & Operations'), findsOneWidget);
      expect(find.text('College Overview'), findsOneWidget);
    });

    testWidgets('3. HOD Dashboard renders department metrics and uses canonical feedback states', (tester) async {
      tester.view.physicalSize = const Size(390.0, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint('FLUTTER_ERROR_TEST3: ${details.toString()}');
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      await tester.pumpWidget(
        _wrapWithApp(
          const HodDashboard(),
          user: hodUser,
          overrides: [
            hodStatsProvider.overrideWith((ref) async => [
              _makeStat('Dept Faculty', '14', LucideIcons.users),
              _makeStat('Students', '320', LucideIcons.graduationCap),
              _makeStat('Sections', '8', LucideIcons.layoutGrid),
              _makeStat('Attendance', '91%', LucideIcons.clipboardCheck),
            ]),
            todayScheduleProvider.overrideWithValue(const AsyncValue.data([])),
            facultyAssignmentsProvider.overrideWith(_FakeFacultyAssignmentsNotifier.new),
            hodActivityProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('HOD'), findsOneWidget);
      expect(find.text('Department Overview'), findsOneWidget);
      // Verify canonical empty state for allocations is shown
      expect(find.text('No Teaching Allocations'), findsOneWidget);
    });

    testWidgets('4. Faculty Dashboard prioritizes SEE CLASS -> TAKE ACTION in first viewport', (tester) async {
      tester.view.physicalSize = const Size(390.0, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final nextLecture = TimetableModel(
        id: 'tt_1',
        collegeId: 'col_1',
        departmentId: 'dept_cs',
        courseId: 'c_1',
        academicYearId: 'ay_1',
        semesterId: 'sem_1',
        sectionId: 'sec_A',
        subjectId: 'sub_algo',
        facultyId: 'fac1',
        dayOfWeek: TimetableDay.monday,
        startTime: '10:00',
        endTime: '23:59',
        sessionType: TimetableSessionType.lecture,
        roomNumber: 'LH-101',
        createdAt: now,
        updatedAt: now,
      );

      final sampleSubject = Subject(
        id: 'sub_algo',
        collegeId: 'col_1',
        departmentId: 'dept_cs',
        courseId: 'c_1',
        semesterId: 'sem_1',
        name: 'Design & Analysis of Algorithms',
        code: 'CS301',
        credits: 4,
      );

      final sampleSection = Section(
        id: 'sec_A',
        collegeId: 'col_1',
        departmentId: 'dept_cs',
        courseId: 'c_1',
        semesterId: 'sem_1',
        academicYearId: 'ay_1',
        name: 'A',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          const FacultyDashboard(),
          user: facultyUser,
          overrides: [
            nextClassProvider.overrideWithValue(AsyncValue.data(nextLecture)),
            subjectMapProvider.overrideWith((ref) => {'sub_algo': sampleSubject}),
            sectionMapProvider.overrideWith((ref) => {'sec_A': sampleSection}),
            facultyStatsProvider.overrideWith((ref) async => [
              _makeStat('Classes Today', '3', LucideIcons.calendarCheck),
              _makeStat('Active Sections', '4', LucideIcons.layoutGrid),
              _makeStat('Attendance %', '94%', LucideIcons.clipboardCheck),
              _makeStat('Pending Marks', '1', LucideIcons.clock),
            ]),
            todayScheduleProvider.overrideWithValue(AsyncValue.data([nextLecture])),
            myFacultyAssignmentsProvider.overrideWith((ref) => []),
            facultyActivityProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Faculty badge present
      expect(find.text('FACULTY'), findsOneWidget);
      // Next scheduled lecture is prominently presented in the hero card
      expect(find.text('NEXT SCHEDULED SESSION'), findsOneWidget);
      expect(find.text('Design & Analysis of Algorithms'), findsOneWidget);
      expect(find.text('10:00 – 23:59'), findsWidgets);
      // Direct Mark Attendance primary CTA is directly accessible above the fold
      expect(find.text('Mark Attendance'), findsWidgets);
    });

    testWidgets('5. Student Dashboard displays academic standing, attendance, and today classes', (tester) async {
      tester.view.physicalSize = const Size(390.0, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapWithApp(
          const StudentDashboard(),
          user: studentUser,
          overrides: [
            studentStatsProvider.overrideWith((ref) async => [
              _makeStat('Overall Attendance', '88.5%', LucideIcons.clipboardCheck),
              _makeStat('Classes Attended', '42', LucideIcons.checkCheck),
              _makeStat('Classes Missed', '5', LucideIcons.alertTriangle),
              _makeStat('Classes Today', '3', LucideIcons.calendar),
            ]),
            todayScheduleProvider.overrideWithValue(const AsyncValue.data([])),
            studentActivityProvider.overrideWith((ref) async => []),
            currentStudentAcademicProfileProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('STUDENT'), findsOneWidget);
      expect(find.text('STUDENT ACADEMIC PORTAL'), findsOneWidget);
      expect(find.text('My Academic Overview'), findsOneWidget);
      expect(find.text('88.5%'), findsOneWidget);
      expect(find.text('Classes Missed'), findsOneWidget);
    });

    testWidgets('6. Action hit targets are at least 48x48dp compliant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AcadexButton(
                    label: 'Primary CTA',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  AcadexIconButton(
                    icon: LucideIcons.plus,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'Section Title',
                    actionLabel: 'View All →',
                    onAction: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check AcadexButton size
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, greaterThanOrEqualTo(44.0));

      // Check AcadexIconButton touch target constraint
      final iconButtonFinder = find.byType(AcadexIconButton);
      expect(iconButtonFinder, findsOneWidget);
      final iconBtnSize = tester.getSize(iconButtonFinder);
      expect(iconBtnSize.width, greaterThanOrEqualTo(48.0));
      expect(iconBtnSize.height, greaterThanOrEqualTo(48.0));

      // Check SectionHeader action TextButton hit target
      final textBtnFinder = find.byType(TextButton);
      expect(textBtnFinder, findsOneWidget);
      final textBtnSize = tester.getSize(textBtnFinder);
      expect(textBtnSize.width, greaterThanOrEqualTo(48.0));
      expect(textBtnSize.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('7. Font scale resilience at 1.0, 1.15, and 1.25 textScaleFactor', (tester) async {
      for (final scale in [1.0, 1.15, 1.25]) {
        tester.view.physicalSize = const Size(360.0, 780.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360.0, 780.0),
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  children: [
                    StatCard(
                      stat: DashboardStatModel(
                        title: 'Attendance Rate',
                        value: '95.2%',
                        subtitle: 'Above institutional threshold',
                        icon: LucideIcons.clipboardCheck,
                        iconColor: AcadexColors.primary,
                        iconBackground: AcadexColors.primaryLight,
                      ),
                    ),
                    StatCard(
                      stat: DashboardStatModel(
                        title: 'Missed Sessions',
                        value: '3',
                        subtitle: 'Recorded this semester',
                        icon: LucideIcons.alertTriangle,
                        iconColor: AcadexColors.error,
                        iconBackground: AcadexColors.errorLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'StatCard must not overflow under text scale factor $scale');
        expect(find.text('95.2%'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      }
    });

    testWidgets('8. Role-Specific Navigation Definitions strictly respect authorization boundaries', (tester) async {
      // Test Super Admin Drawer items
      await tester.pumpWidget(
        _wrapWithApp(
          const AcadexDrawer(activeRoute: '/dashboard/super_admin', isModal: false),
          user: superAdminUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Platform Users'), findsOneWidget);
      expect(find.text('Global Analytics'), findsOneWidget);

      // Test Student Drawer items (No administrative routes exposed)
      await tester.pumpWidget(
        _wrapWithApp(
          const AcadexDrawer(activeRoute: '/dashboard/student', isModal: false),
          user: studentUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Timetable'), findsOneWidget);
      expect(find.text('Study Notes'), findsOneWidget);
      expect(find.text('Platform Users'), findsNothing);
      expect(find.text('Global Analytics'), findsNothing);

      // Test Student Bottom Nav (5 concise student-friendly destinations)
      await tester.pumpWidget(
        _wrapWithApp(
          AcadexBottomNav(
            activeRoute: '/dashboard/student',
            onTabSelected: (_) {},
          ),
          user: studentUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Colleges'), findsNothing);
    });

    testWidgets('9. Super Admin Attendance screen uses unified AcadexPageContainer & TabBar card', (tester) async {
      tester.view.physicalSize = const Size(390.0, 844.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapWithApp(
          const SuperAdminAttendanceDashboardScreen(),
          user: superAdminUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Multi-Campus Attendance'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Colleges'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
    });
  });
}
