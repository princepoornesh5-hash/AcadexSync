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
import 'package:campus_management/features/users/presentation/screens/user_directory_screen.dart';
import 'package:campus_management/features/users/presentation/screens/user_detail_screen.dart';
import 'package:campus_management/features/users/presentation/screens/user_form_screen.dart';
import 'package:campus_management/features/users/presentation/screens/profile_screen.dart';
import 'package:campus_management/features/users/presentation/widgets/user_list_item.dart';
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

  final testFaculty = UserProfileModel(
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
    Department(
      id: 'dept_ece',
      collegeId: 'college_1',
      name: 'Electronics & Communication',
      code: 'ECE',
      hodId: 'hod_2',
      description: 'Department of Electronics',
    ),
  ];

  group('ACADEX Phase 9Q.1 — Users & Roles UI/UX Tests', () {
    testWidgets('UserRoleBadge and UserStatusBadge render appropriate labels and colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                UserRoleBadge(role: AppRole.superAdmin),
                UserRoleBadge(role: AppRole.collegeAdmin),
                UserRoleBadge(role: AppRole.hod),
                UserRoleBadge(role: AppRole.faculty),
                UserRoleBadge(role: AppRole.student),
                UserStatusBadge(status: AccountStatus.active),
                UserStatusBadge(status: AccountStatus.pendingActivation),
                UserStatusBadge(status: AccountStatus.inactive),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('College Admin'), findsOneWidget);
      expect(find.text('HOD'), findsOneWidget);
      expect(find.text('Faculty'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pending Activation'), findsOneWidget);
      expect(find.text('Deactivated'), findsOneWidget);
    });

    testWidgets('UserListItem renders avatar, name, badges, and metadata accurately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserListItem(
              user: testHod,
              departmentName: 'Computer Science & Engineering',
            ),
          ),
        ),
      );

      expect(find.text('Dr. Alan Turing'), findsOneWidget);
      expect(find.text('alan@campus.edu'), findsOneWidget);
      expect(find.text('EMP-HOD-01'), findsOneWidget);
      expect(find.text('Computer Science & Engineering'), findsOneWidget);
      expect(find.text('HOD'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('UserDirectoryScreen renders search, role tabs, and user list for College Admin', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testCollegeAdmin, token: 'tok'))),
            departmentsProvider.overrideWith(() => _FakeDepartmentNotifier(testDepartments)),
            usersListProvider.overrideWith((ref) async => [testHod, testFaculty, testStudent]),
          ],
          child: const MaterialApp(
            home: UserDirectoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Users & Roles'), findsOneWidget);
      expect(find.text('Add User'), findsOneWidget);
      expect(find.text('Dr. Alan Turing'), findsOneWidget);
      expect(find.text('Prof. Grace Hopper'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Directory Records'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('UserDetailScreen displays profile attributes and authorized admin actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testCollegeAdmin, token: 'tok'))),
            departmentsProvider.overrideWith(() => _FakeDepartmentNotifier(testDepartments)),
            userDetailProvider('hod_1').overrideWith((ref) async => testHod),
          ],
          child: const MaterialApp(
            home: UserDetailScreen(userId: 'hod_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dr. Alan Turing'), findsWidgets);
      expect(find.text('alan@campus.edu'), findsWidgets);
      expect(find.text('Identity & Contact'), findsOneWidget);
      expect(find.text('Academic & System Record'), findsOneWidget);
      expect(find.text('Edit User'), findsOneWidget);
      expect(find.text('Deactivate Account'), findsOneWidget);
    });

    testWidgets('UserDetailScreen displays Reissue Code action for pending activation accounts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testCollegeAdmin, token: 'tok'))),
            departmentsProvider.overrideWith(() => _FakeDepartmentNotifier(testDepartments)),
            userDetailProvider('fac_1').overrideWith((ref) async => testFaculty),
          ],
          child: const MaterialApp(
            home: UserDetailScreen(userId: 'fac_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Prof. Grace Hopper'), findsWidgets);
      expect(find.text('Reissue Code'), findsOneWidget);
    });

    testWidgets('UserFormScreen renders creation fields and adapts dynamically', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testCollegeAdmin, token: 'tok'))),
            departmentsProvider.overrideWith(() => _FakeDepartmentNotifier(testDepartments)),
          ],
          child: const MaterialApp(
            home: UserFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Register New User'), findsOneWidget);
      expect(find.text('Account Role & Type'), findsOneWidget);
      expect(find.text('Personal & Contact Details'), findsOneWidget);
      expect(find.text('Institutional Assignment'), findsOneWidget);
      expect(find.text('Register User'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders authenticated self-service details', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testHod, token: 'tok'))),
            departmentsProvider.overrideWith(() => _FakeDepartmentNotifier(testDepartments)),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Dr. Alan Turing'), findsWidgets);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Personal & Contact Information'), findsOneWidget);
      expect(find.text('Academic & Institutional Record'), findsOneWidget);
    });
  });
}
