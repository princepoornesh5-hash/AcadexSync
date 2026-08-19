import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/faculty_attendance_completion.dart';
import '../../../../../core/presentation/widgets/acadex_badge.dart';

class FacultyCompletionCard extends StatelessWidget {
  final FacultyAttendanceCompletion completion;

  const FacultyCompletionCard({super.key, required this.completion});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isComplete = completion.pendingClasses == 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    completion.facultyName,
                    style: AcadexTypography.title(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                ),
                if (isComplete)
                  const AcadexBadge(
                    label: 'Completed',
                    variant: AcadexBadgeVariant.success,
                    icon: LucideIcons.checkCircle2,
                  )
                else
                  AcadexBadge(
                    label: '${completion.pendingClasses} Pending',
                    variant: AcadexBadgeVariant.warning,
                    icon: LucideIcons.clock,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              completion.assignedSubjects.join(", "),
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completion.progress,
                      backgroundColor: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? AcadexColors.success : AcadexColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${completion.completedClasses} / ${completion.completedClasses + completion.pendingClasses}",
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (completion.lastCompletionTime != null && isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Completed at ${DateFormat('HH:mm').format(completion.lastCompletionTime!)}",
                  style: AcadexTypography.caption(
                    color: AcadexColors.success,
                  ).copyWith(fontSize: 11),
                ),
              )
          ],
        ),
      ),
    );
  }
}
