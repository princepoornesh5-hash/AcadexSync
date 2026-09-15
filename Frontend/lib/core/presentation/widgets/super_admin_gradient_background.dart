import 'package:flutter/material.dart';

/// Centralized canonical definition for the Super Admin unified gradient surface.
/// Implements the exact 21-stop vertical linear gradient sequence:
/// 0% (#000000) at top -> progressively lighter blue -> white (#FFFFFF) at bottom.
abstract class AcadexSuperAdminGradient {
  static const List<double> stops = [
    0.00,
    0.05,
    0.10,
    0.15,
    0.20,
    0.25,
    0.30,
    0.35,
    0.40,
    0.45,
    0.50,
    0.55,
    0.60,
    0.65,
    0.70,
    0.75,
    0.80,
    0.85,
    0.90,
    0.95,
    1.00,
  ];

  static const List<Color> colors = [
    Color(0xFF000000), // 0%   - Deep Black
    Color(0xFF000D1A), // 5%   - Very Dark Blue-Black
    Color(0xFF001A33), // 10%  - Dark Midnight Blue
    Color(0xFF00264D), // 15%  - Deep Navy Blue
    Color(0xFF003366), // 20%  - Navy Blue
    Color(0xFF004080), // 25%  - Dark Royal Blue
    Color(0xFF004D99), // 30%  - Classic Royal Blue
    Color(0xFF0059B3), // 35%  - Medium Royal Blue
    Color(0xFF0066CC), // 40%  - Vibrant Blue
    Color(0xFF0073E6), // 45%  - Electric Blue
    Color(0xFF0080FF), // 50%  - Sky Blue (Middle Anchor)
    Color(0xFF1A8CFF), // 55%  - Bright Sky Blue
    Color(0xFF3399FF), // 60%  - Light Sky Blue
    Color(0xFF4DA6FF), // 65%  - Soft Light Blue
    Color(0xFF66B3FF), // 70%  - Powder Blue
    Color(0xFF80BFFF), // 75%  - Soft Ice Blue
    Color(0xFF99CCFF), // 80%  - Pale Blue Accent
    Color(0xFFB3D9FF), // 85%  - Very Pale Blue
    Color(0xFFCCE6FF), // 90%  - Faint Blue Tint
    Color(0xFFE6F2FF), // 95%  - Barely-There Blue
    Color(0xFFFFFFFF), // 100% - Pure White
  ];

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: stops,
    colors: colors,
  );

  /// Returns the linearly interpolated gradient color at vertical fraction t in [0.0, 1.0].
  static Color colorAt(double t) {
    final clampedT = t.clamp(0.0, 1.0);
    for (int i = 0; i < stops.length - 1; i++) {
      if (clampedT >= stops[i] && clampedT <= stops[i + 1]) {
        final double segmentSpan = stops[i + 1] - stops[i];
        final double u = segmentSpan == 0 ? 0.0 : (clampedT - stops[i]) / segmentSpan;
        return Color.lerp(colors[i], colors[i + 1], u) ?? colors[i];
      }
    }
    return colors.last;
  }

  /// Calculates relative luminance of the gradient at vertical fraction t.
  static double luminanceAt(double t) {
    return colorAt(t).computeLuminance();
  }

  /// Determines the highest-contrast primary text color against the local gradient at vertical fraction t.
  static Color contrastingTextColor({
    required double t,
    Color darkColor = const Color(0xFF07111F),
    Color lightColor = const Color(0xFFFFFFFF),
  }) {
    final double bgLuminance = luminanceAt(t);
    final double lightLuminance = lightColor.computeLuminance();
    final double darkLuminance = darkColor.computeLuminance();

    // Standard WCAG contrast ratios:
    final double contrastWithLight = (lightLuminance + 0.05) / (bgLuminance + 0.05);
    final double contrastWithDark = (bgLuminance + 0.05) / (darkLuminance + 0.05);

    return contrastWithLight >= contrastWithDark ? lightColor : darkColor;
  }

  /// Determines the highest-contrast secondary text color against the local gradient at vertical fraction t.
  static Color secondaryTextColor({
    required double t,
    Color darkSecondary = const Color(0xFF334155),
    Color lightSecondary = const Color(0xFFCCE6FF),
  }) {
    return contrastingTextColor(
      t: t,
      darkColor: darkSecondary,
      lightColor: lightSecondary,
    );
  }

  static const double darkThresholdLuminance = 0.20;
  static const double lightThresholdLuminance = 0.40;

  /// Evaluates two-state text mode (Light vs Dark) using dead-band hysteresis.
  /// If currentMode is light: remains light until luminance >= lightThresholdLuminance (0.40).
  /// If currentMode is dark: remains dark until luminance <= darkThresholdLuminance (0.20).
  /// Inside the dead band [0.20, 0.40], it preserves the current mode without switching.
  static AcadexAdaptiveTextMode evaluateMode({
    required double t,
    required AcadexAdaptiveTextMode currentMode,
  }) {
    final double luminance = luminanceAt(t);
    if (currentMode == AcadexAdaptiveTextMode.light) {
      if (luminance >= lightThresholdLuminance) {
        return AcadexAdaptiveTextMode.dark;
      }
      return AcadexAdaptiveTextMode.light;
    } else {
      if (luminance <= darkThresholdLuminance) {
        return AcadexAdaptiveTextMode.light;
      }
      return AcadexAdaptiveTextMode.dark;
    }
  }

  /// Returns the discrete text color for the given mode (Strictly #FFFFFF or #07111F).
  static Color colorForMode({
    required AcadexAdaptiveTextMode mode,
    Color darkColor = const Color(0xFF07111F),
    Color lightColor = const Color(0xFFFFFFFF),
  }) {
    return mode == AcadexAdaptiveTextMode.light ? lightColor : darkColor;
  }
}

/// Strict two-state mode for adaptive gradient typography.
enum AcadexAdaptiveTextMode {
  light, // White typography for dark regions
  dark,  // Dark navy typography for light regions
}

/// Inherited scope indicating that content is rendered directly over
/// the authoritative Acadex gradient background.
class AcadexGradientScope extends InheritedWidget {
  final GlobalKey gradientKey;

  const AcadexGradientScope({
    super.key,
    required this.gradientKey,
    required super.child,
  });

  static AcadexGradientScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AcadexGradientScope>();
  }

  @override
  bool updateShouldNotify(AcadexGradientScope oldWidget) {
    return gradientKey != oldWidget.gradientKey;
  }
}

/// Reusable gradient background component for the Super Admin unified surface.
class SuperAdminGradientBackground extends StatefulWidget {
  final Widget child;

  const SuperAdminGradientBackground({
    super.key,
    required this.child,
  });

  /// Official Super Admin prototype vertical linear gradient.
  static const LinearGradient gradient = AcadexSuperAdminGradient.gradient;

  @override
  State<SuperAdminGradientBackground> createState() => _SuperAdminGradientBackgroundState();
}

class _SuperAdminGradientBackgroundState extends State<SuperAdminGradientBackground> {
  final GlobalKey _gradientKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AcadexGradientScope(
      gradientKey: _gradientKey,
      child: Container(
        key: _gradientKey,
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AcadexSuperAdminGradient.gradient,
        ),
        child: widget.child,
      ),
    );
  }
}

