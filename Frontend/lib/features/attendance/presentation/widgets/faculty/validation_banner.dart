import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';

class ValidationBanner extends StatelessWidget {
  final int remainingCount;

  const ValidationBanner({super.key, required this.remainingCount});

  @override
  Widget build(BuildContext context) {
    if (remainingCount == 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.warning.withValues(alpha: 0.4) : AcadexColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: AcadexColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Attention: $remainingCount student(s) currently have unmarked attendance.",
              style: AcadexTypography.bodySmall(
                color: isDark ? Colors.white : AcadexColors.warningDark,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
