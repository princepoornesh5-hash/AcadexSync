import 'dart:typed_data';
import 'package:dio/dio.dart';

class ImageKitUploadAuth {
  final String token;
  final int expire;
  final String signature;
  final String publicKey;
  final String urlEndpoint;
  final String folder;
  final String fileName;
  final String? fileId;

  const ImageKitUploadAuth({
    required this.token,
    required this.expire,
    required this.signature,
    required this.publicKey,
    required this.urlEndpoint,
    required this.folder,
    required this.fileName,
    this.fileId,
  });

  factory ImageKitUploadAuth.fromJson(Map<String, dynamic> json) {
    return ImageKitUploadAuth(
      token: json['token'] as String,
      expire: json['expire'] is int ? json['expire'] as int : int.parse(json['expire'].toString()),
      signature: json['signature'] as String,
      publicKey: json['publicKey'] as String,
      urlEndpoint: json['urlEndpoint'] as String,
      folder: json['folder'] as String,
      fileName: json['fileName'] as String,
      fileId: json['fileId'] as String?,
    );
  }
}

class ImageKitUploadResult {
  final String fileId;
  final String name;
  final String url;
  final String? thumbnailUrl;
  final int size;
  final String filePath;

  const ImageKitUploadResult({
    required this.fileId,
    required this.name,
    required this.url,
    this.thumbnailUrl,
    required this.size,
    required this.filePath,
  });

  factory ImageKitUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageKitUploadResult(
      fileId: json['fileId'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      size: json['size'] is int ? json['size'] as int : int.parse(json['size'].toString()),
      filePath: json['filePath'] as String? ?? '',
    );
  }
}

class ImageKitUploader {
  static const String uploadEndpoint = 'https://upload.imagekit.io/api/v1/files/upload';
  final Dio _dio;

  ImageKitUploader([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            ));

  /// Uploads a binary file directly to ImageKit using backend-provided authorization parameters.
  Future<ImageKitUploadResult> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required ImageKitUploadAuth auth,
    void Function(int count, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'fileName': fileName,
      'publicKey': auth.publicKey,
      'signature': auth.signature,
      'expire': auth.expire.toString(),
      'token': auth.token,
      'folder': auth.folder,
      'useUniqueFileName': 'false',
    });

    final response = await _dio.post(
      uploadEndpoint,
      data: formData,
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200 && response.data != null) {
      return ImageKitUploadResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } else {
      throw Exception('ImageKit upload failed with status code ${response.statusCode}');
    }
  }
}
