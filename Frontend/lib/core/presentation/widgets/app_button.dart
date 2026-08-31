import 'package:flutter/material.dart';
import 'acadex_button.dart';

enum AppButtonVariant { primary, secondary, outline, text, destructive }

/// Legacy bridge widget delegating to [AcadexButton].
/// Maintained for test compatibility. Prefer using [AcadexButton] directly.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    AcadexButtonVariant canonicalVariant;
    switch (variant) {
      case AppButtonVariant.primary:
        canonicalVariant = AcadexButtonVariant.primary;
        break;
      case AppButtonVariant.secondary:
        canonicalVariant = AcadexButtonVariant.soft;
        break;
      case AppButtonVariant.outline:
        canonicalVariant = AcadexButtonVariant.secondary;
        break;
      case AppButtonVariant.destructive:
        canonicalVariant = AcadexButtonVariant.danger;
        break;
      case AppButtonVariant.text:
        canonicalVariant = AcadexButtonVariant.ghost;
        break;
    }

    return AcadexButton(
      label: label,
      onPressed: onPressed,
      variant: canonicalVariant,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      padding: padding,
    );
  }
}
