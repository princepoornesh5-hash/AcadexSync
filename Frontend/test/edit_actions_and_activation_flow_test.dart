import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/college_screens.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/activation_result_screen.dart';
import 'package:campus_management/features/users/domain/models/user_profile_model.dart';
import 'package:campus_management/features/users/domain/models/user_status_enum.dart';
import 'package:campus_management/features/users/presentation/providers/user_providers.dart';
import 'package:campus_management/features/users/presentation/screens/user_form_screen.dart';
import 'package:campus_management/features/users/presentation/widgets/user_activation_result_dialog.dart';
import 'package:campus_management/features/users/data/repositories/user_repository.dart';
import 'package:campus_management/features/users/data/repositories/api_user_repository.dart';

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

class _FakeCollegeNotifier extends CollegeNotifier {
  final List<College> _colleges;
  _FakeCollegeNotifier(this._colleges);

  @override
  Future<List<College>> build() async => _colleges;
}

class _FakeUserRepository implements UserRepository {
  final UserProfileModel testUser;
  _FakeUserRepository({required this.testUser});

  @override
  Future<UserProfileModel?> getUserById(String id) async => testUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSuperAdmin = UserProfileModel(
    id: 'super_admin_1',
    name: 'Super Admin Person',
    email: 'super@acadex.edu',
    phone: '+91 9999999999',
    role: AppRole.superAdmin,
    status: UserStatus.active,
    accountStatus: AccountStatus.active,
  );

  final testCollege = College(
    id: 'col_123',
    name: 'Global Institute of Technology',
    code: 'GIT',
    principal: 'Dr. Johnathan Smith',
    address: '100 University Boulevard',
    email: 'contact@git.edu',
    phone: '9876543210',
    isActive: true,
  );

  final testFacultyUser = UserProfileModel(
    id: 'fac_123',
    name: 'Prof. Alan Turing',
    email: 'alan.turing@git.edu',
    phone: '+91 9876543210',
    role: AppRole.faculty,
    collegeId: 'col_123',
    departmentId: 'dept_cse',
    employeeId: 'FAC-CSE-007',
    status: UserStatus.active,
    accountStatus: AccountStatus.active,
  );

  final testDepartment = Department(
    id: 'dept_cse',
    collegeId: 'col_123',
    name: 'Computer Science & Engineering',
    code: 'CSE',
    hodId: 'hod_1',
    description: 'Department of Computer Science',
  );

  group('ACADEX — Edit Actions & Activation Verification Tests', () {
    testWidgets('1. CollegeFormScreen loads existing data in edit mode and populates all form fields', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testSuperAdmin, token: 'tok'))),
            collegeByIdProvider('col_123').overrideWith((ref) async => testCollege),
            collegesProvider.overrideWith(() => _FakeCollegeNotifier([testCollege])),
          ],
          child: const MaterialApp(
            home: CollegeFormScreen(collegeId: 'col_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit College'), findsOneWidget);
      expect(find.text('Global Institute of Technology'), findsOneWidget);
      expect(find.text('GIT'), findsOneWidget);
      expect(find.text('Dr. Johnathan Smith'), findsOneWidget);
      expect(find.text('100 University Boulevard'), findsOneWidget);
      expect(find.text('contact@git.edu'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
    });

    testWidgets('2. UserFormScreen loads existing user data in edit mode without crashing or assertion failures', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testSuperAdmin, token: 'tok'))),
            departmentsProvider.overrideWith(() => _FakeDepartmentNotifier([testDepartment])),
            collegesProvider.overrideWith(() => _FakeCollegeNotifier([testCollege])),
            userRepositoryProvider.overrideWithValue(_FakeUserRepository(testUser: testFacultyUser)),
          ],
          child: const MaterialApp(
            home: UserFormScreen(userId: 'fac_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit User Record'), findsOneWidget);
      expect(find.text('Prof. Alan Turing'), findsOneWidget);
      expect(find.text('alan.turing@git.edu'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.text('FAC-CSE-007'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('3. UserActivationResultDialog renders College Code, PIN Number, and single-use Activation Code', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final createUserResult = CreateUserResult(
        user: testFacultyUser,
        activationCode: 'ACT-PROV-987654',
        invitationId: 'inv_123',
        collegeCode: 'GIT',
        expiresAt: DateTime.now().add(const Duration(hours: 48)),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UserActivationResultDialog(result: createUserResult),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User Provisioned Successfully'), findsOneWidget);
      expect(find.text('ACT-PROV-987654'), findsOneWidget);
      expect(find.text('FAC-CSE-007'), findsOneWidget);
      expect(find.text('GIT'), findsOneWidget);
      expect(find.text('Prof. Alan Turing'), findsOneWidget);
      expect(find.text('Copy All Credentials'), findsOneWidget);
    });

    testWidgets('4. ActivationResultScreen renders College Admin credentials with PIN and College Code', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provisionResult = ProvisionAdminResult(
        activationCode: 'ACT-ADMIN-555888',
        adminName: 'Dr. Sarah Connor',
        adminInstituteId: 'GIT-ADMIN-01',
        adminEmail: 'sarah@git.edu',
        adminPhone: '+91 9876543210',
        collegeName: 'Global Institute of Technology',
        collegeCode: 'GIT',
        invitationId: 'inv_admin_1',
        expiresAt: DateTime.now().add(const Duration(hours: 48)),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivationResultScreen(result: provisionResult),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('College Admin Provisioned'), findsOneWidget);
      expect(find.text('ACT-ADMIN-555888'), findsOneWidget);
      expect(find.text('GIT-ADMIN-01'), findsOneWidget);
      expect(find.text('Dr. Sarah Connor'), findsOneWidget);
      expect(find.text('Global Institute of Technology (GIT)'), findsOneWidget);
      expect(find.text('Copy Activation Code'), findsOneWidget);
    });
  });
}
