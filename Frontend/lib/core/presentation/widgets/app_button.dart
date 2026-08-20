import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, text, destructive }

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
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12);

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AcadexColors.primaryNavy,
            foregroundColor: Colors.white,
            padding: effectivePadding,
            shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          ),
          child: content,
        );
        break;
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AcadexColors.emeraldTeal,
            foregroundColor: Colors.white,
            padding: effectivePadding,
            shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          ),
          child: content,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AcadexColors.primaryNavy,
            side: const BorderSide(color: AcadexColors.borderLight, width: 1.5),
            padding: effectivePadding,
            shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          ),
          child: content,
        );
        break;
      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AcadexColors.coralError,
            foregroundColor: Colors.white,
            padding: effectivePadding,
            shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          ),
          child: content,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: effectivePadding,
            shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          ),
          child: content,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
