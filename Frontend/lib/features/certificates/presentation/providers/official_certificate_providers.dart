import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../storage/presentation/providers/storage_providers.dart';
import '../../domain/models/official_certificate_models.dart';
import '../../domain/repositories/official_certificate_repository.dart';
import '../../data/repositories/mock_official_certificate_repository.dart';
import '../../data/repositories/firebase_official_certificate_repository.dart';

/// Repository Provider
final officialCertificateRepositoryProvider = Provider<OfficialCertificateRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    final authState = ref.watch(authProvider);
    UserModel? currentUser;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    }
    return MockOfficialCertificateRepository(currentUser: currentUser);
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  final fileStorage = ref.watch(fileStorageRepositoryProvider);
  return FirebaseOfficialCertificateRepository(
    firestoreService,
    fileStorageRepository: fileStorage,
  );
});

/// Student-facing: Applicable Requirements with Submissions Stream
final studentOfficialRequirementsWithSubmissionsProvider =
    StreamProvider.autoDispose<List<RequirementWithSubmission>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return const Stream.empty();
  }

  final student = authState.user;
  final repo = ref.watch(officialCertificateRepositoryProvider);
  return repo.watchRequirementsWithSubmissionsForStudent(student: student);
});

/// Student-facing: Direct Submissions Stream
final studentOfficialSubmissionsProvider = StreamProvider.autoDispose<List<OfficialCertificate>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return const Stream.empty();
  }

  final repo = ref.watch(officialCertificateRepositoryProvider);
  return repo.watchStudentSubmissions(authState.user.id);
});

/// Admin/HOD: Requirements Stream
final officialCertificateRequirementsListProvider =
    StreamProvider.autoDispose<List<OfficialCertificateRequirement>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return const Stream.empty();
  }

  final user = authState.user;
  final collegeId = user.collegeId ?? '';
  final repo = ref.watch(officialCertificateRepositoryProvider);

  String? departmentScope;
  if (user.role == AppRole.hod) {
    departmentScope = user.departmentId;
  }

  return repo.watchRequirements(collegeId, departmentId: departmentScope);
});

/// Admin/HOD: Submissions Stream
final officialCertificateSubmissionsListProvider = StreamProvider.autoDispose<List<OfficialCertificate>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return const Stream.empty();
  }

  final user = authState.user;
  final collegeId = user.collegeId ?? '';
  final repo = ref.watch(officialCertificateRepositoryProvider);

  String? departmentScope;
  if (user.role == AppRole.hod) {
    departmentScope = user.departmentId;
  }

  return repo.watchCollegeSubmissions(collegeId, departmentId: departmentScope);
});

/// Filter State
class OfficialCertificateFilter {
  final String searchQuery;
  final OfficialCertificateStatus? statusFilter;
  final String? departmentFilter;
  final String? requirementFilter;

  const OfficialCertificateFilter({
    this.searchQuery = '',
    this.statusFilter,
    this.departmentFilter,
    this.requirementFilter,
  });

  OfficialCertificateFilter copyWith({
    String? searchQuery,
    OfficialCertificateStatus? statusFilter,
    String? departmentFilter,
    String? requirementFilter,
    bool clearStatus = false,
    bool clearDepartment = false,
    bool clearRequirement = false,
  }) {
    return OfficialCertificateFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      departmentFilter: clearDepartment ? null : (departmentFilter ?? this.departmentFilter),
      requirementFilter: clearRequirement ? null : (requirementFilter ?? this.requirementFilter),
    );
  }
}

final officialCertificateFilterProvider = StateProvider.autoDispose<OfficialCertificateFilter>((ref) {
  return const OfficialCertificateFilter();
});

