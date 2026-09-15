import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../data/repositories/api_user_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final apiUserRepositoryProvider = Provider<ApiUserRepository>((ref) {
  return ApiUserRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return ref.watch(apiUserRepositoryProvider);
});

// Filters
final userRoleFilterProvider = StateProvider<AppRole?>((ref) => null);
final userCollegeFilterProvider = StateProvider<String?>((ref) => null);
final userDeptFilterProvider = StateProvider<String?>((ref) => null);
final userStatusFilterProvider = StateProvider<UserStatus?>((ref) => null);
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// List Provider
final usersListProvider = FutureProvider.autoDispose<List<UserProfileModel>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  final authState = ref.watch(authProvider);
  
  if (authState is! AuthAuthenticated) {
    return [];
  }
  
  final currentUser = authState.user;
  
  String? scopeCollegeId;
  String? scopeDepartmentId;

  if (currentUser.role == AppRole.superAdmin) {
    scopeCollegeId = ref.watch(userCollegeFilterProvider);
  } else if (currentUser.role == AppRole.collegeAdmin) {
    scopeCollegeId = currentUser.collegeId;
  } else if (currentUser.role == AppRole.hod) {
    scopeCollegeId = currentUser.collegeId;
    scopeDepartmentId = currentUser.departmentId;
  } else if (currentUser.role == AppRole.student || currentUser.role == AppRole.faculty) {
    // Faculty/Student can only view their own department's roster or authorized directory
    scopeCollegeId = currentUser.collegeId;
    scopeDepartmentId = currentUser.departmentId;
  }

  return repo.getUsers(
    scopeCollegeId: scopeCollegeId,
    scopeDepartmentId: scopeDepartmentId,
    role: ref.watch(userRoleFilterProvider),
    departmentId: ref.watch(userDeptFilterProvider) ?? scopeDepartmentId,
    status: ref.watch(userStatusFilterProvider),
    searchQuery: ref.watch(userSearchQueryProvider),
  );
});

// Detail Provider
final userDetailProvider = FutureProvider.autoDispose.family<UserProfileModel?, String>((ref, id) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserById(id);
});

// Mutator Notifier
class UserManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  UserManagementNotifier(this._ref) : super(const AsyncData(null));

  Future<CreateUserResult> createUser(UserProfileModel user) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(userRepositoryProvider);
      CreateUserResult result;
      if (repo is ApiUserRepository) {
        result = await repo.createUserWithInvitation(user);
      } else {
        final created = await repo.createUser(user);
        result = CreateUserResult(
          user: created,
          activationCode: 'ACT-TEST-000000',
          invitationId: 'inv_test',
          collegeCode: 'COLL',
          expiresAt: DateTime.now().add(const Duration(hours: 48)),
        );
      }
      _ref.invalidate(usersListProvider);
      _ref.invalidate(superAdminStatsProvider);
      _ref.invalidate(collegeAdminStatsProvider);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateUser(UserProfileModel user) async {
    state = const AsyncLoading();
    try {
      await _ref.read(userRepositoryProvider).updateUser(user);
      _ref.invalidate(usersListProvider);
      _ref.invalidate(userDetailProvider(user.id));
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(superAdminStatsProvider);
      _ref.invalidate(collegeAdminStatsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deactivateUser(String id) async {
    state = const AsyncLoading();
    try {
      await _ref.read(userRepositoryProvider).deleteUser(id);
      _ref.invalidate(usersListProvider);
      _ref.invalidate(userDetailProvider(id));
      _ref.invalidate(superAdminStatsProvider);
      _ref.invalidate(collegeAdminStatsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> reactivateUser(String id) async {
    state = const AsyncLoading();
    try {
      await _ref.read(userRepositoryProvider).reactivateUser(id);
      _ref.invalidate(usersListProvider);
      _ref.invalidate(userDetailProvider(id));
      _ref.invalidate(superAdminStatsProvider);
      _ref.invalidate(collegeAdminStatsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteUserPermanently(String id) async {
    state = const AsyncLoading();
    try {
      await _ref.read(userRepositoryProvider).deleteUserPermanently(id);
      _ref.invalidate(usersListProvider);
      _ref.invalidate(userDetailProvider(id));
      _ref.invalidate(superAdminStatsProvider);
      _ref.invalidate(collegeAdminStatsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<String> generateActivationCode(UserProfileModel user) async {
    final apiRepo = _ref.read(apiUserRepositoryProvider);
    return await apiRepo.reissueActivationCodeForUser(user.id);
  }

  Future<String> reissueActivationCode(String userId) async {
    final apiRepo = _ref.read(apiUserRepositoryProvider);
    return await apiRepo.reissueActivationCodeForUser(userId);
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, AsyncValue<void>>((ref) {
  return UserManagementNotifier(ref);
});
