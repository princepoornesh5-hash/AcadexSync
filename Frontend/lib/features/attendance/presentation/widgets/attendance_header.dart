import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';

class AttendanceHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const AttendanceHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AcadexTypography.title(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