/// Filtered Submissions Provider
final filteredOfficialSubmissionsProvider = Provider.autoDispose<List<OfficialCertificate>>((ref) {
  final asyncSubmissions = ref.watch(officialCertificateSubmissionsListProvider);
  final filter = ref.watch(officialCertificateFilterProvider);

  final submissions = asyncSubmissions.valueOrNull ?? [];

  return submissions.where((s) {
    if (filter.statusFilter != null && s.status != filter.statusFilter) {
      return false;
    }
    if (filter.departmentFilter != null &&
        filter.departmentFilter!.isNotEmpty &&
        s.departmentId != filter.departmentFilter) {
      return false;
    }
    if (filter.requirementFilter != null &&
        filter.requirementFilter!.isNotEmpty &&
        s.requirementId != filter.requirementFilter) {
      return false;
    }
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      final nameMatch = s.studentName.toLowerCase().contains(query);
      final idMatch = s.studentId.toLowerCase().contains(query);
      final certMatch = s.certificateName.toLowerCase().contains(query);
      final fileMatch = s.fileName.toLowerCase().contains(query);
      if (!nameMatch && !idMatch && !certMatch && !fileMatch) {
        return false;
      }
    }
    return true;
  }).toList();
});

/// Student Summary Metrics Model
class StudentCertificateMetrics {
  final int totalRequired;
  final int totalSubmitted;
  final int totalVerified;
  final int totalPending;
  final int totalResubmissionRequired;

  const StudentCertificateMetrics({
    this.totalRequired = 0,
    this.totalSubmitted = 0,
    this.totalVerified = 0,
    this.totalPending = 0,
    this.totalResubmissionRequired = 0,
  });
}

/// Student Summary Metrics Provider
final studentOfficialCertificateMetricsProvider = Provider.autoDispose<StudentCertificateMetrics>((ref) {
  final asyncList = ref.watch(studentOfficialRequirementsWithSubmissionsProvider);
  final list = asyncList.valueOrNull ?? [];

  int requiredCount = 0;
  int submittedCount = 0;
  int verifiedCount = 0;
  int pendingCount = 0;
  int resubmissionCount = 0;

  for (final item in list) {
    if (item.requirement.required) {
      requiredCount++;
    }
    if (item.submission != null) {
      submittedCount++;
      switch (item.submission!.status) {
        case OfficialCertificateStatus.verified:
          verifiedCount++;
          break;
        case OfficialCertificateStatus.pending:
          pendingCount++;
          break;
        case OfficialCertificateStatus.resubmissionRequired:
          resubmissionCount++;
          break;
        default:
          break;
      }
    }
  }

  return StudentCertificateMetrics(
    totalRequired: requiredCount,
    totalSubmitted: submittedCount,
    totalVerified: verifiedCount,
    totalPending: pendingCount,
    totalResubmissionRequired: resubmissionCount,
  );
});

/// Admin/HOD Summary Metrics Model
class AdminCertificateMetrics {
  final int totalRequirements;
  final int totalSubmissions;
  final int pendingVerification;
  final int verified;
  final int resubmissionRequired;
  final int rejected;

  const AdminCertificateMetrics({
    this.totalRequirements = 0,
    this.totalSubmissions = 0,
    this.pendingVerification = 0,
    this.verified = 0,
    this.resubmissionRequired = 0,
    this.rejected = 0,
  });
}

/// Admin/HOD Summary Metrics Provider
final adminOfficialCertificateMetricsProvider = Provider.autoDispose<AdminCertificateMetrics>((ref) {
  final reqs = ref.watch(officialCertificateRequirementsListProvider).valueOrNull ?? [];
  final subs = ref.watch(officialCertificateSubmissionsListProvider).valueOrNull ?? [];

  int pending = 0;
  int verified = 0;
  int resubmission = 0;
  int rejected = 0;

  for (final s in subs) {
    switch (s.status) {
      case OfficialCertificateStatus.pending:
        pending++;
        break;
      case OfficialCertificateStatus.verified:
        verified++;
        break;
      case OfficialCertificateStatus.resubmissionRequired:
        resubmission++;
        break;
      case OfficialCertificateStatus.rejected:
        rejected++;
        break;
      default:
        break;
    }
  }

  return AdminCertificateMetrics(
    totalRequirements: reqs.length,
    totalSubmissions: subs.length,
    pendingVerification: pending,
    verified: verified,
    resubmissionRequired: resubmission,
    rejected: rejected,
  );
});
