import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';

enum AcadexButtonVariant { primary, secondary, soft, danger, ghost }
enum AcadexButtonSize { sm, md, lg }

class AcadexButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final AcadexButtonVariant variant;
  final AcadexButtonSize size;
  final EdgeInsetsGeometry? padding;

  const AcadexButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.variant = AcadexButtonVariant.primary,
    this.size = AcadexButtonSize.md,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color bg;
    Color fg;
    Color iconColor;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AcadexButtonVariant.primary:
        bg = AcadexColors.primary;
        fg = Colors.white;
        iconColor = Colors.white;
        break;
      case AcadexButtonVariant.secondary:
        bg = Colors.white;
        fg = AcadexColors.ink;
        iconColor = AcadexColors.ink;
        border = const BorderSide(
          color: AcadexColors.hairline,
          width: 1.0,
        );
        break;
      case AcadexButtonVariant.soft:
        bg = AcadexColors.primaryLight;
        fg = AcadexColors.primary;
        iconColor = AcadexColors.primary;
        break;
      case AcadexButtonVariant.danger:
        bg = AcadexColors.error;
        fg = Colors.white;
        iconColor = Colors.white;
        break;
      case AcadexButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AcadexColors.primary;
        iconColor = AcadexColors.primary;
        break;
    }

    double height;
    EdgeInsets defaultPadding;
    double fontSize;
    double iconSize;

    switch (size) {
      case AcadexButtonSize.sm:
        height = 36;
        defaultPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        fontSize = 12.5;
        iconSize = 14;
        break;
      case AcadexButtonSize.md:
        height = 44;
        defaultPadding = const EdgeInsets.symmetric(horizontal: 18, vertical: 11);
        fontSize = 14;
        iconSize = 16;
        break;
      case AcadexButtonSize.lg:
        height = 50;
        defaultPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
        fontSize = 15;
        iconSize = 18;
        break;
    }

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 8),
        ],
        if (isLoading && label.isNotEmpty) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AcadexTypography.button(color: fg).copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg.withValues(alpha: 0.5),
      disabledForegroundColor: fg.withValues(alpha: 0.5),
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: padding ?? defaultPadding,
      minimumSize: Size(isFullWidth ? double.infinity : 0, height),
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(
        borderRadius: AcadexRadius.borderRadiusMd,
        side: border,
      ),
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: content,
    );
  }
}

class AcadexSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final AcadexButtonSize size;

  const AcadexSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = AcadexButtonSize.md,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      variant: AcadexButtonVariant.secondary,
      size: size,
    );
  }
}

class AcadexIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AcadexIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    const defaultColor = AcadexColors.inkSecondary;

    final btn = Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: AcadexRadius.borderRadiusSm,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AcadexRadius.borderRadiusSm,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: size,
            color: color ?? defaultColor,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
