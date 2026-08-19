import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/mock_certificate_repository.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import '../../domain/models/certificate_type.dart';
import '../../domain/repositories/certificate_repository.dart';

import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../data/repositories/firebase_certificate_repository.dart';

import '../../../storage/presentation/providers/storage_providers.dart';

// ---- Repository Provider ----

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockCertificateRepository();
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  final fileStorageRepo = ref.watch(fileStorageRepositoryProvider);
  return FirebaseCertificateRepository(
    firestoreService,
    fileStorageRepository: fileStorageRepo,
  );
});

// ---- Upload State ----

enum UploadStage { idle, selecting, validating, uploading, saving, completed, failed }

class UploadState {
  final UploadStage stage;
  final String? errorMessage;
  const UploadState({this.stage = UploadStage.idle, this.errorMessage});
  UploadState copyWith({UploadStage? stage, String? errorMessage}) =>
      UploadState(stage: stage ?? this.stage, errorMessage: errorMessage ?? this.errorMessage);
}

final certificateUploadStateProvider = StateProvider<UploadState>((_) => const UploadState());

// ---- Student Certificates (Real-time Stream) ----

final studentCertificatesProvider = StreamProvider<List<Certificate>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);
  final user = authState.user;
  if (user.role != AppRole.student) return Stream.value([]);
  final repo = ref.watch(certificateRepositoryProvider);
  return repo.watchStudentCertificates(user.firebaseUid ?? user.id);
});

// ---- Faculty Certificates (Real-time Stream scoped to department) ----

final facultyCertificatesProvider = StreamProvider<List<Certificate>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);
  final user = authState.user;
  if (user.collegeId == null || user.departmentId == null) return Stream.value([]);
  final repo = ref.watch(certificateRepositoryProvider);
  return repo.watchFacultyStudentCertificates(
    facultyUid: user.firebaseUid ?? user.id,
    collegeId: user.collegeId!,
    departmentId: user.departmentId!,
  );
});

// ---- Search Query ----

final certificateSearchQueryProvider = StateProvider<String>((_) => '');

// ---- Active Filter ----

class CertificateFilter {
  final CertificateType? type;
  final CertificateStatus? status;
  final bool? isVerified;
  const CertificateFilter({this.type, this.status, this.isVerified});
  bool get isActive => type != null || status != null || isVerified != null;
  CertificateFilter copyWith({CertificateType? type, CertificateStatus? status, bool? isVerified}) =>
      CertificateFilter(
        type: type ?? this.type,
        status: status ?? this.status,
        isVerified: isVerified ?? this.isVerified,
      );
}

final certificateFilterProvider = StateProvider<CertificateFilter>((_) => const CertificateFilter());

// ---- Computed: Filtered + Searched Student Certs ----

final filteredStudentCertificatesProvider = Provider<AsyncValue<List<Certificate>>>((ref) {
  final certs = ref.watch(studentCertificatesProvider);
  final query = ref.watch(certificateSearchQueryProvider).toLowerCase();
  final filter = ref.watch(certificateFilterProvider);

  return certs.whenData((list) {
    var result = list;
    if (query.isNotEmpty) {
      result = result.where((c) =>
        c.title.toLowerCase().contains(query) ||
        c.issuer.toLowerCase().contains(query) ||
        c.type.displayName.toLowerCase().contains(query),
      ).toList();
    }
    if (filter.type != null) result = result.where((c) => c.type == filter.type).toList();
    if (filter.status != null) result = result.where((c) => c.status == filter.status).toList();
    if (filter.isVerified != null) result = result.where((c) => c.isVerified == filter.isVerified).toList();
    return result;
  });
});

// ---- Computed: Filtered Faculty Certs ----

final filteredFacultyCertificatesProvider = Provider<AsyncValue<List<Certificate>>>((ref) {
  final certs = ref.watch(facultyCertificatesProvider);
  final query = ref.watch(certificateSearchQueryProvider).toLowerCase();
  final filter = ref.watch(certificateFilterProvider);

  return certs.whenData((list) {
    var result = list;
    if (query.isNotEmpty) {
      result = result.where((c) =>
        c.title.toLowerCase().contains(query) ||
        c.issuer.toLowerCase().contains(query) ||
        c.studentName.toLowerCase().contains(query) ||
        c.type.displayName.toLowerCase().contains(query),
      ).toList();
    }
    if (filter.type != null) result = result.where((c) => c.type == filter.type).toList();
    if (filter.status != null) result = result.where((c) => c.status == filter.status).toList();
    if (filter.isVerified != null) result = result.where((c) => c.isVerified == filter.isVerified).toList();
    return result;
  });
});
