import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/repositories/file_storage_repository.dart';
import '../../data/repositories/mock_file_storage_repository.dart';
import '../../data/repositories/firebase_file_storage_repository.dart';

final fileStorageRepositoryProvider = Provider<FileStorageRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockFileStorageRepository();
  }
  final storageService = ref.watch(firebaseStorageServiceProvider);
  return FirebaseFileStorageRepository(storageService);
});
