enum AssignmentType {
  homework,
  labWork,
  quiz,
  project,
  other;

  String get label {
    switch (this) {
      case AssignmentType.homework:
        return 'Homework';
      case AssignmentType.labWork:
        return 'Lab Work';
      case AssignmentType.quiz:
        return 'Quiz';
      case AssignmentType.project:
        return 'Project';
      case AssignmentType.other:
        return 'Other';
    }
  }

  static AssignmentType fromString(String? val) {
    if (val == null) return AssignmentType.homework;
    final lower = val.trim().toLowerCase().replaceAll(' ', '_');
    switch (lower) {
      case 'lab_work':
      case 'labwork':
        return AssignmentType.labWork;
      case 'quiz':
        return AssignmentType.quiz;
      case 'project':
        return AssignmentType.project;
      case 'other':
        return AssignmentType.other;
      case 'homework':
      default:
        return AssignmentType.homework;
    }
  }
}

enum AssignmentStatus {
  draft,
  published,
  closed;

  String get label {
    switch (this) {
      case AssignmentStatus.draft:
        return 'Draft';
      case AssignmentStatus.published:
        return 'Published';
      case AssignmentStatus.closed:
        return 'Closed';
    }
  }

  static AssignmentStatus fromString(String? val) {
    if (val == null) return AssignmentStatus.draft;
    final upper = val.trim().toUpperCase();
    switch (upper) {
      case 'PUBLISHED':
        return AssignmentStatus.published;
      case 'CLOSED':
        return AssignmentStatus.closed;
      case 'DRAFT':
      default:
        return AssignmentStatus.draft;
    }
  }
}

enum StudentTaskStatus {
  pending,
  completed,
  overdue;

  String get label {
    switch (this) {
      case StudentTaskStatus.pending:
        return 'Pending';
      case StudentTaskStatus.completed:
        return 'Completed';
      case StudentTaskStatus.overdue:
        return 'Overdue';
    }
  }

  static StudentTaskStatus fromString(String? val) {
    if (val == null) return StudentTaskStatus.pending;
    final upper = val.trim().toUpperCase();
    switch (upper) {
      case 'COMPLETED':
        return StudentTaskStatus.completed;
      case 'OVERDUE':
        return StudentTaskStatus.overdue;
      case 'PENDING':
      default:
        return StudentTaskStatus.pending;
    }
  }
}

enum FacultyReviewStatus {
  notReviewed,
  reviewed;

  String get label {
    switch (this) {
      case FacultyReviewStatus.notReviewed:
        return 'Review Pending';
      case FacultyReviewStatus.reviewed:
        return 'Reviewed';
    }
  }

  static FacultyReviewStatus fromString(String? val) {
    if (val == null) return FacultyReviewStatus.notReviewed;
    final upper = val.trim().toUpperCase();
    switch (upper) {
      case 'REVIEWED':
        return FacultyReviewStatus.reviewed;
      case 'NOT_REVIEWED':
      default:
        return FacultyReviewStatus.notReviewed;
    }
  }
}

class AssignmentAttachmentModel {
  final String name;
  final String url;
  final String? fileType;
  final int? fileSize;

  const AssignmentAttachmentModel({
    required this.name,
    required this.url,
    this.fileType,
    this.fileSize,
  });

  factory AssignmentAttachmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachmentModel(
      name: json['name']?.toString() ?? 'Attachment',
      url: json['url']?.toString() ?? '',
      fileType: json['fileType']?.toString(),
      fileSize: json['fileSize'] is num ? (json['fileSize'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      if (fileType != null) 'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
    };
  }
}

class AssignmentModel {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String sectionId;
  final String subjectId;
  final String facultyId;
  final String? facultyAssignmentId;
  final String facultyName;
  final String title;
  final String description;
  final List<String> questions;
  final AssignmentType assignmentType;
  final String dueDate;
  final String dueTime;
  final DateTime dueDateTime;
  final int maximumMarks;
  final List<AssignmentAttachmentModel> attachments;
  final AssignmentStatus status;
  final DateTime? publishedAt;
  final DateTime? closedAt;
  final DateTime? createdAt;

  // Joined / UI Context
  final String? subjectName;
  final String? sectionName;
  final int? totalStudents;
  final int? completedCount;
  final int? pendingCount;

  // Student specific context
  final StudentTaskStatus? studentStatus;
  final DateTime? completedAt;
  final bool isLate;
  final FacultyReviewStatus? reviewStatus;
  final int? marks;

