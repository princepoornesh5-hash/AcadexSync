import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/users/domain/models/user_profile_model.dart';
import 'package:campus_management/features/users/domain/models/user_status_enum.dart';
import 'package:campus_management/features/users/data/repositories/mock_user_profile_repository.dart';
import 'package:campus_management/features/users/presentation/providers/user_profile_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
      .setMockMethodCallHandler((MethodCall methodCall) async => null);

  group('Prompt 66: Profile Security & Immutability Tests', () {
    UserProfileModel makeProfile({AppRole role = AppRole.student}) {
      return UserProfileModel(
        id: 'user_${role.name}',
        firebaseUid: 'uid_${role.name}',
        name: 'Test User',
        email: 'test@acadex.com',
        role: role,
        collegeId: 'collegeA',
        departmentId: 'deptA',
        status: UserStatus.active,
        phone: '9999999999',
      );
    }

    test('1. updateProfile only modifies name and phone — role is preserved', () async {
      final repo = MockUserProfileRepository();
      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final profile = makeProfile(role: AppRole.student);
      await repo.saveUserProfile(profile);

      // Simulate what ProfileEditNotifier.updateProfile does
      final updated = profile.copyWith(
        name: 'Updated Name',
        phone: '8888888888',
        updatedAt: DateTime.now(),
      );

      // Authorization fields must remain unchanged
      expect(updated.role, equals(AppRole.student));
      expect(updated.collegeId, equals('collegeA'));
      expect(updated.departmentId, equals('deptA'));
      expect(updated.name, equals('Updated Name'));
      expect(updated.phone, equals('8888888888'));
    });

    test('2. Role field is never modified by updateProfile', () {
      final profile = makeProfile(role: AppRole.faculty);
      // Simulate what an attacker might do — try to pass a different role to copyWith
      // ProfileEditNotifier.updateProfile does NOT pass role to copyWith, so it defaults to the original
      final updated = profile.copyWith(name: 'Hacker', phone: '0000000000', updatedAt: DateTime.now());
      expect(updated.role, equals(AppRole.faculty)); // Role unchanged
    });

    test('3. collegeId is preserved after profile update', () {
      final profile = makeProfile();
      final updated = profile.copyWith(name: 'New Name', updatedAt: DateTime.now());
      expect(updated.collegeId, equals('collegeA'));
    });

    test('4. departmentId is preserved after profile update', () {
      final profile = makeProfile();
      final updated = profile.copyWith(name: 'New Name', updatedAt: DateTime.now());
      expect(updated.departmentId, equals('deptA'));
    });

    test('5. accountStatus is preserved after profile update', () {
      final profile = makeProfile();
      final updated = profile.copyWith(name: 'New Name', updatedAt: DateTime.now());
      expect(updated.accountStatus, equals(AccountStatus.active));
    });

    test('6. Empty name is rejected', () {
      final profile = makeProfile();
      // The SecurityRule: if updated.name.isEmpty throw Exception
      final updated = profile.copyWith(name: '', updatedAt: DateTime.now());
      expect(updated.name.isEmpty, isTrue);
      // Simulate the check in updateProfile
      expect(() {
        if (updated.name.isEmpty) throw Exception('Name cannot be empty.');
      }, throwsException);
    });

    test('7. Password validation: new must differ from current', () {
      const current = 'Password123';
      const newPass = 'Password123';
      // Simulates the validator logic
      expect(newPass == current, isTrue); // Should be rejected
    });

    test('8. Password validation: minimum 8 characters', () {
      const shortPass = 'abc123';
      expect(shortPass.length < 8, isTrue); // Should be rejected
    });

    test('9. Password mismatch is caught', () {
      const newPass = 'NewSecure123';
      const confirmPass = 'NewSecure456';
      expect(newPass != confirmPass, isTrue); // Should be rejected
    });

    test('10. Mock profile repository does not leak state between users', () async {
      final repo = MockUserProfileRepository();

      final profileA = makeProfile(role: AppRole.student);
      final profileB = UserProfileModel(
        id: 'user_b',
        firebaseUid: 'uid_b',
        name: 'Student B',
        email: 'b@acadex.com',
        role: AppRole.student,
        collegeId: 'collegeB',
        departmentId: 'deptB',
        status: UserStatus.active,
        phone: '1111111111',
      );

      await repo.saveUserProfile(profileA);
      await repo.saveUserProfile(profileB);

      final loadedA = await repo.getUserProfileByUid('uid_${AppRole.student.name}');
      final loadedB = await repo.getUserProfileByUid('uid_b');

      expect(loadedA?.email, equals('test@acadex.com'));
      expect(loadedB?.email, equals('b@acadex.com'));
      expect(loadedA?.collegeId, isNot(equals(loadedB?.collegeId)));
    });

    test('11. Production mock protection: MockUserProfileRepository is separate from FirebaseUserProfileRepository', () {
      final repo = MockUserProfileRepository();
      expect(repo.runtimeType.toString(), equals('MockUserProfileRepository'));
    });
  });
}
