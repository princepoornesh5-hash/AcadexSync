import 'dart:async';
import 'dart:typed_data';
import '../../../../core/firebase/firebase_exceptions.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/achievement_models.dart';
import '../../domain/repositories/achievement_repository.dart';

class MockAchievementRepository implements AchievementRepository {
  final UserModel? currentUser;
  final List<Achievement> _achievements = [];
  final Set<String> _simulatedStorage = {};
  bool _initialized = false;

  MockAchievementRepository({
    this.currentUser,
    List<Achievement>? initialAchievements,
  }) {
    if (initialAchievements != null) {
      _achievements.addAll(initialAchievements);
      _initialized = true;
    }
    _initData();
  }

  void _initData() {
    if (_initialized || _achievements.isNotEmpty) return;
    _initialized = true;

    final now = DateTime.now();

    final sampleAchievements = [
      Achievement(
        id: 'ach_1',
        studentUid: 'student_1',
        studentId: 'CSE-2024-001',
        studentName: 'Alice Johnson',
        collegeId: 'college_1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        category: AchievementCategory.hackathon,
        title: 'National Innovation Hackathon Winner',
        description: 'First prize in 36-hour hackathon for building an AI-powered smart campus energy management system.',
        issuer: 'Indian Institute of Technology (IIT)',
        achievementDate: DateTime(now.year, now.month - 1, 15),
        skills: ['Flutter', 'Python', 'IoT', 'AI/ML'],
        fileName: 'hackathon_winner_cert.pdf',
        fileType: 'pdf',
        fileSizeBytes: 2 * 1024 * 1024,
        storagePath: '/colleges/college_1/students/student_1/achievements/hackathon_winner_cert.pdf',
        fileUrl: 'https://firebasestorage.googleapis.com/mock/achievements/hackathon_winner_cert.pdf',
        status: AchievementStatus.active,
        createdAt: now.subtract(const Duration(days: 30)),
        createdBy: 'Alice Johnson',
        isVerificationRequested: true,
        verificationStatus: AchievementVerificationStatus.verified,
        verifiedBy: 'Dr. Alan Turing',
        verifiedAt: now.subtract(const Duration(days: 25)),
      ),
      Achievement(
        id: 'ach_2',
        studentUid: 'student_1',
        studentId: 'CSE-2024-001',
        studentName: 'Alice Johnson',
        collegeId: 'college_1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        category: AchievementCategory.certification,
        title: 'Google Cloud Certified Professional Cloud Architect',
        description: 'Demonstrated proficiency in cloud architecture, security, and scalable infrastructure deployment.',
        issuer: 'Google Cloud',
        achievementDate: DateTime(now.year, now.month - 3, 10),
        skills: ['GCP', 'Kubernetes', 'Cloud Architecture'],
        fileName: 'gcp_architect.pdf',
        fileType: 'pdf',
        fileSizeBytes: 1024 * 750,
        storagePath: '/colleges/college_1/students/student_1/achievements/gcp_architect.pdf',
        fileUrl: 'https://firebasestorage.googleapis.com/mock/achievements/gcp_architect.pdf',
        status: AchievementStatus.active,
        createdAt: now.subtract(const Duration(days: 90)),
        createdBy: 'Alice Johnson',
        isVerificationRequested: true,
        verificationStatus: AchievementVerificationStatus.verified,
        verifiedBy: 'Dr. Alan Turing',
        verifiedAt: now.subtract(const Duration(days: 85)),
      ),
      Achievement(
        id: 'ach_3',
        studentUid: 'student_1',
        studentId: 'CSE-2024-001',
        studentName: 'Alice Johnson',
        collegeId: 'college_1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        category: AchievementCategory.technical,
        title: 'Open Source Contributor — Flutter Core',
        description: 'Merged 3 bugfix PRs into Flutter engine and framework repository.',
        issuer: 'GitHub / Flutter Community',
        achievementDate: DateTime(now.year, now.month - 2, 20),
        skills: ['Dart', 'C++', 'Open Source'],
        status: AchievementStatus.active,
        createdAt: now.subtract(const Duration(days: 60)),
        createdBy: 'Alice Johnson',
        isVerificationRequested: false,
        verificationStatus: AchievementVerificationStatus.unverified,
      ),
      Achievement(
        id: 'ach_4',
        studentUid: 'student_1',
        studentId: 'CSE-2024-001',
        studentName: 'Alice Johnson',
        collegeId: 'college_1',
        departmentId: 'dept_cse',
        courseId: 'crs_btech',
        semesterId: 'sem_6',
        sectionId: 'sec_a',
        academicYearId: 'ay_2026',
        category: AchievementCategory.internship,
        title: 'Software Engineering Intern — Acame Tech',
        description: '2-month summer internship working on backend microservices and Redis caching layers.',
        issuer: 'Acame Technologies',
        achievementDate: DateTime(now.year - 1, 8, 30),
        skills: ['Go', 'Redis', 'Docker'],
        fileName: 'internship_letter.png',
        fileType: 'png',
        fileSizeBytes: 1024 * 1200,
        storagePath: '/colleges/college_1/students/student_1/achievements/internship_letter.png',
        fileUrl: 'https://firebasestorage.googleapis.com/mock/achievements/internship_letter.png',
        status: AchievementStatus.active,
        createdAt: now.subtract(const Duration(days: 350)),
        createdBy: 'Alice Johnson',
        isVerificationRequested: true,
        verificationStatus: AchievementVerificationStatus.pending,
      ),
      Achievement(
        id: 'ach_5',
        studentUid: 'student_2',
        studentId: 'ECE-2024-042',
        studentName: 'Bob Miller',
        collegeId: 'college_1',
        departmentId: 'dept_ece',
        courseId: 'crs_btech',
        semesterId: 'sem_4',
        sectionId: 'sec_b',
        academicYearId: 'ay_2026',
        category: AchievementCategory.sports,
        title: 'Inter-University Badminton Championship — Gold Medalist',
        description: 'Won Singles Gold in state level university badminton tournament.',
        issuer: 'State Sports Authority',
        achievementDate: DateTime(now.year, 2, 10),
        skills: ['Badminton', 'Sportsmanship'],
        fileName: 'badminton_gold.jpg',
        fileType: 'jpg',
        fileSizeBytes: 1024 * 900,
        storagePath: '/colleges/college_1/students/student_2/achievements/badminton_gold.jpg',
        fileUrl: 'https://firebasestorage.googleapis.com/mock/achievements/badminton_gold.jpg',
        status: AchievementStatus.active,
        createdAt: now.subtract(const Duration(days: 100)),
        createdBy: 'Bob Miller',
        isVerificationRequested: true,
        verificationStatus: AchievementVerificationStatus.pending,
      ),
    ];

    _achievements.addAll(sampleAchievements);
    for (final a in sampleAchievements) {
      if (a.storagePath != null) {
        _simulatedStorage.add(a.storagePath!);
      }
    }
  }

