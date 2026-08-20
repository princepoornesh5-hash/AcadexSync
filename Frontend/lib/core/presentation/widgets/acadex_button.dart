import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

enum AcadexButtonVariant { primary, secondary, danger, ghost }
enum AcadexButtonSize { sm, md, lg }

class AcadexButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final AcadexButtonVariant variant;
  final AcadexButtonSize size;

  const AcadexButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.variant = AcadexButtonVariant.primary,
    this.size = AcadexButtonSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AcadexButtonVariant.primary:
        bg = AcadexColors.primary;
        fg = Colors.white;
        break;
      case AcadexButtonVariant.secondary:
        bg = isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface;
        fg = isDark ? AcadexColors.darkInk : AcadexColors.ink;
        border = BorderSide(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        );
        break;
      case AcadexButtonVariant.danger:
        bg = AcadexColors.error;
        fg = Colors.white;
        break;
      case AcadexButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AcadexColors.primaryMuted : AcadexColors.primary;
        break;
    }

    double height;
    EdgeInsets padding;
    double fontSize;
    double iconSize;

    switch (size) {
      case AcadexButtonSize.sm:
        height = 34;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        fontSize = 12;
        iconSize = 14;
        break;
      case AcadexButtonSize.md:
        height = 42;
        padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10);
        fontSize = 14;
        iconSize = 16;
        break;
      case AcadexButtonSize.lg:
        height = 48;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
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
          Icon(icon, size: iconSize, color: fg),
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
      padding: padding,
      minimumSize: Size(isFullWidth ? double.infinity : 0, height),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary;

    final btn = Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: AcadexRadius.borderRadiusSm,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AcadexRadius.borderRadiusSm,
        child: Padding(
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
