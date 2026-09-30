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
  absent('ABSENT', 'Absent'),
  excused('EXCUSED', 'Excused');

  final String value;
  final String label;
  const StudentMarkStatus(this.value, this.label);

  static StudentMarkStatus fromValue(String? val) {
    switch (val?.toUpperCase()) {
      case 'ENTERED':
        return StudentMarkStatus.entered;
      case 'ABSENT':
        return StudentMarkStatus.absent;
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
  final String studentName;
  final String? rollNumber;
  final String? admissionNumber;
  final Map<String, double?> componentMarks;
  final double totalMarks;
  final StudentMarkStatus status;
  final String? remarks;

  const StudentAssessmentEntryModel({
    required this.studentId,
    required this.studentName,
    this.rollNumber,
    this.admissionNumber,
    required this.componentMarks,
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

    return StudentAssessmentEntryModel(
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Student',
      rollNumber: json['rollNumber']?.toString(),
      admissionNumber: json['admissionNumber']?.toString(),
      componentMarks: marks,
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0.0,
      status: StudentMarkStatus.fromValue(json['status']?.toString()),
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'rollNumber': rollNumber,
    'admissionNumber': admissionNumber,
    'componentMarks': componentMarks,
    'totalMarks': totalMarks,
    'status': status.value,
    'remarks': remarks,
  };

  StudentAssessmentEntryModel copyWith({
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? admissionNumber,
    Map<String, double?>? componentMarks,
    double? totalMarks,
    StudentMarkStatus? status,
    String? remarks,
  }) {
    return StudentAssessmentEntryModel(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      componentMarks: componentMarks ?? Map.from(this.componentMarks),
      totalMarks: totalMarks ?? this.totalMarks,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
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
      previousValue: json['previousValue'] is Map ? Map<String, dynamic>.from(json['previousValue'] as Map) : null,
      newValue: json['newValue'] is Map ? Map<String, dynamic>.from(json['newValue'] as Map) : null,
    );
  }
}

enum InternalAssessmentStatus {
  draft('DRAFT', 'Draft'),
  open('OPEN', 'Open for Entry'),
  closed('CLOSED', 'Closed & Locked'),
  reviewed('REVIEWED', 'Reviewed'),
  published('PUBLISHED', 'Published & Locked'),
  archived('ARCHIVED', 'Archived');

  final String value;
  final String label;
  const InternalAssessmentStatus(this.value, this.label);

  static InternalAssessmentStatus fromValue(String? val) {
    switch (val?.toUpperCase()) {
      case 'OPEN':
        return InternalAssessmentStatus.open;
      case 'CLOSED':
        return InternalAssessmentStatus.closed;
      case 'REVIEWED':
        return InternalAssessmentStatus.reviewed;
      case 'PUBLISHED':
        return InternalAssessmentStatus.published;
      case 'ARCHIVED':
        return InternalAssessmentStatus.archived;
      case 'DRAFT':
      default:
        return InternalAssessmentStatus.draft;
    }
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
  final String title;
  final String assessmentType;
  final double maximumMarks;
  final DateTime? assessmentDate;
  final List<AssessmentComponentModel> components;
  final List<StudentAssessmentEntryModel> entries;
  final InternalAssessmentStatus status;
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
    required this.title,
    this.assessmentType = 'INTERNAL_EXAM',
    this.maximumMarks = 50.0,
    this.assessmentDate,
    this.components = const [],
    this.entries = const [],
    this.status = InternalAssessmentStatus.draft,
    this.publishedAt,
    this.lockedAt,
    this.closedAt,
    this.auditLog = const [],
  });

  factory InternalAssessmentModel.fromJson(Map<String, dynamic> json) {
    final rawComps = json['components'] as List? ?? [];
    final comps = rawComps
        .map((c) => AssessmentComponentModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    final rawEntries = json['entries'] as List? ?? [];
    final entries = rawEntries
        .map((e) => StudentAssessmentEntryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawAudit = json['auditLog'] as List? ?? [];
    final audit = rawAudit
        .map((a) => AssessmentAuditEntryModel.fromJson(Map<String, dynamic>.from(a as Map)))
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
      title: json['title']?.toString() ?? 'Internal Assessment',
      assessmentType: json['assessmentType']?.toString() ?? 'INTERNAL_EXAM',
      maximumMarks: (json['maximumMarks'] as num?)?.toDouble() ?? 50.0,
      assessmentDate: json['assessmentDate'] != null
          ? DateTime.tryParse(json['assessmentDate'].toString())
          : null,
      components: comps,
      entries: entries,
      status: InternalAssessmentStatus.fromValue(json['status']?.toString()),
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
        .map((c) => AssessmentComponentModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    return AssessmentContextModel(
      assessment: assessment,
      subject: json['subject'] != null ? Map<String, dynamic>.from(json['subject'] as Map) : {},
      section: json['section'] != null ? Map<String, dynamic>.from(json['section'] as Map) : {},
      facultyAssignment: json['facultyAssignment'] != null
          ? Map<String, dynamic>.from(json['facultyAssignment'] as Map)
          : null,
      components: comps,
      isLocked: json['isLocked'] as bool? ?? (assessment?.status == InternalAssessmentStatus.published || assessment?.status == InternalAssessmentStatus.closed),
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
        .map((c) => AssessmentComponentModel.fromJson(Map<String, dynamic>.from(c as Map)))
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
      subject: json['subject'] != null ? Map<String, dynamic>.from(json['subject'] as Map) : {},
      section: json['section'] != null ? Map<String, dynamic>.from(json['section'] as Map) : null,
      semester: json['semester'] != null ? Map<String, dynamic>.from(json['semester'] as Map) : null,
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
      status: json['status'] != null ? StudentMarkStatus.fromValue(json['status'].toString()) : null,
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
        .map((a) => SubjectAssessmentItemSummary.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    return SubjectAssessmentSummaryModel(
      subjectId: json['subjectId']?.toString() ?? '',
      semesterId: json['semesterId']?.toString() ?? '',
      studentId: json['studentId']?.toString(),
      totalAssessments: (json['totalAssessments'] as num?)?.toInt() ?? 0,
      publishedAssessments: (json['publishedAssessments'] as num?)?.toInt() ?? 0,
      totalMaxMarks: (json['totalMaxMarks'] as num?)?.toDouble() ?? 0.0,
      totalObtainedMarks: (json['totalObtainedMarks'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      assessments: items,
    );
  }
}
