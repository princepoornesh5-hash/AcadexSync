import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../domain/models/academic_models.dart';
import '../models/setup_action_decision.dart';

export '../models/setup_action_decision.dart';

enum AcademicPrerequisiteType {
  course,
  academicYear,
  semester,
  section,
  subject,
  faculty,
  facultyAssignment,
  room,
  enrollment,
  publishedTimetable,
}

class PrerequisiteCheckResult {
  final bool isAllowed;
  final AcademicPrerequisiteType? missingType;
  final String? message;
  final String? actionLabel;
  final String? actionRoute;

  const PrerequisiteCheckResult({
    required this.isAllowed,
    this.missingType,
    this.message,
    this.actionLabel,
    this.actionRoute,
  });

  const PrerequisiteCheckResult.allowed()
      : isAllowed = true,
        missingType = null,
        message = null,
        actionLabel = null,
        actionRoute = null;

  const PrerequisiteCheckResult.blocked({
    required this.missingType,
    required this.message,
    required this.actionLabel,
    required this.actionRoute,
  }) : isAllowed = false;

  bool get isSatisfied => isAllowed;
}


class AcademicPrerequisiteGuard {
  /// Validates prerequisites before Semester creation.
  static PrerequisiteCheckResult checkSemesterPrerequisites({
    required List<Course> courses,
    required List<AcademicYear> academicYears,
    AppRole? role,
  }) {
    if (courses.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        message: 'Please create a course first.',
        actionLabel: 'Create Course',
        actionRoute: '/academics/courses/new',
      );
    }
    if (academicYears.isEmpty) {
      final isHod = role == AppRole.hod;
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.academicYear,
        message: isHod
            ? 'Academic Year is institution-wide and managed by College Administration. Please notify your College Admin.'
            : 'Please create an academic year first.',
        actionLabel: isHod ? 'Notify College Admin' : 'Create Academic Year',
        actionRoute: isHod ? null : '/academics/academic_years/new',
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Centralized setup next-action decision resolver (Prompt 10)
  static SetupActionDecision resolveMilestoneDecision({
    required SetupMilestoneId milestoneId,
    required AppRole currentRole,
    required String departmentId,
    required String collegeId,
    required List<Course> courses,
    required List<AcademicYear> academicYears,
    required List<Semester> semesters,
    required List<Section> sections,
    required List<Subject> subjects,
    required List<Faculty> faculty,
    required List<FacultyAssignment> facultyAssignments,
    required List<Student> students,
    required int timetableCount,
    AcademicYear? currentAcademicYear,
  }) {
    final isHod = currentRole == AppRole.hod;
    final isCollegeAdmin = currentRole == AppRole.collegeAdmin;
    final isSuperAdmin = currentRole == AppRole.superAdmin;
    final canManageDept = isHod || isCollegeAdmin || isSuperAdmin;

    final deptCourses = courses.where((c) => c.departmentId == departmentId && c.isActive).toList();
    final activeCollegeYears = academicYears.where((y) => (collegeId.isEmpty || y.collegeId == collegeId) && y.isActive).toList();
    final effectiveAy = currentAcademicYear ?? (activeCollegeYears.isNotEmpty ? activeCollegeYears.first : null);
    final hasAcademicYear = effectiveAy != null;

    final deptSemesters = semesters.where((s) => s.departmentId == departmentId && (s.isCurrent || s.status == 'active')).toList();
    final deptSections = sections.where((s) => s.departmentId == departmentId && s.isActive).toList();
    final deptSubjects = subjects.where((s) => s.departmentId == departmentId && s.isActive).toList();
    final deptAssignments = facultyAssignments.where((a) => a.departmentId == departmentId && a.isActive).toList();
    final activeFaculty = faculty.where((f) => (f.departmentId.isEmpty || f.departmentId == departmentId) && f.isActive).toList();
    final enrolledStudents = students.where((s) => s.isActive && s.sectionId.isNotEmpty).toList();
    final allDeptStudents = students.where((s) => s.isActive).toList();

    final firstCourse = deptCourses.isNotEmpty ? deptCourses.first : null;
    final firstSemester = deptSemesters.isNotEmpty ? deptSemesters.first : null;
    final firstSection = deptSections.isNotEmpty ? deptSections.first : null;

    switch (milestoneId) {
      case SetupMilestoneId.course:
        if (deptCourses.isNotEmpty) {
          return SetupActionDecision.complete(
            milestoneId: milestoneId,
            currentRole: currentRole,
            explanation: '${deptCourses.first.name}${deptCourses.length > 1 ? " (+${deptCourses.length - 1} more)" : ""}',
            contextParams: {'departmentId': departmentId},
          );
        }
        if (canManageDept) {
          return SetupActionDecision.ready(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            actionRoute: '/academics/courses/new?departmentId=$departmentId',
            actionLabel: 'Create Course',
            explanation: 'Define degree or diploma programs offered by your department.',
            contextParams: {'departmentId': departmentId},
          );
        }
        return SetupActionDecision.waitingOnOtherRole(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: AppRole.hod,
          missingDependency: AcademicPrerequisiteType.course,
          explanation: 'A course must be created before department academic setup can proceed.',
          waitingReason: 'Course creation is managed by Department Head or College Administration.',
        );

      case SetupMilestoneId.academicYear:
        if (hasAcademicYear) {
          return SetupActionDecision.complete(
            milestoneId: milestoneId,
            currentRole: currentRole,
            explanation: effectiveAy.name,
            contextParams: {'academicYearId': effectiveAy.id},
          );
        }
        if (isHod) {
          // Hard requirement: HOD must never be routed into a 403 page
          return SetupActionDecision.waitingOnOtherRole(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.academicYear,
            explanation: 'Your college has not configured an academic year yet. Semesters require an active academic year.',
            waitingReason: 'Academic Year is created by College Admin and is required before semesters can be configured.',
            notifyActionLabel: 'Notify College Admin',
          );
        }
        if (isCollegeAdmin || isSuperAdmin) {
          return SetupActionDecision.ready(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: AppRole.collegeAdmin,
            actionRoute: '/academics/academic_years/new',
            actionLabel: 'Create Academic Year',
            explanation: 'Academic Year is required for semester setup across college departments.',
          );
        }
        return SetupActionDecision.waitingOnOtherRole(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: AppRole.collegeAdmin,
          missingDependency: AcademicPrerequisiteType.academicYear,
          explanation: 'Academic Year is required for semester setup.',
          waitingReason: 'Academic Year is created by College Admin.',
        );

      case SetupMilestoneId.semester:
        if (deptSemesters.isNotEmpty) {
          return SetupActionDecision.complete(
            milestoneId: milestoneId,
            currentRole: currentRole,
            explanation: '${deptSemesters.first.name}${deptSemesters.length > 1 ? " (+${deptSemesters.length - 1} more)" : ""}',
            contextParams: {
              'departmentId': departmentId,
              if (firstCourse != null) 'courseId': firstCourse.id,
              if (effectiveAy != null) 'academicYearId': effectiveAy.id,
            },
          );
        }
        if (deptCourses.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.course,
            canCurrentUserAct: canManageDept,
            actionRoute: canManageDept ? '/academics/courses/new?departmentId=$departmentId' : null,
            actionLabel: canManageDept ? 'Create Course' : null,
            explanation: 'Create a course first before setting up teaching semesters.',
          );
        }
        if (!hasAcademicYear) {
          if (isHod) {
            return SetupActionDecision.waitingOnOtherRole(
              milestoneId: milestoneId,
              currentRole: currentRole,
              ownerRole: AppRole.collegeAdmin,
              missingDependency: AcademicPrerequisiteType.academicYear,
              explanation: 'Waiting for College Admin to configure Academic Year before semesters can be created.',
              waitingReason: 'Academic Year is managed by College Administration.',
              notifyActionLabel: 'Notify College Admin',
            );
          }
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.academicYear,
            canCurrentUserAct: true,
            actionRoute: '/academics/academic_years/new',
            actionLabel: 'Create Academic Year',
            explanation: 'An Academic Year must be created before adding semesters.',
          );
        }
        // Both Course and Academic Year are present
        final activeCourse = deptCourses.first;
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/academics/semesters/new?courseId=${activeCourse.id}&academicYearId=${effectiveAy.id}',
          actionLabel: 'Create Semester',
          explanation: 'Create active teaching terms under your department courses.',
          contextParams: {
            'departmentId': departmentId,
            'courseId': activeCourse.id,
            'academicYearId': effectiveAy.id,
          },
        );

