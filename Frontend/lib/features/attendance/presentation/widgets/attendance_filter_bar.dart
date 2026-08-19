import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';

class AttendanceFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onMarkAllPresent;
  
  const AttendanceFilterBar({
    super.key,
    required this.onSearch,
    required this.onMarkAllPresent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
              ),
              child: TextField(
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: "Search by Name or Roll No...",
                  hintStyle: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: onSearch,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AcadexButton(
            label: "Mark All Present",
            icon: LucideIcons.checkCheck,
            variant: AcadexButtonVariant.secondary,
            onPressed: onMarkAllPresent,
          ),
        ],
      ),
    );
  }
}
