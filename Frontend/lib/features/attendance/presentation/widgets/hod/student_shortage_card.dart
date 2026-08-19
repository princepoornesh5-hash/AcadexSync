import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/student_shortage.dart';

class StudentShortageCard extends StatelessWidget {
  final StudentShortage shortage;

  const StudentShortageCard({super.key, required this.shortage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCritical = shortage.status == ShortageStatus.critical;
    final color = isCritical ? AcadexColors.error : AcadexColors.warning;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  "${shortage.currentPercentage.toInt()}%",
                  style: AcadexTypography.title(color: color).copyWith(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortage.studentName,
                    style: AcadexTypography.body(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${shortage.rollNumber} • ${shortage.semester} • ${shortage.section}",
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
