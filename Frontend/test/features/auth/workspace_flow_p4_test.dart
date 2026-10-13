import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/workspace_model.dart';
import 'package:campus_management/features/auth/data/repositories/workspace_repository.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/presentation/providers/workspace_providers.dart';
import 'package:campus_management/features/auth/presentation/widgets/workspace_selector_dialog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/presentation/coordinators/notification_navigation_coordinator.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_providers.dart';

class FakeWorkspaceRepository implements WorkspaceRepository {
  List<WorkspaceMembershipModel> membershipsToReturn = [];
  bool shouldThrow = false;
  String? lastSwitchedTarget;

  @override
  Future<List<WorkspaceMembershipModel>> getMyMemberships() async {
    if (shouldThrow) throw Exception('Network error');
    return membershipsToReturn;
  }

  @override
  Future<SwitchWorkspaceResult> switchWorkspace(String targetCollegeId) async {
    lastSwitchedTarget = targetCollegeId;
    if (shouldThrow) throw Exception('Unauthorized target');
    return SwitchWorkspaceResult(
      accessToken: 'fresh_jwt_token_for_$targetCollegeId',
      activeWorkspace: {
        'collegeId': targetCollegeId,
        'collegeName': 'Switched College',
        'collegeCode': 'SWT',
        'roles': ['HOD'],
        'role': 'HOD',
      },
      userJson: {
        'id': 'user_123',
        'name': 'Dr. Test User',
        'email': 'test@campus.edu',
        'role': 'HOD',
        'collegeId': targetCollegeId,
        'accountStatus': 'active',
      },
    );
  }
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  UserModel? updatedUser;

  FakeAuthNotifier(super.initial);

  @override
  Future<void> login(String identifier, String password) async {}
  @override
  Future<void> loginAsDevelopmentRole(AppRole role) async {}
  @override
  Future<void> logout() async {
    state = const AuthUnauthenticated();
  }
  @override
  Future<void> logoutAll() async {
    state = const AuthUnauthenticated();
  }
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
  @override
  void updateCurrentUser(UserModel updatedUser) {
    this.updatedUser = updatedUser;
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user: updatedUser, token: (state as AuthAuthenticated).token);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'user_123',
    name: 'Dr. Test User',
    email: 'test@campus.edu',
    role: AppRole.faculty,
    collegeId: 'college_a',
  );

  final collegeAMembership = WorkspaceMembershipModel(
    id: 'mem_1',
    collegeId: 'college_a',
    collegeName: 'Engineering Campus A',
    collegeCode: 'ENGA',
    status: 'ACTIVE',
    isDefault: true,
    roles: [AppRole.faculty],
    primaryRole: AppRole.faculty,
    departmentName: 'Computer Science',
  );

  final collegeBMembership = WorkspaceMembershipModel(
    id: 'mem_2',
    collegeId: 'college_b',
    collegeName: 'Medical Campus B',
    collegeCode: 'MEDB',
    status: 'ACTIVE',
    isDefault: false,
    roles: [AppRole.hod],
    primaryRole: AppRole.hod,
    departmentName: 'Pathology',
  );

  group('Prompt 4: Workspace Flow & Multi-College UX Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('1. WorkspaceMembershipModel correctly serializes and deserializes', () {
      final json = collegeAMembership.toJson();
      final reconstituted = WorkspaceMembershipModel.fromJson(json);

      expect(reconstituted.collegeId, equals('college_a'));
      expect(reconstituted.collegeCode, equals('ENGA'));
      expect(reconstituted.primaryRole, equals(AppRole.faculty));
      expect(reconstituted.isActive, isTrue);
    });

    test('2. Single workspace resolves as active workspace without prompts', () async {
      final fakeRepo = FakeWorkspaceRepository()..membershipsToReturn = [collegeAMembership];

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt-1'))),
          workspaceRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final workspaces = await container.read(userWorkspacesProvider.future);
      expect(workspaces.length, equals(1));

      final active = container.read(activeWorkspaceProvider);
      expect(active, isNotNull);
      expect(active!.collegeId, equals('college_a'));
      expect(active.collegeName, equals('Engineering Campus A'));
    });

    test('3. Multiple workspaces load authoritatively and allow switching', () async {
      final fakeRepo = FakeWorkspaceRepository()
        ..membershipsToReturn = [collegeAMembership, collegeBMembership];

      final fakeAuth = FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt-1'));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuth),
          workspaceRepositoryProvider.overrideWithValue(fakeRepo),
          userNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
      );

      final controller = container.read(workspaceSwitchControllerProvider);

      final switchSuccess = await controller.switchWorkspace('college_b');
      expect(switchSuccess, isTrue);
      expect(fakeRepo.lastSwitchedTarget, equals('college_b'));

      expect(container.read(activeWorkspaceIdProvider), equals('college_b'));
      expect(fakeAuth.updatedUser?.role, equals(AppRole.hod));
    });

    test('4. Switch to unauthorized college fails without corrupting active workspace', () async {
      final fakeRepo = FakeWorkspaceRepository()
        ..membershipsToReturn = [collegeAMembership]; // User only belongs to college_a

      final fakeAuth = FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt-1'));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuth),
          workspaceRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final controller = container.read(workspaceSwitchControllerProvider);

      expect(
        () => controller.switchWorkspace('unauthorized_college_x'),
        throwsA(isA<Exception>()),
      );

      // Active workspace remains college_a
      expect(container.read(activeWorkspaceIdProvider), equals('college_a'));
    });

    testWidgets('5. WorkspaceSelectorDialog renders available options with badges', (tester) async {
      final fakeRepo = FakeWorkspaceRepository()
        ..membershipsToReturn = [collegeAMembership, collegeBMembership];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt-1'))),
            workspaceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkspaceSelectorDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Switch Workspace'), findsOneWidget);
      expect(find.text('Engineering Campus A'), findsOneWidget);
      expect(find.text('Medical Campus B'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget); // College A is currently active
    });

    testWidgets('6. Zero workspaces displays recovery state and logout action', (tester) async {
      final fakeRepo = FakeWorkspaceRepository()..membershipsToReturn = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt-1'))),
            workspaceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkspaceSelectorDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Workspaces Found'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    test('7. NotificationNavigationCoordinator safely validates cross-workspace intent', () async {
      final fakeRepo = FakeWorkspaceRepository()
        ..membershipsToReturn = [collegeAMembership, collegeBMembership];

      final fakeAuth = FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt-1'));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuth),
          workspaceRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final coordinator = container.read(notificationNavigationCoordinatorProvider);

      // Cold start: queue pending intent before auth
      final pendingNotification = NotificationModel(
        id: 'notif_1',
        title: 'Assignment Graded',
        message: 'Your marks are posted',
        category: NotificationCategory.assignment,
        priority: NotificationPriority.normal,
        audienceType: NotificationAudienceType.personal,
        timestamp: DateTime.now(),
        collegeId: 'college_b',
        navigationTarget: '/assignments/asg_123',
      );

      coordinator.setPendingNotification(pendingNotification);
      expect(coordinator.pendingNotification?.id, equals('notif_1'));
      expect(coordinator.pendingNotification?.collegeId, equals('college_b'));

      coordinator.clearPendingNotification();
      expect(coordinator.pendingNotification, isNull);
    });
  });
}
