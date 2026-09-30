import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/profile_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Canonical read model provider for the authenticated user's composed profile.
final profileProvider = FutureProvider<ComposedProfileModel>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyProfile();
});

/// Parameterized provider to inspect a scoped profile by user ID.
final userProfileByIdProvider =
    FutureProvider.family<ComposedProfileModel, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfileById(userId);
});

/// Parameterized provider for directory queries.
final profileDirectoryProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getDirectory(
    search: params['search'] as String?,
    role: params['role'] as String?,
    departmentId: params['departmentId'] as String?,
    page: (params['page'] as num?)?.toInt() ?? 1,
    limit: (params['limit'] as num?)?.toInt() ?? 20,
  );
});

class ProfileActionNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileActionNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<ComposedProfileModel> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateMyProfile(data);

      // Invalidate profile read cache
      _ref.invalidate(profileProvider);

      // Synchronize auth user display name and phone if present
      final authState = _ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        final updatedAuthUser = authState.user.copyWith(
          name: updated.user.name,
          phone: updated.user.phone,
        );
        _ref.read(authProvider.notifier).updateCurrentUser(updatedAuthUser);
      }

      state = const AsyncValue.data(null);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final profileActionNotifierProvider =
    StateNotifierProvider<ProfileActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileActionNotifier(repo, ref);
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

      // Invalidate profile read cache
      _ref.invalidate(profileProvider);

      // Update in-memory auth state user if current user updated their own avatar
      final authState = _ref.read(authProvider);
      if (authState is AuthAuthenticated &&
          (targetUserId == null || targetUserId == authState.user.id)) {
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
