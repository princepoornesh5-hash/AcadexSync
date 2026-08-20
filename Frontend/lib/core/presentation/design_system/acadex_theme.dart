import 'package:flutter/material.dart';
import 'acadex_colors.dart';
import 'acadex_spacing.dart';

/// ACADEX Material 3 Theme Definition
class AcadexTheme {
  AcadexTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AcadexColors.primaryNavy,
      scaffoldBackgroundColor: AcadexColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AcadexColors.primaryNavy,
        onPrimary: Colors.white,
        primaryContainer: AcadexColors.primaryNavyLight,
        onPrimaryContainer: Colors.white,
        secondary: AcadexColors.emeraldTeal,
        onSecondary: Colors.white,
        secondaryContainer: AcadexColors.emeraldTealSurface,
        onSecondaryContainer: AcadexColors.emeraldTeal,
        error: AcadexColors.coralError,
        onError: Colors.white,
        errorContainer: AcadexColors.coralErrorSurface,
        onErrorContainer: AcadexColors.coralError,
        surface: AcadexColors.surfaceLight,
        onSurface: AcadexColors.textPrimaryLight,
        outline: AcadexColors.borderLight,
        outlineVariant: AcadexColors.borderLightSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AcadexColors.surfaceLight,
        foregroundColor: AcadexColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        color: AcadexColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.lgBorder,
          side: BorderSide(color: AcadexColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcadexColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AcadexColors.primaryNavy,
          side: const BorderSide(color: AcadexColors.borderLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AcadexColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.borderLight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.emeraldTeal, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.coralError),
        ),
        hintStyle: const TextStyle(color: AcadexColors.textMutedLight, fontSize: 14),
        labelStyle: const TextStyle(color: AcadexColors.textSecondaryLight, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AcadexColors.borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AcadexColors.primaryNavyLight,
      scaffoldBackgroundColor: AcadexColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AcadexColors.emeraldTealLight,
        onPrimary: Colors.black,
        primaryContainer: AcadexColors.primaryNavy,
        onPrimaryContainer: Colors.white,
        secondary: AcadexColors.emeraldTealLight,
        onSecondary: Colors.black,
        secondaryContainer: AcadexColors.surfaceDarkElevated,
        onSecondaryContainer: AcadexColors.emeraldTealLight,
        error: AcadexColors.coralErrorLight,
        onError: Colors.black,
        errorContainer: AcadexColors.surfaceDarkElevated,
        onErrorContainer: AcadexColors.coralErrorLight,
        surface: AcadexColors.surfaceDark,
        onSurface: AcadexColors.textPrimaryDark,
        outline: AcadexColors.borderDark,
        outlineVariant: AcadexColors.borderDarkSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AcadexColors.surfaceDark,
        foregroundColor: AcadexColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        color: AcadexColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.lgBorder,
          side: BorderSide(color: AcadexColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcadexColors.emeraldTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AcadexColors.textPrimaryDark,
          side: const BorderSide(color: AcadexColors.borderDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AcadexColors.surfaceDarkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.borderDark),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.borderDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.emeraldTealLight, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.coralErrorLight),
        ),
        hintStyle: const TextStyle(color: AcadexColors.textMutedDark, fontSize: 14),
        labelStyle: const TextStyle(color: AcadexColors.textSecondaryDark, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AcadexColors.borderDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
