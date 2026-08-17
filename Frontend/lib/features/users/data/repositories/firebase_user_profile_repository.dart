import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/repositories/user_profile_repository.dart';

class FirebaseUserProfileRepository implements UserProfileRepository {
  final FirestoreService _firestoreService;

  FirebaseUserProfileRepository(this._firestoreService);

  @override
  Future<UserProfileModel?> getUserProfileByUid(String firebaseUid) async {
    final doc = await _firestoreService.getDocument('users', firebaseUid);
    if (doc == null) return null;
    return UserProfileModel.fromJson(doc);
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    final uid = profile.firebaseUid ?? profile.id;
    await _firestoreService.setDocument('users', uid, profile.toJson());
  }
}
