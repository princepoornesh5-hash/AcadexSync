import 'dart:typed_data';
import '../../domain/models/file_category.dart';
import '../../domain/models/stored_file.dart';
import '../../domain/repositories/file_storage_repository.dart';

class NotConfiguredFileStorageRepository implements FileStorageRepository {
  static const String limitationMessage = 'Persistent file storage provider not configured.';

  @override
  Future<StoredFile> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required FileCategory category,
    required String ownerUid,
    String? collegeId,
    String? departmentId,
    String? studentId,
    String? facultyUid,
    Map<String, String>? customMetadata,
  }) async {
    throw Exception(limitationMessage);
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async {
    throw Exception(limitationMessage);
  }

  @override
  Future<StoredFile> getFileMetadata(String storagePath) async {
    throw Exception(limitationMessage);
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    throw Exception(limitationMessage);
  }

  @override
  Future<List<StoredFile>> listFiles(String directoryPath) async {
    throw Exception(limitationMessage);
  }

  @override
  Future<void> updateMetadata(String storagePath, Map<String, String> newMetadata) async {
    throw Exception(limitationMessage);
  }
}
