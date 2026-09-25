import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/academic_models.dart';

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
      return const PrerequisiteCheckResult.blocked(
        missingType: AcademicPrerequisiteType.academicYear,
        message: 'Please create an academic year first.',
        actionLabel: 'Create Academic Year',
        actionRoute: '/academics/academic_years/new',
      );
    }
    return const PrerequisiteCheckResult.allowed();
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
