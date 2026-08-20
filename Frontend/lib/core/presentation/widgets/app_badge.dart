import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';

enum AppBadgeVariant { success, warning, error, info, neutral, primary }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (backgroundColor != null && textColor != null) {
      bg = backgroundColor!;
      fg = textColor!;
    } else {
      switch (variant) {
        case AppBadgeVariant.success:
          bg = AcadexColors.emeraldTealSurface;
          fg = AcadexColors.emeraldTeal;
          break;
        case AppBadgeVariant.warning:
          bg = AcadexColors.amberSurface;
          fg = AcadexColors.amberAccent;
          break;
        case AppBadgeVariant.error:
          bg = AcadexColors.coralErrorSurface;
          fg = AcadexColors.coralError;
          break;
        case AppBadgeVariant.info:
          bg = AcadexColors.skyInfoSurface;
          fg = AcadexColors.skyInfo;
          break;
        case AppBadgeVariant.primary:
          bg = AcadexColors.primaryNavy;
          fg = Colors.white;
          break;
        case AppBadgeVariant.neutral:
          bg = AcadexColors.surfaceLightMuted;
          fg = AcadexColors.textSecondaryLight;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AcadexRadius.smBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
