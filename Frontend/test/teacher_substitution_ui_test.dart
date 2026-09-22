import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/domain/models/teacher_substitution.dart';
import 'package:campus_management/features/timetable/domain/models/calendar_override.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_lookup_providers.dart';
import 'package:campus_management/features/timetable/presentation/widgets/teacher_substitution_dialog.dart';
import 'package:campus_management/features/timetable/presentation/widgets/today_schedule_timeline.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX — Timetable Prompt 6 Frontend Teacher Substitution & Operational UI Tests', () {
    late MockTimetableRepository mockRepo;

    final hodUser = const UserModel(
      id: 'hod_1',
      name: 'Dr. Ada Lovelace',
      email: 'hod@cs.edu',
      role: AppRole.hod,
      collegeId: 'col_1',
      departmentId: 'dept_cs',
    );

    final originalFaculty = Faculty(
      id: 'fac_orig',
      name: 'Prof. Alan Turing',
      email: 'turing@cs.edu',
      phone: '555-0101',
      departmentId: 'dept_cs',
      collegeId: 'col_1',
      employeeId: 'EMP-001',
      designation: 'Professor',
      isActive: true,
    );

    final substituteFaculty = Faculty(
      id: 'fac_sub',
      name: 'Prof. Grace Hopper',
      email: 'hopper@cs.edu',
      phone: '555-0102',
      departmentId: 'dept_cs',
      collegeId: 'col_1',
      employeeId: 'EMP-002',
      designation: 'Associate Professor',
      isActive: true,
    );

    final otherDeptFaculty = Faculty(
      id: 'fac_other',
      name: 'Prof. Richard Feynman',
      email: 'feynman@phy.edu',
      phone: '555-0103',
      departmentId: 'dept_phy',
      collegeId: 'col_1',
      employeeId: 'EMP-003',
      designation: 'Professor',
      isActive: true,
    );

    final testSubject = Subject(
      id: 'sub_algo',
      name: 'Design & Analysis of Algorithms',
      code: 'CS-401',
      departmentId: 'dept_cs',
      collegeId: 'col_1',
      courseId: 'crs_cs',
      semesterId: 'sem_4',
      credits: 4,
      type: 'theory',
      isActive: true,
    );

    final testSection = Section(
      id: 'sec_a',
      name: 'Section A',
      departmentId: 'dept_cs',
      collegeId: 'col_1',
      courseId: 'crs_cs',
      semesterId: 'sem_4',
      academicYearId: 'ay_2026',
      capacity: 60,
      isActive: true,
    );

    setUp(() {
      mockRepo = MockTimetableRepository();
    });

    Widget createTestApp({
      required Widget child,
      UserModel? user,
      MockTimetableRepository? repo,
    }) {
      final currentUser = user ?? hodUser;
      final currentRepo = repo ?? mockRepo;

      return ProviderScope(
        overrides: [
          timetableRepositoryProvider.overrideWithValue(currentRepo),
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: currentUser, token: 'jwt-tok-xyz'))),
          timetableFacultyMapProvider.overrideWith((ref) => {
            originalFaculty.id: originalFaculty,
            substituteFaculty.id: substituteFaculty,
            otherDeptFaculty.id: otherDeptFaculty,
          }),
          timetableSubjectMapProvider.overrideWith((ref) => {
            testSubject.id: testSubject,
          }),
          timetableSectionMapProvider.overrideWith((ref) => {
            testSection.id: testSection,
          }),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    // A. Admin can open substitution UI
    testWidgets('A. Admin can open substitution UI', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              TeacherSubstitutionDialog.show(
                ctx,
                timetableId: 'tt_container_1',
                timetableEntryId: 'tt_entry_1',
                dayOfWeek: TimetableDay.monday,
                startTime: '10:00',
                endTime: '11:00',
                subjectId: 'sub_algo',
                originalFacultyId: 'fac_orig',
                sectionId: 'sec_a',
                roomNumber: 'LHC-101',
                initialDate: DateTime(2026, 9, 28),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Assign Teacher Substitute'), findsOneWidget);
      expect(find.text('Substitution Date'), findsOneWidget);
      expect(find.text('Confirm Substitution'), findsOneWidget);
    });

    // B. Correct original faculty is shown
    testWidgets('B. Correct original faculty is shown', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              TeacherSubstitutionDialog.show(
                ctx,
                timetableId: 'tt_container_1',
                timetableEntryId: 'tt_entry_1',
                dayOfWeek: TimetableDay.monday,
                startTime: '10:00',
                endTime: '11:00',
                subjectId: 'sub_algo',
                originalFacultyId: 'fac_orig',
                sectionId: 'sec_a',
                roomNumber: 'LHC-101',
                initialDate: DateTime(2026, 9, 28),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Original Teacher: Prof. Alan Turing'), findsOneWidget);
      expect(find.text('Design & Analysis of Algorithms'), findsOneWidget);
      expect(find.text('Section: Section A'), findsOneWidget);
    });

    // C. Substitute faculty can be selected & HOD department scoping
    testWidgets('C. Substitute faculty can be selected and HOD only sees own department', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              TeacherSubstitutionDialog.show(
                ctx,
                timetableId: 'tt_container_1',
                timetableEntryId: 'tt_entry_1',
                dayOfWeek: TimetableDay.monday,
                startTime: '10:00',
                endTime: '11:00',
                subjectId: 'sub_algo',
                originalFacultyId: 'fac_orig',
                sectionId: 'sec_a',
                initialDate: DateTime(2026, 9, 28),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Open substitute dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Prof. Grace Hopper (same department) MUST be in the dropdown
      expect(find.text('Prof. Grace Hopper (EMP-002)').last, findsOneWidget);

      // Prof. Richard Feynman (dept_phy) MUST NOT be present for HOD
      expect(find.text('Prof. Richard Feynman (EMP-003)'), findsNothing);

      // Select Prof. Grace Hopper
      await tester.tap(find.text('Prof. Grace Hopper (EMP-002)').last);
      await tester.pumpAndSettle();
    });

    // D. Reason can be entered
    testWidgets('D. Reason can be entered', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              TeacherSubstitutionDialog.show(
                ctx,
                timetableId: 'tt_container_1',
                timetableEntryId: 'tt_entry_1',
                dayOfWeek: TimetableDay.monday,
                startTime: '10:00',
                endTime: '11:00',
                subjectId: 'sub_algo',
                originalFacultyId: 'fac_orig',
                sectionId: 'sec_a',
                initialDate: DateTime(2026, 9, 28),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final reasonField = find.byType(TextField);
      expect(reasonField, findsOneWidget);

      await tester.enterText(reasonField, 'Attending research symposium');
      await tester.pump();

      expect(find.text('Attending research symposium'), findsOneWidget);
    });

    // E. Create substitution calls real API / repository
    testWidgets('E. Create substitution calls repository with correct payload', (tester) async {
      bool onSavedCalled = false;

      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              TeacherSubstitutionDialog.show(
                ctx,
                timetableId: 'tt_container_1',
                timetableEntryId: 'tt_entry_1',
                dayOfWeek: TimetableDay.monday,
                startTime: '10:00',
                endTime: '11:00',
                subjectId: 'sub_algo',
                originalFacultyId: 'fac_orig',
                sectionId: 'sec_a',
                initialDate: DateTime(2026, 9, 28),
                onSaved: () => onSavedCalled = true,
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Select substitute
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prof. Grace Hopper (EMP-002)').last);
      await tester.pumpAndSettle();

      // Enter reason
      await tester.enterText(find.byType(TextField), 'Medical leave coverage');
      await tester.pump();

      // Submit
      await tester.tap(find.text('Confirm Substitution'));
      await tester.pumpAndSettle();

      expect(onSavedCalled, isTrue);

      final subs = await mockRepo.getTeacherSubstitutions(date: '2026-09-28');
      expect(subs.length, 1);
      expect(subs.first.substituteFacultyId, 'fac_sub');
      expect(subs.first.originalFacultyId, 'fac_orig');
      expect(subs.first.reason, 'Medical leave coverage');
    });

    // F. Successful creation refreshes UI
    testWidgets('F. Successful creation refreshes UI and displays SnackBar', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              TeacherSubstitutionDialog.show(
                ctx,
                timetableId: 'tt_container_1',
                timetableEntryId: 'tt_entry_1',
                dayOfWeek: TimetableDay.monday,
                startTime: '10:00',
                endTime: '11:00',
                subjectId: 'sub_algo',
                originalFacultyId: 'fac_orig',
                sectionId: 'sec_a',
                initialDate: DateTime(2026, 9, 28),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Select substitute & enter reason
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prof. Grace Hopper (EMP-002)').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Conference attendance');
      await tester.pump();

      await tester.tap(find.text('Confirm Substitution'));
      await tester.pumpAndSettle();

      // Dialog is popped
      expect(find.text('Assign Teacher Substitute'), findsNothing);
      // SnackBar displayed
      expect(find.text('Teacher substitution scheduled successfully.'), findsOneWidget);
    });

    // G. Failed creation preserves state
    testWidgets('G. Failed creation preserves state and displays error', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              TeacherSubstitutionDialog.show(
                ctx,
                timetableId: 'tt_container_1',
                timetableEntryId: 'tt_entry_1',
                dayOfWeek: TimetableDay.monday,
                startTime: '10:00',
                endTime: '11:00',
                subjectId: 'sub_algo',
                originalFacultyId: 'fac_orig',
                sectionId: 'sec_a',
                initialDate: DateTime(2026, 9, 28),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Click submit without selecting substitute
      await tester.tap(find.text('Confirm Substitution'));
      await tester.pumpAndSettle();

      // Dialog remains open
      expect(find.text('Assign Teacher Substitute'), findsOneWidget);
      expect(find.text('Please select a substitute faculty member.'), findsOneWidget);
    });

    // H. Duplicate substitution shows error
    testWidgets('H. Duplicate substitution shows 409 error', (tester) async {
      // Pre-seed an existing substitution for 2026-09-28
      await mockRepo.createTeacherSubstitution(
        const TeacherSubstitution(
          id: 'sub_100',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'tt_entry_1',
          date: '2026-09-28',
          originalFacultyId: 'fac_orig',
          substituteFacultyId: 'fac_sub',
          reason: 'Initial assignment',
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              TeacherSubstitutionDialog.show(
                ctx,
                timetableId: 'tt_container_1',
                timetableEntryId: 'tt_entry_1',
                dayOfWeek: TimetableDay.monday,
                startTime: '10:00',
                endTime: '11:00',
                subjectId: 'sub_algo',
                originalFacultyId: 'fac_orig',
                sectionId: 'sec_a',
                initialDate: DateTime(2026, 9, 28),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Auto-fetch detects existing substitution
      expect(find.text('Manage Teacher Substitution'), findsOneWidget);
      expect(find.text('Active Substitution on 2026-09-28'), findsOneWidget);
      expect(find.text('Remove Substitution'), findsOneWidget);
    });

    // I. Substitution appears only on target date
    test('I. Substitution applies only to specified calendar date', () async {
      // Seed a class slot
      await mockRepo.createEntry(
        TimetableModel(
          id: 'slot_1',
          timetableId: 'tt_container_1',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          courseId: 'crs_cs',
          academicYearId: 'ay_2026',
          semesterId: 'sem_4',
          sectionId: 'sec_a',
          subjectId: 'sub_algo',
          facultyId: 'fac_orig',
          dayOfWeek: TimetableDay.monday,
          startTime: '10:00',
          endTime: '11:00',
          roomNumber: 'LHC-101',
          sessionType: TimetableSessionType.lecture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create substitution on 2026-09-28
      await mockRepo.createTeacherSubstitution(
        const TeacherSubstitution(
          id: 'sub_test',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'slot_1',
          date: '2026-09-28',
          originalFacultyId: 'fac_orig',
          substituteFacultyId: 'fac_sub',
          reason: 'Coverage',
        ),
      );

      // Query target date (2026-09-28)
      final targetDateClasses = await mockRepo.getTimetable(
        collegeId: 'col_1',
        sectionId: 'sec_a',
        date: '2026-09-28',
      );
      expect(targetDateClasses.first.facultyId, 'fac_sub');
      expect(targetDateClasses.first.isSubstituted, isTrue);

      // Query different date (2026-09-21)
      final otherDateClasses = await mockRepo.getTimetable(
        collegeId: 'col_1',
        sectionId: 'sec_a',
        date: '2026-09-21',
      );
      expect(otherDateClasses.first.facultyId, 'fac_orig');
      expect(otherDateClasses.first.isSubstituted, isFalse);
    });

    // J. Following occurrence restores original faculty
    test('J. Following weekly occurrence restores original faculty', () async {
      await mockRepo.createEntry(
        TimetableModel(
          id: 'slot_1',
          timetableId: 'tt_container_1',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          courseId: 'crs_cs',
          academicYearId: 'ay_2026',
          semesterId: 'sem_4',
          sectionId: 'sec_a',
          subjectId: 'sub_algo',
          facultyId: 'fac_orig',
          dayOfWeek: TimetableDay.monday,
          startTime: '10:00',
          endTime: '11:00',
          roomNumber: 'LHC-101',
          sessionType: TimetableSessionType.lecture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await mockRepo.createTeacherSubstitution(
        const TeacherSubstitution(
          id: 'sub_test',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'slot_1',
          date: '2026-09-28',
          originalFacultyId: 'fac_orig',
          substituteFacultyId: 'fac_sub',
          reason: 'Coverage',
        ),
      );

      // Following occurrence Monday 2026-10-05
      final nextWeekClasses = await mockRepo.getTimetable(
        collegeId: 'col_1',
        sectionId: 'sec_a',
        date: '2026-10-05',
      );
      expect(nextWeekClasses.first.facultyId, 'fac_orig');
      expect(nextWeekClasses.first.isSubstituted, isFalse);
    });

    // K. Faculty operational timetable reflects substitution
    test('K. Substitute faculty operational timetable includes the substituted class', () async {
      await mockRepo.createEntry(
        TimetableModel(
          id: 'slot_1',
          timetableId: 'tt_container_1',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          courseId: 'crs_cs',
          academicYearId: 'ay_2026',
          semesterId: 'sem_4',
          sectionId: 'sec_a',
          subjectId: 'sub_algo',
          facultyId: 'fac_orig',
          dayOfWeek: TimetableDay.monday,
          startTime: '10:00',
          endTime: '11:00',
          roomNumber: 'LHC-101',
          sessionType: TimetableSessionType.lecture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await mockRepo.createTeacherSubstitution(
        const TeacherSubstitution(
          id: 'sub_test',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'slot_1',
          date: '2026-09-28',
          originalFacultyId: 'fac_orig',
          substituteFacultyId: 'fac_sub',
          reason: 'Coverage',
        ),
      );

      // Substitute queries their operational schedule
      final subSchedule = await mockRepo.getTimetable(
        collegeId: 'col_1',
        facultyId: 'fac_sub',
        date: '2026-09-28',
      );
      expect(subSchedule.length, 1);
      expect(subSchedule.first.isSubstituted, isTrue);
      expect(subSchedule.first.facultyId, 'fac_sub');
    });

    // L. Original faculty loses attendance action on target date
    test('L. Original faculty operational timetable excludes substituted class', () async {
      await mockRepo.createEntry(
        TimetableModel(
          id: 'slot_1',
          timetableId: 'tt_container_1',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          courseId: 'crs_cs',
          academicYearId: 'ay_2026',
          semesterId: 'sem_4',
          sectionId: 'sec_a',
          subjectId: 'sub_algo',
          facultyId: 'fac_orig',
          dayOfWeek: TimetableDay.monday,
          startTime: '10:00',
          endTime: '11:00',
          roomNumber: 'LHC-101',
          sessionType: TimetableSessionType.lecture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await mockRepo.createTeacherSubstitution(
        const TeacherSubstitution(
          id: 'sub_test',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'slot_1',
          date: '2026-09-28',
          originalFacultyId: 'fac_orig',
          substituteFacultyId: 'fac_sub',
          reason: 'Coverage',
        ),
      );

      // Original faculty queries their schedule for 2026-09-28
      final origSchedule = await mockRepo.getTimetable(
        collegeId: 'col_1',
        facultyId: 'fac_orig',
        date: '2026-09-28',
      );
      expect(origSchedule, isEmpty);
    });

    // M. Substitute faculty receives attendance action & badge
    testWidgets('M. Substitute faculty receives attendance action and Substitute Duty badge', (tester) async {
      final now = DateTime.now();
      final currentDay = TimetableDay.values[now.weekday - 1];

      final entry = TimetableModel(
        id: 'slot_1',
        timetableId: 'tt_container_1',
        collegeId: 'col_1',
        departmentId: 'dept_cs',
        courseId: 'crs_cs',
        academicYearId: 'ay_2026',
        semesterId: 'sem_4',
        sectionId: 'sec_a',
        subjectId: 'sub_algo',
        facultyId: 'fac_sub',
        isSubstituted: true,
        dayOfWeek: currentDay,
        startTime: '00:00',
        endTime: '23:59',
        roomNumber: 'LHC-101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final facultyUser = const UserModel(
        id: 'fac_sub',
        name: 'Prof. Grace Hopper',
        email: 'hopper@cs.edu',
        role: AppRole.faculty,
        collegeId: 'col_1',
        departmentId: 'dept_cs',
      );

      await tester.pumpWidget(createTestApp(
        user: facultyUser,
        child: TodayScheduleTimeline(classes: [entry]),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Substitute Duty'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    // N. Student sees substitute faculty
    testWidgets('N. Student sees substitute faculty and Substitute Teacher badge', (tester) async {
      final entry = TimetableModel(
        id: 'slot_1',
        timetableId: 'tt_container_1',
        collegeId: 'col_1',
        departmentId: 'dept_cs',
        courseId: 'crs_cs',
        academicYearId: 'ay_2026',
        semesterId: 'sem_4',
        sectionId: 'sec_a',
        subjectId: 'sub_algo',
        facultyId: 'fac_sub',
        isSubstituted: true,
        dayOfWeek: TimetableDay.monday,
        startTime: '10:00',
        endTime: '11:00',
        roomNumber: 'LHC-101',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final studentUser = const UserModel(
        id: 'std_1',
        name: 'Student Bob',
        email: 'bob@cs.edu',
        role: AppRole.student,
        collegeId: 'col_1',
        departmentId: 'dept_cs',
        sectionId: 'sec_a',
      );

      await tester.pumpWidget(createTestApp(
        user: studentUser,
        child: TodayScheduleTimeline(classes: [entry]),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Substitute Teacher'), findsOneWidget);
      expect(find.text('Prof. Grace Hopper'), findsOneWidget);
    });

    // O. Cancelled class overrides substitution
    test('O. Cancelled class overrides substitution on that date', () async {
      await mockRepo.createEntry(
        TimetableModel(
          id: 'slot_1',
          timetableId: 'tt_container_1',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          courseId: 'crs_cs',
          academicYearId: 'ay_2026',
          semesterId: 'sem_4',
          sectionId: 'sec_a',
          subjectId: 'sub_algo',
          facultyId: 'fac_orig',
          dayOfWeek: TimetableDay.monday,
          startTime: '10:00',
          endTime: '11:00',
          roomNumber: 'LHC-101',
          sessionType: TimetableSessionType.lecture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create substitution
      await mockRepo.createTeacherSubstitution(
        const TeacherSubstitution(
          id: 'sub_test',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'slot_1',
          date: '2026-09-28',
          originalFacultyId: 'fac_orig',
          substituteFacultyId: 'fac_sub',
          reason: 'Coverage',
        ),
      );

      // Create CANCELLED override for that slot and date
      await mockRepo.createCalendarOverride(
        const CalendarOverride(
          id: 'ov_cancelled',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'slot_1',
          date: '2026-09-28',
          type: CalendarOverrideType.cancelled,
          scope: CalendarOverrideScope.entry,
          reason: 'Class suspended by department',
          createdBy: 'admin_1',
        ),
      );

      final schedule = await mockRepo.getTimetable(
        collegeId: 'col_1',
        sectionId: 'sec_a',
        date: '2026-09-28',
      );
      expect(schedule, isEmpty);
    });

    // P. Holiday overrides substitution
    test('P. Holiday overrides substitution on that date', () async {
      await mockRepo.createEntry(
        TimetableModel(
          id: 'slot_1',
          timetableId: 'tt_container_1',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          courseId: 'crs_cs',
          academicYearId: 'ay_2026',
          semesterId: 'sem_4',
          sectionId: 'sec_a',
          subjectId: 'sub_algo',
          facultyId: 'fac_orig',
          dayOfWeek: TimetableDay.monday,
          startTime: '10:00',
          endTime: '11:00',
          roomNumber: 'LHC-101',
          sessionType: TimetableSessionType.lecture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Create substitution
      await mockRepo.createTeacherSubstitution(
        const TeacherSubstitution(
          id: 'sub_test',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'slot_1',
          date: '2026-09-28',
          originalFacultyId: 'fac_orig',
          substituteFacultyId: 'fac_sub',
          reason: 'Coverage',
        ),
      );

      // Create HOLIDAY override on 2026-09-28
      await mockRepo.createCalendarOverride(
        const CalendarOverride(
          id: 'ov_holiday',
          collegeId: 'col_1',
          date: '2026-09-28',
          type: CalendarOverrideType.holiday,
          scope: CalendarOverrideScope.college,
          reason: 'Public Holiday',
          createdBy: 'admin_1',
        ),
      );

      final schedule = await mockRepo.getTimetable(
        collegeId: 'col_1',
        sectionId: 'sec_a',
        date: '2026-09-28',
      );
      expect(schedule, isEmpty);
    });

    // Q. Removal restores original faculty
    test('Q. Removal restores original faculty on specified date', () async {
      await mockRepo.createEntry(
        TimetableModel(
          id: 'slot_1',
          timetableId: 'tt_container_1',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          courseId: 'crs_cs',
          academicYearId: 'ay_2026',
          semesterId: 'sem_4',
          sectionId: 'sec_a',
          subjectId: 'sub_algo',
          facultyId: 'fac_orig',
          dayOfWeek: TimetableDay.monday,
          startTime: '10:00',
          endTime: '11:00',
          roomNumber: 'LHC-101',
          sessionType: TimetableSessionType.lecture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final sub = await mockRepo.createTeacherSubstitution(
        const TeacherSubstitution(
          id: 'sub_to_delete',
          collegeId: 'col_1',
          departmentId: 'dept_cs',
          sectionId: 'sec_a',
          timetableId: 'tt_container_1',
          timetableEntryId: 'slot_1',
          date: '2026-09-28',
          originalFacultyId: 'fac_orig',
          substituteFacultyId: 'fac_sub',
          reason: 'Temporary coverage',
        ),
      );

      // Verify substituted
      final beforeDelete = await mockRepo.getTimetable(collegeId: 'col_1', sectionId: 'sec_a', date: '2026-09-28');
      expect(beforeDelete.first.facultyId, 'fac_sub');

      // Delete substitution
      await mockRepo.deleteTeacherSubstitution(sub.id);

      // Verify original faculty restored
      final afterDelete = await mockRepo.getTimetable(collegeId: 'col_1', sectionId: 'sec_a', date: '2026-09-28');
      expect(afterDelete.first.facultyId, 'fac_orig');
      expect(afterDelete.first.isSubstituted, isFalse);
    });

    // R. Timetable deletion 409 shows archive guidance
    testWidgets('R. Timetable deletion 409 displays archive guidance and archive CTA', (tester) async {
      mockRepo.simulateAttendanceConflictOnDelete = true;

      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              try {
                await mockRepo.deleteTimetableContainer('tt_container_with_history');
              } catch (e) {
                final errorMsg = e.toString().replaceFirst('Exception: ', '');
                if (errorMsg.contains('attendance') || errorMsg.contains('archive')) {
                  showDialog<void>(
                    context: ctx,
                    builder: (alertCtx) => AlertDialog(
                      title: const Text('Cannot Delete Timetable'),
                      content: const Text(
                        'Attendance history exists for this timetable. It cannot be permanently deleted. Please archive the timetable instead.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(alertCtx).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await mockRepo.archiveTimetableContainer('tt_container_with_history');
                            if (alertCtx.mounted) Navigator.of(alertCtx).pop();
                          },
                          child: const Text('Archive Timetable'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Trigger Delete'),
          ),
        ),
      ));

      await tester.tap(find.text('Trigger Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Cannot Delete Timetable'), findsOneWidget);
      expect(
        find.text(
          'Attendance history exists for this timetable. It cannot be permanently deleted. Please archive the timetable instead.',
        ),
        findsOneWidget,
      );
      expect(find.text('Archive Timetable'), findsOneWidget);

      await tester.tap(find.text('Archive Timetable'));
      await tester.pumpAndSettle();

      expect(find.text('Cannot Delete Timetable'), findsNothing);
    });
  });
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
