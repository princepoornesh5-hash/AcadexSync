/// Explicit lifecycle states for Academic Result (Prompt 44).
enum ResultLifecycleStatus {
  draft('DRAFT', 'Draft'),
  calculated('CALCULATED', 'Calculated'),
  underReview('UNDER_REVIEW', 'Under Review'),
  finalized('FINALIZED', 'Finalized'),
  published('PUBLISHED', 'Published'),
  reopened('REOPENED', 'Reopened'),
  archived('ARCHIVED', 'Archived');

  final String value;
  final String label;
  const ResultLifecycleStatus(this.value, this.label);

  static ResultLifecycleStatus fromValue(String? val) {
    switch (val?.toUpperCase()) {
      case 'CALCULATED':
        return ResultLifecycleStatus.calculated;
      case 'UNDER_REVIEW':
        return ResultLifecycleStatus.underReview;
      case 'FINALIZED':
        return ResultLifecycleStatus.finalized;
      case 'PUBLISHED':
        return ResultLifecycleStatus.published;
      case 'REOPENED':
        return ResultLifecycleStatus.reopened;
      case 'ARCHIVED':
        return ResultLifecycleStatus.archived;
      case 'DRAFT':
      default:
        return ResultLifecycleStatus.draft;
    }
  }
}

/// Official Subject-level result status.
enum SubjectResultStatus {
  pass('PASS', 'Pass'),
  fail('FAIL', 'Fail'),
  incomplete('INCOMPLETE', 'Incomplete'),
  withheld('WITHHELD', 'Withheld'),
  exempted('EXEMPTED', 'Exempted');

  final String value;
  final String label;
  const SubjectResultStatus(this.value, this.label);

  static SubjectResultStatus fromValue(String? val) {
    switch (val?.toUpperCase()) {
      case 'PASS':
        return SubjectResultStatus.pass;
      case 'FAIL':
        return SubjectResultStatus.fail;
      case 'WITHHELD':
        return SubjectResultStatus.withheld;
      case 'EXEMPTED':
        return SubjectResultStatus.exempted;
      case 'INCOMPLETE':
      default:
        return SubjectResultStatus.incomplete;
    }
  }
}

/// Overall semester academic status.
enum OverallResultStatus {
  pass('PASS', 'Pass'),
  fail('FAIL', 'Fail'),
  incomplete('INCOMPLETE', 'Incomplete'),
  withheld('WITHHELD', 'Withheld'),
  promoted('PROMOTED', 'Promoted'),
  pendingReview('PENDING_REVIEW', 'Pending Review');

  final String value;
  final String label;
  const OverallResultStatus(this.value, this.label);

  static OverallResultStatus fromValue(String? val) {
    switch (val?.toUpperCase()) {
      case 'PASS':
        return OverallResultStatus.pass;
      case 'FAIL':
        return OverallResultStatus.fail;
      case 'WITHHELD':
        return OverallResultStatus.withheld;
      case 'PROMOTED':
        return OverallResultStatus.promoted;
      case 'PENDING_REVIEW':
        return OverallResultStatus.pendingReview;
      case 'INCOMPLETE':
      default:
        return OverallResultStatus.incomplete;
    }
  }
}

/// Model representing single subject calculation outcome.
class SubjectResultModel {
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final double credits;
  final double internalMarks;
  final double? attendancePercentage;
  final bool? attendancePassed;
  final bool? practicalCompleted;
  final double totalMarks;
  final double percentage;
  final String? grade;
  final double? gradePoint;
  final SubjectResultStatus status;
  final String? remarks;

  const SubjectResultModel({
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.credits,
    required this.internalMarks,
    this.attendancePercentage,
    this.attendancePassed,
    this.practicalCompleted,
    required this.totalMarks,
    required this.percentage,
    this.grade,
    this.gradePoint,
    required this.status,
    this.remarks,
  });