  const AssignmentModel({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.academicYearId,
    required this.semesterId,
    required this.sectionId,
    required this.subjectId,
    required this.facultyId,
    this.facultyAssignmentId,
    required this.facultyName,
    required this.title,
    required this.description,
    this.questions = const [],
    this.assignmentType = AssignmentType.homework,
    required this.dueDate,
    required this.dueTime,
    required this.dueDateTime,
    required this.maximumMarks,
    this.attachments = const [],
    this.status = AssignmentStatus.draft,
    this.publishedAt,
    this.closedAt,
    this.createdAt,
    this.subjectName,
    this.sectionName,
    this.totalStudents,
    this.completedCount,
    this.pendingCount,
    this.studentStatus,
    this.completedAt,
    this.isLate = false,
    this.reviewStatus,
    this.marks,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['assignmentId'] ?? json['_id'] ?? '';
    final rawQuestions = json['questions'];
    List<String> questionsList = [];
    if (rawQuestions is List) {
      questionsList = rawQuestions.map((q) => q.toString()).toList();
    }

    final rawAttachments = json['attachments'];
    List<AssignmentAttachmentModel> attachmentsList = [];
    if (rawAttachments is List) {
      attachmentsList = rawAttachments
          .whereType<Map<String, dynamic>>()
          .map((a) => AssignmentAttachmentModel.fromJson(a))
          .toList();
    }

    // Parse subject name
    String? subjectName;
    if (json['subjectId'] is Map && json['subjectId']['name'] != null) {
      subjectName = json['subjectId']['name'].toString();
    } else if (json['subjectName'] != null) {
      subjectName = json['subjectName'].toString();
    }

    // Parse section name
    String? sectionName;
    if (json['sectionId'] is Map && json['sectionId']['name'] != null) {
      sectionName = json['sectionId']['name'].toString();
    } else if (json['sectionName'] != null) {
      sectionName = json['sectionName'].toString();
    }

    final rawDueDateTime = json['dueDateTime'];
    DateTime dueDateTime;
    if (rawDueDateTime != null) {
      dueDateTime = DateTime.tryParse(rawDueDateTime.toString()) ?? DateTime.now();
    } else {
      dueDateTime = DateTime.now();
    }

    return AssignmentModel(
      id: rawId.toString(),
      collegeId: (json['collegeId'] is Map ? json['collegeId']['_id'] : json['collegeId'])?.toString() ?? '',
      departmentId: (json['departmentId'] is Map ? json['departmentId']['_id'] : json['departmentId'])?.toString() ?? '',
      courseId: (json['courseId'] is Map ? json['courseId']['_id'] : json['courseId'])?.toString() ?? '',
      academicYearId: (json['academicYearId'] is Map ? json['academicYearId']['_id'] : json['academicYearId'])?.toString() ?? '',
      semesterId: (json['semesterId'] is Map ? json['semesterId']['_id'] : json['semesterId'])?.toString() ?? '',
      sectionId: (json['sectionId'] is Map ? json['sectionId']['_id'] : json['sectionId'])?.toString() ?? '',
      subjectId: (json['subjectId'] is Map ? json['subjectId']['_id'] : json['subjectId'])?.toString() ?? '',
      facultyId: (json['facultyId'] is Map ? json['facultyId']['_id'] : json['facultyId'])?.toString() ?? '',
      facultyAssignmentId: json['facultyAssignmentId']?.toString(),
      facultyName: json['facultyName']?.toString() ?? 'Faculty',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      questions: questionsList,
      assignmentType: AssignmentType.fromString(json['assignmentType']?.toString()),
      dueDate: json['dueDate']?.toString() ?? '',
      dueTime: json['dueTime']?.toString() ?? '',
      dueDateTime: dueDateTime,
      maximumMarks: json['maximumMarks'] is num ? (json['maximumMarks'] as num).toInt() : 10,
      attachments: attachmentsList,
      status: AssignmentStatus.fromString(json['status']?.toString()),
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt'].toString()) : null,
      closedAt: json['closedAt'] != null ? DateTime.tryParse(json['closedAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      subjectName: subjectName,
      sectionName: sectionName,
      totalStudents: json['totalStudents'] is num ? (json['totalStudents'] as num).toInt() : null,
      completedCount: json['completedCount'] is num ? (json['completedCount'] as num).toInt() : null,
      pendingCount: json['pendingCount'] is num ? (json['pendingCount'] as num).toInt() : null,
      studentStatus: json['studentStatus'] != null ? StudentTaskStatus.fromString(json['studentStatus'].toString()) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      isLate: json['isLate'] == true,
      reviewStatus: json['reviewStatus'] != null ? FacultyReviewStatus.fromString(json['reviewStatus'].toString()) : null,
      marks: json['marks'] is num ? (json['marks'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'facultyId': facultyId,
      if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
      'facultyName': facultyName,
      'title': title,
      'description': description,
      'questions': questions,
      'assignmentType': assignmentType.label,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'dueDateTime': dueDateTime.toIso8601String(),
      'maximumMarks': maximumMarks,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'status': status.name.toUpperCase(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

class StudentAssignmentActivityModel {
  final String studentId;
  final String studentName;
  final String? rollNumber;
  final StudentTaskStatus status;
  final DateTime? completedAt;
  final bool isLate;
  final FacultyReviewStatus reviewStatus;
  final int? marks;
  final int maximumMarks;

  const StudentAssignmentActivityModel({
    required this.studentId,
    required this.studentName,
    this.rollNumber,
    required this.status,
    this.completedAt,
    this.isLate = false,
    required this.reviewStatus,
    this.marks,
    required this.maximumMarks,
  });

  factory StudentAssignmentActivityModel.fromJson(Map<String, dynamic> json, int maxMarks) {
    return StudentAssignmentActivityModel(
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Student',
      rollNumber: json['rollNumber']?.toString(),
      status: StudentTaskStatus.fromString(json['status']?.toString()),
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      isLate: json['isLate'] == true,
      reviewStatus: FacultyReviewStatus.fromString(json['reviewStatus']?.toString()),
      marks: json['marks'] is num ? (json['marks'] as num).toInt() : null,
      maximumMarks: json['maximumMarks'] is num ? (json['maximumMarks'] as num).toInt() : maxMarks,
    );
  }

  StudentAssignmentActivityModel copyWith({
    int? marks,
    FacultyReviewStatus? reviewStatus,
  }) {
    return StudentAssignmentActivityModel(
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      status: status,
      completedAt: completedAt,
      isLate: isLate,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      marks: marks ?? this.marks,
      maximumMarks: maximumMarks,
    );
  }
}

class AssignmentActivitySummaryModel {
  final int totalStudents;
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final int reviewedCount;
  final double? averageMarks;
  final int maximumMarks;

  const AssignmentActivitySummaryModel({
    required this.totalStudents,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.reviewedCount,
    this.averageMarks,
    required this.maximumMarks,
  });

  factory AssignmentActivitySummaryModel.fromJson(Map<String, dynamic> json) {
    return AssignmentActivitySummaryModel(
      totalStudents: json['totalStudents'] is num ? (json['totalStudents'] as num).toInt() : 0,
      completedCount: json['completedCount'] is num ? (json['completedCount'] as num).toInt() : 0,
      pendingCount: json['pendingCount'] is num ? (json['pendingCount'] as num).toInt() : 0,
      overdueCount: json['overdueCount'] is num ? (json['overdueCount'] as num).toInt() : 0,
      reviewedCount: json['reviewedCount'] is num ? (json['reviewedCount'] as num).toInt() : 0,
      averageMarks: json['averageMarks'] is num ? (json['averageMarks'] as num).toDouble() : null,
      maximumMarks: json['maximumMarks'] is num ? (json['maximumMarks'] as num).toInt() : 10,
    );
  }
}

class AssignmentActivityResponseModel {
  final AssignmentModel assignment;
  final AssignmentActivitySummaryModel summary;
  final List<StudentAssignmentActivityModel> completed;
  final List<StudentAssignmentActivityModel> pending;

  const AssignmentActivityResponseModel({
    required this.assignment,
    required this.summary,
    required this.completed,
    required this.pending,
  });

  factory AssignmentActivityResponseModel.fromJson(Map<String, dynamic> json) {
    final asgn = AssignmentModel.fromJson(json['assignment'] is Map<String, dynamic> ? json['assignment'] as Map<String, dynamic> : {});
    final summary = AssignmentActivitySummaryModel.fromJson(json['summary'] is Map<String, dynamic> ? json['summary'] as Map<String, dynamic> : {});
    
    final rawCompleted = json['completed'];
    List<StudentAssignmentActivityModel> completedList = [];
    if (rawCompleted is List) {
      completedList = rawCompleted
          .whereType<Map<String, dynamic>>()
          .map((c) => StudentAssignmentActivityModel.fromJson(c, asgn.maximumMarks))
          .toList();
    }

    final rawPending = json['pending'];
    List<StudentAssignmentActivityModel> pendingList = [];
    if (rawPending is List) {
      pendingList = rawPending
          .whereType<Map<String, dynamic>>()
          .map((p) => StudentAssignmentActivityModel.fromJson(p, asgn.maximumMarks))
          .toList();
    }

    return AssignmentActivityResponseModel(
      assignment: asgn,
      summary: summary,
      completed: completedList,
      pending: pendingList,
    );
  }
}
