import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/imagekit_uploader.dart';

class ProfileRepository {
  static const int maxProfileImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  final ApiClient _apiClient;
  final ImageKitUploader _uploader;

  ProfileRepository({ApiClient? apiClient, ImageKitUploader? uploader})
      : _apiClient = apiClient ?? apiClientInstance,
        _uploader = uploader ?? ImageKitUploader();

  static ApiClient get apiClientInstance => apiClient;

  static bool isImageExtensionSupported(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return allowedImageExtensions.contains(ext);
  }

  static String resolveImageMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Phase 1: Request upload authorization parameters from backend
  Future<ImageKitUploadAuth> requestUploadAuth({
    required String fileName,
    required String mimeType,
    required int fileSize,
    String? targetUserId,
  }) async {
    final endpoint = targetUserId != null && targetUserId.isNotEmpty
        ? '/users/$targetUserId/profile-image/upload-url'
        : '/users/me/profile-image/upload-url';

    final response = await _apiClient.dio.post(
      endpoint,
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSize': fileSize,
      },
    );

    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'] as Map<String, dynamic>;
      final authMap = data['uploadAuth'] is Map
          ? Map<String, dynamic>.from(data['uploadAuth'] as Map)
          : data;
      return ImageKitUploadAuth.fromJson(authMap);
    }
    throw Exception('Failed to obtain profile image upload authorization');
  }

  /// Phase 2: Complete upload and trigger server-side ImageKit verification
  Future<Map<String, dynamic>> completeUpload({
    required String fileId,
    required String fileUrl,
    String? targetUserId,
  }) async {
    final endpoint = targetUserId != null && targetUserId.isNotEmpty
        ? '/users/$targetUserId/profile-image/complete'
        : '/users/me/profile-image/complete';

    final response = await _apiClient.dio.post(
      endpoint,
      data: {
        'fileId': fileId,
        'fileUrl': fileUrl,
      },
    );

    if (response.data != null && response.data['data'] != null) {
      return Map<String, dynamic>.from(response.data['data'] as Map);
    }
    throw Exception('Failed to complete and verify profile picture update');
  }

  /// Full orchestrated profile image upload pipeline
  Future<String> uploadAndSetProfileImage({
    required String fileName,
    required Uint8List imageBytes,
    String? targetUserId,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (!isImageExtensionSupported(fileName)) {
      throw Exception('Unsupported image format. Allowed: JPG, JPEG, PNG, WebP');
    }
    if (imageBytes.lengthInBytes > maxProfileImageSizeBytes) {
      throw Exception('Image size exceeds the maximum limit of 5MB');
    }

    final mimeType = resolveImageMimeType(fileName);
    final auth = await requestUploadAuth(
      fileName: fileName,
      mimeType: mimeType,
      fileSize: imageBytes.lengthInBytes,
      targetUserId: targetUserId,
    );

    final uploadResult = await _uploader.uploadFile(
      fileBytes: imageBytes,
      fileName: fileName,
      auth: auth,
      onProgress: onProgress,
    );

    final updatedUser = await completeUpload(
      fileId: uploadResult.fileId,
      fileUrl: uploadResult.url,
      targetUserId: targetUserId,
    );

    return (updatedUser['profilePictureUrl'] ?? uploadResult.url).toString();
  }
}
