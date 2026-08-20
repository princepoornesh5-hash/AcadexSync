import 'package:flutter/material.dart';

/// ACADEX Official Spacing, Sizing & Radius Tokens
class AcadexSpacing {
  AcadexSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double section = 48.0;

  // Insets
  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets densePadding = EdgeInsets.all(12.0);
  static const EdgeInsets modalPadding = EdgeInsets.all(20.0);
}

class AcadexRadius {
  AcadexRadius._();

  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double xl = 18.0;
  static const double full = 999.0;

  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullBorder = BorderRadius.all(Radius.circular(full));
}
