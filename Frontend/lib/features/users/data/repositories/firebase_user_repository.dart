import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import 'user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  final FirestoreService _firestoreService;

  FirebaseUserRepository(this._firestoreService);

  @override
  Future<List<UserProfileModel>> getUsers({
    String? scopeCollegeId,
    String? scopeDepartmentId,
    AppRole? role,
    String? departmentId,
    UserStatus? status,
    String? searchQuery,
  }) async {
    final filters = <String, dynamic>{};
    
    // Server-side equality scoping
    if (scopeCollegeId != null) {
      filters['collegeId'] = scopeCollegeId;
    }
    if (scopeDepartmentId != null) {
      filters['departmentId'] = scopeDepartmentId;
    }
    if (role != null) {
      filters['role'] = role.value;
    }
    if (departmentId != null) {
      filters['departmentId'] = departmentId;
    }
    if (status != null) {
      filters['status'] = status.value;
    }

    final docs = await _firestoreService.queryCollection('users', filters);
    final profiles = docs.map((doc) => UserProfileModel.fromJson(doc)).toList();

    return profiles.where((user) {
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final nameMatch = user.name.toLowerCase().contains(query);
        final emailMatch = user.email.toLowerCase().contains(query);
        final empIdMatch = user.employeeId?.toLowerCase().contains(query) ?? false;
        final rollNoMatch = user.rollNumber?.toLowerCase().contains(query) ?? false;
        
        if (!nameMatch && !emailMatch && !empIdMatch && !rollNoMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<UserProfileModel?> getUserById(String id) async {
    final doc = await _firestoreService.getDocument('users', id);
    if (doc == null) return null;
    return UserProfileModel.fromJson(doc);
  }

  @override
  Future<UserProfileModel> createUser(UserProfileModel user) async {
    final uid = user.firebaseUid ?? user.id;
    await _firestoreService.setDocument('users', uid, user.toJson());
    return user;
  }

  @override
  Future<UserProfileModel> updateUser(UserProfileModel user) async {
    final uid = user.firebaseUid ?? user.id;
    await _firestoreService.setDocument('users', uid, user.toJson());
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    final user = await getUserById(id);
    if (user != null) {
      final updated = user.copyWith(status: UserStatus.inactive);
      await updateUser(updated);
    }
  }

  @override
  Future<void> reactivateUser(String id) async {
    final user = await getUserById(id);
    if (user != null) {
      final updated = user.copyWith(status: UserStatus.active);
      await updateUser(updated);
    }
  }
}
