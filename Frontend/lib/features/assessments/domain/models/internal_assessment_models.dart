class AssessmentComponentModel {
  final String key;
  final String name;
  final double maxMarks;
  final double weightage;
  final bool isStudentVisible;

  const AssessmentComponentModel({
    required this.key,
    required this.name,
    required this.maxMarks,
    this.weightage = 0,
    this.isStudentVisible = true,
  });

  factory AssessmentComponentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentComponentModel(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      maxMarks: (json['maxMarks'] as num?)?.toDouble() ?? 10.0,
      weightage: (json['weightage'] as num?)?.toDouble() ?? 0.0,
      isStudentVisible: json['isStudentVisible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'maxMarks': maxMarks,
    'weightage': weightage,
    'isStudentVisible': isStudentVisible,
  };
}

enum StudentMarkStatus {
  notEntered('NOT_ENTERED', 'Not Entered'),
  entered('ENTERED', 'Entered'),
  present('PRESENT', 'Present'),
  absent('ABSENT', 'Absent'),
  exempted('EXEMPTED', 'Exempted'),
  notAppeared('NOT_APPEARED', 'Not Appeared'),
  excused('EXCUSED', 'Excused');

  final String value;
  final String label;
  const StudentMarkStatus(this.value, this.label);

  static StudentMarkStatus fromValue(String? val) {
    switch (val?.toUpperCase()) {
      case 'PRESENT':
        return StudentMarkStatus.present;
      case 'ENTERED':
        return StudentMarkStatus.entered;
      case 'ABSENT':
        return StudentMarkStatus.absent;
      case 'EXEMPTED':
        return StudentMarkStatus.exempted;
      case 'NOT_APPEARED':
        return StudentMarkStatus.notAppeared;
      case 'EXCUSED':
        return StudentMarkStatus.excused;
      case 'NOT_ENTERED':
      default:
        return StudentMarkStatus.notEntered;
    }
  }
}

class StudentAssessmentEntryModel {
  final String studentId;
  final String? studentEnrollmentId;
  final String studentName;
  final String? rollNumber;
  final String? admissionNumber;
  final Map<String, double?> componentMarks;
  final double? marks;
  final double totalMarks;
  final StudentMarkStatus status;
  final String? remarks;

  const StudentAssessmentEntryModel({
    required this.studentId,
    this.studentEnrollmentId,
    required this.studentName,
    this.rollNumber,
    this.admissionNumber,
    required this.componentMarks,
    this.marks,
    this.totalMarks = 0,
    this.status = StudentMarkStatus.notEntered,
    this.remarks,
  });

  factory StudentAssessmentEntryModel.fromJson(Map<String, dynamic> json) {
    final rawMarks = json['componentMarks'] as Map<String, dynamic>? ?? {};
    final marks = <String, double?>{};
    for (final entry in rawMarks.entries) {
      if (entry.value == null) {
        marks[entry.key] = null;
      } else if (entry.value is num) {
        marks[entry.key] = (entry.value as num).toDouble();
      } else {
        marks[entry.key] = double.tryParse(entry.value.toString());
      }
    }

    final singleMark =
        (json['marks'] as num?)?.toDouble() ??
        (json['obtainedMarks'] as num?)?.toDouble() ??
        (json['totalMarks'] as num?)?.toDouble();

    return StudentAssessmentEntryModel(
      studentId: json['studentId']?.toString() ?? '',
      studentEnrollmentId: json['studentEnrollmentId']?.toString(),
      studentName: json['studentName']?.toString() ?? 'Student',
      rollNumber: json['rollNumber']?.toString(),
      admissionNumber: json['admissionNumber']?.toString(),
      componentMarks: marks,
      marks: singleMark,
      totalMarks:
          (json['totalMarks'] as num?)?.toDouble() ?? (singleMark ?? 0.0),
      status: StudentMarkStatus.fromValue(json['status']?.toString()),
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    if (studentEnrollmentId != null) 'studentEnrollmentId': studentEnrollmentId,
    'studentName': studentName,
    'rollNumber': rollNumber,
    'admissionNumber': admissionNumber,
    'componentMarks': componentMarks,
    'marks': marks ?? totalMarks,
    'totalMarks': totalMarks,
    'status': status.value,
    'remarks': remarks,
  };

  StudentAssessmentEntryModel copyWith({
    String? studentId,
    String? studentEnrollmentId,
    String? studentName,
    String? rollNumber,
    String? admissionNumber,
    Map<String, double?>? componentMarks,
    double? marks,
    double? totalMarks,
    StudentMarkStatus? status,
    String? remarks,
  }) {
    return StudentAssessmentEntryModel(
      studentId: studentId ?? this.studentId,
      studentEnrollmentId: studentEnrollmentId ?? this.studentEnrollmentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      componentMarks: componentMarks ?? Map.from(this.componentMarks),
      marks: marks ?? this.marks,
      totalMarks: totalMarks ?? this.totalMarks,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }
}

class MarksRosterItemModel {
  final String studentEnrollmentId;
  final String studentId;
  final String studentName;
  final String? rollNumber;
  final String? admissionNumber;
  final double? marks;
  final double maximumMarks;
  final double passMarks;
  final StudentMarkStatus status;
  final String? remarks;
  final bool isLocked;
  final DateTime? lockedAt;

  const MarksRosterItemModel({
    required this.studentEnrollmentId,
    required this.studentId,
    required this.studentName,
    this.rollNumber,
    this.admissionNumber,
    this.marks,
    this.maximumMarks = 25,
    this.passMarks = 0,
    this.status = StudentMarkStatus.notEntered,
    this.remarks,
    this.isLocked = false,
    this.lockedAt,
  });

  factory MarksRosterItemModel.fromJson(Map<String, dynamic> json) {
    return MarksRosterItemModel(
      studentEnrollmentId: json['studentEnrollmentId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Student',
      rollNumber: json['rollNumber']?.toString(),
      admissionNumber: json['admissionNumber']?.toString(),
      marks: (json['marks'] as num?)?.toDouble(),
      maximumMarks: (json['maximumMarks'] as num?)?.toDouble() ?? 25.0,
      passMarks: (json['passMarks'] as num?)?.toDouble() ?? 0.0,
      status: StudentMarkStatus.fromValue(json['status']?.toString()),
      remarks: json['remarks']?.toString(),
      isLocked: json['isLocked'] as bool? ?? false,
      lockedAt: json['lockedAt'] != null
          ? DateTime.tryParse(json['lockedAt'].toString())
          : null,
    );
  }
}

class MarksRosterSummaryModel {
  final int totalStudents;
  final int enteredCount;
  final int presentCount;
  final int absentCount;
  final int exemptedCount;
  final int notAppearedCount;
  final int unresolvedCount;

  const MarksRosterSummaryModel({
    this.totalStudents = 0,
    this.enteredCount = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.exemptedCount = 0,
    this.notAppearedCount = 0,
    this.unresolvedCount = 0,
  });

  factory MarksRosterSummaryModel.fromJson(Map<String, dynamic> json) {
    return MarksRosterSummaryModel(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      enteredCount: (json['enteredCount'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      exemptedCount: (json['exemptedCount'] as num?)?.toInt() ?? 0,
      notAppearedCount: (json['notAppearedCount'] as num?)?.toInt() ?? 0,
      unresolvedCount: (json['unresolvedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MarksRosterResponseModel {
  final Map<String, dynamic> assessment;
  final MarksRosterSummaryModel summary;
  final List<MarksRosterItemModel> roster;

  const MarksRosterResponseModel({
    required this.assessment,
    required this.summary,
    required this.roster,
  });

  factory MarksRosterResponseModel.fromJson(Map<String, dynamic> json) {
    final rawRoster = json['roster'] as List? ?? [];
    return MarksRosterResponseModel(
      assessment: json['assessment'] is Map
          ? Map<String, dynamic>.from(json['assessment'] as Map)
          : {},
      summary: MarksRosterSummaryModel.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : {},
      ),
      roster: rawRoster
          .map(
            (r) => MarksRosterItemModel.fromJson(
              Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList(),
    );
  }
}

class AssessmentAuditEntryModel {
  final String action;
  final String? performedByName;
  final String? performedByRole;
  final DateTime timestamp;
  final String? details;
  final Map<String, dynamic>? previousValue;
  final Map<String, dynamic>? newValue;

  const AssessmentAuditEntryModel({
    required this.action,
    this.performedByName,
    this.performedByRole,
    required this.timestamp,
    this.details,
    this.previousValue,
    this.newValue,
  });

  factory AssessmentAuditEntryModel.fromJson(Map<String, dynamic> json) {
    return AssessmentAuditEntryModel(
      action: json['action']?.toString() ?? 'ACTION',
      performedByName: json['performedByName']?.toString(),
      performedByRole: json['performedByRole']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      details: json['details']?.toString(),
      previousValue: json['previousValue'] is Map
          ? Map<String, dynamic>.from(json['previousValue'] as Map)
          : null,
      newValue: json['newValue'] is Map
          ? Map<String, dynamic>.from(json['newValue'] as Map)
          : null,
    );
  }
}

enum InternalAssessmentStatus {
  draft('DRAFT', 'Draft'),
  scheduled('SCHEDULED', 'Scheduled'),
  completed('COMPLETED', 'Completed'),
  open('OPEN', 'Open for Entry'),
  marksEntry('MARKS_ENTRY', 'Marks Entry'),
  submitted('SUBMITTED', 'Submitted'),
  closed('CLOSED', 'Closed & Locked'),
  reviewed('REVIEWED', 'Reviewed'),
  published('PUBLISHED', 'Published & Locked'),
  locked('LOCKED', 'Locked'),
  archived('ARCHIVED', 'Archived');

  final String value;
  final String label;
  const InternalAssessmentStatus(this.value, this.label);

  static InternalAssessmentStatus fromValue(String? val) {
    switch (val?.toUpperCase()) {
      case 'SCHEDULED':
        return InternalAssessmentStatus.scheduled;
      case 'COMPLETED':
        return InternalAssessmentStatus.completed;
      case 'OPEN':
        return InternalAssessmentStatus.open;
      case 'MARKS_ENTRY':
        return InternalAssessmentStatus.marksEntry;
      case 'SUBMITTED':
        return InternalAssessmentStatus.submitted;
      case 'CLOSED':
        return InternalAssessmentStatus.closed;
      case 'REVIEWED':
        return InternalAssessmentStatus.reviewed;
      case 'PUBLISHED':
        return InternalAssessmentStatus.published;
      case 'LOCKED':
        return InternalAssessmentStatus.locked;
      case 'ARCHIVED':
        return InternalAssessmentStatus.archived;
      case 'DRAFT':
      default:
        return InternalAssessmentStatus.draft;
    }
  }
}

class AcademicScopeTargetModel {
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String? sectionId;
  final String? facultyAssignmentId;
  final String? departmentName;
  final String? sectionName;
  final int? semesterNumber;
  final int studentCount;

  const AcademicScopeTargetModel({
    required this.departmentId,
    required this.courseId,
    required this.academicYearId,
    required this.semesterId,
    this.sectionId,
    this.facultyAssignmentId,
    this.departmentName,
    this.sectionName,
    this.semesterNumber,
    this.studentCount = 0,
  });

  factory AcademicScopeTargetModel.fromJson(Map<String, dynamic> json) {
    return AcademicScopeTargetModel(
      departmentId: json['departmentId']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      academicYearId: json['academicYearId']?.toString() ?? '',
      semesterId: json['semesterId']?.toString() ?? '',
      sectionId: json['sectionId']?.toString(),
      facultyAssignmentId: json['facultyAssignmentId']?.toString(),
      departmentName: json['departmentName']?.toString(),
      sectionName: json['sectionName']?.toString(),
      semesterNumber: (json['semesterNumber'] as num?)?.toInt(),
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'departmentId': departmentId,
    'courseId': courseId,
    'academicYearId': academicYearId,
    'semesterId': semesterId,
    if (sectionId != null) 'sectionId': sectionId,
    if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
    if (departmentName != null) 'departmentName': departmentName,
    if (sectionName != null) 'sectionName': sectionName,
    if (semesterNumber != null) 'semesterNumber': semesterNumber,
    'studentCount': studentCount,
  };
}

class ScopePreviewStudentItem {
  final String studentEnrollmentId;
  final String studentId;
  final String name;
  final String? rollNumber;
  final String? departmentId;
  final String? sectionId;

  const ScopePreviewStudentItem({
    required this.studentEnrollmentId,
    required this.studentId,
    required this.name,
    this.rollNumber,
    this.departmentId,
    this.sectionId,
  });

  factory ScopePreviewStudentItem.fromJson(Map<String, dynamic> json) {
    return ScopePreviewStudentItem(
      studentEnrollmentId: json['studentEnrollmentId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Student',
      rollNumber: json['rollNumber']?.toString(),
      departmentId: json['departmentId']?.toString(),
      sectionId: json['sectionId']?.toString(),
    );
  }
}

class ScopePreviewBreakdownItem {
  final String departmentId;
  final String? sectionId;
  final int count;

  const ScopePreviewBreakdownItem({
    required this.departmentId,
    this.sectionId,
    required this.count,
  });

  factory ScopePreviewBreakdownItem.fromJson(Map<String, dynamic> json) {
    return ScopePreviewBreakdownItem(
      departmentId: json['departmentId']?.toString() ?? '',
      sectionId: json['sectionId']?.toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScopePreviewResponseModel {
  final int totalStudents;
  final int uniqueStudents;
  final int duplicateEnrollments;
  final List<ScopePreviewBreakdownItem> breakdown;
  final List<ScopePreviewStudentItem> students;

  const ScopePreviewResponseModel({
    required this.totalStudents,
    required this.uniqueStudents,
    required this.duplicateEnrollments,
    this.breakdown = const [],
    this.students = const [],
  });

  factory ScopePreviewResponseModel.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] as List? ?? [];
    final rawStudents = json['students'] as List? ?? [];
    return ScopePreviewResponseModel(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      uniqueStudents: (json['uniqueStudents'] as num?)?.toInt() ?? 0,
      duplicateEnrollments:
          (json['duplicateEnrollments'] as num?)?.toInt() ?? 0,
      breakdown: rawBreakdown
          .map(
            (b) => ScopePreviewBreakdownItem.fromJson(
              Map<String, dynamic>.from(b as Map),
            ),
          )
          .toList(),
      students: rawStudents
          .map(
            (s) => ScopePreviewStudentItem.fromJson(
              Map<String, dynamic>.from(s as Map),
            ),
          )
          .toList(),
    );
  }
}

class ScheduleConflictDetail {
  final String type;
  final String description;
  final String? conflictingAssessmentId;

  const ScheduleConflictDetail({
    required this.type,
    required this.description,
    this.conflictingAssessmentId,
  });

  factory ScheduleConflictDetail.fromJson(Map<String, dynamic> json) {
    return ScheduleConflictDetail(
      type: json['type']?.toString() ?? 'CONFLICT',
      description:
          json['description']?.toString() ??
          json['message']?.toString() ??
          'Conflict detected',
      conflictingAssessmentId: json['conflictingAssessmentId']?.toString(),
    );
  }
}

class ScheduleConflictReportModel {
  final bool hasConflict;
  final List<ScheduleConflictDetail> conflicts;

  const ScheduleConflictReportModel({
    required this.hasConflict,
    this.conflicts = const [],
  });

  factory ScheduleConflictReportModel.fromJson(Map<String, dynamic> json) {
    final rawConflicts = json['conflicts'] as List? ?? [];
    return ScheduleConflictReportModel(
      hasConflict: json['hasConflict'] as bool? ?? rawConflicts.isNotEmpty,
      conflicts: rawConflicts
          .map(
            (c) => ScheduleConflictDetail.fromJson(
              Map<String, dynamic>.from(c as Map),
            ),
          )
          .toList(),
    );
  }
}

class InternalAssessmentModel {
  final String? id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String semesterId;
  final String? sectionId;
  final String subjectId;
  final String? facultyAssignmentId;
  final String? facultyName;
  final List<AcademicScopeTargetModel> academicScopes;
  final bool isCommonExam;
  final bool isPublishedToStudents;
  final String title;
  final String assessmentType;
  final double maximumMarks;
  final DateTime? assessmentDate;
  final Map<String, dynamic>? schedule;
  final List<AssessmentComponentModel> components;
  final List<StudentAssessmentEntryModel> entries;
  final InternalAssessmentStatus status;
  final String? sourceType;
  final String? importBatchId;
  final DateTime? publishedAt;
  final DateTime? lockedAt;
  final DateTime? closedAt;
  final List<AssessmentAuditEntryModel> auditLog;

  const InternalAssessmentModel({
    this.id,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.semesterId,
    this.sectionId,
    required this.subjectId,
    this.facultyAssignmentId,
    this.facultyName,
    this.academicScopes = const [],
    this.isCommonExam = false,
    this.isPublishedToStudents = false,
    required this.title,
    this.assessmentType = 'INTERNAL_EXAM',
    this.maximumMarks = 50.0,
    this.assessmentDate,
    this.schedule,
    this.components = const [],
    this.entries = const [],
    this.status = InternalAssessmentStatus.draft,
    this.sourceType,
    this.importBatchId,
    this.publishedAt,
    this.lockedAt,
    this.closedAt,
    this.auditLog = const [],
  });

  factory InternalAssessmentModel.fromJson(Map<String, dynamic> json) {
    final rawComps = json['components'] as List? ?? [];
    final comps = rawComps
        .map(
          (c) => AssessmentComponentModel.fromJson(
            Map<String, dynamic>.from(c as Map),
          ),
        )
        .toList();

    final rawEntries = json['entries'] as List? ?? [];
    final entries = rawEntries
        .map(
          (e) => StudentAssessmentEntryModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();

    final rawAudit = json['auditLog'] as List? ?? [];
    final audit = rawAudit
        .map(
          (a) => AssessmentAuditEntryModel.fromJson(
            Map<String, dynamic>.from(a as Map),
          ),
        )
        .toList();

    final rawScopes = json['academicScopes'] as List? ?? [];
    final scopes = rawScopes
        .map(
          (s) => AcademicScopeTargetModel.fromJson(
            Map<String, dynamic>.from(s as Map),
          ),
        )
        .toList();

    return InternalAssessmentModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      collegeId: json['collegeId']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      semesterId: json['semesterId']?.toString() ?? '',
      sectionId: json['sectionId']?.toString(),
      subjectId: json['subjectId']?.toString() ?? '',
      facultyAssignmentId: json['facultyAssignmentId']?.toString(),
      facultyName: json['facultyName']?.toString(),
      academicScopes: scopes,
      isCommonExam: json['isCommonExam'] as bool? ?? scopes.isNotEmpty,
      isPublishedToStudents: json['isPublishedToStudents'] as bool? ?? false,
      title: json['title']?.toString() ?? 'Internal Assessment',
      assessmentType: json['assessmentType']?.toString() ?? 'INTERNAL_EXAM',
      maximumMarks: (json['maximumMarks'] as num?)?.toDouble() ?? 50.0,
      assessmentDate: json['assessmentDate'] != null
          ? DateTime.tryParse(json['assessmentDate'].toString())
          : null,
      schedule: json['schedule'] is Map
          ? Map<String, dynamic>.from(json['schedule'] as Map)
          : null,
      components: comps,
      entries: entries,
      status: InternalAssessmentStatus.fromValue(json['status']?.toString()),
      sourceType: json['sourceType']?.toString(),
      importBatchId: json['importBatchId']?.toString(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      lockedAt: json['lockedAt'] != null
          ? DateTime.tryParse(json['lockedAt'].toString())
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      auditLog: audit,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'collegeId': collegeId,
    'departmentId': departmentId,
    'courseId': courseId,
    'semesterId': semesterId,
    if (sectionId != null) 'sectionId': sectionId,
    'subjectId': subjectId,
    if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
    if (facultyName != null) 'facultyName': facultyName,
    'academicScopes': academicScopes.map((s) => s.toJson()).toList(),
    'isCommonExam': isCommonExam,
    'isPublishedToStudents': isPublishedToStudents,
    'title': title,
    'assessmentType': assessmentType,
    'maximumMarks': maximumMarks,
    if (assessmentDate != null)
      'assessmentDate': assessmentDate!.toIso8601String(),
    if (schedule != null) 'schedule': schedule,
    'components': components.map((c) => c.toJson()).toList(),
    'status': status.value,
  };
}

class AssessmentContextModel {
  final InternalAssessmentModel? assessment;
  final Map<String, dynamic> subject;
  final Map<String, dynamic> section;
  final Map<String, dynamic>? facultyAssignment;
  final List<AssessmentComponentModel> components;
  final bool isLocked;
  final Map<String, dynamic>? gradingConfig;

  const AssessmentContextModel({
    this.assessment,
    required this.subject,
    required this.section,
    this.facultyAssignment,
    this.components = const [],
    this.isLocked = false,
    this.gradingConfig,
  });

  factory AssessmentContextModel.fromJson(Map<String, dynamic> json) {
    InternalAssessmentModel? assessment;
    if (json['assessment'] != null && json['assessment'] is Map) {
      assessment = InternalAssessmentModel.fromJson(
        Map<String, dynamic>.from(json['assessment'] as Map),
      );
    }

    final rawComps = json['components'] as List? ?? [];
    final comps = rawComps
        .map(
          (c) => AssessmentComponentModel.fromJson(
            Map<String, dynamic>.from(c as Map),
          ),
        )
        .toList();

    return AssessmentContextModel(
      assessment: assessment,
      subject: json['subject'] != null
          ? Map<String, dynamic>.from(json['subject'] as Map)
          : {},
      section: json['section'] != null
          ? Map<String, dynamic>.from(json['section'] as Map)
          : {},
      facultyAssignment: json['facultyAssignment'] != null
          ? Map<String, dynamic>.from(json['facultyAssignment'] as Map)
          : null,
      components: comps,
      isLocked:
          json['isLocked'] as bool? ??
          (assessment?.status == InternalAssessmentStatus.published ||
              assessment?.status == InternalAssessmentStatus.closed),
      gradingConfig: json['gradingConfig'] != null
          ? Map<String, dynamic>.from(json['gradingConfig'] as Map)
          : null,
    );
  }
}

class StudentPublishedMarksItem {
  final String id;
  final Map<String, dynamic> subject;
  final Map<String, dynamic>? section;
  final Map<String, dynamic>? semester;
  final DateTime? publishedAt;
  final List<AssessmentComponentModel> components;
  final Map<String, double?> marks;
  final double totalMarks;
  final StudentMarkStatus status;
  final String? remarks;

  const StudentPublishedMarksItem({
    required this.id,
    required this.subject,
    this.section,
    this.semester,
    this.publishedAt,
    this.components = const [],
    this.marks = const {},
    this.totalMarks = 0,
    this.status = StudentMarkStatus.entered,
    this.remarks,
  });

  factory StudentPublishedMarksItem.fromJson(Map<String, dynamic> json) {
    final rawComps = json['components'] as List? ?? [];
    final comps = rawComps
        .map(
          (c) => AssessmentComponentModel.fromJson(
            Map<String, dynamic>.from(c as Map),
          ),
        )
        .toList();

    final rawMarks = json['marks'] as Map<String, dynamic>? ?? {};
    final marks = <String, double?>{};
    for (final e in rawMarks.entries) {
      if (e.value == null) {
        marks[e.key] = null;
      } else if (e.value is num) {
        marks[e.key] = (e.value as num).toDouble();
      } else {
        marks[e.key] = double.tryParse(e.value.toString());
      }
    }

    return StudentPublishedMarksItem(
      id: json['id']?.toString() ?? '',
      subject: json['subject'] != null
          ? Map<String, dynamic>.from(json['subject'] as Map)
          : {},
      section: json['section'] != null
          ? Map<String, dynamic>.from(json['section'] as Map)
          : null,
      semester: json['semester'] != null
          ? Map<String, dynamic>.from(json['semester'] as Map)
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      components: comps,
      marks: marks,
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0.0,
      status: StudentMarkStatus.fromValue(json['status']?.toString()),
      remarks: json['remarks']?.toString(),
    );
  }
}

class SubjectAssessmentItemSummary {
  final String assessmentId;
  final String title;
  final String type;
  final double maxMarks;
  final double? obtainedMarks;
  final StudentMarkStatus? status;

  const SubjectAssessmentItemSummary({
    required this.assessmentId,
    required this.title,
    required this.type,
    required this.maxMarks,
    this.obtainedMarks,
    this.status,
  });

  factory SubjectAssessmentItemSummary.fromJson(Map<String, dynamic> json) {
    return SubjectAssessmentItemSummary(
      assessmentId: json['assessmentId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'INTERNAL_EXAM',
      maxMarks: (json['maxMarks'] as num?)?.toDouble() ?? 50.0,
      obtainedMarks: (json['obtainedMarks'] as num?)?.toDouble(),
      status: json['status'] != null
          ? StudentMarkStatus.fromValue(json['status'].toString())
          : null,
    );
  }
}

class SubjectAssessmentSummaryModel {
  final String subjectId;
  final String semesterId;
  final String? studentId;
  final int totalAssessments;
  final int publishedAssessments;
  final double totalMaxMarks;
  final double totalObtainedMarks;
  final double percentage;
  final List<SubjectAssessmentItemSummary> assessments;

  const SubjectAssessmentSummaryModel({
    required this.subjectId,
    required this.semesterId,
    this.studentId,
    required this.totalAssessments,
    required this.publishedAssessments,
    required this.totalMaxMarks,
    required this.totalObtainedMarks,
    required this.percentage,
    this.assessments = const [],
  });

  factory SubjectAssessmentSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawAssessments = json['assessments'] as List? ?? [];
    final items = rawAssessments
        .map(
          (a) => SubjectAssessmentItemSummary.fromJson(
            Map<String, dynamic>.from(a as Map),
          ),
        )
        .toList();

    return SubjectAssessmentSummaryModel(
      subjectId: json['subjectId']?.toString() ?? '',
      semesterId: json['semesterId']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      totalAssessments: (json['totalAssessments'] as num?)?.toInt() ?? 0,
      publishedAssessments:
          (json['publishedAssessments'] as num?)?.toInt() ?? 0,
      totalMaxMarks: (json['totalMaxMarks'] as num?)?.toDouble() ?? 0.0,
      totalObtainedMarks:
          (json['totalObtainedMarks'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      assessments: items,
    );
  }
}

class AssessmentScheduleModel {
  final String? id;
  final String collegeId;
  final String assessmentId;
  final DateTime date;
  final String dateString;
  final String startTime;
  final String endTime;
  final String? roomId;
  final String? roomName;
  final String? invigilatorFacultyId;
  final String? invigilatorName;
  final String? instructions;
  final String status;
  final List<String> targetSectionIds;
  final List<String> targetDepartmentIds;

  const AssessmentScheduleModel({
    this.id,
    required this.collegeId,
    required this.assessmentId,
    required this.date,
    required this.dateString,
    required this.startTime,
    required this.endTime,
    this.roomId,
    this.roomName,
    this.invigilatorFacultyId,
    this.invigilatorName,
    this.instructions,
    this.status = 'SCHEDULED',
    this.targetSectionIds = const [],
    this.targetDepartmentIds = const [],
  });

  factory AssessmentScheduleModel.fromJson(Map<String, dynamic> json) {
    final rawSecs = json['targetSectionIds'] as List? ?? [];
    final secIds = rawSecs
        .map((s) => s is Map ? s['_id']?.toString() ?? '' : s.toString())
        .toList();
    final rawDepts = json['targetDepartmentIds'] as List? ?? [];
    final deptIds = rawDepts
        .map((d) => d is Map ? d['_id']?.toString() ?? '' : d.toString())
        .toList();

    return AssessmentScheduleModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      collegeId: json['collegeId']?.toString() ?? '',
      assessmentId: json['assessmentId'] is Map
          ? (json['assessmentId']['_id']?.toString() ?? '')
          : (json['assessmentId']?.toString() ?? ''),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dateString: json['dateString']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      roomId: json['roomId'] is Map
          ? (json['roomId']['_id']?.toString() ?? '')
          : json['roomId']?.toString(),
      roomName: json['roomId'] is Map
          ? json['roomId']['name']?.toString()
          : null,
      invigilatorFacultyId: json['invigilatorFacultyId'] is Map
          ? (json['invigilatorFacultyId']['_id']?.toString() ?? '')
          : json['invigilatorFacultyId']?.toString(),
      invigilatorName: json['invigilatorFacultyId'] is Map
          ? json['invigilatorFacultyId']['name']?.toString()
          : null,
      instructions: json['instructions']?.toString(),
      status: json['status']?.toString() ?? 'SCHEDULED',
      targetSectionIds: secIds,
      targetDepartmentIds: deptIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'assessmentId': assessmentId,
    'date': date.toIso8601String(),
    'dateString': dateString,
    'startTime': startTime,
    'endTime': endTime,
    if (roomId != null) 'roomId': roomId,
    if (invigilatorFacultyId != null)
      'invigilatorFacultyId': invigilatorFacultyId,
    if (instructions != null) 'instructions': instructions,
    'targetSectionIds': targetSectionIds,
    'targetDepartmentIds': targetDepartmentIds,
  };
}

class AssessmentMarkModel {
  final String? id;
  final String collegeId;
  final String assessmentId;
  final String? facultyAssignmentId;
  final String subjectId;
  final String studentEnrollmentId;
  final String studentId;
  final String studentName;
  final String? rollNumber;
  final String? admissionNumber;
  final double? marks;
  final double maximumMarks;
  final double? passMarks;
  final StudentMarkStatus status;
  final String? remarks;
  final bool isLocked;
  final String sourceType;

  const AssessmentMarkModel({
    this.id,
    required this.collegeId,
    required this.assessmentId,
    this.facultyAssignmentId,
    required this.subjectId,
    required this.studentEnrollmentId,
    required this.studentId,
    required this.studentName,
    this.rollNumber,
    this.admissionNumber,
    this.marks,
    required this.maximumMarks,
    this.passMarks,
    required this.status,
    this.remarks,
    this.isLocked = false,
    this.sourceType = 'LIVE',
  });

  factory AssessmentMarkModel.fromJson(Map<String, dynamic> json) {
    return AssessmentMarkModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      collegeId: json['collegeId']?.toString() ?? '',
      assessmentId: json['assessmentId']?.toString() ?? '',
      facultyAssignmentId: json['facultyAssignmentId']?.toString(),
      subjectId: json['subjectId']?.toString() ?? '',
      studentEnrollmentId: json['studentEnrollmentId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Student',
      rollNumber: json['rollNumber']?.toString(),
      admissionNumber: json['admissionNumber']?.toString(),
      marks: (json['marks'] as num?)?.toDouble(),
      maximumMarks: (json['maximumMarks'] as num?)?.toDouble() ?? 100.0,
      passMarks: (json['passMarks'] as num?)?.toDouble(),
      status: StudentMarkStatus.fromValue(json['status']?.toString()),
      remarks: json['remarks']?.toString(),
      isLocked: json['isLocked'] as bool? ?? false,
      sourceType: json['sourceType']?.toString() ?? 'LIVE',
    );
  }
}

typedef AssessmentModel = InternalAssessmentModel;
typedef AssessmentStatus = InternalAssessmentStatus;
