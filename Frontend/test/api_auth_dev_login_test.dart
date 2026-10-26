import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/features/auth/data/repositories/api_auth_repository.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/services/session_manager.dart';
import 'package:campus_management/features/auth/data/repositories/workspace_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiAuthRepository Development Login Tests', () {
    late ApiClient apiClient;
    late Dio customDio;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      customDio = Dio();
      apiClient = ApiClient(
        customDio: customDio,
        storage: const FlutterSecureStorage(),
      );
    });

    test('loginAsDevelopmentRole sends POST /auth/dev-login and saves tokens and active workspace', () async {
      customDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/dev-login' && options.method == 'POST') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'accessToken': 'jwt.svgp.token.header.payload.signature',
                  'refreshToken': 'jwt.svgp.refresh.header.payload.signature',
                  'workspaceId': 'svgp_workspace_123',
                  'user': {
                    'id': 'user_college_admin_123',
                    'name': 'Dr. K. Srinivasulu',
                    'email': 'college@acadex.com',
                    'role': 'COLLEGE_ADMIN',
                    'accountStatus': 'active',
                    'collegeId': 'svgp_workspace_123',
                  },
                },
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final repo = ApiAuthRepository(apiClient);
      final user = await repo.loginAsDevelopmentRole(AppRole.collegeAdmin);

      expect(user.email, 'college@acadex.com');
      expect(user.role, AppRole.collegeAdmin);
      expect(user.name, 'Dr. K. Srinivasulu');

      // Verify tokens and workspace saved into secure storage
      expect(await apiClient.getToken(), 'jwt.svgp.token.header.payload.signature');
      expect(await apiClient.getRefreshToken(), 'jwt.svgp.refresh.header.payload.signature');
      expect(await apiClient.getActiveWorkspace(), 'svgp_workspace_123');
    });

    test('AuthNotifier.loginAsDevelopmentRole performs state transition to AuthAuthenticated', () async {
      customDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/dev-login') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'accessToken': 'valid_jwt_access_token',
                  'refreshToken': 'valid_jwt_refresh_token',
                  'workspaceId': 'svgp_workspace_123',
                  'user': {
                    'id': 'user_cme_hod',
                    'name': 'Dr. V. Radha Krishna',
                    'email': 'hod@acadex.com',
                    'role': 'HOD',
                    'accountStatus': 'active',
                  },
                },
              },
            ));
          }
          return handler.next(options);
        },
      ));

      const storage = FlutterSecureStorage();
      final repo = ApiAuthRepository(apiClient);
      final sessionManager = SessionManager(storage);

      final notifier = AuthNotifier(repo, sessionManager, apiClient);
      await notifier.loginAsDevelopmentRole(AppRole.hod);

      final state = notifier.state;
      expect(state, isA<AuthAuthenticated>());
      final authState = state as AuthAuthenticated;
      expect(authState.user.email, 'hod@acadex.com');
      expect(authState.user.role, AppRole.hod);
      expect(authState.token, 'valid_jwt_access_token');
    });

    test('WorkspaceRepository.getMyMemberships correctly parses array response from backend', () async {
      customDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/workspaces/my-memberships') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'User workspaces retrieved successfully',
                'data': [
                  {
                    'membershipId': 'mem_svgp_hod',
                    'collegeId': '6ac3c8910d1cfe82de0caf94',
                    'collegeName': 'Sri Venkateswara Government Polytechnic, Tirupati',
                    'collegeCode': 'SVGP',
                    'status': 'active',
                    'isDefault': true,
                    'roles': ['HOD'],
                    'departments': [
                      {
                        'id': '6adcf45ff7b6627a7b7a6a6c',
                        'name': 'Computer Engineering',
                        'code': 'CME',
                      }
                    ],
                  }
                ],
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final workspaceRepo = WorkspaceRepository(apiClient);
      final memberships = await workspaceRepo.getMyMemberships();

      expect(memberships.length, 1);
      final mem = memberships.first;
      expect(mem.id, 'mem_svgp_hod');
      expect(mem.collegeCode, 'SVGP');
      expect(mem.roles.contains(AppRole.hod), isTrue);
      expect(mem.departmentId, '6adcf45ff7b6627a7b7a6a6c');
      expect(mem.departmentName, 'Computer Engineering');
      expect(mem.departmentCode, 'CME');
      expect(mem.isActive, isTrue);
    });
  });
}

