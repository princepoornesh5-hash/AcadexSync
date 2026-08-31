import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/provision_admin_screen.dart';
import 'package:campus_management/features/academic_structure/data/repositories/api_academic_repository.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAcademicRepository implements ApiAcademicRepository {
  int provisionCalls = 0;
  final List<ProvisionAdminResult> resultsToReturn;
  int _currentIndex = 0;

  _MockAcademicRepository({List<ProvisionAdminResult>? results})
      : resultsToReturn = results ?? [];

  @override
  Future<ProvisionAdminResult> provisionCollegeAdmin(
    String collegeId,
    Map<String, dynamic> data,
  ) async {
    provisionCalls++;
    // Simulate real network latency
    await Future.delayed(const Duration(milliseconds: 50));
    if (_currentIndex < resultsToReturn.length) {
      return resultsToReturn[_currentIndex++];
    }
    return ProvisionAdminResult(
      activationCode: 'ACT-COL-000111',
      adminName: data['name'] as String? ?? 'Admin Name',
      adminInstituteId: data['instituteId'] as String? ?? 'ADM-01',
      adminEmail: data['email'] as String?,
      adminPhone: data['phone'] as String?,
      collegeName: 'Global Institute of Technology',
      collegeCode: 'GIT',
      invitationId: 'inv_1',
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
    );
  }

  @override
  Future<College> getCollegeById(String id) async {
    return College(
      id: 'col_123',
      name: 'Global Institute of Technology',
      code: 'GIT',
      principal: 'Dr. Johnathan Smith',
      address: '100 University Boulevard',
      email: 'contact@git.edu',
      phone: '9876543210',
      isActive: true,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCollegeAdmins(String id) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSuperAdmin = const UserModel(
    id: 'super_admin_1',
    name: 'Super Admin User',
    email: 'super@acadex.edu',
    role: AppRole.superAdmin,
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

  group('ACADEX — Provision College Admin Lifecycle & Async Result Tests', () {
    test('1. ProvisionCollegeAdminNotifier does NOT throw disposed error when unobserved during async completion', () async {
      final container = ProviderContainer(
        overrides: [
          apiAcademicRepositoryProvider.overrideWithValue(_MockAcademicRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Call provision on the notifier without any active listeners (simulating ref.read)
      final notifier = container.read(provisionCollegeAdminProvider.notifier);
      final result = await notifier.provision('col_123', {
        'name': 'Dr. Test Admin',
        'instituteId': 'GIT-ADM-99',
      });

      expect(result.activationCode, 'ACT-COL-000111');
      expect(result.adminName, 'Dr. Test Admin');
      expect(result.adminInstituteId, 'GIT-ADM-99');
    });

    testWidgets('2. ProvisionAdminScreen submits successfully and renders ActivationResultScreen with code', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = _MockAcademicRepository(
        results: [
          ProvisionAdminResult(
            activationCode: 'ACT-ADMIN-999888',
            adminName: 'Dr. Bruce Wayne',
            adminInstituteId: 'GIT-ADMIN-007',
            adminEmail: 'bruce@wayne.edu',
            adminPhone: '+91 9876543210',
            collegeName: 'Global Institute of Technology',
            collegeCode: 'GIT',
            invitationId: 'inv_bruce',
            expiresAt: DateTime.now().add(const Duration(hours: 48)),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testSuperAdmin, token: 'tok'))),
            collegeByIdProvider('col_123').overrideWith((ref) async => testCollege),
            apiAcademicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ProvisionAdminScreen(collegeId: 'col_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter form fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name *'), 'Dr. Bruce Wayne');
      await tester.enterText(find.widgetWithText(TextFormField, 'PIN Number *'), 'GIT-ADMIN-007');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email (Optional)'), 'bruce@wayne.edu');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone (Optional)'), '9876543210');

      // Submit
      final submitBtn = find.text('Provision Administrator');
      await tester.tap(submitBtn);

      // Await async network completion and settle navigation
      await tester.pumpAndSettle();

      // Verify Activation Result Screen is displayed with real activation code
      expect(find.text('College Admin Provisioned'), findsOneWidget);
      expect(find.text('ACT-ADMIN-999888'), findsOneWidget);
      expect(find.text('GIT-ADMIN-007'), findsOneWidget);
      expect(find.text('Dr. Bruce Wayne'), findsOneWidget);
      expect(find.text('Global Institute of Technology (GIT)'), findsOneWidget);
      expect(find.text('Copy Activation Code'), findsOneWidget);
      expect(find.text('Copy All Credentials'), findsOneWidget);
    });

    testWidgets('3. Double-tap on submit does NOT trigger duplicate provisioning requests', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = _MockAcademicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testSuperAdmin, token: 'tok'))),
            collegeByIdProvider('col_123').overrideWith((ref) async => testCollege),
            apiAcademicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ProvisionAdminScreen(collegeId: 'col_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name *'), 'Dr. Bruce Wayne');
      await tester.enterText(find.widgetWithText(TextFormField, 'PIN Number *'), 'GIT-ADMIN-007');

      final submitBtn = find.text('Provision Administrator');
      // Rapid double tap
      await tester.tap(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.provisionCalls, 1);
    });

    test('4. Independent provisioning of Account A and Account B receives unique activation codes', () async {
      final mockRepo = _MockAcademicRepository(
        results: [
          ProvisionAdminResult(
            activationCode: 'ACT-ALPHA-111111',
            adminName: 'Admin Alpha',
            adminInstituteId: 'ADM-A',
            collegeName: 'College A',
            collegeCode: 'COLA',
            invitationId: 'inv_a',
            expiresAt: DateTime.now().add(const Duration(hours: 48)),
          ),
          ProvisionAdminResult(
            activationCode: 'ACT-BETA-222222',
            adminName: 'Admin Beta',
            adminInstituteId: 'ADM-B',
            collegeName: 'College B',
            collegeCode: 'COLB',
            invitationId: 'inv_b',
            expiresAt: DateTime.now().add(const Duration(hours: 48)),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          apiAcademicRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      container.listen(provisionCollegeAdminProvider, (_, __) {});
      final notifier = container.read(provisionCollegeAdminProvider.notifier);

      final resA = await notifier.provision('col_a', {'name': 'Admin Alpha', 'instituteId': 'ADM-A'});
      final resB = await notifier.provision('col_b', {'name': 'Admin Beta', 'instituteId': 'ADM-B'});

      expect(resA.activationCode, 'ACT-ALPHA-111111');
      expect(resB.activationCode, 'ACT-BETA-222222');
      expect(resA.activationCode, isNot(resB.activationCode));
    });
  });
}
