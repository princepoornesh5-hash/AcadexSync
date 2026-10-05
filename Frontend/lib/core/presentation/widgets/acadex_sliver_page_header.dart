import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';

/// Canonical ACADEX scroll-driven transforming header widget.
/// 
/// Seamlessly transitions between:
/// - STATE A (Expanded): Prominent contextual title, subtitle, comfortable top spacing.
/// - STATE B (Intermediate): Continuous scroll-driven interpolation of height, position, font size, and subtitle opacity.
/// - STATE C (Compact): Pinned compact app bar consuming minimal vertical space with content scrolling underneath.
class AcadexSliverPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Widget? leading;
  final double? expandedHeight;
  final PreferredSizeWidget? bottom;
  final Widget? contextualWidget;
  final Color? backgroundColor;

  const AcadexSliverPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.leading,
    this.expandedHeight,
    this.bottom,
    this.contextualWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _AcadexTransformingHeaderDelegate(
        title: title,
        subtitle: subtitle,
        actions: actions,
        onBack: onBack,
        leading: leading,
        customExpandedHeight: expandedHeight,
        bottom: bottom,
        contextualWidget: contextualWidget,
        backgroundColor: backgroundColor,
        topPadding: topPadding,
        isDark: isDark,
      ),
    );
  }
}