  Future<void> _delay() async {
    await Future.delayed(const Duration(milliseconds: 10));
  }

  bool isStorageFilePresent(String path) => _simulatedStorage.contains(path);

  @override
  Future<List<Achievement>> getStudentAchievements({
    required String studentUid,
    required String collegeId,
    AchievementStatus? status,
  }) async {
    await _delay();
    return _achievements.where((a) {
      if (a.studentUid != studentUid || a.collegeId != collegeId) return false;
      if (status != null && a.status != status) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.achievementDate.compareTo(a.achievementDate));
  }

  @override
  Future<Achievement?> getAchievementById(String id) async {
    await _delay();
    try {
      return _achievements.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createAchievement({
    required Achievement achievement,
    Uint8List? fileBytes,
  }) async {
    await _delay();

    // 1. Role & Identity checks
    if (currentUser != null) {
      if (currentUser!.role == AppRole.superAdmin) {
        throw const BackendPermissionException('Super Admin cannot manage routine student achievements.');
      }
      if (currentUser!.role == AppRole.student && currentUser!.id != achievement.studentUid) {
        throw const BackendPermissionException('Students can only create achievements for themselves.');
      }
      if (currentUser!.collegeId != null && currentUser!.collegeId != achievement.collegeId) {
        throw const BackendPermissionException('Tenant isolation error: College mismatch.');
      }
      if (currentUser!.departmentId != null && currentUser!.departmentId != achievement.departmentId) {
        throw const BackendPermissionException('Department mismatch: Student must use authenticated department.');
      }
    }

    // 2. File validations
    if (achievement.fileSizeBytes > 10 * 1024 * 1024) {
      throw const BackendValidationException('Achievement file size exceeds 10MB limit.');
    }

    if (achievement.fileType != null && achievement.fileType!.isNotEmpty) {
      final allowed = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
      if (!allowed.contains(achievement.fileType!.toLowerCase())) {
        throw const BackendValidationException('Unsupported file format. Allowed: PDF, JPG, PNG, DOC, DOCX.');
      }
    }

    // 3. Status determination based on verification request
    final initialVerificationStatus = achievement.isVerificationRequested
        ? AchievementVerificationStatus.pending
        : AchievementVerificationStatus.unverified;

    final prepared = achievement.copyWith(
      verificationStatus: initialVerificationStatus,
    );

    if (prepared.storagePath != null) {
      _simulatedStorage.add(prepared.storagePath!);
    }

    _achievements.removeWhere((a) => a.id == prepared.id);
    _achievements.add(prepared);
  }

  @override
  Future<void> updateAchievement({
    required Achievement achievement,
    Uint8List? newFileBytes,
    String? oldStoragePath,
  }) async {
    await _delay();

    final existingIndex = _achievements.indexWhere((a) => a.id == achievement.id);
    if (existingIndex == -1) {
      throw const BackendDatabaseException('Achievement not found');
    }
    final existing = _achievements[existingIndex];

    // 1. Role boundary & Academic Identity immutability
    if (currentUser != null) {
      if (currentUser!.role == AppRole.student && currentUser!.id != existing.studentUid) {
        throw const BackendPermissionException('Cannot update another student\'s achievement.');
      }
      // Immutable academic fields verification
      if (achievement.studentUid != existing.studentUid ||
          achievement.collegeId != existing.collegeId ||
          achievement.departmentId != existing.departmentId ||
          achievement.courseId != existing.courseId ||
          achievement.semesterId != existing.semesterId ||
          achievement.sectionId != existing.sectionId) {
        throw const BackendValidationException('Academic identity fields are immutable.');
      }
    }

    // 2. File validations
    if (achievement.fileSizeBytes > 10 * 1024 * 1024) {
      throw const BackendValidationException('Achievement file size exceeds 10MB limit.');
    }

    // 3. Storage replacement & cleanup
    if (oldStoragePath != null &&
        oldStoragePath.isNotEmpty &&
        oldStoragePath != achievement.storagePath) {
      _simulatedStorage.remove(oldStoragePath);
    }
    if (achievement.storagePath != null) {
      _simulatedStorage.add(achievement.storagePath!);
    }

    // 4. Update status if re-requesting verification
    AchievementVerificationStatus nextVerification = existing.verificationStatus;
    if (achievement.isVerificationRequested && existing.verificationStatus == AchievementVerificationStatus.unverified) {
      nextVerification = AchievementVerificationStatus.pending;
    } else if (achievement.isVerificationRequested && existing.verificationStatus == AchievementVerificationStatus.rejected) {
      nextVerification = AchievementVerificationStatus.pending;
    }

    final updated = achievement.copyWith(
      verificationStatus: nextVerification,
      updatedAt: DateTime.now(),
    );

    _achievements[existingIndex] = updated;
  }

  @override
  Future<void> deleteAchievement({
    required String achievementId,
    String? storagePath,
  }) async {
    await _delay();

    final existing = _achievements.where((a) => a.id == achievementId).firstOrNull;
    if (existing == null) return;

    if (currentUser != null) {
      if (currentUser!.role == AppRole.student && currentUser!.id != existing.studentUid) {
        throw const BackendPermissionException('Cannot delete another student\'s achievement.');
      }
      if (currentUser!.role == AppRole.faculty && currentUser!.departmentId != existing.departmentId) {
        throw const BackendPermissionException('Faculty cannot delete achievements outside their department.');
      }
    }

    if (storagePath != null && storagePath.isNotEmpty) {
      _simulatedStorage.remove(storagePath);
    }
    if (existing.storagePath != null) {
      _simulatedStorage.remove(existing.storagePath!);
    }

    _achievements.removeWhere((a) => a.id == achievementId);
  }

  @override
  Future<void> reviewVerification({
    required String achievementId,
    required String reviewerUid,
    required String reviewerName,
    required AchievementVerificationStatus status,
    String? verificationNote,
  }) async {
    await _delay();

    final existingIndex = _achievements.indexWhere((a) => a.id == achievementId);
    if (existingIndex == -1) {
      throw const BackendDatabaseException('Achievement not found');
    }
    final existing = _achievements[existingIndex];

    // 1. Review authority check
    if (currentUser != null) {
      if (currentUser!.role == AppRole.student) {
        throw const BackendPermissionException('Students cannot verify achievements.');
      }
      if (currentUser!.role == AppRole.superAdmin) {
        throw const BackendPermissionException('Super Admin cannot perform routine verifications.');
      }
      if (currentUser!.role == AppRole.hod && currentUser!.departmentId != existing.departmentId) {
        throw const BackendPermissionException('HOD cannot verify achievements from another department.');
      }
      if (currentUser!.role == AppRole.faculty && currentUser!.departmentId != existing.departmentId) {
        throw const BackendPermissionException('Faculty cannot verify achievements from another department.');
      }
    }

    // 2. Reason validation for rejection
    if (status == AchievementVerificationStatus.rejected) {
      if (verificationNote == null || verificationNote.trim().isEmpty) {
        throw const BackendValidationException('A verification note is mandatory when rejecting an achievement.');
      }
    }

    final updated = existing.copyWith(
      verificationStatus: status,
      verifiedBy: reviewerName,
      verifiedAt: DateTime.now(),
      verificationNote: verificationNote,
      updatedAt: DateTime.now(),
    );

    _achievements[existingIndex] = updated;
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
    await _delay();

    return _achievements.where((a) {
      if (requester.collegeId != null && a.collegeId != requester.collegeId) return false;

      // Role Scoping
      switch (requester.role) {
        case AppRole.student:
          if (a.studentUid != requester.id) return false;
          break;
        case AppRole.faculty:
          if (requester.departmentId != null && a.departmentId != requester.departmentId) return false;
          if (requester.sectionId != null && a.sectionId.isNotEmpty && a.sectionId != requester.sectionId) {
            return false;
          }
          break;
        case AppRole.hod:
          if (requester.departmentId != null && a.departmentId != requester.departmentId) return false;
          break;
        case AppRole.collegeAdmin:
          // Can access all departments in the college
          break;
        case AppRole.superAdmin:
          // Platform level overview only
          break;
      }

      // Explicit filters
      if (departmentId != null && a.departmentId != departmentId) return false;
      if (courseId != null && a.courseId != courseId) return false;
      if (semesterId != null && a.semesterId != semesterId) return false;
      if (sectionId != null && a.sectionId != sectionId) return false;
      if (category != null && a.category != category) return false;
      if (verificationStatus != null && a.verificationStatus != verificationStatus) return false;

      return true;
    }).toList()
      ..sort((a, b) => b.achievementDate.compareTo(a.achievementDate));
  }

  @override
  Stream<List<Achievement>> watchStudentAchievements({
    required String studentUid,
    required String collegeId,
  }) {
    return Stream.value(
      _achievements
          .where((a) => a.studentUid == studentUid && a.collegeId == collegeId)
          .toList()
        ..sort((a, b) => b.achievementDate.compareTo(a.achievementDate)),
    );
  }

  @override
  Stream<List<Achievement>> watchScopedAchievements({
    required UserModel requester,
  }) {
    return Stream.fromFuture(getScopedAchievements(requester: requester));
  }

  @override
  Future<AchievementMetrics> getStudentMetrics({
    required String studentUid,
    required String collegeId,
  }) async {
    final list = await getStudentAchievements(studentUid: studentUid, collegeId: collegeId);
    final currentYear = DateTime.now().year;

    int total = list.length;
    int verified = list.where((a) => a.isVerified).length;
    int pending = list.where((a) => a.isPending).length;
    int unverified = list.where((a) => a.isUnverified).length;
    int rejected = list.where((a) => a.isRejected).length;
    int thisYear = list.where((a) => a.year == currentYear).length;

    return AchievementMetrics(
      total: total,
      verified: verified,
      pending: pending,
      unverified: unverified,
      rejected: rejected,
      currentYearCount: thisYear,
    );
  }

  @override
  Future<AchievementMetrics> getAdminMetrics({
    required UserModel requester,
  }) async {
    final list = await getScopedAchievements(requester: requester);
    final currentYear = DateTime.now().year;

    int total = list.length;
    int verified = list.where((a) => a.isVerified).length;
    int pending = list.where((a) => a.isPending).length;
    int unverified = list.where((a) => a.isUnverified).length;
    int rejected = list.where((a) => a.isRejected).length;
    int thisYear = list.where((a) => a.year == currentYear).length;

    return AchievementMetrics(
      total: total,
      verified: verified,
      pending: pending,
      unverified: unverified,
      rejected: rejected,
      currentYearCount: thisYear,
    );
  }
}
