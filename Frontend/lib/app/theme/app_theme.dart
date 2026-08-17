import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Acadex Color Tokens (Notion-inspired workspace system)
class AcadexColors {
  // Primary Structural Actions
  static const Color primary = Color(0xFF0075DE);
  static const Color primaryPressed = Color(0xFF005BAB);
  static const Color secondary = Color(0xFF213183);

  // Surfaces & Canvas
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasSoft = Color(0xFFF6F5F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFE6E6E6);

  // Typography & Ink
  static const Color ink = Color(0xFF000000);
  static const Color inkSecondary = Color(0xFF31302E);
  static const Color inkMuted = Color(0xFF615D59);
  static const Color inkFaint = Color(0xFFA39E98);

  // Decorative Accents (MUST NOT be used for structural primary buttons)
  static const Color accentSky = Color(0xFF62AEF0);
  static const Color accentPurple = Color(0xFFD6B6F6);
  static const Color accentDeepPurple = Color(0xFF391C57);
  static const Color accentPink = Color(0xFFFF64C8);
  static const Color accentOrange = Color(0xFFDD5B00);
  static const Color accentDeepOrange = Color(0xFF793400);
  static const Color accentTeal = Color(0xFF2A9D99);
  static const Color accentGreen = Color(0xFF1AAE39);
  static const Color accentBrown = Color(0xFF523410);

  // Restrained Status / Semantic Colors
  static const Color success = Color(0xFF1AAE39);
  static const Color successLight = Color(0xFFE8F8EC);
  static const Color warning = Color(0xFFDD5B00);
  static const Color warningLight = Color(0xFFFDF2E9);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0075DE);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Restrained Dark Mode Tokens
  static const Color darkCanvas = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceCard = Color(0xFF252525);
  static const Color darkHairline = Color(0xFF2E2E2E);
  static const Color darkInk = Color(0xFFFFFFFF);
  static const Color darkInkSecondary = Color(0xFFCCCCCC);
  static const Color darkInkMuted = Color(0xFF888888);
}

/// Centralized Shape & Radius Tokens
class AcadexRadius {
  static const double xs = 4.0;    // Inputs
  static const double sm = 5.0;
  static const double md = 8.0;    // Utility controls
  static const double lg = 12.0;   // Cards & Panels
  static const double xl = 16.0;   // Large containers & Dialogs
  static const double full = 9999.0; // Pill radius for primary CTAs & Badges

