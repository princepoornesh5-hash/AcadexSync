import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../data/repositories/firebase_user_profile_repository.dart';
import '../../data/repositories/mock_user_profile_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/models/user_profile_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
  final FirebaseAuthService _authService;
  final Ref _ref;

  ProfileEditNotifier(this._repository, this._authService, this._ref) : super(const ProfileEditState());

  void reset() => state = const ProfileEditState();

  Future<void> updateProfile(UserProfileModel currentProfile, String name, String phone) async {
    state = state.copyWith(status: ProfileEditStatus.saving, clearError: true);
    try {
      final updated = currentProfile.copyWith(name: name.trim(), phone: phone.trim(), updatedAt: DateTime.now());
      await _repository.saveUserProfile(updated);
      
      // We also update the AuthProvider's current user to reflect UI immediately
      // The authProvider will be accessed via ref
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
        // Mock success
        state = state.copyWith(status: ProfileEditStatus.saved);
        return;
      }

      // 1. Re-authenticate logic if necessary (In full version). 
      // For now, we'll try to just update password. If it fails with requires-recent-login, 
      // the mapped FirebaseErrorMapper will throw it.
      await _authService.updatePassword(newPassword);
      state = state.copyWith(status: ProfileEditStatus.saved);
    } catch (e) {
      String errMsg = e.toString().replaceAll("Exception: ", "");
      if (errMsg.contains('requires-recent-login')) {
        errMsg = "Security restriction: Please log out and log back in before changing your password.";
      }
      state = state.copyWith(status: ProfileEditStatus.error, error: errMsg);
    }
  }
}

final profileEditProvider = StateNotifierProvider<ProfileEditNotifier, ProfileEditState>((ref) {
  final repo = ref.watch(userProfileRepositoryProvider);
  final authService = ref.watch(firebaseAuthServiceProvider);
  return ProfileEditNotifier(repo, authService, ref);
});
