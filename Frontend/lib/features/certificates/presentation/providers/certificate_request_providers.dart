import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/certificate_request_model.dart';
import '../../data/repositories/certificate_request_repository.dart';
import '../../data/repositories/mock_certificate_request_repository.dart';
import '../../data/repositories/firebase_certificate_request_repository.dart';

final mockCertificateRequestRepositoryProvider = Provider<CertificateRequestRepository>((ref) {
  return MockCertificateRequestRepository();
});

final firebaseCertificateRequestRepositoryProvider = Provider<CertificateRequestRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseCertificateRequestRepository(firestoreService);
});

final certificateRequestRepositoryProvider = Provider<CertificateRequestRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return ref.watch(mockCertificateRequestRepositoryProvider);
  }
  return ref.watch(firebaseCertificateRequestRepositoryProvider);
});

final certificateTypesProvider = FutureProvider<List<ConfiguredCertificateType>>((ref) async {
  final repository = ref.watch(certificateRequestRepositoryProvider);
  return repository.getCertificateTypes();
});

final userCertificateRequestsProvider = StreamProvider<List<CertificateRequest>>((ref) async* {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    yield [];
    return;
  }

  final user = authState.user;
  final repository = ref.watch(certificateRequestRepositoryProvider);

  if (user.role == AppRole.student) {
    await for (final requests in repository.watchStudentRequests(user.id)) {
      yield requests;
    }
  } else if (user.role == AppRole.hod) {
    await for (final requests in repository.watchAdminRequests(departmentId: user.departmentId)) {
      yield requests;
    }
  } else if (user.role == AppRole.collegeAdmin) {
    await for (final requests in repository.watchAdminRequests(collegeId: user.collegeId)) {
      yield requests;
    }
  } else if (user.role == AppRole.superAdmin) {
    await for (final requests in repository.watchAdminRequests()) {
      yield requests;
    }
  } else {
    // Faculty usually don't process general requests unless configured, we will return empty or read-only scope
    yield [];
  }
});

class CertificateRequestFilterState {
  final CertificateRequestStatus? status;
  final String? certificateTypeId;
  final String searchQuery;

  CertificateRequestFilterState({
    this.status,
    this.certificateTypeId,
    this.searchQuery = '',
  });

  CertificateRequestFilterState copyWith({
    CertificateRequestStatus? status,
    String? certificateTypeId,
    String? searchQuery,
    bool clearStatus = false,
    bool clearType = false,
  }) {
    return CertificateRequestFilterState(
      status: clearStatus ? null : (status ?? this.status),
      certificateTypeId: clearType ? null : (certificateTypeId ?? this.certificateTypeId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final certificateRequestFilterProvider = StateProvider<CertificateRequestFilterState>((ref) => CertificateRequestFilterState());

final filteredCertificateRequestsProvider = Provider<AsyncValue<List<CertificateRequest>>>((ref) {
  final asyncRequests = ref.watch(userCertificateRequestsProvider);
  final filters = ref.watch(certificateRequestFilterProvider);

  return asyncRequests.whenData((requests) {
    return requests.where((req) {
      if (filters.status != null && req.status != filters.status) return false;
      if (filters.certificateTypeId != null && req.certificateTypeId != filters.certificateTypeId) return false;
      
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        if (!req.certificateTypeName.toLowerCase().contains(query) &&
            !req.studentId.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

class CertificateRequestManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createRequest(CertificateRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(certificateRequestRepositoryProvider);
      await repository.createRequest(request);
    });
  }

  Future<void> updateStatus({
    required String requestId,
    required CertificateRequestStatus status,
    String? rejectionReason,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authProvider);
      String? reviewerId;
      if (authState is AuthAuthenticated) {
        reviewerId = authState.user.id;
      }
      
      final repository = ref.read(certificateRequestRepositoryProvider);
      await repository.updateRequestStatus(
        requestId: requestId,
        status: status,
        rejectionReason: rejectionReason,
        reviewedBy: reviewerId,
      );
    });
  }
}

final certificateRequestManagementProvider = AsyncNotifierProvider<CertificateRequestManagementNotifier, void>(() {
  return CertificateRequestManagementNotifier();
});
