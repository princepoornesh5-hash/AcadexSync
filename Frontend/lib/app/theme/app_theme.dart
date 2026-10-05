import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/presentation/design_system/acadex_colors.dart';
import '../../core/presentation/design_system/acadex_spacing.dart';

export '../../core/presentation/design_system/acadex_colors.dart';
export '../../core/presentation/design_system/acadex_spacing.dart';
export '../../core/presentation/design_system/acadex_breakpoints.dart';
export '../../core/presentation/design_system/acadex_typography.dart';

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
  static const Color background = AcadexColors.canvas;
  static const Color surface = AcadexColors.surface;
  static const Color primary = AcadexColors.primary;
  static const Color primaryLight = AcadexColors.primaryLight;
  static const Color secondary = AcadexColors.secondary;
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
  static const Color purpleLight = AcadexColors.accentPurpleLight;
  static const Color orange = AcadexColors.accentOrange;
  static const Color orangeLight = AcadexColors.accentOrangeLight;
  static const Color teal = AcadexColors.accentTeal;
  static const Color tealLight = AcadexColors.accentTealLight;
}

/// Main Application Theme Engine
class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AcadexColors.canvas,
      primaryColor: AcadexColors.primary,
      dividerColor: AcadexColors.hairline,
      splashColor: AcadexColors.primaryLight.withValues(alpha: 0.5),
      highlightColor: Colors.transparent,

      colorScheme: const ColorScheme.light(
        primary: AcadexColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AcadexColors.primaryLight,
        onPrimaryContainer: AcadexColors.primary,
        secondary: AcadexColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AcadexColors.secondaryLight,
        onSecondaryContainer: AcadexColors.secondary,
        surface: AcadexColors.surface,
        onSurface: AcadexColors.ink,
        surfaceContainerHighest: AcadexColors.canvasSoft,
        error: AcadexColors.error,
        onError: Colors.white,
        errorContainer: AcadexColors.errorLight,
        onErrorContainer: AcadexColors.errorDark,
        outline: AcadexColors.hairline,
        outlineVariant: AcadexColors.hairlineHover,
      ),

      // Card System - Clean, lightweight, flat surface with crisp subtle hairline border
      cardTheme: CardThemeData(
        color: AcadexColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusLg,
          side: const BorderSide(
            color: AcadexColors.hairline,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // App Bar System - Clean, flat, high-contrast
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AcadexColors.ink,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AcadexColors.inkSecondary, size: 20),
      ),

      // Button System - Uniform 44px minimum tap targets
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcadexColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AcadexColors.surface,
          foregroundColor: AcadexColors.ink,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AcadexColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusSm,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme - Consistent 44-48px touch targets & crisp focused states
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        labelStyle: GoogleFonts.inter(
          color: AcadexColors.inkSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: AcadexColors.primary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(
          color: AcadexColors.inkMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: GoogleFonts.inter(
          color: AcadexColors.inkMuted,
          fontSize: 11.5,
        ),
        errorStyle: GoogleFonts.inter(
          color: AcadexColors.error,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AcadexColors.inkMuted,
        suffixIconColor: AcadexColors.inkMuted,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.inter(
          color: AcadexColors.ink,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(4),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: AcadexRadius.borderRadiusMd,
              side: const BorderSide(color: AcadexColors.hairline, width: 1),
            ),
          ),
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: AcadexColors.primary,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        dividerColor: AcadexColors.hairline,
        dayStyle: GoogleFonts.inter(fontSize: 13.5, color: AcadexColors.ink),
        yearStyle: GoogleFonts.inter(fontSize: 13.5, color: AcadexColors.ink),
        todayForegroundColor: WidgetStateProperty.all(AcadexColors.primary),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AcadexColors.inkFaint;
          return AcadexColors.ink;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AcadexColors.primary;
          return Colors.transparent;
        }),
      ),

      dividerTheme: const DividerThemeData(
        color: AcadexColors.hairline,
        thickness: 1,
        space: 1,
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: AcadexColors.surface,
        elevation: 0,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AcadexColors.surface,
        selectedIconTheme: const IconThemeData(color: AcadexColors.primary, size: 22),
        unselectedIconTheme: const IconThemeData(color: AcadexColors.inkMuted, size: 22),
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

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AcadexColors.surface,
        selectedItemColor: AcadexColors.primary,
        unselectedItemColor: AcadexColors.inkMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        elevation: 4,
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        constraints: const BoxConstraints(maxWidth: 480),
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusXl,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AcadexColors.ink,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13.5,
          color: AcadexColors.inkSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AcadexColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AcadexRadius.xl)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AcadexColors.canvasSoft,
        disabledColor: AcadexColors.canvasSoft,
        selectedColor: AcadexColors.primaryLight,
        secondarySelectedColor: AcadexColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusFull,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AcadexColors.ink),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AcadexColors.canvasSoft),
        headingTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AcadexColors.inkSecondary,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AcadexColors.ink,
        ),
        dividerThickness: 1,
        horizontalMargin: 14,
        columnSpacing: 20,
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: AcadexColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AcadexColors.primary,
        unselectedLabelColor: AcadexColors.inkMuted,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: AcadexColors.hairline,
      ),

      textTheme: baseTextTheme.copyWith(
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AcadexColors.ink,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AcadexColors.ink,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: AcadexColors.ink,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AcadexColors.inkSecondary,
        ),
      ).apply(
        bodyColor: AcadexColors.ink,
        displayColor: AcadexColors.ink,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AcadexColors.darkCanvas,
      primaryColor: AcadexColors.primary,
      dividerColor: AcadexColors.darkHairline,
      splashColor: AcadexColors.primaryMuted.withValues(alpha: 0.2),
      highlightColor: Colors.transparent,

      colorScheme: const ColorScheme.dark(
        primary: AcadexColors.primaryMuted,
        onPrimary: Colors.white,
        primaryContainer: AcadexColors.primaryHover,
        onPrimaryContainer: AcadexColors.darkInk,
        secondary: AcadexColors.secondaryLight,
        onSecondary: AcadexColors.ink,
        secondaryContainer: AcadexColors.darkSurfaceCard,
        onSecondaryContainer: AcadexColors.darkInk,
        surface: AcadexColors.darkSurface,
        onSurface: AcadexColors.darkInk,
        surfaceContainerHighest: AcadexColors.darkSurfaceCard,
        error: AcadexColors.error,
        onError: Colors.white,
        errorContainer: AcadexColors.errorDarkContainer,
        onErrorContainer: AcadexColors.errorLight,
        outline: AcadexColors.darkHairline,
        outlineVariant: AcadexColors.darkHairlineHover,
      ),

      cardTheme: CardThemeData(
        color: AcadexColors.darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusLg,
          side: const BorderSide(
            color: AcadexColors.darkHairline,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AcadexColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AcadexColors.darkInk,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AcadexColors.darkInkSecondary, size: 20),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcadexColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AcadexColors.darkSurfaceCard,
          foregroundColor: AcadexColors.darkInk,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AcadexColors.primaryMuted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusSm,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AcadexColors.darkSurfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.primaryMuted, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.borderRadiusMd,
          borderSide: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        labelStyle: GoogleFonts.inter(
          color: AcadexColors.darkInkSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: AcadexColors.primaryMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(
          color: AcadexColors.darkInkMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: GoogleFonts.inter(
          color: AcadexColors.darkInkMuted,
          fontSize: 11.5,
        ),
        errorStyle: GoogleFonts.inter(
          color: AcadexColors.errorLight,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AcadexColors.darkInkMuted,
        suffixIconColor: AcadexColors.darkInkMuted,
      ),

      dividerTheme: const DividerThemeData(
        color: AcadexColors.darkHairline,
        thickness: 1,
        space: 1,
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: AcadexColors.darkSurface,
        elevation: 0,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AcadexColors.darkSurface,
        selectedIconTheme: const IconThemeData(color: AcadexColors.primaryMuted, size: 22),
        unselectedIconTheme: const IconThemeData(color: AcadexColors.darkInkMuted, size: 22),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: AcadexColors.primaryMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: AcadexColors.darkInkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AcadexColors.darkSurface,
        selectedItemColor: AcadexColors.primaryMuted,
        unselectedItemColor: AcadexColors.darkInkMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        elevation: 4,
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AcadexColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        constraints: const BoxConstraints(maxWidth: 480),
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusXl,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AcadexColors.darkInk,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13.5,
          color: AcadexColors.darkInkSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AcadexColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AcadexRadius.xl)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AcadexColors.darkSurfaceCard,
        disabledColor: AcadexColors.darkSurfaceCard,
        selectedColor: AcadexColors.primaryHover,
        secondarySelectedColor: AcadexColors.primaryHover,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusFull,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AcadexColors.darkInk),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: AcadexColors.primaryMuted,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AcadexColors.primaryMuted,
        unselectedLabelColor: AcadexColors.darkInkMuted,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: AcadexColors.darkHairline,
      ),

      textTheme: baseTextTheme.apply(
        bodyColor: AcadexColors.darkInk,
        displayColor: AcadexColors.darkInk,
      ),
    );
  }
}

/// Centralized Acadex Motion & Micro-Interaction Tokens
class AcadexMotion {
  AcadexMotion._();

  // Standardized Durations
  static const Duration instant = Duration.zero;
  static const Duration micro = Duration(milliseconds: 120);   // Press, hover, icon tweaks
  static const Duration fast = Duration(milliseconds: 180);    // Card entrance, chip toggle, fade
  static const Duration normal = Duration(milliseconds: 240);  // Views, tabs, accordions
  static const Duration page = Duration(milliseconds: 280);    // Page transitions, modal sheets

  // Standardized Curves
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;

  // Accessibility Check
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  // Duration resolver respecting accessibility reduced motion
  static Duration resolveDuration(BuildContext context, Duration standardDuration) {
    if (isReducedMotion(context)) return Duration.zero;
    return standardDuration;
  }
}
