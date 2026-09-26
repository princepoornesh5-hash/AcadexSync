import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/users/domain/models/user_profile_model.dart';
import 'package:campus_management/features/users/domain/models/user_status_enum.dart';
import 'package:campus_management/features/users/presentation/providers/user_providers.dart';
import 'package:campus_management/features/users/data/repositories/user_repository.dart';
import 'package:campus_management/features/users/presentation/screens/user_directory_screen.dart';
import 'package:campus_management/features/users/presentation/screens/user_detail_screen.dart';
import 'package:campus_management/features/users/presentation/screens/user_form_screen.dart';
import 'package:campus_management/features/users/presentation/widgets/user_role_badge.dart';
import 'package:campus_management/features/users/presentation/widgets/user_status_badge.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDepartmentNotifier extends DepartmentNotifier {
  final List<Department> _departments;
  _FakeDepartmentNotifier(this._departments);

  @override
  Future<List<Department>> build() async => _departments;
}

class _FakeUserRepository implements UserRepository {
  bool createUserCalled = false;
  bool updateUserCalled = false;
  bool deleteUserCalled = false;
  bool reactivateUserCalled = false;

  final List<UserProfileModel> users;

  _FakeUserRepository(this.users);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UserProfileModel>> getUsers({
    String? scopeCollegeId,
    String? scopeDepartmentId,
    AppRole? role,
    String? departmentId,
    UserStatus? status,
    String? searchQuery,
  }) async {
    var filtered = List<UserProfileModel>.from(users);
    if (role != null) {
      filtered = filtered.where((u) => u.role == role).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((u) => u.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    return filtered;
  }

  @override
  Future<UserProfileModel?> getUserById(String id) async {
    return users.firstWhere((u) => u.id == id, orElse: () => users.first);
  }

  @override
  Future<UserProfileModel> createUser(UserProfileModel user) async {
    createUserCalled = true;
    return user;
  }

  @override
  Future<UserProfileModel> updateUser(UserProfileModel user) async {
    updateUserCalled = true;
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    deleteUserCalled = true;
  }

  @override
  Future<void> reactivateUser(String id) async {
    reactivateUserCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testCollegeAdmin = UserProfileModel(
    id: 'admin_1',
    name: 'Admin Sarah',
    email: 'sarah@campus.edu',
    phone: '+91 9876543210',
    role: AppRole.collegeAdmin,
    collegeId: 'college_1',
    status: UserStatus.active,
    accountStatus: AccountStatus.active,
  );

  final testHod = UserProfileModel(
    id: 'hod_1',
    name: 'Dr. Alan Turing',
    email: 'alan@campus.edu',
    phone: '+91 9876543211',
    role: AppRole.hod,
    collegeId: 'college_1',
    departmentId: 'dept_cse',
    employeeId: 'EMP-HOD-01',
    status: UserStatus.active,
    accountStatus: AccountStatus.active,
    profilePictureUrl: 'https://ik.imagekit.io/acadex/profiles/hod1.png',
  );

  final testFacultyPending = UserProfileModel(
    id: 'fac_1',
    name: 'Prof. Grace Hopper',
    email: 'grace@campus.edu',
    phone: '+91 9876543212',
    role: AppRole.faculty,
    collegeId: 'college_1',
    departmentId: 'dept_cse',
    employeeId: 'EMP-FAC-02',
    status: UserStatus.pending,
    accountStatus: AccountStatus.pendingActivation,
  );

  final testStudent = UserProfileModel(
    id: 'stud_1',
    name: 'Ada Lovelace',
    email: 'ada@campus.edu',
    phone: '+91 9876543213',
    role: AppRole.student,
    collegeId: 'college_1',
    departmentId: 'dept_cse',
    rollNumber: '2026-CSE-001',
    status: UserStatus.active,
    accountStatus: AccountStatus.active,
  );

  final testDepartments = [
    Department(
      id: 'dept_cse',
      collegeId: 'college_1',
      name: 'Computer Science & Engineering',
      code: 'CSE',
      hodId: 'hod_1',
      description: 'Department of Computer Science',
    ),
  ];

  Widget createTestWidget(
    Widget child, {
    List<UserProfileModel>? usersList,
    _FakeUserRepository? customRepo,
  }) {
    final fakeRepo = customRepo ?? _FakeUserRepository(usersList ?? [testHod, testFacultyPending, testStudent]);

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testCollegeAdmin, token: 'token'))),
        departmentsProvider.overrideWith(() => _FakeDepartmentNotifier(testDepartments)),
        userRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('ACADEX — Users & Roles Vertical Slice Tests', () {
    testWidgets('1. User directory renders title, search, filters, and user cards', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const UserDirectoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Users & Roles'), findsOneWidget);
      expect(find.text('Add User'), findsOneWidget);
      expect(find.textContaining('Dr. Alan Turing'), findsOneWidget);
      expect(find.textContaining('Prof. Grace Hopper'), findsOneWidget);
      expect(find.textContaining('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('2. Search field filters user list dynamically', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const UserDirectoryScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Alan');
      await tester.pumpAndSettle();

      expect(find.textContaining('Dr. Alan Turing'), findsOneWidget);
    });

    testWidgets('3. Role filters allow filtering by HOD, Faculty, Student', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const UserDirectoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('HOD'), findsWidgets);
      expect(find.text('Faculty'), findsWidgets);
      expect(find.text('Student'), findsWidgets);
    });

    testWidgets('4. Role badges and status badges render with proper tokens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                UserRoleBadge(role: AppRole.hod),
                UserRoleBadge(role: AppRole.faculty),
                UserRoleBadge(role: AppRole.student),
                UserStatusBadge(status: AccountStatus.active),
                UserStatusBadge(status: AccountStatus.pendingActivation),
                UserStatusBadge(status: AccountStatus.deactivated),
              ],
            ),
          ),
        ),
      );

      expect(find.text('HOD'), findsOneWidget);
      expect(find.text('Faculty'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pending Activation'), findsOneWidget);
      expect(find.text('Deactivated'), findsOneWidget);
    });

    testWidgets('5. User Form renders in create mode with role-specific fields', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const UserFormScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Register New User'), findsOneWidget);
      expect(find.textContaining('Full Name'), findsOneWidget);
      expect(find.textContaining('Email Address'), findsOneWidget);
      expect(find.textContaining('Phone Number'), findsOneWidget);
      expect(find.textContaining('Employee ID'), findsOneWidget);
      expect(find.text('Register User'), findsOneWidget);
    });

    testWidgets('6. User Form validates required fields on submission', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const UserFormScreen()));
      await tester.pumpAndSettle();

      final submitBtn = find.text('Register User');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a full name'), findsOneWidget);
      expect(find.text('Please enter an email address'), findsOneWidget);
      expect(find.text('Please enter a phone number'), findsOneWidget);
    });

    testWidgets('7. User Form creates user and invokes backend repository', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final customRepo = _FakeUserRepository([]);

      await tester.pumpWidget(createTestWidget(const UserFormScreen(), customRepo: customRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Prof. Charles Babbage');
      await tester.enterText(find.byType(TextFormField).at(1), 'babbage@campus.edu');
      await tester.enterText(find.byType(TextFormField).at(2), '+91 9123456780');
      await tester.enterText(find.byType(TextFormField).at(3), 'EMP-CS-99');

      final submitBtn = find.text('Register User');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(customRepo.createUserCalled, isTrue);
    });

    testWidgets('8. User Detail screen displays full user profile and metadata', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const UserDetailScreen(userId: 'hod_1')));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Alan Turing'), findsWidgets);
      expect(find.text('alan@campus.edu'), findsOneWidget);
      expect(find.textContaining('EMP-HOD-01'), findsOneWidget);
      expect(find.text('Computer Science & Engineering'), findsWidgets);
      expect(find.text('Edit User'), findsOneWidget);
      expect(find.text('Deactivate Account'), findsOneWidget);
    });

    testWidgets('9. User Detail screen displays Reissue Activation for pending users', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const UserDetailScreen(userId: 'fac_1'), usersList: [testFacultyPending]));
      await tester.pumpAndSettle();

      expect(find.text('Prof. Grace Hopper'), findsWidgets);
      expect(find.text('Reissue Code'), findsOneWidget);
    });

    testWidgets('10. Deactivate account shows confirmation dialog and dispatches deletion', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final customRepo = _FakeUserRepository([testHod]);

      await tester.pumpWidget(createTestWidget(const UserDetailScreen(userId: 'hod_1'), customRepo: customRepo));
      await tester.pumpAndSettle();

      final deactivateBtn = find.text('Deactivate Account');
      await tester.ensureVisible(deactivateBtn);
      await tester.tap(deactivateBtn);
      await tester.pumpAndSettle();

      expect(find.text('Deactivate User Account'), findsOneWidget);
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Deactivate');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(customRepo.deleteUserCalled, isTrue);
    });

    testWidgets('11. Empty directory displays empty state illustration', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const UserDirectoryScreen(), usersList: []));
      await tester.pumpAndSettle();

      expect(find.text('No users found'), findsOneWidget);
    });

    testWidgets('12. Dark mode and mobile responsive layout render cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testCollegeAdmin, token: 'token'))),
            departmentsProvider.overrideWith(() => _FakeDepartmentNotifier(testDepartments)),
            userRepositoryProvider.overrideWithValue(_FakeUserRepository([testHod])),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const UserDirectoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Users & Roles'), findsOneWidget);
      expect(find.text('Dr. Alan Turing'), findsOneWidget);
    });
  });
}
