import 'package:flutter/material.dart';
import 'acadex_chip.dart';

enum AppBadgeVariant { success, warning, error, info, neutral, primary }

/// Legacy bridge widget delegating to [AcadexBadge].
/// Maintained for test compatibility. Prefer using [AcadexBadge] directly.
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
    AcadexBadgeVariant canonicalVariant;
    switch (variant) {
      case AppBadgeVariant.success:
        canonicalVariant = AcadexBadgeVariant.success;
        break;
      case AppBadgeVariant.warning:
        canonicalVariant = AcadexBadgeVariant.warning;
        break;
      case AppBadgeVariant.error:
        canonicalVariant = AcadexBadgeVariant.danger;
        break;
      case AppBadgeVariant.info:
        canonicalVariant = AcadexBadgeVariant.info;
        break;
      case AppBadgeVariant.primary:
        canonicalVariant = AcadexBadgeVariant.primary;
        break;
      case AppBadgeVariant.neutral:
        canonicalVariant = AcadexBadgeVariant.neutral;
        break;
    }

    return AcadexBadge(
      label: label,
      variant: canonicalVariant,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}
