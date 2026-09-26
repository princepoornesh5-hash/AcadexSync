import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/domain/models/auth_state.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import '../../domain/models/academic_models.dart';
import '../utils/academic_prerequisite_guard.dart';
import 'academic_providers.dart';

export '../models/setup_action_decision.dart';

enum SetupMilestoneStatus {
  completed,
  ready,
  waitingOnAdmin,
  blocked,
}

class SetupMilestone {
  final SetupMilestoneId id;
  final int stepNumber;
  final String title;
  final String description;
  final SetupMilestoneStatus status;
  final int completedCount;
  final String? summaryDetail;
  final String actionLabel;
  final String? actionRoute;
  final String viewLabel;
  final String viewRoute;
  final bool isWaitingOnAdmin;
  final String? adminMessage;
  final Map<String, String> contextParams;
  final SetupActionDecision? decision;

  const SetupMilestone({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.completedCount,
    this.summaryDetail,
    required this.actionLabel,
    this.actionRoute,
    required this.viewLabel,
    required this.viewRoute,
    this.isWaitingOnAdmin = false,
    this.adminMessage,
    this.contextParams = const {},
    this.decision,
  });

  bool get isCompleted => status == SetupMilestoneStatus.completed;
  bool get isReady => status == SetupMilestoneStatus.ready;
  bool get isBlocked => status == SetupMilestoneStatus.blocked;
  bool get canCurrentUserAct => decision?.canCurrentUserAct ?? (status == SetupMilestoneStatus.ready);
  String? get waitingReason => decision?.waitingReason ?? adminMessage;

  factory SetupMilestone.fromDecision({
    required SetupMilestoneId id,
    required int stepNumber,
    required String title,
    required String description,
    required int completedCount,
    String? summaryDetail,
    required String viewLabel,
    required String viewRoute,
    required SetupActionDecision decision,
  }) {
    SetupMilestoneStatus status;
    switch (decision.status) {
      case SetupDecisionStatus.complete:
        status = SetupMilestoneStatus.completed;
        break;
      case SetupDecisionStatus.ready:
        status = SetupMilestoneStatus.ready;
        break;
      case SetupDecisionStatus.waitingOnOtherRole:
        status = SetupMilestoneStatus.waitingOnAdmin;
        break;
      case SetupDecisionStatus.blocked:
        status = SetupMilestoneStatus.blocked;
        break;
    }

    final isWaiting = decision.isWaitingOnOtherRole;
    final effectiveAdminMessage = decision.explanation;

    return SetupMilestone(
      id: id,
      stepNumber: stepNumber,
      title: title,
      description: description,
      status: status,
      completedCount: completedCount,
      summaryDetail: summaryDetail,
      actionLabel: decision.actionLabel ?? (isWaiting ? 'Notify College Admin' : 'Action Required'),
      actionRoute: decision.actionRoute,
      viewLabel: viewLabel,
      viewRoute: viewRoute,
      isWaitingOnAdmin: isWaiting,
      adminMessage: effectiveAdminMessage,
      contextParams: decision.contextParams,
      decision: decision,
    );
  }
}

class DepartmentSetupState {
  final Department? department;
  final String departmentId;
  final String departmentName;
  final String collegeId;
  final List<SetupMilestone> milestones;
  final int completedCount;
  final int totalCount;
  final double progressRatio;
  final int percentage;
  final bool isComplete;
  final bool isCurrentContextComplete;
  final bool isDepartmentFullyConfigured;
  final List<CourseSetupCoverage> courseCoverages;
  final List<CourseSetupCoverage> incompleteCourses;
  final SetupMilestone? nextActionableMilestone;
  final String? multiContextNotice;
  final bool isHod;
  final bool canSwitchDepartment;

  const DepartmentSetupState({
    required this.department,
    required this.departmentId,
    required this.departmentName,
    required this.collegeId,
    required this.milestones,
    required this.completedCount,
    this.totalCount = 8,
    required this.progressRatio,
    required this.percentage,
    required this.isComplete,
    required this.isCurrentContextComplete,
    required this.isDepartmentFullyConfigured,
    this.courseCoverages = const [],
    this.incompleteCourses = const [],
    this.nextActionableMilestone,
    this.multiContextNotice,
    this.isHod = false,
    this.canSwitchDepartment = false,
  });
}

