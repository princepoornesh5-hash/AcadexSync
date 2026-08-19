import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';

class AcadexListTile extends StatelessWidget {
  final Widget? leading;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Color? leadingBackgroundColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? contentPadding;

  const AcadexListTile({
    super.key,
    this.leading,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingBackgroundColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isSelected
        ? (isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight)
        : Colors.transparent;

    final defaultBorder = isSelected
        ? Border.all(
            color: isDark ? AcadexColors.primaryMuted.withValues(alpha: 0.5) : AcadexColors.primary.withValues(alpha: 0.3),
            width: 1,
          )
        : Border.all(color: Colors.transparent, width: 1);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && leadingIcon != null) {
      final iconColor = leadingIconColor ?? (isDark ? AcadexColors.primaryMuted : AcadexColors.primary);
      final iconBg = leadingBackgroundColor ??
          (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft);

      leadingWidget = Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: AcadexRadius.borderRadiusMd,
        ),
        child: Icon(leadingIcon, size: 18, color: iconColor),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: defaultBorder,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AcadexRadius.borderRadiusMd,
          child: Padding(
            padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (leadingWidget != null) ...[
                  leadingWidget,
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AcadexTypography.bodyMedium(
                          color: isSelected
                              ? (isDark ? AcadexColors.primaryMuted : AcadexColors.primary)
                              : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                        ).copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ] else if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
