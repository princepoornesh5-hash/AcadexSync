import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'acadex_colors.dart';

/// Extended [TextStyle] that is both a valid [TextStyle] and callable as a function.
/// This guarantees complete compatibility across both property-style consumers:
///   `style: AcadexTypography.caption`
///   `style: AcadexTypography.caption.copyWith(...)`
/// and callable-style consumers:
///   `style: AcadexTypography.caption()`
///   `style: AcadexTypography.caption(color: ...)`
///   `style: AcadexTypography.caption(color: ...).copyWith(...)`
class AcadexTextStyle extends TextStyle {
  const AcadexTextStyle({
    super.inherit,
    super.color,
    super.backgroundColor,
    super.fontSize,
    super.fontWeight,
    super.fontStyle,
    super.letterSpacing,
    super.wordSpacing,
    super.textBaseline,
    super.height,
    super.leadingDistribution,
    super.locale,
    super.foreground,
    super.background,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.debugLabel,
    super.fontFamily,
    super.fontFamilyFallback,
    super.package,
    super.overflow,
  });

  factory AcadexTextStyle.from(TextStyle style) {
    return AcadexTextStyle(
      inherit: style.inherit,
      color: style.color,
      backgroundColor: style.backgroundColor,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      letterSpacing: style.letterSpacing,
      wordSpacing: style.wordSpacing,
      textBaseline: style.textBaseline,
      height: style.height,
      leadingDistribution: style.leadingDistribution,
      locale: style.locale,
      foreground: style.foreground,
      background: style.background,
      shadows: style.shadows,
      fontFeatures: style.fontFeatures,
      fontVariations: style.fontVariations,
      decoration: style.decoration,
      decorationColor: style.decorationColor,
      decorationStyle: style.decorationStyle,
      decorationThickness: style.decorationThickness,
      debugLabel: style.debugLabel,
      fontFamily: style.fontFamily,
      fontFamilyFallback: style.fontFamilyFallback,
      overflow: style.overflow,
    );

  }

  /// Callable invocation: allows `AcadexTypography.caption(...)` or `AcadexTypography.caption()`
  AcadexTextStyle call({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) {
    return copyWith(
      inherit: inherit,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      leadingDistribution: leadingDistribution,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      debugLabel: debugLabel,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      package: package,
      overflow: overflow,
    );
  }

  @override
  AcadexTextStyle copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) {
    final newStyle = super.copyWith(
      inherit: inherit,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      leadingDistribution: leadingDistribution,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      debugLabel: debugLabel,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      package: package,
      overflow: overflow,
    );
    return AcadexTextStyle.from(newStyle);
  }
}

/// Centralized ACADEX Typography System (Inter Font Hierarchy)
/// Tailored for Android mobile viewports to prevent line-wrapping explosions,
/// clipped text, and giant headings while maintaining WCAG AA contrast.
/// All typography tokens are [AcadexTextStyle] instances, allowing both property
/// access (`.copyWith`, direct assignment) and callable invocations `(...)`.
class AcadexTypography {
  AcadexTypography._();

  // ── Display / Hero Styles (Sparse, High-Impact) ──
  static final AcadexTextStyle display1 = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      height: 1.2,
      color: AcadexColors.ink,
    ),
  );

  static final AcadexTextStyle display2 = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.25,
      color: AcadexColors.ink,
    ),
  );

  // ── Headings (Mobile Scaled) ──
  static final AcadexTextStyle heading1 = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.3,
      color: AcadexColors.ink,
    ),
  );

  static final AcadexTextStyle heading2 = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.35,
      color: AcadexColors.ink,
    ),
  );

  static final AcadexTextStyle heading3 = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.4,
      color: AcadexColors.ink,
    ),
  );

  static final AcadexTextStyle title = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.4,
      color: AcadexColors.ink,
    ),
  );

  // ── Body & Content ──
  static final AcadexTextStyle body = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
      color: AcadexColors.ink,
    ),
  );

  static final AcadexTextStyle bodyMedium = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.45,
      color: AcadexColors.ink,
    ),
  );

  static final AcadexTextStyle bodySmall = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.4,
      color: AcadexColors.inkSecondary,
    ),
  );

  // ── Controls & Metadata ──
  static final AcadexTextStyle button = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: Colors.white,
    ),
  );

  static final AcadexTextStyle caption = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.35,
      color: AcadexColors.inkMuted,
    ),
  );

  static final AcadexTextStyle eyebrow = AcadexTextStyle.from(
    GoogleFonts.inter(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AcadexColors.inkMuted,
    ),
  );

  static final AcadexTextStyle code = AcadexTextStyle.from(
    GoogleFonts.jetBrainsMono(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: AcadexColors.ink,
    ),
  );

  // ── Backward-Compatible Getters & Aliases ──
  static AcadexTextStyle get h1 => heading1;
  static AcadexTextStyle get h2 => heading2;
  static AcadexTextStyle get h3 => heading3;
  static AcadexTextStyle get subtitle => title.call(color: AcadexColors.inkSecondary);
  static AcadexTextStyle get bodyLarge => body;
  static AcadexTextStyle get labelLarge => button.call(color: AcadexColors.ink);
  static AcadexTextStyle get labelMedium => bodySmall.call(color: AcadexColors.inkSecondary);
  static AcadexTextStyle get labelSmall => eyebrow;
  static AcadexTextStyle get statHero => display2;
  static AcadexTextStyle get statLarge => heading1;
  static AcadexTextStyle get bodyText => body;
  static AcadexTextStyle get captionText => caption;

  /// Accessibility safety helper: prevents text scaling from overflowing mobile bounds
  static TextScaler clampedTextScaler(BuildContext context, {double max = 1.25}) {
    return MediaQuery.textScalerOf(context).clamp(maxScaleFactor: max);
  }
}
