import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import 'acadex_motion.dart';

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
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;

  const AcadexBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AcadexBadgeVariant.neutral,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    if (backgroundColor != null && textColor != null) {
      bg = backgroundColor!;
      fg = textColor!;
      border = backgroundColor!.withValues(alpha: 0.5);
    } else {
      switch (variant) {
        case AcadexBadgeVariant.neutral:
          bg = AcadexColors.canvasSoft;
          fg = AcadexColors.inkSecondary;
          border = AcadexColors.hairline;
          break;
        case AcadexBadgeVariant.primary:
          bg = AcadexColors.primaryLight;
          fg = AcadexColors.primary;
          border = AcadexColors.primaryLight;
          break;
        case AcadexBadgeVariant.success:
          bg = AcadexColors.successLight;
          fg = AcadexColors.success;
          border = AcadexColors.successLight;
          break;
        case AcadexBadgeVariant.warning:
          bg = AcadexColors.warningLight;
          fg = AcadexColors.warning;
          border = AcadexColors.warningLight;
          break;
        case AcadexBadgeVariant.danger:
          bg = AcadexColors.errorLight;
          fg = AcadexColors.error;
          border = AcadexColors.errorLight;
          break;
        case AcadexBadgeVariant.info:
          bg = AcadexColors.primaryTint;
          fg = AcadexColors.primary;
          border = AcadexColors.primaryLight;
          break;
        case AcadexBadgeVariant.purple:
          bg = AcadexColors.accentPurpleLight;
          fg = AcadexColors.accentPurple;
          border = AcadexColors.accentPurpleLight;
          break;
        case AcadexBadgeVariant.teal:
          bg = AcadexColors.accentTealLight;
          fg = AcadexColors.accentTeal;
          border = AcadexColors.accentTealLight;
          break;
      }
    }

    final child = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          Flexible(
            child: Text(
              label,
              style: AcadexTypography.eyebrow(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
    const selectedBg = AcadexColors.primaryLight;
    const selectedFg = AcadexColors.primary;
    const selectedBorder = AcadexColors.primary;

    const unselectedBg = AcadexColors.surface;
    const unselectedFg = AcadexColors.inkSecondary;
    const unselectedBorder = AcadexColors.hairline;

    return AcadexPressable(
      isInteractive: true,
      onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
      borderRadius: AcadexRadius.borderRadiusFull,
      child: AnimatedContainer(
        duration: AcadexMotion.normal,
        curve: AcadexMotion.curveStandard,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: AcadexRadius.borderRadiusFull,
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              avatar!,
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? selectedFg : unselectedFg),
              const SizedBox(width: 6),
            ],
            AnimatedDefaultTextStyle(
              duration: AcadexMotion.normal,
              curve: AcadexMotion.curveStandard,
              style: AcadexTypography.caption(
                color: isSelected ? selectedFg : unselectedFg,
              ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class AcadexFilterOption<T> {
  final String label;
  final T value;
  final int? count;

  const AcadexFilterOption({
    required this.label,
    required this.value,
    this.count,
  });
}

class AcadexFilterBar<T> extends StatelessWidget {
  final List<AcadexFilterOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const AcadexFilterBar({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = option.value == selectedValue;
          final String displayText = option.count != null ? '${option.label} (${option.count})' : option.label;
          
          return Padding(
            padding: const EdgeInsets.only(right: AcadexSpacing.space8),
            child: AcadexPressable(
              isInteractive: true,
              onTap: () => onSelected(option.value),
              borderRadius: AcadexRadius.borderRadiusSm,
              child: AnimatedContainer(
                duration: AcadexMotion.normal,
                curve: AcadexMotion.curveStandard,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AcadexColors.primary : AcadexColors.surface,
                  borderRadius: AcadexRadius.borderRadiusSm,
                  border: Border.all(
                    color: isSelected ? AcadexColors.primary : AcadexColors.hairline,
                    width: 1,
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: AcadexMotion.normal,
                  curve: AcadexMotion.curveStandard,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AcadexColors.inkSecondary,
                  ),
                  child: Text(displayText),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
