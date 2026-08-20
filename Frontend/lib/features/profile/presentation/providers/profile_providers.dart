import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileImageUploadState {
  final bool isUploading;
  final double progress;
  final String? error;
  final String? uploadedUrl;

  const ProfileImageUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.error,
    this.uploadedUrl,
  });

  ProfileImageUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
    String? uploadedUrl,
  }) {
    return ProfileImageUploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
    );
  }
}

class ProfileImageUploadNotifier extends StateNotifier<ProfileImageUploadState> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileImageUploadNotifier(this._repository, this._ref)
      : super(const ProfileImageUploadState());

  Future<String?> uploadProfileImage({
    required String fileName,
    required Uint8List bytes,
    String? targetUserId,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0.0, error: null);

    try {
      final newUrl = await _repository.uploadAndSetProfileImage(
        fileName: fileName,
        imageBytes: bytes,
        targetUserId: targetUserId,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      // Update in-memory auth state user if current user updated their own avatar
      final authState = _ref.read(authProvider);
      if (authState is AuthAuthenticated && (targetUserId == null || targetUserId == authState.user.id)) {
        final updatedUser = authState.user.copyWith(profilePictureUrl: newUrl);
        _ref.read(authProvider.notifier).updateCurrentUser(updatedUser);
      }

      state = state.copyWith(isUploading: false, uploadedUrl: newUrl);
      return newUrl;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      rethrow;
    }
  }
}

final profileImageUploadProvider =
    StateNotifierProvider<ProfileImageUploadNotifier, ProfileImageUploadState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileImageUploadNotifier(repo, ref);
});
