import '../../../../core/firebase/dev_identity_registry.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/repositories/user_profile_repository.dart';

class MockUserProfileRepository implements UserProfileRepository {
  @override
  Future<UserProfileModel?> getUserProfileByUid(String firebaseUid) async {
    final profileData = DevIdentityRegistry.getProfile(firebaseUid);
    if (profileData == null) return null;
    return UserProfileModel.fromJson(profileData);
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    final uid = profile.firebaseUid ?? profile.id;
    DevIdentityRegistry.registerUidProfile(uid, profile.toJson());
  }
}
