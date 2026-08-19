import 'dart:typed_data';
import '../../../auth/domain/models/user_model.dart';
import '../models/achievement_models.dart';

abstract class AchievementRepository {
  /// Fetches achievements for a specific student.
  Future<List<Achievement>> getStudentAchievements({
    required String studentUid,
    required String collegeId,
    AchievementStatus? status,
  });

  /// Fetches an achievement by its ID.
  Future<Achievement?> getAchievementById(String id);

  /// Creates a new achievement record for the student with optional file upload.
  Future<void> createAchievement({
    required Achievement achievement,
    Uint8List? fileBytes,
  });

  /// Updates an existing achievement with optional file replacement.
  Future<void> updateAchievement({
    required Achievement achievement,
    Uint8List? newFileBytes,
    String? oldStoragePath,
  });

  /// Deletes an achievement and cleans up its physical storage file.
  Future<void> deleteAchievement({
    required String achievementId,
    String? storagePath,
  });

  /// Reviews an achievement verification request (approves or rejects with note).
  Future<void> reviewVerification({
    required String achievementId,
    required String reviewerUid,
    required String reviewerName,
    required AchievementVerificationStatus status,
    String? verificationNote,
  });

  /// Queries achievements scoped by role and academic boundaries.
  Future<List<Achievement>> getScopedAchievements({
    required UserModel requester,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    AchievementCategory? category,
    AchievementVerificationStatus? verificationStatus,
  });

  /// Watches live achievements for a student.
  Stream<List<Achievement>> watchStudentAchievements({
    required String studentUid,
    required String collegeId,
  });

  /// Watches live achievements for an authorized reviewer scope.
  Stream<List<Achievement>> watchScopedAchievements({
    required UserModel requester,
  });

  /// Computes metrics for a student portfolio.
  Future<AchievementMetrics> getStudentMetrics({
    required String studentUid,
    required String collegeId,
  });

  /// Computes metrics for an admin/HOD verification dashboard.
  Future<AchievementMetrics> getAdminMetrics({
    required UserModel requester,
  });
}
