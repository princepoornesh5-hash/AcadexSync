import '../../domain/models/user_profile_model.dart';

abstract class UserProfileRepository {
  /// Fetches an Acadex user profile document from `users/{firebaseUid}`
  Future<UserProfileModel?> getUserProfileByUid(String firebaseUid);

  /// Creates or updates an Acadex user profile document in `users/{firebaseUid}`
  Future<void> saveUserProfile(UserProfileModel profile);
}
