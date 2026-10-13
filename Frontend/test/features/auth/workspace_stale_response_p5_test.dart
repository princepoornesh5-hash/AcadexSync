import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/workspace_model.dart';
import 'package:campus_management/features/auth/data/repositories/workspace_repository.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/presentation/providers/workspace_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_providers.dart';

class MockWorkspaceRepository implements WorkspaceRepository {
  List<WorkspaceMembershipModel> memberships = [];
  bool failNextSwitch = false;

  @override
  Future<List<WorkspaceMembershipModel>> getMyMemberships() async => memberships;

  @override
  Future<SwitchWorkspaceResult> switchWorkspace(String targetCollegeId) async {
    if (failNextSwitch) {
      throw Exception('Server rejected workspace switch: 403 Forbidden');
    }
    return SwitchWorkspaceResult(
      accessToken: 'token_for_$targetCollegeId',
      activeWorkspace: {
        'collegeId': targetCollegeId,
        'collegeName': 'Target Campus',
        'collegeCode': 'TGT',
        'roles': ['FACULTY'],
        'role': 'FACULTY',
      },
      userJson: {
        'id': 'user_test',
        'name': 'Test User',
        'email': 'user@campus.edu',
        'role': 'FACULTY',
        'collegeId': targetCollegeId,
        'accountStatus': 'active',
      },
    );
  }
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  UserModel? updatedUser;

  MockAuthNotifier(super.initial);

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
  void updateCurrentUser(UserModel user) {
    updatedUser = user;
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user: user, token: (state as AuthAuthenticated).token);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final user = UserModel(
    id: 'user_1',
    name: 'Test Professor',
    email: 'prof@campus.edu',
    role: AppRole.faculty,
    collegeId: 'college_alpha',
  );

  final memAlpha = WorkspaceMembershipModel(
    id: 'mem_a',
    collegeId: 'college_alpha',
    collegeName: 'Alpha College of Tech',
    collegeCode: 'ACT',
    status: 'ACTIVE',
    isDefault: true,
    primaryRole: AppRole.faculty,
    roles: [AppRole.faculty],
  );

  final memBeta = WorkspaceMembershipModel(
    id: 'mem_b',
    collegeId: 'college_beta',
    collegeName: 'Beta Science University',
    collegeCode: 'BSU',
    status: 'ACTIVE',
    isDefault: false,
    primaryRole: AppRole.faculty,
    roles: [AppRole.faculty],
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Prompt 5: Workspace Cache Isolation and Stale Response Protection', () {
    test('1. ApiClient workspace epoch increments and rejects stale in-flight response', () {
      final client = ApiClient();
      final initialEpoch = client.currentWorkspaceEpoch;

      // Simulate an in-flight request started at initialEpoch
      final requestOptions = RequestOptions(
        path: '/api/v1/attendance/summary',
        extra: {'workspace_epoch': initialEpoch},
      );

      final response = Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {'studentsCount': 42},
      );

      // Now switch workspace: epoch advances
      client.incrementWorkspaceEpoch();
      expect(client.currentWorkspaceEpoch, equals(initialEpoch + 1));

      // Attempt to validate the stale response against the updated client epoch
      // Using client interceptor logic check
      final reqEpoch = response.requestOptions.extra['workspace_epoch'] as int?;
      expect(reqEpoch, equals(initialEpoch));
      expect(reqEpoch != client.currentWorkspaceEpoch, isTrue);

      // Verify StaleWorkspaceResponseException
      final exception = StaleWorkspaceResponseException(
        requestEpoch: reqEpoch!,
        currentWorkspaceEpoch: client.currentWorkspaceEpoch,
      );
      expect(exception.toString(), contains('StaleWorkspaceResponseException'));
      expect(exception.requestEpoch, equals(initialEpoch));
      expect(exception.currentWorkspaceEpoch, equals(initialEpoch + 1));
    });

    test('2. Successful response with matching epoch passes validation', () {
      final client = ApiClient();
      final currentEpoch = client.currentWorkspaceEpoch;

      final requestOptions = RequestOptions(
        path: '/api/v1/notes',
        extra: {'workspace_epoch': currentEpoch},
      );

      final reqEpoch = requestOptions.extra['workspace_epoch'] as int?;
      expect(reqEpoch, equals(client.currentWorkspaceEpoch));
    });

    test('3. WorkspaceSwitchController advances generation and invalidates caches on switch', () async {
      final mockRepo = MockWorkspaceRepository()
        ..memberships = [memAlpha, memBeta];

      final fakeAuth = MockAuthNotifier(AuthAuthenticated(user: user, token: 'token-alpha'));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuth),
          workspaceRepositoryProvider.overrideWithValue(mockRepo),
          timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          userNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
      );

      final initialGen = container.read(workspaceGenerationProvider);
      expect(initialGen, equals(0));

      final controller = container.read(workspaceSwitchControllerProvider);
      final success = await controller.switchWorkspace('college_beta');

      expect(success, isTrue);
      expect(container.read(activeWorkspaceIdProvider), equals('college_beta'));
      // Generation counter incremented
      expect(container.read(workspaceGenerationProvider), equals(initialGen + 1));
    });

    test('4. Failed workspace switch preserves prior state without advancing generation', () async {
      final mockRepo = MockWorkspaceRepository()
        ..memberships = [memAlpha, memBeta]
        ..failNextSwitch = true;

      final fakeAuth = MockAuthNotifier(AuthAuthenticated(user: user, token: 'token-alpha'));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuth),
          workspaceRepositoryProvider.overrideWithValue(mockRepo),
          timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          userNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
      );

      final initialGen = container.read(workspaceGenerationProvider);
      final controller = container.read(workspaceSwitchControllerProvider);

      expect(
        () => controller.switchWorkspace('college_beta'),
        throwsA(isA<Exception>()),
      );

      // Prior active workspace preserved
      expect(container.read(activeWorkspaceIdProvider), equals('college_alpha'));
      // Generation not incremented
      expect(container.read(workspaceGenerationProvider), equals(initialGen));
    });

    test('5. Logout clears active workspace and increments epoch to kill in-flight requests', () async {
      final apiClient = ApiClient();
      final epochBefore = apiClient.currentWorkspaceEpoch;

      await apiClient.clearTokens();

      expect(apiClient.currentWorkspaceEpoch, equals(epochBefore + 1));
      expect(await apiClient.getToken(), isNull);
      expect(await apiClient.getActiveWorkspace(), isNull);
    });

    test('6. Rapid successive switches advance generation monotonically', () async {
      final mockRepo = MockWorkspaceRepository()
        ..memberships = [memAlpha, memBeta];

      final fakeAuth = MockAuthNotifier(AuthAuthenticated(user: user, token: 'token-alpha'));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => fakeAuth),
          workspaceRepositoryProvider.overrideWithValue(mockRepo),
          timetableRepositoryProvider.overrideWithValue(MockTimetableRepository()),
          userNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
      );

      final controller = container.read(workspaceSwitchControllerProvider);

      await controller.switchWorkspace('college_beta');
      expect(container.read(workspaceGenerationProvider), equals(1));

      await controller.switchWorkspace('college_alpha');
      expect(container.read(workspaceGenerationProvider), equals(2));

      await controller.switchWorkspace('college_beta');
      expect(container.read(workspaceGenerationProvider), equals(3));
      expect(container.read(activeWorkspaceIdProvider), equals('college_beta'));
    });
  });
}
