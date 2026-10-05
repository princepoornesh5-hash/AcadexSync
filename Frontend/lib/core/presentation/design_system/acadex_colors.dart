import 'package:flutter/material.dart';

/// Centralized ACADEX Color Tokens (Modern Academic & Productivity System)
/// Curated for a clean, premium, modern, calm, and high-contrast academic mobile interface.
class AcadexColors {
  AcadexColors._();

  // ── 1. Primary Brand Identity (Vibrant ACADEX Blue) ──
  static const Color primary = Color(0xFF2563EB); // Blue 600 (Primary Action)
  static const Color primaryHover = Color(0xFF1D4ED8); // Blue 700 (Hover/Focus)
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700
  static const Color primaryPressed = Color(0xFF1E40AF); // Blue 800 (Pressed)
  static const Color primaryLight = Color(0xFFDBEAFE); // Blue 100 (Soft Highlight)
  static const Color primarySoft = Color(0xFFDBEAFE); // Blue 100
  static const Color primaryTint = Color(0xFFEFF6FF); // Blue 50 (Subtle Surface)
  static const Color primaryMuted = Color(0xFF60A5FA); // Blue 400

  // ── 2. Secondary & Neutral Brand Accents ──
  static const Color secondary = Color(0xFF0F172A); // Deep Slate 900
  static const Color secondaryLight = Color(0xFFF1F5F9); // Slate 100
  static const Color primaryNavy = Color(0xFF0F172A); // Deep Slate 900 alias

  // ── 3. Super Admin Action Blue Hierarchy ──
  static const Color superAdminDeepAction = Color(0xFF003366); // Deep Action Blue (Primary CTA)
  static const Color superAdminDeepPressed = Color(0xFF00264D); // Deep Pressed Blue
  static const Color superAdminPrimaryAction = Color(0xFF0066CC); // Primary Action Blue
  static const Color superAdminSoftAction = Color(0xFFE6F2FF); // Soft Blue (Soft Actions / Badges)
  static const Color superAdminVerySoft = Color(0xFFEFF6FF); // Very Soft Blue (Card Tint)

  // ── 4. Light Canvas & Surfaces (Calm, Pure & Crisp) ──
  static const Color canvas = Color(0xFFFFFFFF); // Pure White canonical canvas
  static const Color canvasLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color canvasSoft = Color(0xFFF8FAFC); // Slate 50 soft background
  static const Color surface = Color(0xFFFFFFFF); // Pure White cards/containers
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceHover = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLightElevated = Color(0xFFFFFFFF);
  static const Color surfaceLightMuted = Color(0xFFF1F5F9);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color hairline = Color(0xFFE2E8F0); // Slate 200 crisp border
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color hairlineHover = Color(0xFFCBD5E1); // Slate 300
  static const Color borderLightSubtle = Color(0xFFF1F5F9);

  // ── 5. Light Typography & Ink (WCAG AA / AAA High Contrast) ──
  static const Color ink = Color(0xFF07111F); // Dark Navy #07111F primary text
  static const Color textPrimary = Color(0xFF07111F);
  static const Color textPrimaryLight = Color(0xFF07111F);
  static const Color inkSecondary = Color(0xFF475569); // Slate 600 secondary text
  static const Color textSecondary = Color(0xFF475569);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color inkMuted = Color(0xFF64748B); // Slate 500 captions/labels
  static const Color textMuted = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color inkFaint = Color(0xFF94A3B8); // Slate 400 placeholder/disabled
  static const Color textInverseLight = Color(0xFFFFFFFF);

