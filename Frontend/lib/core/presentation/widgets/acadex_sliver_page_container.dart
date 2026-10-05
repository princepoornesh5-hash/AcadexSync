import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import 'acadex_ambient_background.dart';
import 'animated_particle_sphere.dart';

class AcadexSliverPageContainer extends ConsumerWidget {
  final Widget header;
  final List<Widget> slivers;
  final double maxWidth;
  final Color? backgroundColor;
  final double? horizontalPadding;
  final double? bottomPadding;
  final bool? hasBottomNav;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final AcadexAmbientDensity ambientDensity;
  final ParticleSphereVariant? particleSphereVariant;
  final Future<void> Function()? onRefresh;

  const AcadexSliverPageContainer({
    super.key,
    required this.header,
    required this.slivers,
    this.maxWidth = 1400.0,
    this.backgroundColor,
    this.horizontalPadding,
    this.bottomPadding,
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

    final baseBottom = bottomPadding ??
        (effectiveHasBottomNav
            ? (isMobile ? AcadexSpacing.space16 : AcadexSpacing.space24)
            : (mediaBottom + (isMobile ? AcadexSpacing.space20 : AcadexSpacing.space28)));

    final List<Widget> sliverWidgets = slivers.map((item) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        sliver: item,
      );
    }).toList();

    final scrollContent = CustomScrollView(
      controller: scrollController,
      physics: physics ?? (onRefresh != null ? const AlwaysScrollableScrollPhysics() : null),
      slivers: [
        header,
        ...sliverWidgets,
        SliverToBoxAdapter(child: SizedBox(height: baseBottom)),
      ],
    );

    Widget containerBody;
    if (onRefresh != null) {
      containerBody = RefreshIndicator(
        onRefresh: onRefresh!,
        color: AcadexColors.primary,
        child: scrollContent,
      );
    } else {
      containerBody = scrollContent;
    }

    Widget result;
    if (particleSphereVariant != null && !isMobile) {
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
