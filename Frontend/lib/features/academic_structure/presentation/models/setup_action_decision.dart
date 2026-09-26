import '../../../auth/domain/models/role_enum.dart';
import '../utils/academic_prerequisite_guard.dart';

/// Authoritative decision status for an academic setup milestone
enum SetupDecisionStatus {
  ready,
  blocked,
  waitingOnOtherRole,
  complete,
}

/// Identifiers for the 8 canonical academic onboarding milestones
enum SetupMilestoneId {
  course,
  academicYear,
  semester,
  section,
  subject,
  facultyAssignment,
  studentEnrollment,
  timetable,
}

/// Centralized decision result resolving role, scope, prerequisite, and next action
class SetupActionDecision {
  final SetupMilestoneId milestoneId;
  final SetupDecisionStatus status;
  final AppRole currentRole;
  final AppRole? ownerRole;
  final AcademicPrerequisiteType? missingDependency;
  final bool canCurrentUserAct;
  final String? actionRoute;
  final String? actionLabel;
  final String explanation;
  final String? waitingReason;
  final Map<String, String> contextParams;

  const SetupActionDecision({
    required this.milestoneId,
    required this.status,
    required this.currentRole,
    this.ownerRole,
    this.missingDependency,
    required this.canCurrentUserAct,
    this.actionRoute,
    this.actionLabel,
    required this.explanation,
    this.waitingReason,
    this.contextParams = const {},
  });

  bool get isReady => status == SetupDecisionStatus.ready;
  bool get isBlocked => status == SetupDecisionStatus.blocked;
  bool get isWaitingOnOtherRole => status == SetupDecisionStatus.waitingOnOtherRole;
  bool get isComplete => status == SetupDecisionStatus.complete;

  /// Helper factory for fully completed milestones
  factory SetupActionDecision.complete({
    required SetupMilestoneId milestoneId,
    required AppRole currentRole,
    required String explanation,
    Map<String, String> contextParams = const {},
  }) {
    return SetupActionDecision(
      milestoneId: milestoneId,
      status: SetupDecisionStatus.complete,
      currentRole: currentRole,
      canCurrentUserAct: false,
      explanation: explanation,
      contextParams: contextParams,
    );
  }

  /// Helper factory for ready milestones where current user is authorized to act
  factory SetupActionDecision.ready({
    required SetupMilestoneId milestoneId,
    required AppRole currentRole,
    AppRole? ownerRole,
    required String actionRoute,
    required String actionLabel,
    required String explanation,
    Map<String, String> contextParams = const {},
  }) {
    return SetupActionDecision(
      milestoneId: milestoneId,
      status: SetupDecisionStatus.ready,
      currentRole: currentRole,
      ownerRole: ownerRole ?? currentRole,
      canCurrentUserAct: true,
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      explanation: explanation,
      contextParams: contextParams,
    );
  }

  /// Helper factory for milestones waiting on another role (e.g. HOD waiting on College Admin for Academic Year)
  factory SetupActionDecision.waitingOnOtherRole({
    required SetupMilestoneId milestoneId,
    required AppRole currentRole,
    required AppRole ownerRole,
    AcademicPrerequisiteType? missingDependency,
    required String explanation,
    required String waitingReason,
    String? notifyActionLabel,
    Map<String, String> contextParams = const {},
  }) {
    return SetupActionDecision(
      milestoneId: milestoneId,
      status: SetupDecisionStatus.waitingOnOtherRole,
      currentRole: currentRole,
      ownerRole: ownerRole,
      missingDependency: missingDependency,
      canCurrentUserAct: false,
      actionRoute: null, // Hard requirement: NEVER route to a 403 page
      actionLabel: notifyActionLabel ?? 'Notify ${ownerRole == AppRole.collegeAdmin ? "College Admin" : "Administrator"}',
      explanation: explanation,
      waitingReason: waitingReason,
      contextParams: contextParams,
    );
  }

  /// Helper factory for blocked milestones where prerequisites are missing
  factory SetupActionDecision.blocked({
    required SetupMilestoneId milestoneId,
    required AppRole currentRole,
    AppRole? ownerRole,
    required AcademicPrerequisiteType missingDependency,
    required bool canCurrentUserAct,
    String? actionRoute,
    String? actionLabel,
    required String explanation,
    String? waitingReason,
    Map<String, String> contextParams = const {},
  }) {
    return SetupActionDecision(
      milestoneId: milestoneId,
      status: SetupDecisionStatus.blocked,
      currentRole: currentRole,
      ownerRole: ownerRole,
      missingDependency: missingDependency,
      canCurrentUserAct: canCurrentUserAct,
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      explanation: explanation,
      waitingReason: waitingReason,
      contextParams: contextParams,
    );
  }
}

/// Course coverage struct to track whether multi-course departments have partial setups
class CourseSetupCoverage {
  final String courseId;
  final String courseName;
  final String courseCode;
  final bool hasSemester;
  final bool hasSection;
  final bool hasSubject;
  final bool hasFacultyAssignment;
  final bool hasEnrollment;
  final bool hasTimetable;

  const CourseSetupCoverage({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.hasSemester,
    required this.hasSection,
    required this.hasSubject,
    required this.hasFacultyAssignment,
    required this.hasEnrollment,
    required this.hasTimetable,
  });

  bool get isFullyCovered =>
      hasSemester &&
      hasSection &&
      hasSubject &&
      hasFacultyAssignment &&
      hasEnrollment &&
      hasTimetable;

  List<String> get missingSteps {
    final list = <String>[];
    if (!hasSemester) list.add('Semester');
    if (!hasSection) list.add('Sections');
    if (!hasSubject) list.add('Subjects');
    if (!hasFacultyAssignment) list.add('Faculty Allocations');
    if (!hasEnrollment) list.add('Student Enrollment');
    if (!hasTimetable) list.add('Timetable');
    return list;
  }
}