class _AcadexTransformingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Widget? leading;
  final double? customExpandedHeight;
  final PreferredSizeWidget? bottom;
  final Widget? contextualWidget;
  final Color? backgroundColor;
  final double topPadding;
  final bool isDark;

  _AcadexTransformingHeaderDelegate({
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.leading,
    this.customExpandedHeight,
    this.bottom,
    this.contextualWidget,
    this.backgroundColor,
    required this.topPadding,
    required this.isDark,
  });

  double get _bottomHeight => bottom?.preferredSize.height ?? 0.0;

  @override
  double get minExtent => topPadding + kToolbarHeight + _bottomHeight;

  @override
  double get maxExtent {
    if (customExpandedHeight != null) {
      return math.max(minExtent + 1.0, customExpandedHeight! + topPadding + _bottomHeight);
    }
    // Content-derived expanded height
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final hasContextual = contextualWidget != null;
    final contentHeight = (hasSubtitle ? 144.0 : 108.0) + (hasContextual ? 28.0 : 0.0);
    return math.max(minExtent + 1.0, topPadding + contentHeight + _bottomHeight);
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final standardTitleColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final standardSubtitleColor = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
    final bgColor = backgroundColor ?? (isDark ? AcadexColors.darkSurface : AcadexColors.surface);

    final maxShrink = maxExtent - minExtent;
    final rawProgress = maxShrink > 0 ? (shrinkOffset / maxShrink).clamp(0.0, 1.0) : 1.0;

    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final progress = disableAnimations ? (rawProgress > 0.5 ? 1.0 : 0.0) : rawProgress;

    final curvedProgress = Curves.easeInOutCubic.transform(progress);
    final fastOutProgress = Curves.easeOutCubic.transform(progress);

    // Responsive text scaling
    final textScaler = MediaQuery.textScalerOf(context);
    final double expandedFontSize = textScaler.scale(24.0).clamp(20.0, 28.0);
    final double compactFontSize = textScaler.scale(17.5).clamp(15.0, 20.0);

    // Continuous Typography Interpolation
    final double currentFontSize = lerpDouble(expandedFontSize, compactFontSize, curvedProgress)!;
    final FontWeight currentFontWeight = FontWeight.lerp(FontWeight.w700, FontWeight.w600, curvedProgress)!;
    final double currentLetterSpacing = lerpDouble(-0.4, -0.2, curvedProgress)!;

    // Leading Widget configuration
    Widget? leadingWidget;
    if (onBack != null) {
      leadingWidget = IconButton(
        icon: Icon(LucideIcons.arrowLeft, size: 20, color: standardTitleColor),
        onPressed: onBack,
        tooltip: 'Back',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      );
    } else if (leading != null) {
      leadingWidget = leading;
    }

    // Trailing actions bounds
    final actionsCount = actions?.length ?? 0;
    final double compactRight = actionsCount > 0 ? (actionsCount * 44.0 + 16.0) : 16.0;
    final double expandedRight = 16.0;
    final double currentRight = lerpDouble(expandedRight, compactRight, curvedProgress)!;

    // Continuous Coordinates Interpolation for ONE single title
    final double expandedLeft = 16.0;
    final double compactLeft = leadingWidget != null ? 52.0 : 16.0;
    final double currentLeft = lerpDouble(expandedLeft, compactLeft, curvedProgress)!;

    final double expandedTop = topPadding + (leadingWidget != null ? 48.0 : 36.0);
    final double compactTop = topPadding + (kToolbarHeight - 24.0) / 2;
    final double currentTop = lerpDouble(expandedTop, compactTop, fastOutProgress)!;

    // Subtitle fade and upward glide
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final double subtitleFade = (progress * 2.4).clamp(0.0, 1.0);
    final double subtitleOpacity = 1.0 - subtitleFade;
    final double subtitleSlide = lerpDouble(0.0, -8.0, subtitleFade)!;
    final double subtitleTop = expandedTop + currentFontSize * 1.3 + 4.0 + subtitleSlide;

    // Border and elevation as content scrolls underneath
    final double borderAlpha = (progress * 1.5).clamp(0.0, 1.0);
    final borderColor = (isDark ? AcadexColors.darkHairline : AcadexColors.hairline)
        .withValues(alpha: borderAlpha);

    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: 1.0,
            ),
          ),
          boxShadow: progress > 0.6
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 * progress : 0.03 * progress),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pinned Leading Widget (Back button or custom leading)
            if (leadingWidget != null)
              Positioned(
                top: topPadding + (kToolbarHeight - 40.0) / 2,
                left: 6.0,
                width: 40.0,
                height: 40.0,
                child: leadingWidget,
              ),

            // Pinned Trailing Actions
            if (actions != null && actions!.isNotEmpty)
              Positioned(
                top: topPadding,
                right: 8.0,
                height: kToolbarHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: actions!,
                ),
              ),

            // Optional Subtitle (fades out progressively during first 40% of scroll)
            if (hasSubtitle && subtitleOpacity > 0.0)
              Positioned(
                top: subtitleTop,
                left: currentLeft,
                right: currentRight,
                child: Opacity(
                  opacity: subtitleOpacity,
                  child: Text(
                    subtitle!,
                    style: AcadexTypography.bodySmall(color: standardSubtitleColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Optional Contextual Widget (e.g., status chip, badge)
            if (contextualWidget != null && subtitleOpacity > 0.0)
              Positioned(
                top: subtitleTop + (hasSubtitle ? 24.0 : 0.0),
                left: currentLeft,
                right: currentRight,
                child: Opacity(
                  opacity: subtitleOpacity,
                  child: contextualWidget!,
                ),
              ),

            // Single Transforming Title Text Widget (zero teleporting, zero duplicate text)
            Positioned(
              top: currentTop,
              left: currentLeft,
              right: currentRight,
              child: Text(
                title,
                style: AcadexTypography.heading2(color: standardTitleColor).copyWith(
                  fontSize: currentFontSize,
                  fontWeight: currentFontWeight,
                  letterSpacing: currentLetterSpacing,
                  height: 1.2,
                ),
                maxLines: progress > 0.7 ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Pinned Bottom Widget (e.g. TabBar)
            if (bottom != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: _bottomHeight,
                child: bottom!,
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _AcadexTransformingHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        actions != oldDelegate.actions ||
        leading != oldDelegate.leading ||
        onBack != oldDelegate.onBack ||
        customExpandedHeight != oldDelegate.customExpandedHeight ||
        bottom != oldDelegate.bottom ||
        contextualWidget != oldDelegate.contextualWidget ||
        backgroundColor != oldDelegate.backgroundColor ||
        topPadding != oldDelegate.topPadding ||
        isDark != oldDelegate.isDark;
  }
}
