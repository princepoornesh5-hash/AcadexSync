library;

/// Domain models for Department Attendance Analytics (Prompt 6 of 6)

class CourseBreakdownModel {
  final String courseId;
  final String courseName;
  final String courseCode;
  final int studentCount;
  final int sessionCount;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int atRiskCount;

  const CourseBreakdownModel({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.studentCount,
    required this.sessionCount,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.atRiskCount,
  });

  factory CourseBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CourseBreakdownModel(
      courseId: json['courseId']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SemesterBreakdownModel {
  final String semesterId;
  final int semesterNumber;
  final String? courseId;
  final int studentCount;
  final int sessionCount;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int atRiskCount;

  const SemesterBreakdownModel({
    required this.semesterId,
    required this.semesterNumber,
    this.courseId,
    required this.studentCount,
    required this.sessionCount,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.atRiskCount,
  });

  factory SemesterBreakdownModel.fromJson(Map<String, dynamic> json) {
    return SemesterBreakdownModel(
      semesterId: json['semesterId']?.toString() ?? '',
      semesterNumber: (json['semesterNumber'] as num?)?.toInt() ?? 0,
      courseId: json['courseId']?.toString(),
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SectionBreakdownModel {
  final String sectionId;
  final String sectionName;
  final String? courseId;
  final String? semesterId;
  final int studentCount;
  final int sessionCount;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int atRiskCount;

  const SectionBreakdownModel({
    required this.sectionId,
    required this.sectionName,
    this.courseId,
    this.semesterId,
    required this.studentCount,
    required this.sessionCount,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.atRiskCount,
  });

  factory SectionBreakdownModel.fromJson(Map<String, dynamic> json) {
    return SectionBreakdownModel(
      sectionId: json['sectionId']?.toString() ?? '',
      sectionName: json['sectionName']?.toString() ?? '',
      courseId: json['courseId']?.toString(),
      semesterId: json['semesterId']?.toString(),
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubjectBreakdownModel {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int sessionCount;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int atRiskCount;

  const SubjectBreakdownModel({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.sessionCount,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.atRiskCount,
  });

  factory SubjectBreakdownModel.fromJson(Map<String, dynamic> json) {
    return SubjectBreakdownModel(
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? '',
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DepartmentOverviewModel {
  final String collegeId;
  final String departmentId;
  final String departmentName;
  final double overallAttendancePercentage;
  final int totalStudents;
  final int totalSessions;
  final int totalRecords;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int medicalLeaveCount;
  final int onDutyCount;
  final int atRiskCount;
  final double atRiskThreshold;
  final List<CourseBreakdownModel> courseBreakdown;
  final List<SemesterBreakdownModel> semesterBreakdown;
  final List<SectionBreakdownModel> sectionBreakdown;
  final List<SubjectBreakdownModel> subjectBreakdown;

  const DepartmentOverviewModel({
    required this.collegeId,
    required this.departmentId,
    required this.departmentName,
    required this.overallAttendancePercentage,
    required this.totalStudents,
    required this.totalSessions,
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.medicalLeaveCount,
    required this.onDutyCount,
    required this.atRiskCount,
    required this.atRiskThreshold,
    required this.courseBreakdown,
    required this.semesterBreakdown,
    required this.sectionBreakdown,
    required this.subjectBreakdown,
  });

  factory DepartmentOverviewModel.fromJson(Map<String, dynamic> json) {
    return DepartmentOverviewModel(
      collegeId: json['collegeId']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? 'Department',
      overallAttendancePercentage: (json['overallAttendancePercentage'] as num?)?.toDouble() ?? 0.0,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excusedCount'] as num?)?.toInt() ?? 0,
      medicalLeaveCount: (json['medicalLeaveCount'] as num?)?.toInt() ?? 0,
      onDutyCount: (json['onDutyCount'] as num?)?.toInt() ?? 0,
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
      atRiskThreshold: (json['atRiskThreshold'] as num?)?.toDouble() ?? 75.0,
      courseBreakdown: (json['courseBreakdown'] as List<dynamic>?)
              ?.map((e) => CourseBreakdownModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      semesterBreakdown: (json['semesterBreakdown'] as List<dynamic>?)
              ?.map((e) => SemesterBreakdownModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sectionBreakdown: (json['sectionBreakdown'] as List<dynamic>?)
              ?.map((e) => SectionBreakdownModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subjectBreakdown: (json['subjectBreakdown'] as List<dynamic>?)
              ?.map((e) => SubjectBreakdownModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CourseAnalyticsModel {
  final String courseId;
  final String courseName;
  final String courseCode;
  final int studentCount;
  final int sessionCount;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int medicalLeave;
  final int onDuty;
  final int atRiskCount;

  const CourseAnalyticsModel({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.studentCount,
    required this.sessionCount,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.medicalLeave,
    required this.onDuty,
    required this.atRiskCount,
  });

  factory CourseAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return CourseAnalyticsModel(
      courseId: json['courseId']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
      medicalLeave: (json['medicalLeave'] as num?)?.toInt() ?? 0,
      onDuty: (json['onDuty'] as num?)?.toInt() ?? 0,
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SectionAnalyticsModel {
  final String sectionId;
  final String sectionName;
  final String? courseId;
  final String courseName;
  final String? semesterId;
  final int semesterNumber;
  final int enrolledStudents;
  final int totalSessions;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int medicalLeave;
  final int onDuty;
  final int atRiskStudents;

  const SectionAnalyticsModel({
    required this.sectionId,
    required this.sectionName,
    this.courseId,
    required this.courseName,
    this.semesterId,
    required this.semesterNumber,
    required this.enrolledStudents,
    required this.totalSessions,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.medicalLeave,
    required this.onDuty,
    required this.atRiskStudents,
  });

  factory SectionAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return SectionAnalyticsModel(
      sectionId: json['sectionId']?.toString() ?? '',
      sectionName: json['sectionName']?.toString() ?? '',
      courseId: json['courseId']?.toString(),
      courseName: json['courseName']?.toString() ?? '',
      semesterId: json['semesterId']?.toString(),
      semesterNumber: (json['semesterNumber'] as num?)?.toInt() ?? 0,
      enrolledStudents: (json['enrolledStudents'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
      medicalLeave: (json['medicalLeave'] as num?)?.toInt() ?? 0,
      onDuty: (json['onDuty'] as num?)?.toInt() ?? 0,
      atRiskStudents: (json['atRiskStudents'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubjectAnalyticsModel {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String? courseId;
  final String courseName;
  final String? semesterId;
  final int semesterNumber;
  final List<String> assignedSections;
  final int sessionCount;
  final double attendancePercentage;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int medicalLeave;
  final int onDuty;
  final int atRiskCount;

  const SubjectAnalyticsModel({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.courseId,
    required this.courseName,
    this.semesterId,
    required this.semesterNumber,
    required this.assignedSections,
    required this.sessionCount,
    required this.attendancePercentage,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.medicalLeave,
    required this.onDuty,
    required this.atRiskCount,
  });

  factory SubjectAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return SubjectAnalyticsModel(
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? '',
      courseId: json['courseId']?.toString(),
      courseName: json['courseName']?.toString() ?? '',
      semesterId: json['semesterId']?.toString(),
      semesterNumber: (json['semesterNumber'] as num?)?.toInt() ?? 0,
      assignedSections: (json['assignedSections'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
      medicalLeave: (json['medicalLeave'] as num?)?.toInt() ?? 0,
      onDuty: (json['onDuty'] as num?)?.toInt() ?? 0,
      atRiskCount: (json['atRiskCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudentAttendanceAnalyticsModel {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String admissionNumber;
  final String courseId;
  final String courseName;
  final String semesterId;
  final int semesterNumber;
  final String sectionId;
  final String sectionName;
  final double overallAttendancePercentage;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int medicalLeave;
  final int onDuty;
  final int sessionsConsidered;
  final bool isAtRisk;

  const StudentAttendanceAnalyticsModel({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.admissionNumber,
    required this.courseId,
    required this.courseName,
    required this.semesterId,
    required this.semesterNumber,
    required this.sectionId,
    required this.sectionName,
    required this.overallAttendancePercentage,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.medicalLeave,
    required this.onDuty,
    required this.sessionsConsidered,
    required this.isAtRisk,
  });

  factory StudentAttendanceAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceAnalyticsModel(
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      rollNumber: json['rollNumber']?.toString() ?? '',
      admissionNumber: json['admissionNumber']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      semesterId: json['semesterId']?.toString() ?? '',
      semesterNumber: (json['semesterNumber'] as num?)?.toInt() ?? 0,
      sectionId: json['sectionId']?.toString() ?? '',
      sectionName: json['sectionName']?.toString() ?? '',
      overallAttendancePercentage: (json['overallAttendancePercentage'] as num?)?.toDouble() ?? 0.0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
      medicalLeave: (json['medicalLeave'] as num?)?.toInt() ?? 0,
      onDuty: (json['onDuty'] as num?)?.toInt() ?? 0,
      sessionsConsidered: (json['sessionsConsidered'] as num?)?.toInt() ?? 0,
      isAtRisk: json['isAtRisk'] as bool? ?? false,
    );
  }
}

class DepartmentStudentsResult {
  final List<StudentAttendanceAnalyticsModel> students;
  final int total;
  final int page;
  final int limit;
  final double threshold;

  const DepartmentStudentsResult({
    required this.students,
    required this.total,
    required this.page,
    required this.limit,
    required this.threshold,
  });

  factory DepartmentStudentsResult.fromJson(Map<String, dynamic> json) {
    return DepartmentStudentsResult(
      students: (json['students'] as List<dynamic>?)
              ?.map((e) => StudentAttendanceAnalyticsModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 75.0,
    );
  }
}

class TrendAnalyticsModel {
  final String date;
  final String label;
  final int totalSessions;
  final int totalRecords;
  final int present;
  final int absent;
  final double attendancePercentage;

  const TrendAnalyticsModel({
    required this.date,
    required this.label,
    required this.totalSessions,
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.attendancePercentage,
  });

  factory TrendAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return TrendAnalyticsModel(
      date: json['date']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DepartmentAnalyticsFilter {
  final String? courseId;
  final String? academicYearId;
  final String? semesterId;
  final String? sectionId;
  final String? subjectId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool atRiskOnly;
  final String? search;
  final double atRiskThreshold;

  const DepartmentAnalyticsFilter({
    this.courseId,
    this.academicYearId,
    this.semesterId,
    this.sectionId,
    this.subjectId,
    this.startDate,
    this.endDate,
    this.atRiskOnly = false,
    this.search,
    this.atRiskThreshold = 75.0,
  });

  DepartmentAnalyticsFilter copyWith({
    String? Function()? courseId,
    String? Function()? academicYearId,
    String? Function()? semesterId,
    String? Function()? sectionId,
    String? Function()? subjectId,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    bool? atRiskOnly,
    String? Function()? search,
    double? atRiskThreshold,
  }) {
    return DepartmentAnalyticsFilter(
      courseId: courseId != null ? courseId() : this.courseId,
      academicYearId: academicYearId != null ? academicYearId() : this.academicYearId,
      semesterId: semesterId != null ? semesterId() : this.semesterId,
      sectionId: sectionId != null ? sectionId() : this.sectionId,
      subjectId: subjectId != null ? subjectId() : this.subjectId,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      atRiskOnly: atRiskOnly ?? this.atRiskOnly,
      search: search != null ? search() : this.search,
      atRiskThreshold: atRiskThreshold ?? this.atRiskThreshold,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (courseId != null && courseId!.isNotEmpty) params['courseId'] = courseId;
    if (academicYearId != null && academicYearId!.isNotEmpty) params['academicYearId'] = academicYearId;
    if (semesterId != null && semesterId!.isNotEmpty) params['semesterId'] = semesterId;
    if (sectionId != null && sectionId!.isNotEmpty) params['sectionId'] = sectionId;
    if (subjectId != null && subjectId!.isNotEmpty) params['subjectId'] = subjectId;
    if (startDate != null) params['startDate'] = startDate!.toIso8601String().split('T').first;
    if (endDate != null) params['endDate'] = endDate!.toIso8601String().split('T').first;
    if (atRiskOnly) params['atRiskOnly'] = 'true';
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (atRiskThreshold != 75.0) params['atRiskThreshold'] = atRiskThreshold;
    return params;
  }
}
