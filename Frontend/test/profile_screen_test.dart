import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/users/domain/models/user_profile_model.dart';
import 'package:campus_management/features/users/domain/models/user_status_enum.dart';

void main() {
  group('User Profile & Serialization Verification', () {
    test('UserProfileModel serializes and deserializes correctly', () {
      final model = UserProfileModel(
        id: 'user123',
        firebaseUid: 'uid123',
        name: 'Test Name',
        email: 'test@acadex.com',
        role: AppRole.student,
        status: UserStatus.active,
        phone: '1234567890',
        rollNumber: '2023CS001',
      );

      final json = model.toJson();
      expect(json['id'], 'user123');
      expect(json['phone'], '1234567890');
      expect(json['role'], 'STUDENT');

      final fromJson = UserProfileModel.fromJson(json);
      expect(fromJson.name, 'Test Name');
      expect(fromJson.phone, '1234567890');
      expect(fromJson.rollNumber, '2023CS001');
    });

    test('Protected fields remain untouched on copyWith', () {
      final model = UserProfileModel(
        id: 'user123',
        firebaseUid: 'uid123',
        name: 'Test Name',
        email: 'test@acadex.com',
        role: AppRole.student,
        status: UserStatus.active,
        phone: '1234567890',
      );

      final updated = model.copyWith(name: 'Updated Name');
      expect(updated.name, 'Updated Name');
      expect(updated.role, AppRole.student); // Protected role unchanged
    });
  });
}