/// Computes the authoritative progressive academic onboarding & setup state for a department.
final departmentSetupProvider = FutureProvider.autoDispose.family<DepartmentSetupState, String?>((ref, explicitDeptId) async {
  final authState = ref.watch(authProvider);
  final user = authState is AuthAuthenticated ? authState.user : null;
  final role = user?.role ?? AppRole.student;
  final isHod = role == AppRole.hod;
  final isCollegeAdmin = role == AppRole.collegeAdmin;
  final isSuperAdmin = role == AppRole.superAdmin;
  final academicRepo = ref.watch(academicRepositoryProvider);
  final timetableRepo = ref.watch(timetableRepositoryProvider);

  // 1. Determine active department context
  String effectiveDeptId = '';
  if (isHod) {
    effectiveDeptId = user?.departmentId ?? '';
  } else if (explicitDeptId != null && explicitDeptId.isNotEmpty) {
    effectiveDeptId = explicitDeptId;
  } else if (user?.departmentId != null && user!.departmentId!.isNotEmpty) {
    effectiveDeptId = user.departmentId!;
  }

  // Fetch departments list
  final departments = await ref.watch(departmentsProvider.future);
  Department? currentDepartment;

  if (effectiveDeptId.isNotEmpty) {
    try {
      currentDepartment = departments.firstWhere((d) => d.id == effectiveDeptId);
    } catch (_) {
      currentDepartment = null;
    }
  }

  // If still empty and authorized admin, fallback to first available department
  if (currentDepartment == null && departments.isNotEmpty && (isCollegeAdmin || isSuperAdmin)) {
    currentDepartment = departments.first;
    effectiveDeptId = currentDepartment.id;
  }

  final effectiveCollegeId = currentDepartment?.collegeId ?? user?.collegeId ?? '';
  final effectiveDeptName = currentDepartment?.name ?? (effectiveDeptId.isNotEmpty ? effectiveDeptId : 'Your Department');

  // 2. Fetch authoritative domain data
  final courses = await ref.watch(coursesProvider.future);
  final academicYears = await ref.watch(academicYearsProvider.future);
  final currentAcademicYear = ref.watch(currentAcademicYearProvider);
  final semesters = await ref.watch(semestersProvider.future);
  final sections = await ref.watch(sectionsProvider.future);
  final subjects = await ref.watch(subjectsProvider.future);
  final assignments = await ref.watch(facultyAssignmentsProvider.future);
  
  List<Faculty> facultyList = [];
  try {
    facultyList = await academicRepo.getFaculty(departmentId: effectiveDeptId.isNotEmpty ? effectiveDeptId : null);
  } catch (_) {
    facultyList = ref.watch(facultyProvider(null)).items;
  }

  // Fetch students for the department directly via repo to avoid autoDispose cycle
  List<Student> departmentStudents = [];
  if (effectiveDeptId.isNotEmpty) {
    try {
      departmentStudents = await academicRepo.getStudentsByDepartment(effectiveDeptId);
    } catch (_) {
      departmentStudents = [];
    }
  }

  // Fetch timetable containers for department
  int timetableCount = 0;
  if (effectiveDeptId.isNotEmpty) {
    try {
      final containers = await timetableRepo.getTimetableContainers(
        collegeId: effectiveCollegeId,
        departmentId: effectiveDeptId,
      );
      timetableCount = containers.length;
    } catch (_) {
      timetableCount = 0;
    }
  }

  // 3. Filter entities for current department context
  final deptCourses = courses.where((c) => c.departmentId == effectiveDeptId && c.isActive).toList();
  final activeCollegeYears = academicYears.where((y) => (effectiveCollegeId.isEmpty || y.collegeId == effectiveCollegeId) && y.isActive).toList();
  final effectiveAcademicYear = currentAcademicYear ?? (activeCollegeYears.isNotEmpty ? activeCollegeYears.first : null);

  final deptSemesters = semesters.where((s) => s.departmentId == effectiveDeptId && (s.isCurrent || s.status == 'active')).toList();
  final deptSections = sections.where((s) => s.departmentId == effectiveDeptId && s.isActive).toList();
  final deptSubjects = subjects.where((s) => s.departmentId == effectiveDeptId && s.isActive).toList();
  final deptAssignments = assignments.where((a) => a.departmentId == effectiveDeptId && a.isActive).toList();
  final enrolledStudents = departmentStudents.where((s) => s.isActive && s.sectionId.isNotEmpty).toList();

  // 4. Resolve the 8 authoritative milestones using AcademicPrerequisiteGuard
  final List<SetupMilestone> milestones = [];

  // Milestone 1: Course
  final courseDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
    milestoneId: SetupMilestoneId.course,
    currentRole: role,
    departmentId: effectiveDeptId,
    collegeId: effectiveCollegeId,
    courses: courses,
    academicYears: academicYears,
    semesters: semesters,
    sections: sections,
    subjects: subjects,
    faculty: facultyList,
    facultyAssignments: assignments,
    students: departmentStudents,
    timetableCount: timetableCount,
    currentAcademicYear: currentAcademicYear,
  );
  milestones.add(
    SetupMilestone.fromDecision(
      id: SetupMilestoneId.course,
      stepNumber: 1,
      title: 'Course',
      description: 'Define degree or diploma programs offered by your department.',
      completedCount: deptCourses.length,
      summaryDetail: deptCourses.isNotEmpty
          ? '${deptCourses.first.name}${deptCourses.length > 1 ? " (+${deptCourses.length - 1} more)" : ""}'
          : null,
      viewLabel: 'View Courses',
      viewRoute: '/academics/courses',
      decision: courseDecision,
    ),
  );

  // Milestone 2: Academic Year
  final ayDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
    milestoneId: SetupMilestoneId.academicYear,
    currentRole: role,
    departmentId: effectiveDeptId,
    collegeId: effectiveCollegeId,
    courses: courses,
    academicYears: academicYears,
    semesters: semesters,
    sections: sections,
    subjects: subjects,
    faculty: facultyList,
    facultyAssignments: assignments,
    students: departmentStudents,
    timetableCount: timetableCount,
    currentAcademicYear: currentAcademicYear,
  );
  milestones.add(
    SetupMilestone.fromDecision(
      id: SetupMilestoneId.academicYear,
      stepNumber: 2,
      title: 'Academic Year',
      description: 'Associate with active college academic calendar.',
      completedCount: effectiveAcademicYear != null ? 1 : 0,
      summaryDetail: effectiveAcademicYear?.name,
      viewLabel: 'View Academic Years',
      viewRoute: '/academics/academic_years',
      decision: ayDecision,
    ),
  );

  // Milestone 3: Semester
  final semDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
    milestoneId: SetupMilestoneId.semester,
    currentRole: role,
    departmentId: effectiveDeptId,
    collegeId: effectiveCollegeId,
    courses: courses,
    academicYears: academicYears,
    semesters: semesters,
    sections: sections,
    subjects: subjects,
    faculty: facultyList,
    facultyAssignments: assignments,
    students: departmentStudents,
    timetableCount: timetableCount,
    currentAcademicYear: currentAcademicYear,
  );
  milestones.add(
    SetupMilestone.fromDecision(
      id: SetupMilestoneId.semester,
      stepNumber: 3,
      title: 'Semester',
      description: 'Create active teaching terms under your department courses.',
      completedCount: deptSemesters.length,
      summaryDetail: deptSemesters.isNotEmpty
          ? '${deptSemesters.first.name}${deptSemesters.length > 1 ? " (+${deptSemesters.length - 1} more)" : ""}'
          : null,
      viewLabel: 'View Semesters',
      viewRoute: '/academics/semesters',
      decision: semDecision,
    ),
  );

  // Milestone 4: Section
  final secDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
    milestoneId: SetupMilestoneId.section,
    currentRole: role,
    departmentId: effectiveDeptId,
    collegeId: effectiveCollegeId,
    courses: courses,
    academicYears: academicYears,
    semesters: semesters,
    sections: sections,
    subjects: subjects,
    faculty: facultyList,
    facultyAssignments: assignments,
    students: departmentStudents,
    timetableCount: timetableCount,
    currentAcademicYear: currentAcademicYear,
  );
  milestones.add(
    SetupMilestone.fromDecision(
      id: SetupMilestoneId.section,
      stepNumber: 4,
      title: 'Sections',
      description: 'Form classroom student cohorts with designated seat capacity.',
      completedCount: deptSections.length,
      summaryDetail: deptSections.isNotEmpty
          ? '${deptSections.first.name} (${deptSections.first.capacity} seats)${deptSections.length > 1 ? " (+${deptSections.length - 1} more)" : ""}'
          : null,
      viewLabel: 'View Sections',
      viewRoute: '/academics/sections',
      decision: secDecision,
    ),
  );

  // Milestone 5: Subject
  final subDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
    milestoneId: SetupMilestoneId.subject,
    currentRole: role,
    departmentId: effectiveDeptId,
    collegeId: effectiveCollegeId,
    courses: courses,
    academicYears: academicYears,
    semesters: semesters,
    sections: sections,
    subjects: subjects,
    faculty: facultyList,
    facultyAssignments: assignments,
    students: departmentStudents,
    timetableCount: timetableCount,
    currentAcademicYear: currentAcademicYear,
  );
  milestones.add(
    SetupMilestone.fromDecision(
      id: SetupMilestoneId.subject,
      stepNumber: 5,
      title: 'Subjects',
      description: 'Add syllabus courses, theory lectures, and practical labs.',
      completedCount: deptSubjects.length,
      summaryDetail: deptSubjects.isNotEmpty
          ? '${deptSubjects.first.name} (${deptSubjects.first.code})${deptSubjects.length > 1 ? " (+${deptSubjects.length - 1} more)" : ""}'
          : null,
      viewLabel: 'View Subjects',
      viewRoute: '/academics/subjects',
      decision: subDecision,
    ),
  );

  // Milestone 6: Faculty Assignment
  final facDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
    milestoneId: SetupMilestoneId.facultyAssignment,
    currentRole: role,
    departmentId: effectiveDeptId,
    collegeId: effectiveCollegeId,
    courses: courses,
    academicYears: academicYears,
    semesters: semesters,
    sections: sections,
    subjects: subjects,
    faculty: facultyList,
    facultyAssignments: assignments,
    students: departmentStudents,
    timetableCount: timetableCount,
    currentAcademicYear: currentAcademicYear,
  );
  milestones.add(
    SetupMilestone.fromDecision(
      id: SetupMilestoneId.facultyAssignment,
      stepNumber: 6,
      title: 'Faculty Assignments',
      description: 'Allocate teachers and professors to subject section batches.',
      completedCount: deptAssignments.length,
      summaryDetail: deptAssignments.isNotEmpty ? '${deptAssignments.length} Teaching Allocations' : null,
      viewLabel: 'View Allocations',
      viewRoute: '/faculty-assignments',
      decision: facDecision,
    ),
  );

  // Milestone 7: Student Enrollment
  final enrDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
    milestoneId: SetupMilestoneId.studentEnrollment,
    currentRole: role,
    departmentId: effectiveDeptId,
    collegeId: effectiveCollegeId,
    courses: courses,
    academicYears: academicYears,
    semesters: semesters,
    sections: sections,
    subjects: subjects,
    faculty: facultyList,
    facultyAssignments: assignments,
    students: departmentStudents,
    timetableCount: timetableCount,
    currentAcademicYear: currentAcademicYear,
  );
  milestones.add(
    SetupMilestone.fromDecision(
      id: SetupMilestoneId.studentEnrollment,
      stepNumber: 7,
      title: 'Student Enrollment',
      description: 'Assign admitted students to department sections for class rosters.',
      completedCount: enrolledStudents.length,
      summaryDetail: enrolledStudents.isNotEmpty ? '${enrolledStudents.length} Students Enrolled' : null,
      viewLabel: 'View Students',
      viewRoute: '/academics/students',
      decision: enrDecision,
    ),
  );

  // Milestone 8: Timetable
  final ttDecision = AcademicPrerequisiteGuard.resolveMilestoneDecision(
    milestoneId: SetupMilestoneId.timetable,
    currentRole: role,
    departmentId: effectiveDeptId,
    collegeId: effectiveCollegeId,
    courses: courses,
    academicYears: academicYears,
    semesters: semesters,
    sections: sections,
    subjects: subjects,
    faculty: facultyList,
    facultyAssignments: assignments,
    students: departmentStudents,
    timetableCount: timetableCount,
    currentAcademicYear: currentAcademicYear,
  );
  milestones.add(
    SetupMilestone.fromDecision(
      id: SetupMilestoneId.timetable,
      stepNumber: 8,
      title: 'Timetable',
      description: 'Build and publish regular class lecture schedule containers.',
      completedCount: timetableCount,
      summaryDetail: timetableCount > 0 ? '$timetableCount Timetables Scheduled' : null,
      viewLabel: 'View Timetable',
      viewRoute: '/timetable',
      decision: ttDecision,
    ),
  );

  // 5. Calculate Multi-Course Coverage (Prompt 10 Section 7)
  final courseCoverages = <CourseSetupCoverage>[];
  for (final c in deptCourses) {
    final hasSem = deptSemesters.any((s) => s.courseId == c.id);
    final hasSec = deptSections.any((s) => s.courseId == c.id);
    final hasSub = deptSubjects.any((s) => s.courseId == c.id);
    final hasFac = deptAssignments.any((a) => a.courseId == c.id);
    final hasEnr = enrolledStudents.any((st) => st.courseId == c.id);
    final hasTim = timetableCount > 0;

    courseCoverages.add(
      CourseSetupCoverage(
        courseId: c.id,
        courseName: c.name,
        courseCode: c.code,
        hasSemester: hasSem,
        hasSection: hasSec,
        hasSubject: hasSub,
        hasFacultyAssignment: hasFac,
        hasEnrollment: hasEnr,
        hasTimetable: hasTim,
      ),
    );
  }

  final incompleteCourses = courseCoverages.where((cov) => !cov.isFullyCovered).toList();
  final bool hasRemainingCourseCoverage = deptCourses.length > 1 && incompleteCourses.isNotEmpty;

  // 6. Overall progress calculation
  final completedCount = milestones.where((m) => m.isCompleted).length;
  const totalCount = 8;
  final progressRatio = completedCount / totalCount.toDouble();
  final percentage = (progressRatio * 100).round();
  final isCurrentContextComplete = completedCount == totalCount;
  // Department is only completely done when current context is 8/8 AND all department courses are covered
  final isDepartmentFullyConfigured = isCurrentContextComplete && !hasRemainingCourseCoverage;
  final isComplete = isDepartmentFullyConfigured;

  // 7. Smart Next Step Selection (Prompt 10 Section 9)
  SetupMilestone? nextActionable;
  for (final m in milestones) {
    if (!m.isCompleted) {
      nextActionable = m;
      break;
    }
  }

  // 8. Multi-context notice generation (Prompt 9 & Prompt 10 Section 7)
  String? multiContextNotice;
  if (deptCourses.length > 1) {
    final coursesMissingSemester = deptCourses.where((c) => !deptSemesters.any((s) => s.courseId == c.id)).toList();
    if (isCurrentContextComplete && incompleteCourses.isNotEmpty) {
      final incomplete = incompleteCourses.firstWhere(
        (cov) => cov.courseId != deptCourses.first.id,
        orElse: () => incompleteCourses.first,
      );
      multiContextNotice = 'Current setup context complete, but ${incomplete.courseName} still has setup work remaining: ${incomplete.missingSteps.join(", ")}.';
    } else if (coursesMissingSemester.isNotEmpty) {
      multiContextNotice = 'Multiple courses detected: ${coursesMissingSemester.first.name} does not have an active semester configured yet.';
    } else if (incompleteCourses.isNotEmpty) {
      final incomplete = incompleteCourses.firstWhere(
        (cov) => cov.courseId != deptCourses.first.id,
        orElse: () => incompleteCourses.first,
      );
      multiContextNotice = 'Note: ${incomplete.courseName} requires ${incomplete.missingSteps.first} for full department coverage.';
    }
  }

  return DepartmentSetupState(
    department: currentDepartment,
    departmentId: effectiveDeptId,
    departmentName: effectiveDeptName,
    collegeId: effectiveCollegeId,
    milestones: milestones,
    completedCount: completedCount,
    totalCount: totalCount,
    progressRatio: progressRatio,
    percentage: percentage,
    isComplete: isComplete,
    isCurrentContextComplete: isCurrentContextComplete,
    isDepartmentFullyConfigured: isDepartmentFullyConfigured,
    courseCoverages: courseCoverages,
    incompleteCourses: incompleteCourses,
    nextActionableMilestone: nextActionable,
    multiContextNotice: multiContextNotice,
    isHod: isHod,
    canSwitchDepartment: (isCollegeAdmin || isSuperAdmin) && departments.length > 1,
  );
});
