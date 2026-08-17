import 'dart:typed_data';
import '../models/file_category.dart';
import '../models/stored_file.dart';

abstract class FileStorageRepository {
  /// Uploads a binary file to Firebase Storage and returns the [StoredFile] metadata
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
  });

  /// Retrieves the public download URL for a given storage path
  Future<String> getDownloadUrl(String storagePath);

  /// Retrieves the metadata for a given storage path
  Future<StoredFile> getFileMetadata(String storagePath);

  /// Deletes a file at a given storage path
  Future<void> deleteFile(String storagePath);

  /// Lists all files in a specific directory (prefix)
  Future<List<StoredFile>> listFiles(String directoryPath);

  /// Updates custom metadata for a specific file
  Future<void> updateMetadata(String storagePath, Map<String, String> newMetadata);
}
