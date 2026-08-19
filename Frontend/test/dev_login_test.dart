import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/repositories/auth_repository.dart';
import 'package:campus_management/features/auth/repositories/firebase_auth_repository.dart';
import 'package:campus_management/features/users/domain/repositories/user_profile_repository.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';

class MockUserProfileRepositoryImpl implements UserProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirebaseAuthServiceImpl implements FirebaseAuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Development Test Login & Role Verification', () {
    test('MockAuthRepository resolves all 5 development roles', () async {
      final repo = MockAuthRepository();

      final roles = [
        AppRole.superAdmin,
        AppRole.collegeAdmin,
        AppRole.hod,
        AppRole.faculty,
        AppRole.student,
      ];

      for (final role in roles) {
        final user = await repo.loginAsDevelopmentRole(role);
        expect(user.role, role);
        expect(user.email.isNotEmpty, isTrue);
        expect(user.name.isNotEmpty, isTrue);
      }
    });

    test('FirebaseAuthRepository delegates loginAsDevelopmentRole in debug mode', () async {
      final repo = FirebaseAuthRepository(
        MockFirebaseAuthServiceImpl(),
        MockUserProfileRepositoryImpl(),
      );

      final user = await repo.loginAsDevelopmentRole(AppRole.student);
      expect(user.role, AppRole.student);
      expect(user.email, 'student@acadex.com');
    });
  });
}