  static BorderRadius get borderRadiusXs => BorderRadius.circular(xs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(sm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(md);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(lg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(xl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(full);
}

/// Centralized Spacing Tokens (8px Rhythm)
class AcadexSpacing {
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
}

/// Centralized Typography System (Inter)
class AcadexTypography {
  static TextStyle display1({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 64,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.125,
        color: color,
      );

  static TextStyle display2({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 54,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.875,
        color: color,
      );

  static TextStyle heading1({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle heading2({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.625,
        color: color,
      );

  static TextStyle heading3({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: color,
      );

  static TextStyle title({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.125,
        color: color,
      );

  static TextStyle body({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({Color color = AcadexColors.inkSecondary}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle button({Color color = Colors.white}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle caption({Color color = AcadexColors.inkMuted}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle eyebrow({Color color = AcadexColors.inkMuted}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      );
}

/// Backwards Compatibility Mapping for AppColors
class AppColors {
  static const Color primary = AcadexColors.primary;
  static const Color primaryPressed = AcadexColors.primaryPressed;
  static const Color primaryActive = AcadexColors.primaryPressed;
  static const Color commerce = AcadexColors.accentOrange;

  static const Color canvasDark = AcadexColors.darkCanvas;
  static const Color surfaceDarkElevated = AcadexColors.darkSurface;
  static const Color surfaceDarkCard = AcadexColors.darkSurfaceCard;

  static const Color canvasLight = AcadexColors.canvas;
  static const Color surfaceSoft = AcadexColors.canvasSoft;
  static const Color surfaceCard = AcadexColors.surface;

  static const Color textLight = AcadexColors.darkInk;
  static const Color textMuted = AcadexColors.inkMuted;
  static const Color textDark = AcadexColors.ink;
  static const Color textDarkMute = AcadexColors.inkMuted;

  static const Color onDark = AcadexColors.darkInk;
  static const Color onPrimary = Colors.white;

  static const Color success = AcadexColors.success;
  static const Color warning = AcadexColors.warning;
  static const Color error = AcadexColors.error;
  static const Color hairlineDark = AcadexColors.darkHairline;
}

/// Backwards Compatibility Mapping for DashboardColors
class DashboardColors {
  static const Color background = AcadexColors.canvasSoft;
  static const Color surface = AcadexColors.surface;
  static const Color primary = AcadexColors.primary;
  static const Color primaryLight = AcadexColors.infoLight;
  static const Color secondary = AcadexColors.primary;
  static const Color textPrimary = AcadexColors.ink;
  static const Color textSecondary = AcadexColors.inkSecondary;
  static const Color textMuted = AcadexColors.inkMuted;
  static const Color border = AcadexColors.hairline;
  static const Color divider = AcadexColors.hairline;
  static const Color success = AcadexColors.success;
  static const Color successLight = AcadexColors.successLight;
  static const Color warning = AcadexColors.warning;
  static const Color warningLight = AcadexColors.warningLight;
  static const Color error = AcadexColors.error;
  static const Color errorLight = AcadexColors.errorLight;
  static const Color info = AcadexColors.info;
  static const Color infoLight = AcadexColors.infoLight;
  static const Color purple = AcadexColors.accentPurple;
  static const Color purpleLight = Color(0xFFF3E8FF);
  static const Color orange = AcadexColors.accentOrange;
  static const Color orangeLight = AcadexColors.warningLight;
  static const Color teal = AcadexColors.accentTeal;
  static const Color tealLight = Color(0xFFE6F4F1);
}

/// Main Application Theme Configuration
class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AcadexColors.canvasSoft,
      primaryColor: AcadexColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AcadexColors.primary,
        secondary: AcadexColors.secondary,
        surface: AcadexColors.surface,
        error: AcadexColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AcadexColors.ink,
        onError: Colors.white,
      ),

      // Card System (12px radius, 1px hairline border, 0 elevation)
      cardTheme: CardThemeData(
        color: AcadexColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusLg,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
      ),

      // AppBar Theme (Clean white, hairline bottom border)
      appBarTheme: AppBarTheme(
        backgroundColor: AcadexColors.surface,
        foregroundColor: AcadexColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AcadexColors.ink,
        ),
        iconTheme: const IconThemeData(color: AcadexColors.inkSecondary),
      ),

      // Button System
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcadexColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusFull, // Pill radius for CTAs
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AcadexColors.surface,
          foregroundColor: AcadexColors.ink,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusFull,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AcadexColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input System (4px radius, hairline border, blue focus ring)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AcadexColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusXs,
          borderSide: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusXs,
          borderSide: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusXs,
          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusXs,
          borderSide: const BorderSide(color: AcadexColors.error, width: 1),
        ),
        labelStyle: GoogleFonts.inter(color: AcadexColors.inkMuted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AcadexColors.inkFaint, fontSize: 14),
      ),

      // Divider System
      dividerTheme: const DividerThemeData(
        color: AcadexColors.hairline,
        thickness: 1,
        space: 0,
      ),

      // Navigation Drawer & Rail
      drawerTheme: const DrawerThemeData(
        backgroundColor: AcadexColors.surface,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AcadexColors.surface,
        selectedIconTheme: const IconThemeData(color: AcadexColors.primary),
        unselectedIconTheme: const IconThemeData(color: AcadexColors.inkMuted),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: AcadexColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: AcadexColors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AcadexColors.surface,
        selectedItemColor: AcadexColors.primary,
        unselectedItemColor: AcadexColors.inkMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        elevation: 0,
      ),

      // Dialog & BottomSheet
      dialogTheme: DialogThemeData(
        backgroundColor: AcadexColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusXl,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AcadexColors.ink,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AcadexColors.inkSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AcadexColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AcadexRadius.xl)),
        ),
      ),

      // Chips & Badges
      chipTheme: ChipThemeData(
        backgroundColor: AcadexColors.canvasSoft,
        disabledColor: AcadexColors.canvasSoft,
        selectedColor: AcadexColors.infoLight,
        secondarySelectedColor: AcadexColors.infoLight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusFull,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AcadexColors.ink),
      ),

      // Typography
      textTheme: baseTextTheme.apply(
        bodyColor: AcadexColors.ink,
        displayColor: AcadexColors.ink,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AcadexColors.darkCanvas,
      primaryColor: AcadexColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AcadexColors.primary,
        secondary: AcadexColors.secondary,
        surface: AcadexColors.darkSurface,
        error: AcadexColors.error,
        onPrimary: Colors.white,
        onSurface: AcadexColors.darkInk,
      ),

      // Card System - Restrained Dark Mode
      cardTheme: CardThemeData(
        color: AcadexColors.darkSurfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusLg,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AcadexColors.darkSurface,
        foregroundColor: AcadexColors.darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AcadexColors.darkInk,
        ),
        iconTheme: const IconThemeData(color: AcadexColors.darkInkSecondary),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcadexColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusFull,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AcadexColors.darkSurface,
          foregroundColor: AcadexColors.darkInk,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusFull,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AcadexColors.darkSurfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusXs,
          borderSide: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusXs,
          borderSide: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusXs,
          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AcadexColors.darkInkMuted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AcadexColors.darkInkMuted, fontSize: 14),
      ),

      dividerTheme: const DividerThemeData(
        color: AcadexColors.darkHairline,
        thickness: 1,
        space: 0,
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: AcadexColors.darkSurface,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AcadexColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusXl,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AcadexColors.darkInk,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AcadexColors.darkInkSecondary,
        ),
      ),

      textTheme: baseTextTheme.apply(
        bodyColor: AcadexColors.darkInk,
        displayColor: AcadexColors.darkInk,
      ),
    );
  }
}
