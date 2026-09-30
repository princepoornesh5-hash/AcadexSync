import 'package:flutter/foundation.dart';

@immutable
class DashboardGreetingModel {
  final String displayName;
  final String role;
  final String? avatarUrl;
  final String greetingText;

  const DashboardGreetingModel({
    required this.displayName,
    required this.role,
    this.avatarUrl,
    required this.greetingText,
  });

  factory DashboardGreetingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const DashboardGreetingModel(
        displayName: 'User',
        role: 'STUDENT',
        greetingText: 'Welcome',
      );
    }
    return DashboardGreetingModel(
      displayName: json['displayName'] as String? ?? 'User',
      role: json['role'] as String? ?? 'STUDENT',
      avatarUrl: json['avatarUrl'] as String?,
      greetingText: json['greetingText'] as String? ?? 'Welcome',
    );
  }
}

@immutable
class DashboardContextModel {
  // Student Context
  final bool isEnrollmentAvailable;
  final String? enrollmentId;
  final String? courseId;
  final String? courseName;
  final String? courseCode;
  final String? semesterId;
  final String? semesterName;
  final int? semesterNumber;
  final String? sectionId;
  final String? sectionName;
  final String? academicStage;
  final String? rollNumber;

  // Faculty Context
  final String? facultyId;
  final String? departmentId;
  final String? departmentName;
  final String? designation;
  final String? employeeId;
  final int activeTeachingAssignmentsCount;

  // HOD Context
  final String? departmentCode;
  final String? managedScope;

  // College Admin Context
  final String? collegeId;
  final String? collegeName;
  final String? collegeCode;
  final String? administrativeScope;

  // Super Admin Context
  final String? scope;

  const DashboardContextModel({
    this.isEnrollmentAvailable = false,
    this.enrollmentId,
    this.courseId,
    this.courseName,
    this.courseCode,
    this.semesterId,
    this.semesterName,
    this.semesterNumber,
    this.sectionId,
    this.sectionName,
    this.academicStage,
    this.rollNumber,
    this.facultyId,
    this.departmentId,
    this.departmentName,
    this.designation,
    this.employeeId,
    this.activeTeachingAssignmentsCount = 0,
    this.departmentCode,
    this.managedScope,
    this.collegeId,
    this.collegeName,
    this.collegeCode,
    this.administrativeScope,
    this.scope,
  });

  factory DashboardContextModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DashboardContextModel();

    return DashboardContextModel(
      isEnrollmentAvailable: json['isEnrollmentAvailable'] as bool? ?? false,
      enrollmentId: json['enrollmentId'] as String?,
      courseId: json['courseId'] as String?,
      courseName: json['courseName'] as String?,
      courseCode: json['courseCode'] as String?,
      semesterId: json['semesterId'] as String?,
      semesterName: json['semesterName'] as String?,
      semesterNumber: json['semesterNumber'] as int?,
      sectionId: json['sectionId'] as String?,
      sectionName: json['sectionName'] as String?,
      academicStage: json['academicStage'] as String?,
      rollNumber: json['rollNumber'] as String?,
      facultyId: json['facultyId'] as String?,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      designation: json['designation'] as String?,
      employeeId: json['employeeId'] as String?,
      activeTeachingAssignmentsCount: (json['activeTeachingAssignmentsCount'] as num?)?.toInt() ?? 0,
      departmentCode: json['departmentCode'] as String?,
      managedScope: json['managedScope'] as String?,
      collegeId: json['collegeId'] as String?,
      collegeName: json['collegeName'] as String?,
      collegeCode: json['collegeCode'] as String?,
      administrativeScope: json['administrativeScope'] as String?,
      scope: json['scope'] as String?,
    );
  }
}

@immutable
class DashboardSummaryModel {
  // Student
  final double? attendancePercentage;
  final int assignmentsCompleted;
  final int assignmentsPending;
  final int practicalsCompleted;
  final int practicalsScheduled;
  final int publishedAssessmentsCount;
  final String? latestResultStatus;

  // Faculty
  final int assignedClassesCount;
  final int pendingAttendanceSessions;
  final int submissionsAwaitingReview;
  final int pendingAssessmentMarks;
  final int openPracticalsCount;

  // HOD
  final int activeFacultyCount;
  final int activeStudentsCount;
  final int todayClassesCount;
  final int pendingDepartmentRequests;
  final int pendingAssessmentsCount;
  final int pendingAttendanceCount;