      case SetupMilestoneId.section:
        if (deptSections.isNotEmpty) {
          return SetupActionDecision.complete(
            milestoneId: milestoneId,
            currentRole: currentRole,
            explanation: '${deptSections.first.name} (${deptSections.first.capacity} seats)${deptSections.length > 1 ? " (+${deptSections.length - 1} more)" : ""}',
            contextParams: {
              'departmentId': departmentId,
              if (firstCourse != null) 'courseId': firstCourse.id,
              if (firstSemester != null) 'semesterId': firstSemester.id,
            },
          );
        }
        if (deptSemesters.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.semester,
            canCurrentUserAct: canManageDept && deptCourses.isNotEmpty && hasAcademicYear,
            actionRoute: (canManageDept && deptCourses.isNotEmpty && hasAcademicYear)
                ? '/academics/semesters/new?courseId=${firstCourse?.id ?? ""}&academicYearId=${effectiveAy.id}'
                : null,
            actionLabel: (canManageDept && deptCourses.isNotEmpty && hasAcademicYear) ? 'Create Semester' : null,
            explanation: 'Create a semester for this course before configuring sections.',
          );
        }
        final activeSectionSemester = deptSemesters.first;
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/academics/sections/new?courseId=${firstCourse?.id ?? ""}&semesterId=${activeSectionSemester.id}',
          actionLabel: 'Create Section',
          explanation: 'Form classroom student cohorts with designated seat capacity.',
          contextParams: {
            'departmentId': departmentId,
            if (firstCourse != null) 'courseId': firstCourse.id,
            'semesterId': activeSectionSemester.id,
          },
        );

      case SetupMilestoneId.subject:
        if (deptSubjects.isNotEmpty) {
          return SetupActionDecision.complete(
            milestoneId: milestoneId,
            currentRole: currentRole,
            explanation: '${deptSubjects.first.name} (${deptSubjects.first.code})${deptSubjects.length > 1 ? " (+${deptSubjects.length - 1} more)" : ""}',
            contextParams: {
              'departmentId': departmentId,
              if (firstCourse != null) 'courseId': firstCourse.id,
              if (firstSemester != null) 'semesterId': firstSemester.id,
            },
          );
        }
        if (deptSemesters.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.semester,
            canCurrentUserAct: canManageDept && deptCourses.isNotEmpty && hasAcademicYear,
            actionRoute: (canManageDept && deptCourses.isNotEmpty && hasAcademicYear)
                ? '/academics/semesters/new?courseId=${firstCourse?.id ?? ""}&academicYearId=${effectiveAy.id}'
                : null,
            actionLabel: (canManageDept && deptCourses.isNotEmpty && hasAcademicYear) ? 'Create Semester' : null,
            explanation: 'Create a semester for this course before configuring subjects.',
          );
        }
        final activeSubjectSemester = deptSemesters.first;
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/academics/subjects/new?courseId=${firstCourse?.id ?? ""}&semesterId=${activeSubjectSemester.id}',
          actionLabel: 'Add Subject',
          explanation: 'Add syllabus courses, theory lectures, and practical labs.',
          contextParams: {
            'departmentId': departmentId,
            if (firstCourse != null) 'courseId': firstCourse.id,
            'semesterId': activeSubjectSemester.id,
          },
        );

      case SetupMilestoneId.facultyAssignment:
        if (deptAssignments.isNotEmpty) {
          return SetupActionDecision.complete(
            milestoneId: milestoneId,
            currentRole: currentRole,
            explanation: '${deptAssignments.length} Teaching Allocations',
            contextParams: {
              'departmentId': departmentId,
              if (firstSection != null) 'sectionId': firstSection.id,
            },
          );
        }
        if (deptSections.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.section,
            canCurrentUserAct: canManageDept,
            explanation: 'Create sections before allocating faculty members.',
          );
        }
        if (deptSubjects.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.subject,
            canCurrentUserAct: canManageDept,
            explanation: 'Add subjects before allocating faculty members.',
          );
        }
        // Section & Subject exist, check active faculty availability (Prompt 10 Section 8)
        if (activeFaculty.isEmpty) {
          if (canManageDept) {
            return SetupActionDecision.blocked(
              milestoneId: milestoneId,
              currentRole: currentRole,
              ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
              missingDependency: AcademicPrerequisiteType.faculty,
              canCurrentUserAct: true,
              actionRoute: '/academics/faculty/new?departmentId=$departmentId',
              actionLabel: 'Provision Faculty',
              explanation: 'No active faculty is available for this subject. Provision faculty first.',
            );
          }
          return SetupActionDecision.waitingOnOtherRole(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.faculty,
            explanation: 'No active faculty is available for this subject.',
            waitingReason: 'Faculty creation is handled by College Admin.',
          );
        }
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/faculty-assignments',
          actionLabel: 'Assign Faculty',
          explanation: 'Allocate teachers and professors to subject section batches.',
          contextParams: {
            'departmentId': departmentId,
            if (firstSection != null) 'sectionId': firstSection.id,
          },
        );

      case SetupMilestoneId.studentEnrollment:
        if (enrolledStudents.isNotEmpty) {
          return SetupActionDecision.complete(
            milestoneId: milestoneId,
            currentRole: currentRole,
            explanation: '${enrolledStudents.length} Students Enrolled',
            contextParams: {
              'departmentId': departmentId,
              if (firstSection != null) 'sectionId': firstSection.id,
            },
          );
        }
        if (deptSections.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.section,
            canCurrentUserAct: canManageDept,
            explanation: 'Create sections before enrolling students.',
          );
        }
        // Sections exist. Check whether any students exist in the department
        if (allDeptStudents.isEmpty) {
          if (canManageDept) {
            return SetupActionDecision.blocked(
              milestoneId: milestoneId,
              currentRole: currentRole,
              ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
              missingDependency: AcademicPrerequisiteType.enrollment,
              canCurrentUserAct: true,
              actionRoute: '/academics/students/new?departmentId=$departmentId',
              actionLabel: 'Provision Student',
              explanation: 'No admitted students available for enrollment. Student accounts must be provisioned before assigning to sections.',
            );
          }
          return SetupActionDecision.waitingOnOtherRole(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.enrollment,
            explanation: 'No students are available to enroll.',
            waitingReason: 'Student enrollment requires admitted student records from College Administration.',
          );
        }
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/academics/students',
          actionLabel: 'Enroll Students',
          explanation: 'Assign admitted students to department sections for class rosters.',
          contextParams: {
            'departmentId': departmentId,
            if (firstSection != null) 'sectionId': firstSection.id,
          },
        );

      case SetupMilestoneId.timetable:
        if (timetableCount > 0) {
          return SetupActionDecision.complete(
            milestoneId: milestoneId,
            currentRole: currentRole,
            explanation: '$timetableCount Timetables Scheduled',
            contextParams: {'departmentId': departmentId},
          );
        }
        if (deptSections.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.section,
            canCurrentUserAct: false,
            actionRoute: null,
            explanation: 'Create sections before generating timetables.',
          );
        }
        if (deptSubjects.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.subject,
            canCurrentUserAct: false,
            actionRoute: null,
            explanation: 'Add subjects before generating timetables.',
          );
        }
        if (deptAssignments.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.facultyAssignment,
            canCurrentUserAct: false,
            actionRoute: null,
            explanation: 'Assign faculty to subjects before creating timetable schedules.',
          );
        }
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/timetable/manage',
          actionLabel: 'Create Timetable',
          explanation: 'Build and publish regular class lecture schedule containers.',
          contextParams: {'departmentId': departmentId},
        );
    }
  }

  /// Validates prerequisites before Section creation.
  static PrerequisiteCheckResult checkSectionPrerequisites({
    required List<Course> courses,
    required List<Semester> semesters,
  }) {
    if (courses.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        message: 'Please create a course first.',
        actionLabel: 'Create Course',
        actionRoute: '/academics/courses/new',
      );
    }
    if (semesters.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        message: 'Create a semester for this course first.',
        actionLabel: 'Create Semester',
        actionRoute: '/academics/semesters/new',
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Validates prerequisites before Subject creation.
  static PrerequisiteCheckResult checkSubjectPrerequisites({
    required List<Course> courses,
    required List<Semester> semesters,
  }) {
    if (courses.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        message: 'Please create a course first.',
        actionLabel: 'Create Course',
        actionRoute: '/academics/courses/new',
      );
    }
    if (semesters.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        message: 'Create a semester for this course first.',
        actionLabel: 'Create Semester',
        actionRoute: '/academics/semesters/new',
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Validates prerequisites before Faculty Assignment creation.
  static PrerequisiteCheckResult checkFacultyAssignmentPrerequisites({
    required List<Course> courses,
    required List<Semester> semesters,
    required List<Section> sections,
    required List<Subject> subjects,
    List<Faculty>? faculty,
    List<Faculty>? faculties,
  }) {
    final effectiveFaculty = faculty ?? faculties ?? <Faculty>[];
    if (courses.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        message: 'Please create a course first.',
        actionLabel: 'Create Course',
        actionRoute: '/academics/courses/new',
      );
    }
    if (semesters.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        message: 'Create a semester for this course first.',
        actionLabel: 'Create Semester',
        actionRoute: '/academics/semesters/new',
      );
    }
    if (sections.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.section,
        message: 'Create a section for this semester first.',
        actionLabel: 'Create Section',
        actionRoute: '/academics/sections/new',
      );
    }
    if (subjects.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.subject,
        message: 'Add a subject for this semester first.',
        actionLabel: 'Add Subject',
        actionRoute: '/academics/subjects/new',
      );
    }
    final activeFaculty = effectiveFaculty.where((f) => f.isActive).toList();
    if (activeFaculty.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.faculty,
        message: 'No active faculty available. Create or activate a faculty member first.',
        actionLabel: 'Provision Faculty',
        actionRoute: '/academics/faculty/new',
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Validates prerequisites before Student Enrollment.
  static PrerequisiteCheckResult checkStudentEnrollmentPrerequisites({
    required List<Course> courses,
    required List<Semester> semesters,
    required List<Section> sections,
  }) {
    if (courses.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        message: 'Create a course before enrolling students.',
        actionLabel: 'Create Course',
        actionRoute: '/academics/courses/new',
      );
    }
    if (semesters.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        message: 'Create a semester first.',
        actionLabel: 'Create Semester',
        actionRoute: '/academics/semesters/new',
      );
    }
    if (sections.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.section,
        message: 'Create a section first.',
        actionLabel: 'Create Section',
        actionRoute: '/academics/sections/new',
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Validates the comprehensive prerequisite chain before Timetable authoring.
  static PrerequisiteCheckResult checkTimetablePrerequisites({
    required List<Course> courses,
    required List<AcademicYear> academicYears,
    required List<Semester> semesters,
    required List<Section> sections,
    required List<Subject> subjects,
    required List<FacultyAssignment> facultyAssignments,
    required List<Room> rooms,
  }) {
    if (courses.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        message: 'Create a course first.',
        actionLabel: 'Create Course',
        actionRoute: '/academics/courses/new',
      );
    }
    if (academicYears.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.academicYear,
        message: 'Create an academic year first.',
        actionLabel: 'Create Academic Year',
        actionRoute: '/academics/academic_years/new',
      );
    }
    if (semesters.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        message: 'Create a semester for this course first.',
        actionLabel: 'Create Semester',
        actionRoute: '/academics/semesters/new',
      );
    }
    if (sections.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.section,
        message: 'Create a section for this semester first.',
        actionLabel: 'Create Section',
        actionRoute: '/academics/sections/new',
      );
    }
    if (subjects.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.subject,
        message: 'Add a subject for this semester first.',
        actionLabel: 'Add Subject',
        actionRoute: '/academics/subjects/new',
      );
    }
    final activeAssignments = facultyAssignments.where((a) => a.isActive).toList();
    if (activeAssignments.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.facultyAssignment,
        message: 'Assign a faculty member to the subject before creating the timetable.',
        actionLabel: 'Assign Faculty',
        actionRoute: '/academics/assignments',
      );
    }
    if (rooms.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.room,
        message: 'Add a classroom/room before scheduling a class.',
        actionLabel: 'Add Room',
        actionRoute: '/timetable/manage',
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Validates prerequisites before taking attendance.
  static PrerequisiteCheckResult checkAttendanceEntryPrerequisites({
    required bool isTimetablePublished,
    required int enrolledStudentsCount,
  }) {
    if (!isTimetablePublished) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.publishedTimetable,
        message: 'This class is not published on the timetable.',
        actionLabel: 'View Timetable',
        actionRoute: '/timetable',
      );
    }
    if (enrolledStudentsCount <= 0) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.enrollment,
        message: 'No students are enrolled in this section yet.',
        actionLabel: 'Manage Sections',
        actionRoute: '/academics/sections',
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Displays a modal explaining the missing prerequisite with direct action button.
  static Future<void> showBlockerDialog(
    BuildContext context,
    PrerequisiteCheckResult result,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AcadexColors.warning.withValues(alpha: 0.15),
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: const Icon(LucideIcons.alertTriangle, size: 20, color: AcadexColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Missing Prerequisite',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          result.message ?? 'A required prerequisite is missing.',
          style: AcadexTypography.body(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          if (result.actionLabel != null && result.actionRoute != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(result.actionRoute!);
              },
              child: Text(result.actionLabel!),
            ),
        ],
      ),
    );
  }

  /// Inline warning card for embedded form states.
  static Widget buildWarningCard({
    required BuildContext context,
    required PrerequisiteCheckResult result,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: AcadexColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alertTriangle, size: 18, color: AcadexColors.warning),
              const SizedBox(width: 8),
              Text(
                'Prerequisite Required',
                style: AcadexTypography.bodyMedium(
                  color: isDark ? AcadexColors.warning : AcadexColors.warningDark,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.message ?? 'Please complete the required academic prerequisite.',
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          if (result.actionLabel != null && result.actionRoute != null) ...[
            const SizedBox(height: 12),
            AcadexButton(
              label: result.actionLabel!,
              icon: LucideIcons.arrowRight,
              variant: AcadexButtonVariant.primary,
              size: AcadexButtonSize.sm,
              onPressed: () => context.push(result.actionRoute!),
            ),
          ],
        ],
      ),
    );
  }
}
