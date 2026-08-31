import 'package:flutter/material.dart';

/// A lightweight translucent white readability surface designed for Super Admin
/// content placed over the vertical 21-stop blue-to-white gradient.
///
/// It provides a guaranteed high-contrast reading surface for dark text (#07111F, #334155, #475569)
/// across the entire gradient (from pitch black #000000 at top to pale #FFFFFF at bottom)
/// without requiring dynamic text color swapping.
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
        color: backgroundColor ?? const Color.fromRGBO(255, 255, 255, 0.74),
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        border: border ?? Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.45),
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
