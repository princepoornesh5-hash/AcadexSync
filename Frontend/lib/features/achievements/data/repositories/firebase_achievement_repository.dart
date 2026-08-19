import 'dart:typed_data';
import '../../../../core/firebase/firebase_exceptions.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../storage/domain/models/file_category.dart';
import '../../../storage/domain/repositories/file_storage_repository.dart';
import '../../domain/models/achievement_models.dart';
import '../../domain/repositories/achievement_repository.dart';

class FirebaseAchievementRepository implements AchievementRepository {
  final FirestoreService _firestoreService;
  final FileStorageRepository? _fileStorageRepository;

  static const String _collection = 'achievements';

  FirebaseAchievementRepository(
    this._firestoreService, {
    FileStorageRepository? fileStorageRepository,
  }) : _fileStorageRepository = fileStorageRepository;

  @override
  Future<List<Achievement>> getStudentAchievements({
    required String studentUid,
    required String collegeId,
    AchievementStatus? status,
  }) async {
    final filters = <String, dynamic>{
      'studentUid': studentUid,
      'collegeId': collegeId,
    };
    if (status != null) {
      filters['status'] = status.name;
    }

    final result = await _firestoreService.queryCollectionPaginated(
      _collection,
      filters,
      limit: 100,
      orderBy: 'achievementDate',
      descending: true,
    );

    return result.data.map((d) => Achievement.fromJson(d)).toList();
  }

  @override
  Future<Achievement?> getAchievementById(String id) async {
    final doc = await _firestoreService.getDocument(_collection, id);
    if (doc == null) return null;
    return Achievement.fromJson(doc);
  }

  @override
  Future<void> createAchievement({
    required Achievement achievement,
    Uint8List? fileBytes,
  }) async {
    // 1. Validation
    if (achievement.fileSizeBytes > 10 * 1024 * 1024) {
      throw const BackendValidationException('File size exceeds 10MB limit.');
    }

    String? finalFileUrl = achievement.fileUrl;
    String? finalStoragePath = achievement.storagePath;

    // 2. Storage upload if bytes provided
    if (fileBytes != null && _fileStorageRepository != null && achievement.fileName != null) {
      try {
        final stored = await _fileStorageRepository.uploadFile(
          bytes: fileBytes,
          fileName: achievement.fileName!,
          contentType: _mapContentType(achievement.fileType ?? 'pdf'),
          category: FileCategory.certificate,
          ownerUid: achievement.studentUid,
          collegeId: achievement.collegeId,
          departmentId: achievement.departmentId,
          studentId: achievement.studentId,
          customMetadata: {
            'achievementTitle': achievement.title,
            'category': achievement.category.name,
          },
        );
        finalFileUrl = stored.downloadUrl;
        finalStoragePath = stored.storagePath;
      } catch (e) {
        throw BackendStorageException('Failed to upload achievement proof: $e');
      }
    }

    final prepared = achievement.copyWith(
      fileUrl: finalFileUrl,
      storagePath: finalStoragePath,
      verificationStatus: achievement.isVerificationRequested
          ? AchievementVerificationStatus.pending
          : AchievementVerificationStatus.unverified,
    );

    // 3. Write Firestore metadata with rollback
    try {
      await _firestoreService.setDocument(_collection, prepared.id, prepared.toJson());
    } catch (e) {
      if (finalStoragePath != null && _fileStorageRepository != null) {
        try {
          await _fileStorageRepository.deleteFile(finalStoragePath);
        } catch (_) {}
      }
      throw BackendDatabaseException('Failed to save achievement: $e');
    }
  }

