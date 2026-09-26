import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';

enum AcademicSetupStep {
  course,
  academicYear,
  semester,
  section,
  subject,
  facultyAssignment,
  studentEnrollment,
  timetable,
  publishTimetable,
}

class FreshDepartmentSetupCard extends StatelessWidget {
  final AcademicSetupStep currentStep;
  final VoidCallback onAction;
  final String actionLabel;
  final String? customMessage;

  const FreshDepartmentSetupCard({
    super.key,
    required this.currentStep,
    required this.onAction,
    required this.actionLabel,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AcadexColors.primary.withValues(alpha: 0.12),
                            borderRadius: AcadexRadius.borderRadiusMd,
                          ),
                          child: const Icon(LucideIcons.sparkles, color: AcadexColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Academic Foundation Setup",
                                style: AcadexTypography.heading3(
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Fresh Department Onboarding",
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AcadexBadge(
                    label: "FOUNDATION",
                    variant: AcadexBadgeVariant.primary,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Text(
                customMessage ??
                    "Establish your department's core academic hierarchy before sections, subjects, faculty allocations, and timetable can be created.",
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 8-Step Guided Roadmap
              _buildStepItem(
                context,
                stepNumber: 1,
                title: "Course",
                description: "Define courses offered by your department (e.g. Diploma in Computer Engineering).",
                icon: LucideIcons.graduationCap,
                isCompleted: currentStep.index > AcademicSetupStep.course.index,
                isCurrent: currentStep == AcademicSetupStep.course,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                context,
                stepNumber: 2,
                title: "Academic Year",
                description: "Associate or confirm the active institutional academic calendar (e.g. 2026–27).",
                icon: LucideIcons.calendar,
                isCompleted: currentStep.index > AcademicSetupStep.academicYear.index,
                isCurrent: currentStep == AcademicSetupStep.academicYear,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                context,
                stepNumber: 3,
                title: "Semesters",
                description: "Create sequential semesters for your course and academic year.",
                icon: LucideIcons.calendarClock,
                isCompleted: currentStep.index > AcademicSetupStep.semester.index,
                isCurrent: currentStep == AcademicSetupStep.semester,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                context,
                stepNumber: 4,
                title: "Sections",
                description: "Create student cohorts (e.g. Section A, B) with seat capacity under each semester.",
                icon: LucideIcons.users,
                isCompleted: currentStep.index > AcademicSetupStep.section.index,
                isCurrent: currentStep == AcademicSetupStep.section,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                context,
                stepNumber: 5,
                title: "Subjects",
                description: "Add theory and lab curriculum subjects with credit hours for your semesters.",
                icon: LucideIcons.bookOpen,
                isCompleted: currentStep.index > AcademicSetupStep.subject.index,
                isCurrent: currentStep == AcademicSetupStep.subject,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                context,
                stepNumber: 6,
                title: "Assign Faculty",
                description: "Assign qualified faculty to teach subjects for each section and academic context.",
                icon: LucideIcons.userCheck,
                isCompleted: currentStep.index > AcademicSetupStep.facultyAssignment.index,
                isCurrent: currentStep == AcademicSetupStep.facultyAssignment,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                context,
                stepNumber: 7,
                title: "Enroll Students",
                description: "Connect existing department students to academic sections to build the authoritative roster.",
                icon: LucideIcons.userPlus,
                isCompleted: currentStep.index > AcademicSetupStep.studentEnrollment.index,
                isCurrent: currentStep == AcademicSetupStep.studentEnrollment,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                context,
                stepNumber: 8,
                title: "Create Timetable",
                description: "Schedule teaching periods using validated faculty assignments and room allocations.",
                icon: LucideIcons.calendarClock,
                isCompleted: currentStep.index > AcademicSetupStep.timetable.index,
                isCurrent: currentStep == AcademicSetupStep.timetable,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStepItem(
                context,
                stepNumber: 9,
                title: "Publish Timetable",
                description: "Validate conflict-free department schedule and publish authoritative periods for faculty and students.",
                icon: LucideIcons.send,
                isCompleted: currentStep.index > AcademicSetupStep.publishTimetable.index,
                isCurrent: currentStep == AcademicSetupStep.publishTimetable,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: onAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required bool isCompleted,
    required bool isCurrent,
    required bool isDark,
  }) {
    Color borderColor;
    Color bgColor;

    if (isCompleted) {
      borderColor = AcadexColors.success.withValues(alpha: 0.5);
      bgColor = isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight;
    } else if (isCurrent) {
      borderColor = AcadexColors.primary;
      bgColor = isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight;
    } else {
      borderColor = isDark ? AcadexColors.darkHairline : AcadexColors.hairline;
      bgColor = isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AcadexColors.success
                  : (isCurrent ? AcadexColors.primary : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft)),
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                : Text(
                    "$stepNumber",
                    style: TextStyle(
                      color: isCurrent ? Colors.white : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "CURRENT STEP",
                          style: TextStyle(
                            color: AcadexColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