  // College Admin
  final int departmentsCount;
  final int facultyCount;
  final int studentsCount;
  final int pendingRequestsCount;
  final int activeAnnouncementsCount;
  final int activeAcademicYearsCount;

  // Super Admin
  final int collegesCount;
  final int usersCount;
  final int activeCollegesCount;
  final String systemStatus;

  const DashboardSummaryModel({
    this.attendancePercentage,
    this.assignmentsCompleted = 0,
    this.assignmentsPending = 0,
    this.practicalsCompleted = 0,
    this.practicalsScheduled = 0,
    this.publishedAssessmentsCount = 0,
    this.latestResultStatus,
    this.assignedClassesCount = 0,
    this.pendingAttendanceSessions = 0,
    this.submissionsAwaitingReview = 0,
    this.pendingAssessmentMarks = 0,
    this.openPracticalsCount = 0,
    this.activeFacultyCount = 0,
    this.activeStudentsCount = 0,
    this.todayClassesCount = 0,
    this.pendingDepartmentRequests = 0,
    this.pendingAssessmentsCount = 0,
    this.pendingAttendanceCount = 0,
    this.departmentsCount = 0,
    this.facultyCount = 0,
    this.studentsCount = 0,
    this.pendingRequestsCount = 0,
    this.activeAnnouncementsCount = 0,
    this.activeAcademicYearsCount = 0,
    this.collegesCount = 0,
    this.usersCount = 0,
    this.activeCollegesCount = 0,
    this.systemStatus = 'OPERATIONAL',
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DashboardSummaryModel();

    return DashboardSummaryModel(
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble(),
      assignmentsCompleted: (json['assignmentsCompleted'] as num?)?.toInt() ?? 0,
      assignmentsPending: (json['assignmentsPending'] as num?)?.toInt() ?? 0,
      practicalsCompleted: (json['practicalsCompleted'] as num?)?.toInt() ?? 0,
      practicalsScheduled: (json['practicalsScheduled'] as num?)?.toInt() ?? 0,
      publishedAssessmentsCount: (json['publishedAssessmentsCount'] as num?)?.toInt() ?? 0,
      latestResultStatus: json['latestResultStatus'] as String?,
      assignedClassesCount: (json['assignedClassesCount'] as num?)?.toInt() ?? 0,
      pendingAttendanceSessions: (json['pendingAttendanceSessions'] as num?)?.toInt() ?? 0,
      submissionsAwaitingReview: (json['submissionsAwaitingReview'] as num?)?.toInt() ?? 0,
      pendingAssessmentMarks: (json['pendingAssessmentMarks'] as num?)?.toInt() ?? 0,
      openPracticalsCount: (json['openPracticalsCount'] as num?)?.toInt() ?? 0,
      activeFacultyCount: (json['activeFacultyCount'] as num?)?.toInt() ?? 0,
      activeStudentsCount: (json['activeStudentsCount'] as num?)?.toInt() ?? 0,
      todayClassesCount: (json['todayClassesCount'] as num?)?.toInt() ?? 0,
      pendingDepartmentRequests: (json['pendingDepartmentRequests'] as num?)?.toInt() ?? 0,
      pendingAssessmentsCount: (json['pendingAssessmentsCount'] as num?)?.toInt() ?? 0,
      pendingAttendanceCount: (json['pendingAttendanceCount'] as num?)?.toInt() ?? 0,
      departmentsCount: (json['departmentsCount'] as num?)?.toInt() ?? 0,
      facultyCount: (json['facultyCount'] as num?)?.toInt() ?? 0,
      studentsCount: (json['studentsCount'] as num?)?.toInt() ?? 0,
      pendingRequestsCount: (json['pendingRequestsCount'] as num?)?.toInt() ?? 0,
      activeAnnouncementsCount: (json['activeAnnouncementsCount'] as num?)?.toInt() ?? 0,
      activeAcademicYearsCount: (json['activeAcademicYearsCount'] as num?)?.toInt() ?? 0,
      collegesCount: (json['collegesCount'] as num?)?.toInt() ?? 0,
      usersCount: (json['usersCount'] as num?)?.toInt() ?? 0,
      activeCollegesCount: (json['activeCollegesCount'] as num?)?.toInt() ?? 0,
      systemStatus: json['systemStatus'] as String? ?? 'OPERATIONAL',
    );
  }
}

@immutable
class DashboardAlertModel {
  final String id;
  final String type;
  final String severity; // INFO, WARNING, CRITICAL
  final String title;
  final String message;
  final String? route;