  // ── 6. Dark Canvas & Surfaces (Deep Slate Architecture) ──
  static const Color darkCanvas = Color(0xFF0B0F17); // Deepest Slate Canvas
  static const Color backgroundDark = Color(0xFF0B0F17);
  static const Color darkCanvasSoft = Color(0xFF111827); // Dark Slate 900
  static const Color darkSurface = Color(0xFF161E2E); // Elevated Dark Card
  static const Color surfaceDark = Color(0xFF161E2E);
  static const Color darkSurfaceCard = Color(0xFF1E293B); // Slate 800 Card
  static const Color surfaceDarkElevated = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);
  static const Color surfaceDarkMuted = Color(0xFF111827);
  static const Color darkSurfaceHover = Color(0xFF243248); // Slate 750
  static const Color darkHairline = Color(0xFF283548); // Slate 700 Border
  static const Color darkBorder = Color(0xFF283548);
  static const Color borderDark = Color(0xFF283548);
  static const Color borderDarkSubtle = Color(0xFF1E293B);
  static const Color darkHairlineHover = Color(0xFF334155); // Slate 600

  // ── 7. Dark Typography & Ink ──
  static const Color darkInk = Color(0xFFF8FAFC); // Slate 50 crisp white text
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkInkSecondary = Color(0xFFE2E8F0); // Slate 200
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkInkMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color darkInkFaint = Color(0xFF64748B); // Slate 500
  static const Color textInverseDark = Color(0xFF0F172A);

  // ── 8. Semantic Status Colors (Accessible, Restrained) ──
  static const Color success = Color(0xFF16A34A); // Green 600
  static const Color successLight = Color(0xFFDCFCE7); // Green 100
  static const Color successDark = Color(0xFF15803D); // Green 700
  static const Color successDarkContainer = Color(0xFF052E16);

  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color warningDark = Color(0xFFB45309); // Amber 700
  static const Color warningDarkContainer = Color(0xFF451A03);

  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color errorDark = Color(0xFFB91C1C); // Red 700
  static const Color errorDarkContainer = Color(0xFF450A0A);

  static const Color info = Color(0xFF2563EB); // Blue 600
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100
  static const Color infoDark = Color(0xFF1D4ED8); // Blue 700

  // ── 9. Role Identification Badges ──
  static const Color superAdminBadge = Color(0xFF7C3AED); // Violet 600
  static const Color collegeAdminBadge = Color(0xFF0284C7); // Sky 600
  static const Color hodBadge = Color(0xFF0D9488); // Teal 600
  static const Color facultyBadge = Color(0xFFD97706); // Amber 600
  static const Color studentBadge = Color(0xFF2563EB); // Blue 600

  // ── 10. Attendance Status Colors ──
  static const Color present = Color(0xFF16A34A); // Green 600
  static const Color absent = Color(0xFFDC2626); // Red 600
  static const Color late = Color(0xFFD97706); // Amber 600
  static const Color excused = Color(0xFF64748B); // Slate 500

  // ── 11. Accent Colors & Convenience Aliases ──
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleLight = Color(0xFFF5F3FF);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentTealLight = Color(0xFFF0FDFA);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color accentOrangeLight = Color(0xFFFFF7ED);
  static const Color accentSky = Color(0xFF0284C7);
  static const Color accentPink = Color(0xFFDB2777);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color accentBrown = Color(0xFF78350F);
  static const Color accentDeepPurple = Color(0xFF4C1D95);
  static const Color accentDeepOrange = Color(0xFF9A3412);

  static const Color emeraldTeal = accentTeal;
  static const Color emeraldTealLight = Color(0xFF14B8A6);
  static const Color emeraldTealSurface = Color(0xFFF0FDF4);
  static const Color amberAccent = warning;
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberSurface = Color(0xFFFFFBEB);
  static const Color coralError = error;
  static const Color coralErrorLight = Color(0xFFF87171);
  static const Color coralErrorSurface = Color(0xFFFEF2F2);
  static const Color skyInfo = info;
  static const Color skyInfoLight = Color(0xFF60A5FA);
  static const Color skyInfoSurface = Color(0xFFEFF6FF);
  static const Color purpleAccent = accentPurple;
  static const Color purpleSurface = accentPurpleLight;

  static const Color navy = primaryNavy;
  static const Color emerald = emeraldTeal;
  static const Color amber = amberAccent;
  static const Color coral = coralError;
  static const Color sky = skyInfo;
  static const Color purple = purpleAccent;
}
