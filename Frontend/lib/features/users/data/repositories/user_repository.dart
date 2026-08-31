import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';

abstract class UserRepository {
  Future<List<UserProfileModel>> getUsers({
    String? scopeCollegeId,
    String? scopeDepartmentId,
    AppRole? role,
    String? departmentId,
    UserStatus? status,
    String? searchQuery,
  });

  Future<UserProfileModel?> getUserById(String id);

  Future<UserProfileModel> createUser(UserProfileModel user);

  Future<dynamic> createUserWithInvitation(UserProfileModel user);

  Future<String> reissueActivationCodeForUser(String userId);

  Future<UserProfileModel> updateUser(UserProfileModel user);

  Future<void> deleteUser(String id); // Deactivate/Suspend

  Future<void> reactivateUser(String id);
}
