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
      primaryColor: AcadexColors.primary,
      scaffoldBackgroundColor: AcadexColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AcadexColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AcadexColors.primaryLight,
        onPrimaryContainer: AcadexColors.primaryDark,
        secondary: AcadexColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AcadexColors.secondaryLight,
        onSecondaryContainer: AcadexColors.secondary,
        error: AcadexColors.error,
        onError: Colors.white,
        errorContainer: AcadexColors.errorLight,
        onErrorContainer: AcadexColors.error,
        surface: AcadexColors.surface,
        onSurface: AcadexColors.ink,
        outline: AcadexColors.hairline,
        outlineVariant: AcadexColors.borderLightSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AcadexColors.surface,
        foregroundColor: AcadexColors.ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        color: AcadexColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.lgBorder,
          side: BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcadexColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AcadexColors.ink,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: AcadexRadius.mdBorder),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AcadexColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AcadexRadius.mdBorder,
          borderSide: BorderSide(color: AcadexColors.error),
        ),
        hintStyle: TextStyle(color: AcadexColors.inkMuted, fontSize: 14),
        labelStyle: TextStyle(color: AcadexColors.inkSecondary, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AcadexColors.hairline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
