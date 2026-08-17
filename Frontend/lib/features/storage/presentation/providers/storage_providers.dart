import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_initializer.dart';
import '../../domain/repositories/file_storage_repository.dart';
import '../../data/repositories/mock_file_storage_repository.dart';
import '../../data/repositories/not_configured_file_storage_repository.dart';

final fileStorageRepositoryProvider = Provider<FileStorageRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockFileStorageRepository();
  }
  return NotConfiguredFileStorageRepository();
});