  factory SubjectResultModel.fromJson(Map<String, dynamic> json) {
    return SubjectResultModel(
      subjectId: json['subjectId']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      credits: (json['credits'] as num?)?.toDouble() ?? 0.0,
      internalMarks: (json['internalMarks'] as num?)?.toDouble() ?? 0.0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble(),
      attendancePassed: json['attendancePassed'] as bool?,
      practicalCompleted: json['practicalCompleted'] as bool?,
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      grade: json['grade']?.toString(),
      gradePoint: (json['gradePoint'] as num?)?.toDouble(),
      status: SubjectResultStatus.fromValue(json['status']?.toString()),
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'subjectId': subjectId,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'credits': credits,
    'internalMarks': internalMarks,
    'attendancePercentage': attendancePercentage,
    'attendancePassed': attendancePassed,
    'practicalCompleted': practicalCompleted,
    'totalMarks': totalMarks,
    'percentage': percentage,
    'grade': grade,
    'gradePoint': gradePoint,
    'status': status.value,
    'remarks': remarks,
  };
}

/// Aggregate summary of semester academic evaluation.
class ResultSummaryModel {
  final double totalCredits;
  final double earnedCredits;
  final double totalMarks;
  final double maxMarks;
  final double percentage;
  final double? gpa;
  final double? cgpa;
  final OverallResultStatus overallStatus;
  final int failedSubjectCount;

  const ResultSummaryModel({
    required this.totalCredits,
    required this.earnedCredits,
    required this.totalMarks,
    required this.maxMarks,
    required this.percentage,
    this.gpa,
    this.cgpa,
    required this.overallStatus,
    this.failedSubjectCount = 0,
  });

