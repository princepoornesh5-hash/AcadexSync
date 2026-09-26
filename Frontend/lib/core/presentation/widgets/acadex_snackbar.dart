import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../errors/acadex_error.dart';

/// Centralized SnackBar and transient notification service for ACADEX
class AcadexSnackBar {
  /// Displays a brief, auto-dismissing success SnackBar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AcadexColors.success,
      icon: LucideIcons.checkCircle2,
      duration: duration,
    );
  }

  /// Displays an actionable, readable duration error SnackBar with automatic sanitization
  static void showError(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(milliseconds: 4000),
    String? fallbackMessage,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final sanitizedMessage = AcadexException.sanitizedMessage(error);
    final displayMessage = (fallbackMessage != null &&
            (sanitizedMessage.isEmpty ||
                sanitizedMessage.startsWith('An unexpected') ||
                sanitizedMessage.startsWith('Something went wrong')))
        ? fallbackMessage
        : (sanitizedMessage.isNotEmpty ? sanitizedMessage : (fallbackMessage ?? 'An error occurred'));
    _show(
      context,
      message: displayMessage,
      backgroundColor: AcadexColors.error,
      icon: LucideIcons.alertCircle,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Displays a visible warning SnackBar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AcadexColors.warning,
      icon: LucideIcons.alertTriangle,
      duration: duration,
    );
  }

  /// Displays a general informational SnackBar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AcadexColors.primary,
      icon: LucideIcons.info,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    try {
      // Dismiss any active snackbar immediately to prevent stacking or lingering across screens
      messenger.hideCurrentSnackBar();

      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      );

      messenger.showSnackBar(snackBar);
    } catch (_) {
      // In headless test environments without active descendant Scaffolds, ignore presentation assertion
    }
  }
}
