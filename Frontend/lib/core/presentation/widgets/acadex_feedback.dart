import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../features/auth/domain/models/auth_state.dart';
import '../../../features/auth/domain/models/role_enum.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'acadex_button.dart';
import 'acadex_readable_surface.dart';

import '../../errors/acadex_error.dart';

class AcadexEmptyState extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final IconData icon;
  final VoidCallback? onActionTap;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool isFilterEmpty;

  const AcadexEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.icon = LucideIcons.inbox,
    this.onActionTap,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
    this.isFilterEmpty = false,
  });

  /// Factory for filter or search empty state with predefined action to clear filters
  factory AcadexEmptyState.filterEmpty({
    Key? key,
    String title = 'No Matching Results',
    String? subtitle,
    String? filterSummary,
    VoidCallback? onClearFilters,
    String clearLabel = 'Clear Filters',
  }) {
    return AcadexEmptyState(
      key: key,
      title: title,
      subtitle: subtitle ??
          (filterSummary != null
              ? 'No records match $filterSummary.'
              : 'No records match the current filter criteria.'),
      icon: LucideIcons.filterX,
      actionLabel: clearLabel,
      actionIcon: LucideIcons.rotateCcw,
      onActionTap: onClearFilters,
      isFilterEmpty: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveSubtitle = subtitle ?? description ?? '';
    final effectiveOnAction = onActionTap ?? onAction;
    final effectiveIcon = isFilterEmpty && icon == LucideIcons.inbox ? LucideIcons.filterX : icon;
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState is AuthAuthenticated && authState.user.role == AppRole.superAdmin;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSuperAdmin ? const Color(0xFFE6F2FF) : AcadexColors.canvasSoft,
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(
                color: isSuperAdmin ? const Color(0xFFCCE6FF) : AcadexColors.hairline,
                width: 1,
              ),
            ),
            child: Icon(
              effectiveIcon,
              size: 28,
              color: isSuperAdmin ? const Color(0xFF003366) : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AcadexTypography.heading3(
              color: isSuperAdmin ? const Color(0xFF07111F) : AcadexColors.ink,
            ),
          ),
          if (effectiveSubtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              effectiveSubtitle,
              textAlign: TextAlign.center,
              style: AcadexTypography.body(
                color: isSuperAdmin ? const Color(0xFF334155) : AcadexColors.inkSecondary,
              ),
            ),
          ],
          if (effectiveOnAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            AcadexButton(
              label: actionLabel!,
              icon: actionIcon,
              onPressed: effectiveOnAction,
            ),
          ],
        ],
      ),
    );

    if (isSuperAdmin) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: AcadexReadableSurface(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Center(
        child: SingleChildScrollView(
          child: content,
        ),
      ),
    );
  }
}

class AcadexErrorState extends ConsumerWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AcadexErrorState({
    super.key,
    this.title = 'Unable to load data',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = LucideIcons.alertTriangle,
    this.actionLabel,
    this.onAction,
  });

  /// Factory constructor that automatically sanitizes and classifies any raw error
  factory AcadexErrorState.fromError({
    Key? key,
    required dynamic error,
    String? title,
    VoidCallback? onRetry,
    String retryLabel = 'Try Again',
    String? actionLabel,
    VoidCallback? onAction,
    String? context,
  }) {
    final parsed = AcadexException.fromError(error, context: context);
    String defaultTitle;
    IconData defaultIcon;

    switch (parsed.category) {
      case ErrorCategory.forbidden:
        defaultTitle = 'Access Restricted';
        defaultIcon = LucideIcons.shieldAlert;
        break;
      case ErrorCategory.notFound:
        defaultTitle = context != null ? '$context Not Found' : 'Resource Not Found';
        defaultIcon = LucideIcons.fileQuestion;
        break;
      case ErrorCategory.offline:
      case ErrorCategory.networkTimeout:
        defaultTitle = 'Connection Problem';
        defaultIcon = LucideIcons.wifiOff;
        break;
      case ErrorCategory.validation:
        defaultTitle = 'Validation Error';
        defaultIcon = LucideIcons.alertCircle;
        break;
      default:
        defaultTitle = context != null ? 'Unable to load $context' : 'Unable to load data';
        defaultIcon = LucideIcons.alertTriangle;
    }

    return AcadexErrorState(
      key: key,
      title: title ?? defaultTitle,
      message: parsed.userMessage,
      onRetry: onRetry,
      retryLabel: retryLabel,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: defaultIcon,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState is AuthAuthenticated && authState.user.role == AppRole.superAdmin;
    final sanitizedMessage = AcadexException.sanitizedMessage(message, fallback: message);

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(
                color: const Color(0xFFFECACA),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: AcadexColors.error,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AcadexTypography.heading3(
              color: isSuperAdmin ? const Color(0xFF07111F) : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sanitizedMessage,
            textAlign: TextAlign.center,
            style: AcadexTypography.body(
              color: isSuperAdmin ? const Color(0xFF334155) : AcadexColors.inkSecondary,
            ),
          ),
          if (onRetry != null || onAction != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onAction != null && actionLabel != null) ...[
                  AcadexButton(
                    label: actionLabel!,
                    variant: AcadexButtonVariant.secondary,
                    onPressed: onAction,
                  ),
                  if (onRetry != null) const SizedBox(width: 12),
                ],
                if (onRetry != null)
                  AcadexButton(
                    label: retryLabel,
                    icon: LucideIcons.refreshCw,
                    variant: AcadexButtonVariant.secondary,
                    onPressed: onRetry,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (isSuperAdmin) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: AcadexReadableSurface(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Center(
        child: SingleChildScrollView(
          child: content,
        ),
      ),
    );
  }
}

class AcadexLoadingState extends ConsumerWidget {
  final String? message;

  const AcadexLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState is AuthAuthenticated && authState.user.role == AppRole.superAdmin;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              isSuperAdmin ? const Color(0xFF003366) : AcadexColors.primary,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isSuperAdmin ? const Color(0xFF334155) : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: isSuperAdmin ? FontWeight.w500 : FontWeight.w400),
          ),
        ],
      ],
    );

    if (isSuperAdmin) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AcadexReadableSurface(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: content,
            ),
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: content,
        ),
      ),
    );
  }
}

/// Canonical AcadexSkeleton widget
class AcadexSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AcadexSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: borderRadius ?? AcadexRadius.borderRadiusSm,
      ),
    );
  }
}

