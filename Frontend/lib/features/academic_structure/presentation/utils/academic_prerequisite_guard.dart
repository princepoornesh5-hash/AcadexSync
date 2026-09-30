import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/institution_config/domain/models/institution_config_models.dart';
import '../../../../features/institution_config/presentation/providers/institution_config_providers.dart';
import '../../domain/models/academic_models.dart';
import '../models/setup_action_decision.dart';

export '../models/setup_action_decision.dart';

/// Conceptual priority levels for academic prerequisites (Prompt 32)
enum PrerequisitePriorityLevel {
  /// Level 1 — Core academic foundation (Academic Year, Program/Course, Semester)
  core,
  /// Level 2 — Contextual operational dependency (Section, Subject, Faculty, Assignment)
  contextual,
  /// Level 3 — Optional operational module (Room, Lab, Record)
  optional,
}

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
  publishedTimetable;

  PrerequisitePriorityLevel get priorityLevel {
    switch (this) {
      case AcademicPrerequisiteType.academicYear:
      case AcademicPrerequisiteType.course:
      case AcademicPrerequisiteType.semester:
        return PrerequisitePriorityLevel.core;
      case AcademicPrerequisiteType.section:
      case AcademicPrerequisiteType.subject:
      case AcademicPrerequisiteType.faculty:
      case AcademicPrerequisiteType.facultyAssignment:
      case AcademicPrerequisiteType.enrollment:
      case AcademicPrerequisiteType.publishedTimetable:
        return PrerequisitePriorityLevel.contextual;
      case AcademicPrerequisiteType.room:
        return PrerequisitePriorityLevel.optional;
    }
  }
}

class PrerequisiteCheckResult {
  final bool isAllowed;
  final AcademicPrerequisiteType? missingType;
  final String? title;
  final String? message;
  final String? actionLabel;
  final String? actionRoute;
  final PrerequisitePriorityLevel priorityLevel;

  const PrerequisiteCheckResult({
    required this.isAllowed,
    this.missingType,
    this.title,
    this.message,
    this.actionLabel,
    this.actionRoute,
    this.priorityLevel = PrerequisitePriorityLevel.contextual,
  });

  const PrerequisiteCheckResult.allowed()
      : isAllowed = true,
        missingType = null,
        title = null,
        message = null,
        actionLabel = null,
        actionRoute = null,
        priorityLevel = PrerequisitePriorityLevel.optional;

  const PrerequisiteCheckResult.blocked({
    required this.missingType,
    this.title,
    required this.message,
    required this.actionLabel,
    required this.actionRoute,
    this.priorityLevel = PrerequisitePriorityLevel.contextual,
  }) : isAllowed = false;

  bool get isSatisfied => isAllowed;
}


