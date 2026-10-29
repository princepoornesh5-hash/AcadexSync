import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../utils/navigation_extensions.dart';

/// Standard ACADEX top-left back navigation button.
///
/// Features:
/// - Consistent LucideIcons.arrowLeft icon
/// - Respects dark/light ACADEX color theme
/// - Subtle pressed-state feedback
/// - Accessibility label and tooltip ('Back')
/// - Standard touch target
/// - Safe navigation with contextual fallback route resolution
class AcadexBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? fallbackRoute;
  final Color? color;
  final double iconSize;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry padding;
  final String tooltip;

  const AcadexBackButton({
    super.key,
    this.onPressed,
    this.fallbackRoute,
    this.color,
    this.iconSize = 20.0,
    this.constraints = const BoxConstraints(minWidth: 40, minHeight: 40),
    this.padding = EdgeInsets.zero,
    this.tooltip = 'Back',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final standardColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final effectiveColor = color ?? standardColor;

    return IconButton(
      icon: Icon(LucideIcons.arrowLeft, size: iconSize, color: effectiveColor),
      tooltip: tooltip,
      padding: padding,
      constraints: constraints,
      splashRadius: 20,
      onPressed:
          onPressed ?? () => context.safePop(fallbackRoute: fallbackRoute),
    );
  }
}
