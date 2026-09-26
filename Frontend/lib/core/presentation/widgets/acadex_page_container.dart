import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import 'acadex_ambient_background.dart';
import 'animated_particle_sphere.dart';
export 'acadex_ambient_background.dart';
export 'animated_particle_sphere.dart';

/// A responsive page container that enforces consistent layout geometry
/// across all Acadex screens.
class AcadexPageContainer extends ConsumerWidget {
  final Widget child;

  /// Maximum content width. Defaults to [AcadexLayout.contentMaxWidth] (1400px).
  /// Use [AcadexLayout.formMaxWidth] (800px) for form-centric pages.
  /// Set to `double.infinity` for no constraint.
  final double maxWidth;

  /// Whether the content should be scrollable. Defaults to true.
  final bool scrollable;

  /// Override the background color. Defaults to canvas/darkCanvas (or transparent for Super Admin).
  final Color? backgroundColor;

  /// Override horizontal padding. If null, uses responsive defaults.
  final double? horizontalPadding;

  /// Override vertical padding (top). If null, uses 24px.
  final double? topPadding;

  /// Override vertical padding (bottom). If null, uses 32px.
  final double? bottomPadding;

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
    final hPad = horizontalPadding ?? _responsiveHorizontalPadding(context);
    final tPad = topPadding ?? (isMobile ? AcadexSpacing.space16 : AcadexSpacing.space24);
    final bPad = bottomPadding ?? (isMobile ? AcadexSpacing.space24 : AcadexSpacing.space32);

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
        padding: EdgeInsets.fromLTRB(hPad, tPad, hPad, bPad),
        child: content,
      );
      if (onRefresh != null) {
        containerBody = RefreshIndicator(
          onRefresh: onRefresh!,
          child: scrollContent,
        );
      } else {
        containerBody = scrollContent;
      }
    } else {
      containerBody = Padding(
        padding: EdgeInsets.fromLTRB(hPad, tPad, hPad, bPad),
        child: content,
      );
    }

    Widget result;
    if (particleSphereVariant != null) {
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
    } else if (ambientDensity != AcadexAmbientDensity.none) {
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

  double _responsiveHorizontalPadding(BuildContext context) {
    if (AcadexBreakpoints.isMobile(context)) {
      return AcadexSpacing.space16;
    } else if (AcadexBreakpoints.isTablet(context)) {
      return AcadexSpacing.space20;
    }
    return AcadexSpacing.space24;
  }
}

/// Standardized layout constants for the Acadex design system.
class AcadexLayout {
  AcadexLayout._();

  /// Maximum content width for full-width pages (dashboards, tables, lists).
  static const double contentMaxWidth = 1400.0;

  /// Maximum content width for form-centric pages (settings, create/edit).
  static const double formMaxWidth = 800.0;

  /// Maximum content width for detail/reading pages.
  static const double detailMaxWidth = 1000.0;

  /// Standard section spacing between major vertical sections.
  static const double sectionSpacing = 28.0;

  /// Standard gap between section header and its content.
  static const double sectionHeaderGap = 12.0;

  /// Standard spacing between grid items.
  static const double gridSpacing = 12.0;

  /// Standard page vertical top padding.
  static const double pageTopPadding = 24.0;

  /// Standard page vertical bottom padding.
  static const double pageBottomPadding = 32.0;

  /// Helper to get responsive horizontal gutter.
  static double horizontalGutter(BuildContext context) {
    if (AcadexBreakpoints.isMobile(context)) {
      return AcadexSpacing.space16;
    } else if (AcadexBreakpoints.isTablet(context)) {
      return AcadexSpacing.space20;
    }
    return AcadexSpacing.space24;
  }

  /// Helper to get responsive stat grid column count.
  static int statGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 4;
    if (width >= 600) return 3;
    if (width >= 375) return 3;   // Modern phones (Moto Edge 60 etc.)
    return 2;                      // Small phones <375px
  }

  /// Standard section spacing widget (SizedBox with height 28).
  static const Widget sectionSpacer = SizedBox(height: sectionSpacing);

  /// Standard header-to-content gap widget (SizedBox with height 12).
  static const Widget headerGap = SizedBox(height: sectionHeaderGap);
}