class AcademicPrerequisiteGuard {
  /// Validates prerequisites before Semester creation.
  static PrerequisiteCheckResult checkSemesterPrerequisites({
    required List<Course> courses,
    required List<AcademicYear> academicYears,
    AppRole? role,
    TerminologyHelper? termHelper,
  }) {
    final courseLabel = termHelper?.programName() ?? 'Course';
    final ayLabel = termHelper?.academicYearName() ?? 'Academic Year';
    final semLabel = termHelper?.semesterName() ?? 'Semester';
    final createCourseLabel = termHelper?.createLabel(AcademicConcept.program) ?? 'Create Course';
    final createAyLabel = termHelper?.createLabel(AcademicConcept.academicYear) ?? 'Create Academic Year';

    if (courses.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        title: 'Before you continue',
        message: 'A $courseLabel is required before creating a $semLabel.',
        actionLabel: createCourseLabel,
        actionRoute: '/academics/courses/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (academicYears.isEmpty) {
      final isHod = role == AppRole.hod;
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.academicYear,
        title: 'Before you continue',
        message: isHod
            ? '$ayLabel is institution-wide and managed by College Administration. Please notify your College Admin before creating a $semLabel.'
            : 'An $ayLabel is required before creating a $semLabel.',
        actionLabel: isHod ? 'Notify College Admin' : createAyLabel,
        actionRoute: isHod ? null : '/academics/academic_years/new',
        priorityLevel: PrerequisitePriorityLevel.core,
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
    bool isSectionEnabled = true,
    TerminologyHelper? termHelper,
  }) {
    final effectiveIsSectionEnabled = termHelper?.isSectionEnabled ?? isSectionEnabled;
    final progLabel = termHelper?.programName() ?? 'Course';
    final progsLabel = termHelper?.programName(plural: true) ?? 'Courses';
    final ayLabel = termHelper?.academicYearName() ?? 'Academic Year';
    final semLabel = termHelper?.semesterName() ?? 'Semester';
    final semsLabel = termHelper?.semesterName(plural: true) ?? 'Semesters';
    final secLabel = termHelper?.sectionName() ?? 'Section';
    final secsLabel = termHelper?.sectionName(plural: true) ?? 'Sections';
    final subLabel = termHelper?.subjectName() ?? 'Subject';
    final subsLabel = termHelper?.subjectName(plural: true) ?? 'Subjects';

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
    final enrolledStudents = students.where((s) => s.isActive && (!effectiveIsSectionEnabled || s.sectionId.isNotEmpty)).toList();
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
            actionLabel: 'Create $progLabel',
            explanation: 'Define $progsLabel offered by your department.',
            contextParams: {'departmentId': departmentId},
          );
        }
        return SetupActionDecision.waitingOnOtherRole(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: AppRole.hod,
          missingDependency: AcademicPrerequisiteType.course,
          explanation: 'A $progLabel must be created before department academic setup can proceed.',
          waitingReason: '$progLabel creation is managed by Department Head or College Administration.',
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
            explanation: 'Your college has not configured an ${ayLabel.toLowerCase()} yet. $semsLabel require an active ${ayLabel.toLowerCase()}.',
            waitingReason: '$ayLabel is created by College Admin and is required before $semsLabel can be configured.',
            notifyActionLabel: 'Notify College Admin',
          );
        }
        if (isCollegeAdmin || isSuperAdmin) {
          return SetupActionDecision.ready(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: AppRole.collegeAdmin,
            actionRoute: '/academics/academic_years/new',
            actionLabel: 'Create $ayLabel',
            explanation: '$ayLabel is required for ${semLabel.toLowerCase()} setup across college departments.',
          );
        }
        return SetupActionDecision.waitingOnOtherRole(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: AppRole.collegeAdmin,
          missingDependency: AcademicPrerequisiteType.academicYear,
          explanation: '$ayLabel is required for ${semLabel.toLowerCase()} setup.',
          waitingReason: '$ayLabel is created by College Admin.',
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
            actionLabel: canManageDept ? 'Create $progLabel' : null,
            explanation: 'Create a $progLabel first before setting up teaching ${semsLabel.toLowerCase()}.',
          );
        }
        if (!hasAcademicYear) {
          if (isHod) {
            return SetupActionDecision.waitingOnOtherRole(
              milestoneId: milestoneId,
              currentRole: currentRole,
              ownerRole: AppRole.collegeAdmin,
              missingDependency: AcademicPrerequisiteType.academicYear,
              explanation: 'Waiting for College Admin to configure $ayLabel before $semsLabel can be created.',
              waitingReason: '$ayLabel is managed by College Administration.',
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
            actionLabel: 'Create $ayLabel',
            explanation: 'An $ayLabel must be created before adding ${semsLabel.toLowerCase()}.',
          );
        }
        // Both Course and Academic Year are present
        final activeCourse = deptCourses.first;
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/academics/semesters/new?courseId=${activeCourse.id}&academicYearId=${effectiveAy.id}',
          actionLabel: 'Create $semLabel',
          explanation: 'Create active teaching terms under your department $progsLabel.',
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
            actionLabel: (canManageDept && deptCourses.isNotEmpty && hasAcademicYear) ? 'Create $semLabel' : null,
            explanation: 'Create a $semLabel for this $progLabel before configuring ${secsLabel.toLowerCase()}.',
          );
        }
        final activeSectionSemester = deptSemesters.first;
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/academics/sections/new?courseId=${firstCourse?.id ?? ""}&semesterId=${activeSectionSemester.id}',
          actionLabel: 'Create $secLabel',
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
            actionLabel: (canManageDept && deptCourses.isNotEmpty && hasAcademicYear) ? 'Create $semLabel' : null,
            explanation: 'Create a $semLabel for this $progLabel before configuring ${subsLabel.toLowerCase()}.',
          );
        }
        final activeSubjectSemester = deptSemesters.first;
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/academics/subjects/new?courseId=${firstCourse?.id ?? ""}&semesterId=${activeSubjectSemester.id}',
          actionLabel: 'Add $subLabel',
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
        if (effectiveIsSectionEnabled && deptSections.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.section,
            canCurrentUserAct: canManageDept,
            explanation: 'Create ${secsLabel.toLowerCase()} before allocating faculty members.',
          );
        }
        if (deptSubjects.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.subject,
            canCurrentUserAct: canManageDept,
            explanation: 'Add ${subsLabel.toLowerCase()} before allocating faculty members.',
          );
        }
        // Section & Subject exist, check active faculty availability
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
              explanation: 'No active faculty is available for this $subLabel. Provision faculty first.',
            );
          }
          return SetupActionDecision.waitingOnOtherRole(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.faculty,
            explanation: 'No active faculty is available for this $subLabel.',
            waitingReason: 'Faculty creation is handled by College Admin.',
          );
        }
        return SetupActionDecision.ready(
          milestoneId: milestoneId,
          currentRole: currentRole,
          ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
          actionRoute: '/faculty-assignments',
          actionLabel: 'Assign Faculty',
          explanation: 'Allocate teachers and professors to $subLabel ${effectiveIsSectionEnabled ? "$secLabel " : ""}batches.',
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
        if (effectiveIsSectionEnabled && deptSections.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.section,
            canCurrentUserAct: canManageDept,
            explanation: 'Create ${secsLabel.toLowerCase()} before enrolling students.',
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
              explanation: 'No admitted students available for enrollment. Student accounts must be provisioned before assigning to ${effectiveIsSectionEnabled ? secsLabel.toLowerCase() : semsLabel.toLowerCase()}.',
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
          explanation: 'Assign admitted students to department ${effectiveIsSectionEnabled ? secsLabel.toLowerCase() : semsLabel.toLowerCase()} for class rosters.',
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
        if (effectiveIsSectionEnabled && deptSections.isEmpty) {
          return SetupActionDecision.blocked(
            milestoneId: milestoneId,
            currentRole: currentRole,
            ownerRole: isHod ? AppRole.hod : AppRole.collegeAdmin,
            missingDependency: AcademicPrerequisiteType.section,
            canCurrentUserAct: false,
            actionRoute: null,
            explanation: 'Create ${secsLabel.toLowerCase()} before generating timetables.',
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
            explanation: 'Add ${subsLabel.toLowerCase()} before generating timetables.',
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
            explanation: 'Assign faculty to ${subsLabel.toLowerCase()} before creating timetable schedules.',
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
    TerminologyHelper? termHelper,
  }) {
    final courseLabel = termHelper?.programName() ?? 'Course';
    final semLabel = termHelper?.semesterName() ?? 'Semester';
    final createCourseLabel = termHelper?.createLabel(AcademicConcept.program) ?? 'Create Course';
    final createSemLabel = termHelper?.createLabel(AcademicConcept.semester) ?? 'Create Semester';

    if (courses.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        title: 'Before you continue',
        message: 'A $courseLabel is required before creating a ${termHelper?.sectionName() ?? "Section"}.',
        actionLabel: createCourseLabel,
        actionRoute: '/academics/courses/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (semesters.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        title: 'Before you continue',
        message: 'Create a $semLabel for this $courseLabel first.',
        actionLabel: createSemLabel,
        actionRoute: '/academics/semesters/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Validates prerequisites before Subject creation.
  static PrerequisiteCheckResult checkSubjectPrerequisites({
    required List<Course> courses,
    required List<Semester> semesters,
    TerminologyHelper? termHelper,
  }) {
    final courseLabel = termHelper?.programName() ?? 'Course';
    final semLabel = termHelper?.semesterName() ?? 'Semester';
    final createCourseLabel = termHelper?.createLabel(AcademicConcept.program) ?? 'Create Course';
    final createSemLabel = termHelper?.createLabel(AcademicConcept.semester) ?? 'Create Semester';

    if (courses.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        title: 'Before you continue',
        message: 'A $courseLabel is required before adding a ${termHelper?.subjectName() ?? "Subject"}.',
        actionLabel: createCourseLabel,
        actionRoute: '/academics/courses/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (semesters.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        title: 'Before you continue',
        message: 'Create a $semLabel for this $courseLabel first.',
        actionLabel: createSemLabel,
        actionRoute: '/academics/semesters/new',
        priorityLevel: PrerequisitePriorityLevel.core,
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
    List<AcademicYear>? academicYears,
    List<Faculty>? faculty,
    List<Faculty>? faculties,
    bool isSectionEnabled = true,
    TerminologyHelper? termHelper,
  }) {
    final effSectionEnabled = termHelper?.isSectionEnabled ?? isSectionEnabled;
    final courseLabel = termHelper?.programName() ?? 'Course';
    final semLabel = termHelper?.semesterName() ?? 'Semester';
    final secLabel = termHelper?.sectionName() ?? 'Section';
    final subLabel = termHelper?.subjectName() ?? 'Subject';
    final ayLabel = termHelper?.academicYearName() ?? 'Academic Year';

    final effectiveFaculty = faculty ?? faculties ?? <Faculty>[];
    if (academicYears != null && academicYears.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.academicYear,
        title: 'Before you continue',
        message: 'Create an $ayLabel before creating a teaching assignment.',
        actionLabel: termHelper?.createLabel(AcademicConcept.academicYear) ?? 'Create Academic Year',
        actionRoute: '/academics/academic_years/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (courses.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        title: 'Before you continue',
        message: 'A $courseLabel is required before allocating faculty.',
        actionLabel: termHelper?.createLabel(AcademicConcept.program) ?? 'Create Course',
        actionRoute: '/academics/courses/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (semesters.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        title: 'Before you continue',
        message: 'Create a $semLabel for this $courseLabel first.',
        actionLabel: termHelper?.createLabel(AcademicConcept.semester) ?? 'Create Semester',
        actionRoute: '/academics/semesters/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (effSectionEnabled && sections.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.section,
        title: 'Before you continue',
        message: 'Create a $secLabel for this $semLabel first.',
        actionLabel: termHelper?.createLabel(AcademicConcept.section) ?? 'Create Section',
        actionRoute: '/academics/sections/new',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    if (subjects.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.subject,
        title: 'Before you continue',
        message: 'Add a $subLabel for this $semLabel first.',
        actionLabel: termHelper?.addLabel(AcademicConcept.subject) ?? 'Add Subject',
        actionRoute: '/academics/subjects/new',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    final activeFaculty = effectiveFaculty.where((f) => f.isActive).toList();
    if (activeFaculty.isEmpty) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.faculty,
        title: 'Before you continue',
        message: 'No active faculty available. Create or activate a faculty member first.',
        actionLabel: 'Provision Faculty',
        actionRoute: '/academics/faculty/new',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Validates prerequisites before Student Enrollment.
  static PrerequisiteCheckResult checkStudentEnrollmentPrerequisites({
    required List<Course> courses,
    required List<Semester> semesters,
    required List<Section> sections,
    bool isSectionEnabled = true,
    TerminologyHelper? termHelper,
  }) {
    final effSectionEnabled = termHelper?.isSectionEnabled ?? isSectionEnabled;
    final courseLabel = termHelper?.programName() ?? 'Course';
    final semLabel = termHelper?.semesterName() ?? 'Semester';
    final secLabel = termHelper?.sectionName() ?? 'Section';

    if (courses.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        title: 'Before you continue',
        message: 'Create a $courseLabel before enrolling students.',
        actionLabel: termHelper?.createLabel(AcademicConcept.program) ?? 'Create Course',
        actionRoute: '/academics/courses/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (semesters.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        title: 'Before you continue',
        message: 'Create a $semLabel first.',
        actionLabel: termHelper?.createLabel(AcademicConcept.semester) ?? 'Create Semester',
        actionRoute: '/academics/semesters/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (effSectionEnabled && sections.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.section,
        title: 'Before you continue',
        message: 'Create a $secLabel first.',
        actionLabel: termHelper?.createLabel(AcademicConcept.section) ?? 'Create Section',
        actionRoute: '/academics/sections/new',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Validates the prerequisite chain before Timetable authoring.
  /// Note: Rooms are optional unless institutional configuration requires them.
  static PrerequisiteCheckResult checkTimetablePrerequisites({
    required List<Course> courses,
    required List<AcademicYear> academicYears,
    required List<Semester> semesters,
    required List<Section> sections,
    required List<Subject> subjects,
    required List<FacultyAssignment> facultyAssignments,
    required List<Room> rooms,
    bool isRoomRequired = false,
    bool isSectionEnabled = true,
    TerminologyHelper? termHelper,
  }) {
    final effSectionEnabled = termHelper?.isSectionEnabled ?? isSectionEnabled;
    final effRoomEnabled = termHelper?.isRoomEnabled ?? true;
    final effRoomRequired = isRoomRequired && effRoomEnabled;

    final courseLabel = termHelper?.programName() ?? 'Course';
    final ayLabel = termHelper?.academicYearName() ?? 'Academic Year';
    final semLabel = termHelper?.semesterName() ?? 'Semester';
    final secLabel = termHelper?.sectionName() ?? 'Section';
    final subLabel = termHelper?.subjectName() ?? 'Subject';
    final roomLabel = termHelper?.roomName() ?? 'Room';

    if (courses.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.course,
        title: 'Timetable needs a little setup',
        message: 'Create a $courseLabel first.',
        actionLabel: termHelper?.createLabel(AcademicConcept.program) ?? 'Create Course',
        actionRoute: '/academics/courses/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (academicYears.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.academicYear,
        title: 'Timetable needs a little setup',
        message: 'Create an $ayLabel first.',
        actionLabel: termHelper?.createLabel(AcademicConcept.academicYear) ?? 'Create Academic Year',
        actionRoute: '/academics/academic_years/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (semesters.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.semester,
        title: 'Timetable needs a little setup',
        message: 'Create a $semLabel for this $courseLabel first.',
        actionLabel: termHelper?.createLabel(AcademicConcept.semester) ?? 'Create Semester',
        actionRoute: '/academics/semesters/new',
        priorityLevel: PrerequisitePriorityLevel.core,
      );
    }
    if (effSectionEnabled && sections.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.section,
        title: 'Timetable needs a little setup',
        message: 'Create a $secLabel for this $semLabel first.',
        actionLabel: termHelper?.createLabel(AcademicConcept.section) ?? 'Create Section',
        actionRoute: '/academics/sections/new',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    if (subjects.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.subject,
        title: 'Timetable needs a little setup',
        message: 'Add a $subLabel for this $semLabel first.',
        actionLabel: termHelper?.addLabel(AcademicConcept.subject) ?? 'Add Subject',
        actionRoute: '/academics/subjects/new',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    final activeAssignments = facultyAssignments.where((a) => a.isActive).toList();
    if (activeAssignments.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.facultyAssignment,
        title: 'Timetable needs a little setup',
        message: 'Assign a faculty member to the $subLabel before creating the timetable. At least one teaching assignment is required before you can schedule a class.',
        actionLabel: 'Assign Faculty',
        actionRoute: '/faculty-assignments',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    if (effRoomRequired && rooms.isEmpty) {
      return PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.room,
        title: 'Timetable needs a little setup',
        message: 'No ${roomLabel.toLowerCase()}s are set up yet. Your institution requires ${roomLabel.toLowerCase()}s for timetable scheduling. Click below to add a $roomLabel.',
        actionLabel: termHelper?.addLabel(AcademicConcept.room) ?? 'Add Room',
        actionRoute: '/academics/rooms/new',
        priorityLevel: PrerequisitePriorityLevel.optional,
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
        title: 'Before you continue',
        message: 'This class is not published on the timetable.',
        actionLabel: 'View Timetable',
        actionRoute: '/timetable',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    if (enrolledStudentsCount <= 0) {
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.enrollment,
        title: 'Before you continue',
        message: 'No students are enrolled in this section yet.',
        actionLabel: 'Manage Sections',
        actionRoute: '/academics/sections',
        priorityLevel: PrerequisitePriorityLevel.contextual,
      );
    }
    return const PrerequisiteCheckResult.allowed();
  }

  /// Smart prerequisite modal explaining what is missing, why it is needed, and what to do next.
  static Future<void> showSmartPrerequisiteDialog(
    BuildContext context,
    PrerequisiteCheckResult result, {
    String? title,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogTitle = title ?? result.title ?? 'Before you continue';

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.12),
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: const Icon(LucideIcons.compass, size: 20, color: AcadexColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dialogTitle,
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message ?? 'A required academic foundation is needed before continuing.',
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          if (result.actionLabel != null && result.actionRoute != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  /// Displays a modal explaining the missing prerequisite with direct action button.
  static Future<void> showBlockerDialog(
    BuildContext context,
    PrerequisiteCheckResult result,
  ) => showSmartPrerequisiteDialog(context, result);

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
              const Icon(LucideIcons.compass, size: 18, color: AcadexColors.warning),
              const SizedBox(width: 8),
              Text(
                result.title ?? 'Before you continue',
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
