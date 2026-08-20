import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/features/auth/data/repositories/api_auth_repository.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/users/data/repositories/api_user_repository.dart';
import 'package:campus_management/features/academic_structure/data/repositories/api_academic_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/api_timetable_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/api_attendance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Live API Repositories Unit Tests', () {
    late ApiClient mockClient;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/auth/login')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': {
                  'accessToken': 'test_access_token',
                  'refreshToken': 'test_refresh_token',
                  'user': {
                    '_id': 'user123',
                    'name': 'Test Super Admin',
                    'email': 'admin@acadex.edu',
                    'role': 'SUPER_ADMIN',
                    'accountStatus': 'ACTIVE',
                  }
                }
              },
            ));
          } else if (options.path.contains('/auth/me')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': {
                  'user': {
                    '_id': 'user123',
                    'name': 'Test Super Admin',
                    'email': 'admin@acadex.edu',
                    'role': 'SUPER_ADMIN',
                    'accountStatus': 'ACTIVE',
                  }
                }
              },
            ));
          } else if (options.path.contains('/users')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': [
                  {
                    '_id': 'user123',
                    'name': 'Test Faculty',
                    'email': 'faculty@acadex.edu',
                    'role': 'FACULTY',
                    'status': 'ACTIVE',
                    'phone': '1234567890',
                  }
                ]
              },
            ));
          } else if (options.path.contains('/colleges')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'data': [
                  {
                    '_id': 'col1',
                    'name': 'ACADEX Engineering Campus',
                    'code': 'AEC',
                    'isActive': true,
                  }
                ]
              },
            ));
          }
          return handler.next(options);
        },
      ));

      mockClient = ApiClient(customDio: dio);
    });

    test('ApiAuthRepository login returns valid UserModel', () async {
      final repo = ApiAuthRepository(mockClient);
      final user = await repo.login('admin@acadex.edu', 'password123');

      expect(user.id, 'user123');
      expect(user.email, 'admin@acadex.edu');
      expect(user.role, AppRole.superAdmin);
    });

    test('ApiAuthRepository getCurrentUser returns valid UserModel', () async {
      final repo = ApiAuthRepository(mockClient);
      final user = await repo.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.id, 'user123');
      expect(user.name, 'Test Super Admin');
    });

    test('ApiUserRepository getUsers parses list correctly', () async {
      final repo = ApiUserRepository(mockClient);
      final users = await repo.getUsers();

      expect(users, isNotEmpty);
      expect(users.first.id, 'user123');
      expect(users.first.role, AppRole.faculty);
    });

    test('ApiAcademicRepository getColleges returns colleges from API', () async {
      final repo = ApiAcademicRepository(mockClient);
      final colleges = await repo.getColleges();

      expect(colleges, isNotEmpty);
      expect(colleges.first.name, 'ACADEX Engineering Campus');
      expect(colleges.first.code, 'AEC');
    });

    test('ApiTimetableRepository instantiate correctly', () {
      final repo = ApiTimetableRepository(mockClient);
      expect(repo, isNotNull);
    });

    test('ApiAttendanceRepository instantiate correctly', () {
      final repo = ApiAttendanceRepository(mockClient);
      expect(repo, isNotNull);
    });
  });
}
