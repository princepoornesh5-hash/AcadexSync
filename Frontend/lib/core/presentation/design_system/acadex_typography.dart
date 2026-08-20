import 'package:flutter/material.dart';
import 'acadex_colors.dart';

/// ACADEX Typography Scale
class AcadexTypography {
  AcadexTypography._();

  static const TextStyle h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
    color: AcadexColors.textPrimaryLight,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AcadexColors.textPrimaryLight,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
    color: AcadexColors.textPrimaryLight,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: AcadexColors.textSecondaryLight,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AcadexColors.textPrimaryLight,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.45,
    color: AcadexColors.textPrimaryLight,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
    color: AcadexColors.textSecondaryLight,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AcadexColors.textPrimaryLight,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AcadexColors.textSecondaryLight,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AcadexColors.textMutedLight,
  );

  static const TextStyle statHero = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
    color: AcadexColors.textPrimaryLight,
  );

  static const TextStyle statLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
    color: AcadexColors.textPrimaryLight,
  );

  // Convenience aliases
  static const TextStyle body = bodyMedium;
  static const TextStyle caption = bodySmall;
}
