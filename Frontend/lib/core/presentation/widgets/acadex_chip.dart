import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

enum AcadexBadgeVariant {
  neutral,
  primary,
  success,
  warning,
  danger,
  info,
  purple,
  teal,
}

class AcadexBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AcadexBadgeVariant variant;
  final VoidCallback? onTap;

  const AcadexBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AcadexBadgeVariant.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case AcadexBadgeVariant.neutral:
        bg = isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft;
        fg = isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary;
        border = isDark ? AcadexColors.darkHairline : AcadexColors.hairline;
        break;
      case AcadexBadgeVariant.primary:
        bg = isDark ? AcadexColors.primaryHover.withValues(alpha: 0.3) : AcadexColors.primaryLight;
        fg = isDark ? AcadexColors.primaryMuted : AcadexColors.primary;
        border = isDark ? AcadexColors.primaryHover.withValues(alpha: 0.5) : AcadexColors.primaryLight;
        break;
      case AcadexBadgeVariant.success:
        bg = isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight;
        fg = isDark ? AcadexColors.success : AcadexColors.successDark;
        border = isDark ? AcadexColors.successDark : AcadexColors.successLight;
        break;
      case AcadexBadgeVariant.warning:
        bg = isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight;
        fg = isDark ? AcadexColors.warning : AcadexColors.warningDark;
        border = isDark ? AcadexColors.warningDark : AcadexColors.warningLight;
        break;
      case AcadexBadgeVariant.danger:
        bg = isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight;
        fg = isDark ? AcadexColors.error : AcadexColors.errorDark;
        border = isDark ? AcadexColors.errorDark : AcadexColors.errorLight;
        break;
      case AcadexBadgeVariant.info:
        bg = isDark ? AcadexColors.infoDark.withValues(alpha: 0.3) : AcadexColors.infoLight;
        fg = isDark ? AcadexColors.info : AcadexColors.infoDark;
        border = isDark ? AcadexColors.infoDark.withValues(alpha: 0.5) : AcadexColors.infoLight;
        break;
      case AcadexBadgeVariant.purple:
        bg = isDark ? AcadexColors.accentDeepPurple.withValues(alpha: 0.4) : AcadexColors.accentPurpleLight;
        fg = isDark ? AcadexColors.accentPurple : AcadexColors.accentDeepPurple;
        border = isDark ? AcadexColors.accentDeepPurple : AcadexColors.accentPurpleLight;
        break;
      case AcadexBadgeVariant.teal:
        bg = isDark ? const Color(0xFF134E4A) : AcadexColors.accentTealLight;
        fg = isDark ? AcadexColors.accentTeal : const Color(0xFF115E59);
        border = isDark ? const Color(0xFF134E4A) : AcadexColors.accentTealLight;
        break;
    }

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AcadexRadius.borderRadiusFull,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AcadexTypography.eyebrow(color: fg),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AcadexRadius.borderRadiusFull,
        child: child,
      );
    }

    return child;
  }
}

class AcadexChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final Widget? avatar;

  const AcadexChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelected,
    this.icon,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? AcadexColors.primaryHover : AcadexColors.primaryLight;
    final selectedFg = isDark ? Colors.white : AcadexColors.primary;
    final selectedBorder = isDark ? AcadexColors.primaryMuted : AcadexColors.primary;

    final unselectedBg = isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface;
    final unselectedFg = isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary;
    final unselectedBorder = isDark ? AcadexColors.darkHairline : AcadexColors.hairline;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      avatar: avatar ?? (icon != null ? Icon(icon, size: 14, color: isSelected ? selectedFg : unselectedFg) : null),
      backgroundColor: unselectedBg,
      selectedColor: selectedBg,
      checkmarkColor: selectedFg,
      labelStyle: AcadexTypography.caption(
        color: isSelected ? selectedFg : unselectedFg,
      ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: AcadexRadius.borderRadiusFull,
        side: BorderSide(
          color: isSelected ? selectedBorder : unselectedBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }
}
