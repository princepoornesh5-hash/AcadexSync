import 'package:flutter/material.dart';
import 'acadex_spacing.dart';

/// Responsive Breakpoint Utilities for ACADEX Mobile-First Platform
enum DeviceType { mobile, tablet, desktop }

class AcadexBreakpoints {
  AcadexBreakpoints._();

  /// Small Android phones (e.g. 360px viewport)
  static const double mobileSmallMax = 374.0;

  /// Standard Android phones (375px - 599px, including 390px, 412px viewports)
  static const double mobileMax = 599.0;

  /// Tablet devices (600px - 1023px)
  static const double tabletMax = 1023.0;

  /// Desktop / Web layouts (1024px+)
  static const double desktopMin = 1024.0;
  static const double desktopMax = 1440.0;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= mobileMax) return DeviceType.mobile;
    if (width <= tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isSmallMobile(BuildContext context) => MediaQuery.sizeOf(context).width <= mobileSmallMax;
  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width <= mobileMax;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mobileMax && width <= tabletMax;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktopMin;

  /// Adaptive horizontal padding for pages
  static double responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= mobileSmallMax) {
      return AcadexSpacing.space12; // 360px: 12px maximizes usable screen width
    } else if (width <= mobileMax) {
      return AcadexSpacing.space16; // 390-412px: 16px standard mobile gutter
    } else if (width <= tabletMax) {
      return AcadexSpacing.space20;
    }
    return AcadexSpacing.space24;
  }

  /// Adaptive internal padding for cards
  static EdgeInsets responsiveCardPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= mobileSmallMax) {
      return const EdgeInsets.all(AcadexSpacing.space12);
    }
    return const EdgeInsets.all(AcadexSpacing.space14);
  }

  static int getGridColumnCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 4}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (AcadexBreakpoints.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (AcadexBreakpoints.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}
