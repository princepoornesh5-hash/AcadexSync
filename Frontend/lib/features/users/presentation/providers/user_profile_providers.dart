import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../data/repositories/firebase_user_profile_repository.dart';
import '../../data/repositories/mock_user_profile_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/models/user_profile_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../data/repositories/api_user_repository.dart';

final apiUserRepositoryProvider = Provider<ApiUserRepository>((ref) {
  return ApiUserRepository();
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockUserProfileRepository();
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseUserProfileRepository(firestoreService);
});

enum ProfileEditStatus { initial, saving, saved, error }

class ProfileEditState {
  final ProfileEditStatus status;
  final String? error;

  const ProfileEditState({
    this.status = ProfileEditStatus.initial,
    this.error,
  });

  ProfileEditState copyWith({ProfileEditStatus? status, String? error, bool clearError = false}) {
    return ProfileEditState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final UserProfileRepository _repository;
  final Ref _ref;

  ProfileEditNotifier(this._repository, this._ref) : super(const ProfileEditState());

  void reset() => state = const ProfileEditState();

  Future<void> updateProfile(UserProfileModel currentProfile, String name, String phone) async {
    state = state.copyWith(status: ProfileEditStatus.saving, clearError: true);
    try {
      final updated = currentProfile.copyWith(name: name.trim(), phone: phone.trim(), updatedAt: DateTime.now());
      await _repository.saveUserProfile(updated);
      
      // Update the AuthProvider's current user to reflect UI immediately
      _ref.read(authProvider.notifier).updateCurrentUser(updated);
      
      state = state.copyWith(status: ProfileEditStatus.saved);
    } catch (e) {
      state = state.copyWith(
        status: ProfileEditStatus.error,
        error: e.toString().replaceAll("Exception: ", ""),
      );
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(status: ProfileEditStatus.saving, clearError: true);
    try {
      if (FirebaseInitializer.shouldUseMock) {
        await Future.delayed(const Duration(seconds: 1));
        state = state.copyWith(status: ProfileEditStatus.saved);
        return;
      }

      // Use the backend API for password change
      final authRepo = _ref.read(apiAuthRepositoryProvider);
      await authRepo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(status: ProfileEditStatus.saved);
    } catch (e) {
      String errMsg = e.toString().replaceAll("Exception: ", "");
      state = state.copyWith(status: ProfileEditStatus.error, error: errMsg);
    }
  }
}

final profileEditProvider = StateNotifierProvider<ProfileEditNotifier, ProfileEditState>((ref) {
  final repo = ref.watch(userProfileRepositoryProvider);
  return ProfileEditNotifier(repo, ref);
});
