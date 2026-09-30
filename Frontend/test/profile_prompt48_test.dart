import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/core/realtime/models/realtime_event.dart';
import 'package:campus_management/core/realtime/presentation/providers/realtime_providers.dart';
import 'package:campus_management/features/profile/domain/models/profile_models.dart';
import 'package:campus_management/features/profile/data/repositories/profile_repository.dart';
import 'package:campus_management/features/profile/presentation/providers/profile_providers.dart';
import 'package:campus_management/features/profile/presentation/screens/profile_screen.dart';
import 'package:campus_management/features/profile/presentation/screens/edit_profile_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  void updateCurrentUser(UserModel user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(
        user: user,
        token: (state as AuthAuthenticated).token,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileRepository implements ProfileRepository {
  ComposedProfileModel mockProfile;
  Map<String, dynamic> lastUpdatedData = {};

  FakeProfileRepository({required this.mockProfile});

  @override
  Future<ComposedProfileModel> getMyProfile() async {
    return mockProfile;
  }

  @override
  Future<ComposedProfileModel> updateMyProfile(Map<String, dynamic> data) async {
    lastUpdatedData = data;
    mockProfile = ComposedProfileModel(
      user: mockProfile.user.copyWith(
        name: data['displayName'] as String? ?? mockProfile.user.name,
        phone: data['phone'] as String? ?? mockProfile.user.phone,
        bio: data['bio'] as String? ?? mockProfile.user.bio,
      ),
      roleProfile: mockProfile.roleProfile,
      completion: mockProfile.completion,
      editableFields: mockProfile.editableFields,
    );
    return mockProfile;
  }

  @override
  Future<ComposedProfileModel> getProfileById(String id) async {
    return mockProfile;
  }

  @override
  Future<Map<String, dynamic>> getDirectory({
    String? search,
    String? role,
    String? departmentId,
    int page = 1,
    int limit = 20,
  }) async {
    return {
      'results': [
        {
          '_id': 'user_dir_1',
          'name': 'Dr. Alan Turing',
          'role': 'FACULTY',
          'designation': 'Professor',
          'department': {'name': 'Computer Science'},
        }
      ],
      'total': 1,
      'page': page,
      'pages': 1,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testStudentUser = UserModel(
    id: 'user_student_1',
    name: 'Aarav Patel',
    email: 'aarav.patel@acadex.edu',
    role: AppRole.student,
    collegeId: 'college_1',
    phone: '+919876543210',
    profilePictureUrl: null,
  );

  final testStudentComposedProfile = ComposedProfileModel(
    user: const BaseUserProfileModel(
      id: 'user_student_1',
      instituteId: 'college_1',
      name: 'Aarav Patel',
      email: 'aarav.patel@acadex.edu',
      phone: '+919876543210',
      role: AppRole.student,
      collegeId: 'college_1',
      collegeName: 'Apex Institute of Technology',
      bio: 'Third year CS student passionate about distributed systems.',
    ),
    roleProfile: const RoleProfileCompositeModel(
      student: StudentRoleProfileModel(
        studentId: 'student_1',
        rollNumber: 'CS2023001',
        isEnrollmentAvailable: true,
        currentEnrollment: CurrentEnrollmentSummaryModel(
          enrollmentId: 'enrollment_1',
          courseId: 'course_1',
          courseName: 'B.Tech Computer Science',
          courseCode: 'CS101',
          semesterId: 'semester_5',
          semesterName: 'Semester V',
          semesterNumber: 5,
          academicYearId: 'ay_2026',
          academicYearName: '2026-2027',
          sectionId: 'sec_a',
          sectionName: 'Section A',
          status: 'ACTIVE',
        ),
      ),
    ),
    completion: const ProfileCompletionModel(
      percentage: 85,
      completedFields: ['name', 'email', 'phone'],
      missingFields: ['profilePictureUrl'],
    ),
    editableFields: ['displayName', 'phone', 'bio'],
  );

  final testFacultyComposedProfile = ComposedProfileModel(
    user: const BaseUserProfileModel(
      id: 'user_faculty_1',
      instituteId: 'college_1',
      name: 'Dr. John McCarthy',
      email: 'john.mccarthy@acadex.edu',
      phone: '+919876500000',
      role: AppRole.faculty,
      collegeId: 'college_1',
      bio: 'Associate Professor of Computer Science.',
    ),
    roleProfile: const RoleProfileCompositeModel(
      faculty: FacultyRoleProfileModel(
        facultyId: 'faculty_1',
        employeeId: 'EMP-CS-042',
        designation: 'Associate Professor',
        specialization: 'Artificial Intelligence',
        qualification: 'Ph.D. in Computer Science',
        activeAssignments: [
          TeachingAssignmentSummaryModel(
            assignmentId: 'assign_1',
            subjectId: 'sub_ai',
            subjectName: 'Artificial Intelligence',
            subjectCode: 'CS502',
            courseId: 'course_1',
            courseName: 'B.Tech Computer Science',
            semesterId: 'sem_5',
            semesterName: 'Semester V',
            sectionId: 'sec_a',
            sectionName: 'Section A',
          ),
        ],
      ),
    ),
    completion: const ProfileCompletionModel(
      percentage: 100,
      completedFields: ['name', 'email', 'phone', 'designation'],
    ),
    editableFields: ['displayName', 'phone', 'bio', 'specialization', 'qualification'],
  );

  final testHodComposedProfile = ComposedProfileModel(
    user: const BaseUserProfileModel(
      id: 'user_hod_1',
      instituteId: 'college_1',
      name: 'Dr. Ada Lovelace',
      email: 'ada.lovelace@acadex.edu',
      phone: '+919876511111',
      role: AppRole.hod,
      collegeId: 'college_1',
      departmentName: 'Computer Science and Engineering',
      bio: 'Head of Department, Computer Science.',
    ),
    roleProfile: const RoleProfileCompositeModel(
      hod: HodRoleProfileModel(
        departmentId: 'dept_cs',
        departmentName: 'Computer Science and Engineering',
        departmentCode: 'CSE',
        designation: 'Professor & Head',
        programsCount: 3,
        facultyCount: 24,
        studentsCount: 360,
      ),
    ),
    completion: const ProfileCompletionModel(
      percentage: 100,
    ),
    editableFields: ['displayName', 'phone', 'bio'],
  );

  final testAdminComposedProfile = ComposedProfileModel(
    user: const BaseUserProfileModel(
      id: 'user_admin_1',
      instituteId: 'college_1',
      name: 'Principal Grace Hopper',
      email: 'principal@acadex.edu',
      phone: '+919876522222',
      role: AppRole.collegeAdmin,
      collegeId: 'college_1',
      collegeName: 'Apex Institute of Technology',
      bio: 'Executive Administrator',
    ),
    roleProfile: const RoleProfileCompositeModel(
      collegeAdmin: CollegeAdminRoleProfileModel(
        collegeId: 'college_1',
        collegeName: 'Apex Institute of Technology',
        collegeCode: 'AIT',
        departmentsCount: 8,
        facultyCount: 120,
        studentsCount: 2400,
      ),
    ),
    completion: const ProfileCompletionModel(
      percentage: 100,
    ),
    editableFields: ['displayName', 'phone', 'bio'],
  );

  Widget createWidgetForTesting({
    required Widget child,
    required FakeProfileRepository repo,
    UserModel? authUser,
  }) {
    final user = authUser ?? testStudentUser;
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'mock_jwt')),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Prompt 48 — Role-Aware Profile Tests', () {
    testWidgets('1. Student profile renders identity and current enrollment', (tester) async {
      final fakeRepo = FakeProfileRepository(mockProfile: testStudentComposedProfile);

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: testStudentUser,
        ),
      );
      await tester.pumpAndSettle();

      // Identity & Contact
      expect(find.text('Aarav Patel'), findsOneWidget);
      expect(find.text('aarav.patel@acadex.edu'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);

      // Student Academic Context from StudentEnrollment
      expect(find.text('CS2023001'), findsOneWidget);
      expect(find.textContaining('B.Tech Computer Science'), findsOneWidget);
      expect(find.text('Semester V'), findsOneWidget);
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Academic Context'), findsOneWidget);
    });

    testWidgets('2. Faculty profile renders active teaching assignments', (tester) async {
      final fakeRepo = FakeProfileRepository(mockProfile: testFacultyComposedProfile);
      final facultyUser = UserModel(
        id: 'user_faculty_1',
        name: 'Dr. John McCarthy',
        email: 'john.mccarthy@acadex.edu',
        role: AppRole.faculty,
        collegeId: 'college_1',
      );

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: facultyUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. John McCarthy'), findsOneWidget);
      expect(find.text('EMP-CS-042'), findsOneWidget);
      expect(find.textContaining('Artificial Intelligence'), findsWidgets);
      expect(find.textContaining('CS502'), findsOneWidget);
      expect(find.text('Active Teaching Assignments'), findsOneWidget);
    });

    testWidgets('3. HOD profile renders department scope', (tester) async {
      final fakeRepo = FakeProfileRepository(mockProfile: testHodComposedProfile);
      final hodUser = UserModel(
        id: 'user_hod_1',
        name: 'Dr. Ada Lovelace',
        email: 'ada.lovelace@acadex.edu',
        role: AppRole.hod,
        collegeId: 'college_1',
      );

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: hodUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Ada Lovelace'), findsOneWidget);
      expect(find.textContaining('Department Leadership'), findsOneWidget);
      expect(find.text('Computer Science and Engineering'), findsWidgets);
      expect(find.text('Programs'), findsOneWidget);
    });

    testWidgets('4. College Admin profile renders institution scope', (tester) async {
      final fakeRepo = FakeProfileRepository(mockProfile: testAdminComposedProfile);
      final adminUser = UserModel(
        id: 'user_admin_1',
        name: 'Principal Grace Hopper',
        email: 'principal@acadex.edu',
        role: AppRole.collegeAdmin,
        collegeId: 'college_1',
      );

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: adminUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Principal Grace Hopper'), findsOneWidget);
      expect(find.text('Administrative Scope'), findsOneWidget);
      expect(find.text('Apex Institute of Technology'), findsWidgets);
      expect(find.text('Departments'), findsOneWidget);
    });

    testWidgets('5. Missing enrollment state renders clear warning banner', (tester) async {
      final profileWithoutEnrollment = ComposedProfileModel(
        user: testStudentComposedProfile.user,
        roleProfile: const RoleProfileCompositeModel(
          student: StudentRoleProfileModel(
            studentId: 'student_1',
            rollNumber: 'CS2023001',
            isEnrollmentAvailable: false,
            currentEnrollment: null,
          ),
        ),
        completion: const ProfileCompletionModel(percentage: 60, missingFields: ['currentEnrollment']),
      );
      final fakeRepo = FakeProfileRepository(mockProfile: profileWithoutEnrollment);

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: testStudentUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current academic enrollment is not available.'), findsOneWidget);
    });

    testWidgets('6. Edit profile screen displays editable personal fields and locks institutional data', (tester) async {
      final fakeRepo = FakeProfileRepository(mockProfile: testStudentComposedProfile);

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const EditProfileScreen(),
          repo: fakeRepo,
          authUser: testStudentUser,
        ),
      );
      await tester.pumpAndSettle();

      // Editable fields populated
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Aarav Patel'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);

      // Institutional Read-only locks
      expect(find.text('Managed by Institution'), findsOneWidget);
      expect(find.text('aarav.patel@acadex.edu'), findsOneWidget);
      expect(find.text('Student'), findsWidgets);
      expect(find.text('CS2023001'), findsOneWidget);
    });

    testWidgets('7. Saving profile update invokes repository with modified personal fields', (tester) async {
      final fakeRepo = FakeProfileRepository(mockProfile: testStudentComposedProfile);

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const EditProfileScreen(),
          repo: fakeRepo,
          authUser: testStudentUser,
        ),
      );
      await tester.pumpAndSettle();

      // Enter new phone number
      final phoneField = find.widgetWithText(TextFormField, '+919876543210');
      await tester.enterText(phoneField, '+919999888877');

      // Scroll to and tap Save Changes button
      final saveButton = find.text('Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.lastUpdatedData['phone'], equals('+919999888877'));
    });

    testWidgets('8. 360px mobile viewport has zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeProfileRepository(mockProfile: testStudentComposedProfile);

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: testStudentUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('9. 390px mobile viewport has zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeProfileRepository(mockProfile: testFacultyComposedProfile);

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: UserModel(
            id: 'user_faculty_1',
            name: 'Dr. John McCarthy',
            email: 'john.mccarthy@acadex.edu',
            role: AppRole.faculty,
            collegeId: 'college_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('10. 412px mobile viewport has zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeProfileRepository(mockProfile: testAdminComposedProfile);

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: UserModel(
            id: 'user_admin_1',
            name: 'Principal Grace Hopper',
            email: 'principal@acadex.edu',
            role: AppRole.collegeAdmin,
            collegeId: 'college_1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('11. Profile completion indicator renders percentage', (tester) async {
      final fakeRepo = FakeProfileRepository(mockProfile: testStudentComposedProfile);

      await tester.pumpWidget(
        createWidgetForTesting(
          child: const ProfileScreen(),
          repo: fakeRepo,
          authUser: testStudentUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Profile Completion'), findsOneWidget);
    });

    test('12. RealtimeDispatcher invalidates profile on profile.updated event', () async {
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository(mockProfile: testStudentComposedProfile)),
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudentUser, token: 'mock_jwt')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initialProfile = await container.read(profileProvider.future);
      expect(initialProfile.user.name, equals('Aarav Patel'));

      final dispatcher = container.read(realtimeDispatcherProvider);
      final eventController = StreamController<RealtimeEvent>.broadcast();
      dispatcher.start(eventController.stream);

      // Emit profile.updated event
      eventController.add(
        RealtimeEvent(
          eventId: 'evt_prof_1',
          eventVersion: 1,
          eventType: 'profile.updated',
          aggregateType: 'profile',
          aggregateId: 'user_student_1',
          action: 'updated',
          occurredAt: DateTime.now(),
          collegeId: 'college_1',
          scope: {'userId': 'user_student_1'},
          payload: {'userId': 'user_student_1', 'displayName': 'Aarav Patel Updated'},
        ),
      );

      // Allow debounce window
      await Future<void>.delayed(const Duration(milliseconds: 350));
      dispatcher.stop();
      await eventController.close();
    });
  });
}
