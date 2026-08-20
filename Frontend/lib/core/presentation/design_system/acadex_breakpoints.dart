import 'package:flutter/material.dart';

/// Responsive Breakpoint Utilities for ACADEX
enum DeviceType { mobile, tablet, desktop }

class AcadexBreakpoints {
  AcadexBreakpoints._();

  static const double mobileMax = 599.0;
  static const double tabletMax = 1023.0;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= mobileMax) return DeviceType.mobile;
    if (width <= tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width <= mobileMax;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMax && width <= tabletMax;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width > tabletMax;

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