  @override
  Future<void> updateAchievement({
    required Achievement achievement,
    Uint8List? newFileBytes,
    String? oldStoragePath,
  }) async {
    if (achievement.fileSizeBytes > 10 * 1024 * 1024) {
      throw const BackendValidationException('File size exceeds 10MB limit.');
    }

    String? finalFileUrl = achievement.fileUrl;
    String? finalStoragePath = achievement.storagePath;

    if (newFileBytes != null && _fileStorageRepository != null && achievement.fileName != null) {
      try {
        final stored = await _fileStorageRepository.uploadFile(
          bytes: newFileBytes,
          fileName: achievement.fileName!,
          contentType: _mapContentType(achievement.fileType ?? 'pdf'),
          category: FileCategory.certificate,
          ownerUid: achievement.studentUid,
          collegeId: achievement.collegeId,
          departmentId: achievement.departmentId,
          studentId: achievement.studentId,
        );
        finalFileUrl = stored.downloadUrl;
        finalStoragePath = stored.storagePath;
      } catch (e) {
        throw BackendStorageException('Failed to upload new proof file: $e');
      }
    }

    final updated = achievement.copyWith(
      fileUrl: finalFileUrl,
      storagePath: finalStoragePath,
      updatedAt: DateTime.now(),
    );

    try {
      await _firestoreService.setDocument(_collection, updated.id, updated.toJson());
    } catch (e) {
      if (newFileBytes != null && finalStoragePath != null && _fileStorageRepository != null) {
        try {
          await _fileStorageRepository.deleteFile(finalStoragePath);
        } catch (_) {}
      }
      throw BackendDatabaseException('Failed to update achievement: $e');
    }

    // Cleanup previous file if replaced
    if (oldStoragePath != null &&
        oldStoragePath.isNotEmpty &&
        oldStoragePath != finalStoragePath &&
        _fileStorageRepository != null) {
      try {
        await _fileStorageRepository.deleteFile(oldStoragePath);
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteAchievement({
    required String achievementId,
    String? storagePath,
  }) async {
    await _firestoreService.deleteDocument(_collection, achievementId);

    if (storagePath != null && storagePath.isNotEmpty && _fileStorageRepository != null) {
      try {
        await _fileStorageRepository.deleteFile(storagePath);
      } catch (_) {}
    }
  }

  @override
  Future<void> reviewVerification({
    required String achievementId,
    required String reviewerUid,
    required String reviewerName,
    required AchievementVerificationStatus status,
    String? verificationNote,
  }) async {
    if (status == AchievementVerificationStatus.rejected) {
      if (verificationNote == null || verificationNote.trim().isEmpty) {
        throw const BackendValidationException('Verification note is mandatory when rejecting.');
      }
    }

    final existing = await getAchievementById(achievementId);
    if (existing == null) {
      throw const BackendDatabaseException('Achievement not found');
    }

    final updated = existing.copyWith(
      verificationStatus: status,
      verifiedBy: reviewerName,
      verifiedAt: DateTime.now(),
      verificationNote: verificationNote,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.setDocument(_collection, achievementId, updated.toJson());
  }

  @override
  Future<List<Achievement>> getScopedAchievements({
    required UserModel requester,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    AchievementCategory? category,
    AchievementVerificationStatus? verificationStatus,
  }) async {
    final filters = <String, dynamic>{};
    if (requester.collegeId != null) {
      filters['collegeId'] = requester.collegeId;
    }

    switch (requester.role) {
      case AppRole.student:
        filters['studentUid'] = requester.id;
        break;
      case AppRole.faculty:
        if (requester.departmentId != null) filters['departmentId'] = requester.departmentId;
        if (requester.sectionId != null) filters['sectionId'] = requester.sectionId;
        break;
      case AppRole.hod:
        if (requester.departmentId != null) filters['departmentId'] = requester.departmentId;
        break;
      case AppRole.collegeAdmin:
      case AppRole.superAdmin:
        break;
    }

    if (departmentId != null) filters['departmentId'] = departmentId;
    if (courseId != null) filters['courseId'] = courseId;
    if (semesterId != null) filters['semesterId'] = semesterId;
    if (sectionId != null) filters['sectionId'] = sectionId;
    if (category != null) filters['category'] = category.name;
    if (verificationStatus != null) filters['verificationStatus'] = verificationStatus.name;

    final result = await _firestoreService.queryCollectionPaginated(
      _collection,
      filters,
      limit: 100,
      orderBy: 'achievementDate',
      descending: true,
    );

    return result.data.map((d) => Achievement.fromJson(d)).toList();
  }

  @override
  Stream<List<Achievement>> watchStudentAchievements({
    required String studentUid,
    required String collegeId,
  }) {
    return _firestoreService.watchQuery(
      _collection,
      {'studentUid': studentUid, 'collegeId': collegeId},
      orderBy: 'achievementDate',
      descending: true,
    ).map((docs) => docs.map((d) => Achievement.fromJson(d)).toList());
  }

  @override
  Stream<List<Achievement>> watchScopedAchievements({
    required UserModel requester,
  }) {
    final filters = <String, dynamic>{};
    if (requester.collegeId != null) filters['collegeId'] = requester.collegeId;
    if (requester.role == AppRole.hod || requester.role == AppRole.faculty) {
      if (requester.departmentId != null) filters['departmentId'] = requester.departmentId;
    }

    return _firestoreService.watchQuery(
      _collection,
      filters,
      orderBy: 'achievementDate',
      descending: true,
    ).map((docs) => docs.map((d) => Achievement.fromJson(d)).toList());
  }

  @override
  Future<AchievementMetrics> getStudentMetrics({
    required String studentUid,
    required String collegeId,
  }) async {
    final list = await getStudentAchievements(studentUid: studentUid, collegeId: collegeId);
    final currentYear = DateTime.now().year;

    return AchievementMetrics(
      total: list.length,
      verified: list.where((a) => a.isVerified).length,
      pending: list.where((a) => a.isPending).length,
      unverified: list.where((a) => a.isUnverified).length,
      rejected: list.where((a) => a.isRejected).length,
      currentYearCount: list.where((a) => a.year == currentYear).length,
    );
  }

  @override
  Future<AchievementMetrics> getAdminMetrics({
    required UserModel requester,
  }) async {
    final list = await getScopedAchievements(requester: requester);
    final currentYear = DateTime.now().year;

    return AchievementMetrics(
      total: list.length,
      verified: list.where((a) => a.isVerified).length,
      pending: list.where((a) => a.isPending).length,
      unverified: list.where((a) => a.isUnverified).length,
      rejected: list.where((a) => a.isRejected).length,
      currentYearCount: list.where((a) => a.year == currentYear).length,
    );
  }

  String _mapContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
