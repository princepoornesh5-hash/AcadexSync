import 'package:flutter/material.dart';

/// ACADEX Official Design System Color Palette
/// Curated for a clean, premium, modern, calm academic interface.
class AcadexColors {
  AcadexColors._();

  // --- Primary Brand Colors ---
  static const Color primaryNavy = Color(0xFF0F2537);
  static const Color primaryNavyLight = Color(0xFF1E3A56);
  static const Color primaryNavyDark = Color(0xFF0A1824);

  // --- Accent & Semantic Colors ---
  static const Color emeraldTeal = Color(0xFF0D9488);
  static const Color emeraldTealLight = Color(0xFF14B8A6);
  static const Color emeraldTealSurface = Color(0xFFF0FDF4);

  static const Color amberAccent = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberSurface = Color(0xFFFFFBEB);

  static const Color coralError = Color(0xFFEF4444);
  static const Color coralErrorLight = Color(0xFFF87171);
  static const Color coralErrorSurface = Color(0xFFFEF2F2);

  static const Color skyInfo = Color(0xFF0284C7);
  static const Color skyInfoLight = Color(0xFF38BDF8);
  static const Color skyInfoSurface = Color(0xFFF0F9FF);

  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color purpleSurface = Color(0xFFF5F3FF);

  // --- Light Theme Neutral Palette ---
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFFFFFFF);
  static const Color surfaceLightMuted = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderLightSubtle = Color(0xFFF1F5F9);

  // --- Light Theme Text Colors ---
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color textInverseLight = Color(0xFFFFFFFF);

  // --- Dark Theme Neutral Palette ---
  static const Color backgroundDark = Color(0xFF0A1118);
  static const Color surfaceDark = Color(0xFF111C26);
  static const Color surfaceDarkElevated = Color(0xFF182635);
  static const Color surfaceDarkMuted = Color(0xFF0E1720);
  static const Color borderDark = Color(0xFF223548);
  static const Color borderDarkSubtle = Color(0xFF182635);

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
  static const Color present = Color(0xFF10B981);
  static const Color absent = Color(0xFFEF4444);
  static const Color late = Color(0xFFF59E0B);
  static const Color excused = Color(0xFF6B7280);

  // --- Convenience Aliases ---
  static const Color navy = primaryNavy;
  static const Color emerald = emeraldTeal;
  static const Color amber = amberAccent;
  static const Color coral = coralError;
  static const Color sky = skyInfo;
  static const Color purple = purpleAccent;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color darkTextPrimary = textPrimaryDark;
  static const Color darkTextSecondary = textSecondaryDark;
  static const Color border = borderLight;
  static const Color darkBorder = borderDark;
  static const Color darkSurfaceElevated = surfaceDarkElevated;
  static const Color surfaceMuted = surfaceLightMuted;
}
