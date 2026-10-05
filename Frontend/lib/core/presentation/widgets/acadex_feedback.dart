import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import 'acadex_button.dart';
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
  final bool isCompact;

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
    this.isCompact = false,
  });

  /// Factory for filter or search empty state with predefined action to clear filters
  factory AcadexEmptyState.filterEmpty({
    Key? key,
    String title = 'No Matching Results',
    String? subtitle,
    String? filterSummary,
    VoidCallback? onClearFilters,
    String clearLabel = 'Clear Filters',
    bool isCompact = false,
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
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveSubtitle = subtitle ?? description ?? '';
    final effectiveOnAction = onActionTap ?? onAction;
    final effectiveIcon = isFilterEmpty && icon == LucideIcons.inbox ? LucideIcons.filterX : icon;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final iconBoxSize = isCompact ? 38.0 : 52.0;
    final iconGlyphSize = isCompact ? 18.0 : 24.0;
    final titleStyle = isCompact
        ? AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink)
        : AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink);
    final subtitleStyle = isCompact
        ? AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)
        : AcadexTypography.body(color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary);

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isCompact ? 320 : 400),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
              borderRadius: isCompact ? AcadexRadius.borderRadiusMd : AcadexRadius.borderRadiusLg,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                width: 1,
              ),
            ),
            child: Icon(
              effectiveIcon,
              size: iconGlyphSize,
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          SizedBox(height: isCompact ? 10 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: titleStyle,
          ),
          if (effectiveSubtitle.isNotEmpty) ...[
            SizedBox(height: isCompact ? 4 : 6),
            Text(
              effectiveSubtitle,
              textAlign: TextAlign.center,
              style: subtitleStyle,
            ),
          ],
          if (effectiveOnAction != null && actionLabel != null) ...[
            SizedBox(height: isCompact ? 12 : 18),
            AcadexButton(
              label: actionLabel!,
              icon: actionIcon,
              size: isCompact ? AcadexButtonSize.sm : AcadexButtonSize.md,
              onPressed: effectiveOnAction,
            ),
          ],
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? AcadexSpacing.space12 : AcadexSpacing.space20,
        horizontal: AcadexSpacing.space16,
      ),
      child: Center(
        child: content,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sanitizedMessage = AcadexException.sanitizedMessage(message, fallback: message);

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(
                color: isDark ? AcadexColors.errorDark : const Color(0xFFFECACA),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isDark ? AcadexColors.errorLight : AcadexColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AcadexTypography.heading3(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sanitizedMessage,
            textAlign: TextAlign.center,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ),
          ),
          if (onRetry != null || onAction != null) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (onAction != null && actionLabel != null)
                  AcadexButton(
                    label: actionLabel!,
                    variant: AcadexButtonVariant.secondary,
                    onPressed: onAction,
                  ),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: content,
      ),
    );
  }
}

class AcadexLoadingState extends StatelessWidget {
  final String? message;
  final double size;

  const AcadexLoadingState({
    super.key,
    this.message,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
            ),
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: content,
      ),
    );
  }
}

/// Lightweight, restrained skeleton box with smooth pulse animation
class AcadexSkeleton extends StatefulWidget {
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
  State<AcadexSkeleton> createState() => _AcadexSkeletonState();
}

class _AcadexSkeletonState extends State<AcadexSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacityAnim = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, _) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: widget.borderRadius ?? AcadexRadius.borderRadiusSm,
            ),
          ),
        );
      },
    );
  }
}

/// Convenient skeleton line for text placeholders
class AcadexSkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const AcadexSkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(AcadexRadius.xs),
    );
  }
}

/// Convenient skeleton card that mirrors an AcadexCard layout
class AcadexSkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? padding;

  const AcadexSkeletonCard({
    super.key,
    this.height = 80.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(AcadexSpacing.space14),
      margin: const EdgeInsets.only(bottom: AcadexSpacing.space8),
      decoration: BoxDecoration(
        color: AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: AcadexColors.hairline, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AcadexSkeleton(width: 38, height: 38, borderRadius: AcadexRadius.smBorder),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AcadexSkeletonLine(width: 140, height: 13),
                SizedBox(height: 8),
                AcadexSkeletonLine(width: 220, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