  factory ResultSummaryModel.fromJson(Map<String, dynamic> json) {
    return ResultSummaryModel(
      totalCredits: (json['totalCredits'] as num?)?.toDouble() ?? 0.0,
      earnedCredits: (json['earnedCredits'] as num?)?.toDouble() ?? 0.0,
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0.0,
      maxMarks: (json['maxMarks'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      gpa: (json['gpa'] as num?)?.toDouble(),
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      overallStatus: OverallResultStatus.fromValue(json['overallStatus']?.toString()),
      failedSubjectCount: (json['failedSubjectCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalCredits': totalCredits,
    'earnedCredits': earnedCredits,
    'totalMarks': totalMarks,
    'maxMarks': maxMarks,
    'percentage': percentage,
    'gpa': gpa,
    'cgpa': cgpa,
    'overallStatus': overallStatus.value,
    'failedSubjectCount': failedSubjectCount,
  };
}

/// Immutable historical snapshot of official release.
class PublicationSnapshotModel {
  final int version;
  final DateTime publishedAt;
  final String publishedBy;
  final ResultSummaryModel summary;
  final List<SubjectResultModel> subjectResults;

  const PublicationSnapshotModel({
    required this.version,
    required this.publishedAt,
    required this.publishedBy,
    required this.summary,
    required this.subjectResults,
  });

  factory PublicationSnapshotModel.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjectResults'] as List<dynamic>? ?? [];
    return PublicationSnapshotModel(
      version: (json['version'] as num?)?.toInt() ?? 1,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      publishedBy: json['publishedBy']?.toString() ?? '',
      summary: ResultSummaryModel.fromJson(
        Map<String, dynamic>.from((json['summary'] as Map?) ?? {}),
      ),
      subjectResults: rawSubjects
          .map((s) => SubjectResultModel.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'publishedAt': publishedAt.toIso8601String(),
    'publishedBy': publishedBy,
    'summary': summary.toJson(),
    'subjectResults': subjectResults.map((s) => s.toJson()).toList(),
  };
}

/// Canonical Academic Result Model for Staff & Admins.
class AcademicResultModel {
  final String id;
  final String collegeId;
  final String studentId;
  final String? academicRecordId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String? sectionId;
  final ResultLifecycleStatus status;
  final int calculationVersion;
  final ResultSummaryModel summary;
  final List<SubjectResultModel> subjectResults;
  final PublicationSnapshotModel? currentPublishedSnapshot;
  final List<PublicationSnapshotModel> publicationHistory;
  final List<Map<String, dynamic>> reopenHistory;
  final Map<String, dynamic>? studentInfo;
  final List<String> validationWarnings;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? finalizedBy;
  final DateTime? finalizedAt;
  final String? publishedBy;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AcademicResultModel({
    required this.id,
    required this.collegeId,
    required this.studentId,
    this.academicRecordId,
    required this.courseId,
    required this.academicYearId,
    required this.semesterId,
    this.sectionId,
    required this.status,
    required this.calculationVersion,
    required this.summary,
    required this.subjectResults,
    this.currentPublishedSnapshot,
    this.publicationHistory = const [],
    this.reopenHistory = const [],
    this.studentInfo,
    this.validationWarnings = const [],
    this.reviewedBy,
    this.reviewedAt,
    this.finalizedBy,
    this.finalizedAt,
    this.publishedBy,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AcademicResultModel.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjectResults'] as List<dynamic>? ?? [];
    final rawPubHistory = json['publicationHistory'] as List<dynamic>? ?? [];
    final rawReopenHistory = json['reopenHistory'] as List<dynamic>? ?? [];
    final rawWarnings = json['validationWarnings'] as List<dynamic>? ?? [];

    return AcademicResultModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      collegeId: json['collegeId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      academicRecordId: json['academicRecordId']?.toString(),
      courseId: json['courseId']?.toString() ?? '',
      academicYearId: json['academicYearId']?.toString() ?? '',
      semesterId: json['semesterId']?.toString() ?? '',
      sectionId: json['sectionId']?.toString(),
      status: ResultLifecycleStatus.fromValue(json['status']?.toString()),
      calculationVersion: (json['calculationVersion'] as num?)?.toInt() ?? 1,
      summary: ResultSummaryModel.fromJson(
        Map<String, dynamic>.from((json['summary'] as Map?) ?? {}),
      ),
      subjectResults: rawSubjects
          .map((s) => SubjectResultModel.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      currentPublishedSnapshot: json['currentPublishedSnapshot'] != null
          ? PublicationSnapshotModel.fromJson(
              Map<String, dynamic>.from(json['currentPublishedSnapshot'] as Map),
            )
          : null,
      publicationHistory: rawPubHistory
          .map((p) => PublicationSnapshotModel.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      reopenHistory: rawReopenHistory
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList(),
      studentInfo: json['studentInfo'] != null
          ? Map<String, dynamic>.from(json['studentInfo'] as Map)
          : null,
      validationWarnings: rawWarnings.map((w) => w.toString()).toList(),
      reviewedBy: json['reviewedBy']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      finalizedBy: json['finalizedBy']?.toString(),
      finalizedAt: json['finalizedAt'] != null
          ? DateTime.tryParse(json['finalizedAt'].toString())
          : null,
      publishedBy: json['publishedBy']?.toString(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

/// Student-Visible Official Result Model (sanitized from currentPublishedSnapshot).
class StudentOfficialResultModel {
  final String semesterId;
  final String academicYearId;
  final String courseId;
  final String courseName;
  final String semesterName;
  final String academicYearName;
  final int version;
  final DateTime publishedAt;
  final ResultSummaryModel summary;
  final List<SubjectResultModel> subjectResults;

  const StudentOfficialResultModel({
    required this.semesterId,
    required this.academicYearId,
    required this.courseId,
    required this.courseName,
    required this.semesterName,
    required this.academicYearName,
    required this.version,
    required this.publishedAt,
    required this.summary,
    required this.subjectResults,
  });

  factory StudentOfficialResultModel.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjectResults'] as List<dynamic>? ?? [];
    return StudentOfficialResultModel(
      semesterId: json['semesterId']?.toString() ?? '',
      academicYearId: json['academicYearId']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? 'Academic Course',
      semesterName: json['semesterName']?.toString() ?? 'Semester',
      academicYearName: json['academicYearName']?.toString() ?? 'Academic Year',
      version: (json['version'] as num?)?.toInt() ?? 1,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      summary: ResultSummaryModel.fromJson(
        Map<String, dynamic>.from((json['summary'] as Map?) ?? {}),
      ),
      subjectResults: rawSubjects
          .map((s) => SubjectResultModel.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
}

/// Academic Rule Configuration models for UI display and validation inspection
class GradeScaleRuleModel {
  final double minPercentage;
  final double maxPercentage;
  final String grade;
  final double gradePoint;
  final String? description;

  const GradeScaleRuleModel({
    required this.minPercentage,
    required this.maxPercentage,
    required this.grade,
    required this.gradePoint,
    this.description,
  });

  factory GradeScaleRuleModel.fromJson(Map<String, dynamic> json) {
    return GradeScaleRuleModel(
      minPercentage: (json['minPercentage'] as num?)?.toDouble() ?? 0.0,
      maxPercentage: (json['maxPercentage'] as num?)?.toDouble() ?? 100.0,
      grade: json['grade']?.toString() ?? '',
      gradePoint: (json['gradePoint'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString(),
    );
  }
}
