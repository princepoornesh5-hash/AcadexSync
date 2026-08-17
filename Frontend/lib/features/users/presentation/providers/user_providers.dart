import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../data/repositories/firebase_user_repository.dart';
import '../../data/repositories/mock_user_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockUserRepository();
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseUserRepository(firestoreService);
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
  
  if (authState is! AuthAuthenticated || authState.user is! UserProfileModel) {
    return [];
  }
  
  final currentUser = authState.user as UserProfileModel;
  
  String? scopeCollegeId;
  String? scopeDepartmentId;

  if (currentUser.role == AppRole.collegeAdmin) {
    scopeCollegeId = currentUser.collegeId;
  } else if (currentUser.role == AppRole.hod) {
    scopeCollegeId = currentUser.collegeId;
    scopeDepartmentId = currentUser.departmentId;
  } else if (currentUser.role == AppRole.student || currentUser.role == AppRole.faculty) {
    // Ordinary Faculty and Students have no business seeing the administrative user list.
    throw Exception('Unauthorized');
  }

  final role = ref.watch(userRoleFilterProvider);
  final dept = ref.watch(userDeptFilterProvider);
  final status = ref.watch(userStatusFilterProvider);
  final query = ref.watch(userSearchQueryProvider);

  return repo.getUsers(
    scopeCollegeId: scopeCollegeId,
    scopeDepartmentId: scopeDepartmentId,
    role: role,
    departmentId: dept,
    status: status,
    searchQuery: query,
  );
});

// Individual User Detail
final userDetailProvider = FutureProvider.family<UserProfileModel?, String>((ref, id) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserById(id);
});

// Mutator Notifier
class UserManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  UserManagementNotifier(this._ref) : super(const AsyncData(null));

  Future<void> createUser(UserProfileModel user) async {
    state = const AsyncLoading();
    try {
      await _ref.read(userRepositoryProvider).createUser(user);
      _ref.invalidate(usersListProvider);
      state = const AsyncData(null);
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
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, AsyncValue<void>>((ref) {
  return UserManagementNotifier(ref);
});
