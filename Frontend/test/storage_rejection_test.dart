import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/storage/data/repositories/not_configured_file_storage_repository.dart';
import 'package:campus_management/features/storage/domain/models/file_category.dart';
import 'dart:typed_data';

void main() {
  group('Production Storage Rejection Tests', () {
    test('NotConfiguredFileStorageRepository rejects file upload', () async {
      final repository = NotConfiguredFileStorageRepository();

      expect(
        () => repository.uploadFile(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.pdf',
          contentType: 'pdf',
          category: FileCategory.noteAttachment,
          ownerUid: 'faculty1',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Persistent file storage provider not configured.'),
          ),
        ),
      );
    });

    test('NotConfiguredFileStorageRepository rejects file deletion', () async {
      final repository = NotConfiguredFileStorageRepository();

      expect(
        () => repository.deleteFile('some/path/file.pdf'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Persistent file storage provider not configured.'),
          ),
        ),
      );
    });
  });
}