  const DashboardAlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.route,
  });

  factory DashboardAlertModel.fromJson(Map<String, dynamic> json) {
    return DashboardAlertModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'INFO',
      severity: json['severity'] as String? ?? 'INFO',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      route: json['route'] as String?,
    );
  }
}

@immutable
class DashboardUpcomingItemModel {
  final String id;
  final String type; // CLASS, PRACTICAL, ASSESSMENT, EVENT, HOLIDAY
  final String title;
  final String? subtitle;
  final String startTime;
  final String? endTime;
  final String? location;
  final String? route;

  const DashboardUpcomingItemModel({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.startTime,
    this.endTime,
    this.location,
    this.route,
  });

  factory DashboardUpcomingItemModel.fromJson(Map<String, dynamic> json) {
    return DashboardUpcomingItemModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'EVENT',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      route: json['route'] as String?,
    );
  }
}

@immutable
class DashboardPendingActionModel {
  final String id;
  final String type;
  final String priority; // LOW, MEDIUM, HIGH
  final String title;
  final String? description;
  final String? deadline;
  final String route;
  final String actionLabel;

  const DashboardPendingActionModel({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    this.description,
    this.deadline,
    required this.route,
    required this.actionLabel,
  });

  factory DashboardPendingActionModel.fromJson(Map<String, dynamic> json) {
    return DashboardPendingActionModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'GENERAL',
      priority: json['priority'] as String? ?? 'MEDIUM',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      deadline: json['deadline'] as String?,
      route: json['route'] as String? ?? '/',
      actionLabel: json['actionLabel'] as String? ?? 'View',
    );
  }
}

@immutable
class DashboardRecentActivityModel {
  final String id;
  final String type; // ANNOUNCEMENT, SUBMISSION, RESULT, REQUEST, ASSESSMENT, PRACTICAL
  final String title;
  final String? description;
  final String timestamp;
  final String? route;

  const DashboardRecentActivityModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.timestamp,
    this.route,
  });

  factory DashboardRecentActivityModel.fromJson(Map<String, dynamic> json) {
    return DashboardRecentActivityModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'GENERAL',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      timestamp: json['timestamp'] as String? ?? '',
      route: json['route'] as String?,
    );
  }
}

@immutable
class DashboardQuickActionModel {
  final String id;
  final String label;
  final String icon;
  final String route;
  final int? badgeCount;
  final bool isPrimary;

  const DashboardQuickActionModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.badgeCount,
    this.isPrimary = false,
  });

  factory DashboardQuickActionModel.fromJson(Map<String, dynamic> json) {
    return DashboardQuickActionModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? 'folder',
      route: json['route'] as String? ?? '/',
      badgeCount: (json['badgeCount'] as num?)?.toInt(),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

@immutable
class HomeDashboardModel {
  final String role;
  final DashboardGreetingModel greeting;
  final DashboardContextModel context;
  final DashboardSummaryModel summary;
  final List<DashboardAlertModel> alerts;
  final List<DashboardUpcomingItemModel> upcoming;
  final List<DashboardPendingActionModel> pendingActions;
  final List<DashboardRecentActivityModel> recent;
  final List<DashboardQuickActionModel> quickActions;

  const HomeDashboardModel({
    required this.role,
    required this.greeting,
    required this.context,
    required this.summary,
    required this.alerts,
    required this.upcoming,
    required this.pendingActions,
    required this.recent,
    required this.quickActions,
  });

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) {
    return HomeDashboardModel(
      role: json['role'] as String? ?? 'STUDENT',
      greeting: DashboardGreetingModel.fromJson(json['greeting'] as Map<String, dynamic>?),
      context: DashboardContextModel.fromJson(json['context'] as Map<String, dynamic>?),
      summary: DashboardSummaryModel.fromJson(json['summary'] as Map<String, dynamic>?),
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((e) => DashboardAlertModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      upcoming: (json['upcoming'] as List<dynamic>?)
              ?.map((e) => DashboardUpcomingItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingActions: (json['pendingActions'] as List<dynamic>?)
              ?.map((e) => DashboardPendingActionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recent: (json['recent'] as List<dynamic>?)
              ?.map((e) => DashboardRecentActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quickActions: (json['quickActions'] as List<dynamic>?)
              ?.map((e) => DashboardQuickActionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
