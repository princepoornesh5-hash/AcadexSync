import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import 'acadex_ambient_background.dart';
import 'animated_particle_sphere.dart';
export 'acadex_ambient_background.dart';
export 'animated_particle_sphere.dart';

/// A responsive page container that enforces consistent layout geometry,
/// safe area handling, and precise viewport bounds across all Acadex mobile & desktop screens.
class AcadexPageContainer extends ConsumerWidget {
  final Widget child;

  /// Maximum content width. Defaults to [AcadexLayout.contentMaxWidth] (1400px).
  /// Use [AcadexLayout.formMaxWidth] (800px) for form-centric pages.
  /// Set to `double.infinity` for no constraint.
  final double maxWidth;

  /// Whether the content should be scrollable. Defaults to true.
  final bool scrollable;

  /// Override the background color. Defaults to canvas/darkCanvas.
  final Color? backgroundColor;

  /// Override horizontal padding. If null, uses responsive defaults (12px on 360px, 16px on 390-412px).
  final double? horizontalPadding;

  /// Override vertical padding (top). If null, respects the top app bar offset.
  final double? topPadding;

  /// Override vertical padding (bottom). If null, respects the bottom navigation offset.
  final double? bottomPadding;

  /// Whether the page is displayed underneath the canonical [AcadexAppBar]. Defaults to true.
  final bool hasAppBar;

  /// Whether the page is displayed above the mobile [AcadexBottomNav]. Defaults to null (auto-detected on mobile).
  final bool? hasBottomNav;

  /// Optional scroll controller for external scroll management.
  final ScrollController? scrollController;

  /// Optional scroll physics.
  final ScrollPhysics? physics;

  /// Optional ambient background density. Defaults to [AcadexAmbientDensity.none].
  final AcadexAmbientDensity ambientDensity;

  /// Optional 3D particle sphere variant. If set, renders the 3D particle sphere.
  final ParticleSphereVariant? particleSphereVariant;

  /// Optional pull-to-refresh callback.
  final Future<void> Function()? onRefresh;

  const AcadexPageContainer({
    super.key,
    required this.child,
    this.maxWidth = AcadexLayout.contentMaxWidth,
    this.scrollable = true,
    this.backgroundColor,
    this.horizontalPadding,
    this.topPadding,
    this.bottomPadding,
    this.hasAppBar = true,
    this.hasBottomNav,
    this.scrollController,
    this.physics,
    this.ambientDensity = AcadexAmbientDensity.none,
    this.particleSphereVariant,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AcadexColors.darkCanvas : AcadexColors.canvas;
    final bgColor = backgroundColor ?? defaultBg;

    final isMobile = AcadexBreakpoints.isMobile(context);
    final hPad = horizontalPadding ?? AcadexBreakpoints.responsiveHorizontalPadding(context);
    final mediaBottom = MediaQuery.paddingOf(context).bottom;

    final effectiveHasBottomNav = hasBottomNav ?? isMobile;

    final baseTop = topPadding ?? (isMobile ? AcadexSpacing.space12 : AcadexSpacing.space16);
    final effectiveTop = baseTop;

    final baseBottom = bottomPadding ??
        (effectiveHasBottomNav
            ? (isMobile ? AcadexSpacing.space16 : AcadexSpacing.space24)
            : (mediaBottom + (isMobile ? AcadexSpacing.space20 : AcadexSpacing.space28)));

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    Widget containerBody;
    if (scrollable) {
      final scrollContent = SingleChildScrollView(
        controller: scrollController,
        physics: physics ?? (onRefresh != null ? const AlwaysScrollableScrollPhysics() : null),
        padding: EdgeInsets.fromLTRB(hPad, effectiveTop, hPad, baseBottom),
        child: content,
      );
      if (onRefresh != null) {
        containerBody = RefreshIndicator(
          onRefresh: onRefresh!,
          color: AcadexColors.primary,
          child: scrollContent,
        );
      } else {
        containerBody = scrollContent;
      }
    } else {
      containerBody = Padding(
        padding: EdgeInsets.fromLTRB(hPad, effectiveTop, hPad, baseBottom),
        child: content,
      );
    }

    Widget result;
    if (particleSphereVariant != null && !isMobile) {
      // Exclude heavy particle sphere on mobile by default to preserve battery and frame rate
      result = ColoredBox(
        color: bgColor,
        child: AnimatedParticleSphereBackground(
          variant: particleSphereVariant!,
          drawBackground: false,
          child: Material(
            color: Colors.transparent,
            child: containerBody,
          ),
        ),
      );
    } else if (ambientDensity != AcadexAmbientDensity.none && !isMobile) {
      result = ColoredBox(
        color: bgColor,
        child: AcadexAmbientBackground(
          density: ambientDensity,
          child: Material(
            color: Colors.transparent,
            child: containerBody,
          ),
        ),
      );
    } else {
      result = Material(
        color: bgColor,
        child: containerBody,
      );
    }

    return result;
  }
}

/// Standardized layout constants for the Acadex mobile-first design system.
class AcadexLayout {
  AcadexLayout._();

  /// Maximum content width for full-width pages (dashboards, tables, lists).
  static const double contentMaxWidth = 1400.0;

  /// Maximum content width for form-centric pages (settings, create/edit).
  static const double formMaxWidth = 800.0;

  /// Maximum content width for detail/reading pages.
  static const double detailMaxWidth = 1000.0;

  /// Standard section spacing between major vertical sections.
  static const double sectionSpacing = 20.0;

  /// Standard gap between section header and its content.
  static const double sectionHeaderGap = 10.0;

  /// Standard spacing between grid items.
  static const double gridSpacing = 10.0;

  /// Standard page vertical top padding.
  static const double pageTopPadding = 16.0;

  /// Standard page vertical bottom padding.
  static const double pageBottomPadding = 24.0;

  /// Helper to get responsive horizontal gutter.
  static double horizontalGutter(BuildContext context) {
    return AcadexBreakpoints.responsiveHorizontalPadding(context);
  }

  /// Helper to get responsive stat grid column count.
  static int statGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return 4;
    if (width >= 600) return 3;
    if (width >= 375) return 2;
    return 2;
  }

  /// Standard section spacing widget.
  static const Widget sectionSpacer = SizedBox(height: sectionSpacing);

  /// Standard header-to-content gap widget.
  static const Widget headerGap = SizedBox(height: sectionHeaderGap);
}
