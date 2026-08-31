import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/repositories/auth_repository.dart';
import 'package:campus_management/features/auth/services/session_manager.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TrackingMockAuthRepository extends MockAuthRepository {
  bool logoutCalled = false;
  bool logoutAllCalled = false;
  UserModel? currentUser;

  @override
  Future<UserModel> login(String identifier, String password) async {
    currentUser = UserModel(
      id: 'usr_test_1',
      name: 'Test Faculty',
      email: 'faculty@acadex.com',
      role: AppRole.faculty,
      instituteId: 'FAC-001',
      accountStatus: AccountStatus.active,
      createdAt: DateTime.now(),
    );
    return currentUser!;
  }

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    currentUser = null;
  }

  @override
  Future<void> logoutAll() async {
    logoutAllCalled = true;
    currentUser = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('ACADEX Priority 1 / Prompt 2: Logout + Session Lifecycle Tests', () {
    late FlutterSecureStorage mockStorage;
    late SessionManager sessionManager;
    late TrackingMockAuthRepository mockRepo;
    late ApiClient apiClient;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      mockStorage = const FlutterSecureStorage();
      sessionManager = SessionManager(mockStorage);
      mockRepo = TrackingMockAuthRepository();
      apiClient = ApiClient(storage: mockStorage);
    });

    test('1. Login stores access tokens and sets AuthAuthenticated state', () async {
      final authNotifier = AuthNotifier(mockRepo, sessionManager, apiClient);
      await authNotifier.login('faculty@acadex.com', 'Pass123!');

      expect(authNotifier.state, isA<AuthAuthenticated>());
      final authState = authNotifier.state as AuthAuthenticated;
      expect(authState.user.role, AppRole.faculty);
      expect(authState.user.email, 'faculty@acadex.com');

      // Verify token in storage
      final storedToken = await sessionManager.getAccessToken();
      expect(storedToken, isNotNull);
    });

    test('2. Logout executes backend revocation and clears local secure storage', () async {
      final authNotifier = AuthNotifier(mockRepo, sessionManager, apiClient);
      await authNotifier.login('faculty@acadex.com', 'Pass123!');
      expect(authNotifier.state, isA<AuthAuthenticated>());

      // Execute Logout
      await authNotifier.logout();

      // Backend revocation called
      expect(mockRepo.logoutCalled, isTrue);

      // Local storage wiped
      final storedToken = await sessionManager.getAccessToken();
      expect(storedToken, isNull);
      final storedUser = await sessionManager.getUser();
      expect(storedUser, isNull);

      // State transitions to AuthUnauthenticated
      expect(authNotifier.state, isA<AuthUnauthenticated>());
    });

    test('3. Logout-All executes backend revocation across all sessions and resets local state', () async {
      final authNotifier = AuthNotifier(mockRepo, sessionManager, apiClient);
      await authNotifier.login('faculty@acadex.com', 'Pass123!');

      // Execute LogoutAll
      await authNotifier.logoutAll();

      expect(mockRepo.logoutAllCalled, isTrue);
      expect(await sessionManager.getAccessToken(), isNull);
      expect(authNotifier.state, isA<AuthUnauthenticated>());
    });

    test('4. Sequential User Switching: User B does not inherit User A state or role', () async {
      final authNotifier = AuthNotifier(mockRepo, sessionManager, apiClient);

      // User A (Faculty)
      await authNotifier.login('faculty@acadex.com', 'Pass123!');
      expect((authNotifier.state as AuthAuthenticated).user.role, AppRole.faculty);

      // Logout User A
      await authNotifier.logout();
      expect(authNotifier.state, isA<AuthUnauthenticated>());
      expect(await sessionManager.getUser(), isNull);

      // User B (Student)
      final studentUser = UserModel(
        id: 'usr_stu_2',
        name: 'Student User',
        email: 'student@acadex.com',
        role: AppRole.student,
        instituteId: 'STU-002',
        accountStatus: AccountStatus.active,
        createdAt: DateTime.now(),
      );
      await sessionManager.saveSession(token: 'student-jwt-token', user: studentUser);

      final restoredUser = await sessionManager.getUser();
      expect(restoredUser?.role, AppRole.student);
      expect(restoredUser?.email, 'student@acadex.com');
      expect(restoredUser?.instituteId, 'STU-002');
    });
  });
}
