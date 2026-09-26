import 'package:flutter/material.dart';

/// ACADEX Official Design System Color Palette
/// Curated for a clean, premium, modern, calm academic interface.
class AcadexColors {
  AcadexColors._();

  // --- Primary Brand Colors (Vibrant ACADEX Blue) ---
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color primaryHover = Color(0xFF1D4ED8); // Blue 700
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryPressed = Color(0xFF1E40AF); // Blue 800
  static const Color primaryLight = Color(0xFFDBEAFE); // Blue 100
  static const Color primarySoft = Color(0xFFDBEAFE);
  static const Color primaryTint = Color(0xFFEFF6FF); // Blue 50
  static const Color primaryMuted = Color(0xFF60A5FA); // Blue 400

  static const Color primaryNavy = Color(0xFF0F172A); // Deep Slate 900
  static const Color secondary = Color(0xFF0F172A);
  static const Color secondaryLight = Color(0xFFF1F5F9);

  // --- Super Admin Action Blue Hierarchy (Prototype) ---
  static const Color superAdminDeepAction = Color(0xFF003366); // Deep Action Blue (Primary CTA)
  static const Color superAdminDeepPressed = Color(0xFF00264D); // Deep Pressed Blue
  static const Color superAdminPrimaryAction = Color(0xFF0066CC); // Primary Action Blue (Border/Icon/Text CTA)
  static const Color superAdminSoftAction = Color(0xFFE6F2FF); // Soft Blue (Soft Actions / Badges)
  static const Color superAdminVerySoft = Color(0xFFEFF6FF); // Very Soft Blue (Card Tint)

  // --- Accent & Semantic Colors ---
  static const Color success = Color(0xFF16A34A); // Green 600
  static const Color successLight = Color(0xFFDCFCE7); // Green 100
  static const Color emeraldTeal = Color(0xFF0D9488);
  static const Color emeraldTealLight = Color(0xFF14B8A6);
  static const Color emeraldTealSurface = Color(0xFFF0FDF4);

  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color amberAccent = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberSurface = Color(0xFFFFFBEB);

  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color coralError = Color(0xFFDC2626);
  static const Color coralErrorLight = Color(0xFFF87171);
  static const Color coralErrorSurface = Color(0xFFFEF2F2);

  static const Color skyInfo = Color(0xFF2563EB);
  static const Color skyInfoLight = Color(0xFF60A5FA);
  static const Color skyInfoSurface = Color(0xFFEFF6FF);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color purpleSurface = Color(0xFFF5F3FF);

  // --- Light Theme Neutral Palette (Pure White Canonical Canvas) ---
  static const Color canvas = Color(0xFFFFFFFF); // Pure White canonical authenticated background
  static const Color canvasLight = Color(0xFFFFFFFF);
  static const Color canvasSoft = Color(0xFFF1F5F9); // Slate 100
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFFFFFFF);
  static const Color surfaceLightMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color hairline = Color(0xFFE2E8F0);
  static const Color hairlineHover = Color(0xFFCBD5E1); // Slate 300
  static const Color borderLightSubtle = Color(0xFFF1F5F9);

  // --- Light Theme Text Colors (High Contrast WCAG AA / AAA) ---
  static const Color ink = Color(0xFF0F172A); // Slate 900 (Primary Text)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color inkSecondary = Color(0xFF475569); // Slate 600 (Secondary Text)
  static const Color textSecondary = Color(0xFF475569);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color inkMuted = Color(0xFF64748B); // Slate 500 (Captions / Labels)
  static const Color textMuted = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color inkFaint = Color(0xFF94A3B8); // Slate 400 (Placeholders)
  static const Color textInverseLight = Color(0xFFFFFFFF);

  // --- Dark Theme Neutral Palette ---
  static const Color backgroundDark = Color(0xFF0B0F17);
  static const Color surfaceDark = Color(0xFF161E2E);
  static const Color surfaceDarkElevated = Color(0xFF1E293B);
  static const Color surfaceDarkMuted = Color(0xFF111827);
  static const Color borderDark = Color(0xFF283548);
  static const Color darkBorder = Color(0xFF283548);
  static const Color borderDarkSubtle = Color(0xFF1E293B);

  // --- Dark Theme Text Colors ---
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color textInverseDark = Color(0xFF0F172A);

  // --- Role Identification Badges ---
  static const Color superAdminBadge = Color(0xFF7C3AED);
  static const Color collegeAdminBadge = Color(0xFF0284C7);
  static const Color hodBadge = Color(0xFF0D9488);
  static const Color facultyBadge = Color(0xFFD97706);
  static const Color studentBadge = Color(0xFF2563EB);

  // --- Attendance Status Colors ---
  static const Color present = Color(0xFF16A34A);
  static const Color absent = Color(0xFFDC2626);
  static const Color late = Color(0xFFD97706);
  static const Color excused = Color(0xFF64748B);

  // --- Convenience Aliases ---
  static const Color navy = primaryNavy;
  static const Color emerald = emeraldTeal;
  static const Color amber = amberAccent;
  static const Color coral = coralError;
  static const Color sky = skyInfo;
  static const Color purple = purpleAccent;
  static const Color darkTextPrimary = textPrimaryDark;
  static const Color darkTextSecondary = textSecondaryDark;
  static const Color darkSurfaceElevated = surfaceDarkElevated;
  static const Color surfaceMuted = surfaceLightMuted;
}
