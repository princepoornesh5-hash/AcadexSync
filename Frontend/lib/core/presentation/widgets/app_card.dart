import 'package:flutter/material.dart';
import 'acadex_card.dart';

/// Legacy bridge widget delegating to [AcadexCard].
/// Maintained for test compatibility. Prefer using [AcadexCard] directly.
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
    return AcadexCard(
      padding: padding,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: child,
    );
  }
}
