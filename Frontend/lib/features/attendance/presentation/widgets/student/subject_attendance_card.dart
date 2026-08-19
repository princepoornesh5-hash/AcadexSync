import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/subject_attendance.dart';

class SubjectAttendanceCard extends StatelessWidget {
  final SubjectAttendance subject;
  final VoidCallback onTap;

  const SubjectAttendanceCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final perc = subject.percentage;
    final isGood = perc >= 75;
    final isWarning = perc >= 60 && perc < 75;
    final color = isGood ? AcadexColors.success : (isWarning ? AcadexColors.warning : AcadexColors.error);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AcadexRadius.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.subjectName,
                            style: AcadexTypography.title(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (subject.subjectCode.isNotEmpty) ...[
                                Text(
                                  subject.subjectCode,
                                  style: AcadexTypography.caption(
                                    color: AcadexColors.primary,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  " • ",
                                  style: TextStyle(
                                    color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  subject.facultyName,
                                  style: AcadexTypography.caption(
                                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${perc.toStringAsFixed(0)}%",
                      style: AcadexTypography.heading1(color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (perc / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Attended", subject.attendedClasses.toString(), AcadexColors.success, isDark),
                    _buildStatItem("Missed", subject.missedClasses.toString(), AcadexColors.error, isDark),
                    _buildStatItem("Total", subject.totalClasses.toString(), isDark ? AcadexColors.darkInk : AcadexColors.ink, isDark),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor, bool isDark) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        Text(
          value,
          style: AcadexTypography.bodySmall(
            color: valueColor,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
