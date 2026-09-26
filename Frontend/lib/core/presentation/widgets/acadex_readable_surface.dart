import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';

/// A lightweight translucent white readability surface designed for content
/// placed over the canonical white canvas.
///
/// It provides a frosted glass-like surface with soft depth and subtle hairline border
/// ensuring visual separation and crisp contrast for dark typography.
class AcadexReadableSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final BoxBorder? border;
  final BoxConstraints? constraints;

  const AcadexReadableSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color.fromRGBO(255, 255, 255, 0.85),
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        border: border ?? Border.all(
          color: AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
