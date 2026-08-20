import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AcadexColors.surfaceDark : AcadexColors.surfaceLight;
    final defaultBorder = isDark ? AcadexColors.borderDark : AcadexColors.borderLight;

    Widget cardContent = Container(
      padding: padding ?? AcadexSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: AcadexRadius.lgBorder,
        border: Border.all(color: borderColor ?? defaultBorder, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.lgBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AcadexRadius.lgBorder,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
