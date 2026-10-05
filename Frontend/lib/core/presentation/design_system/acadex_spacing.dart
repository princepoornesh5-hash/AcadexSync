import 'package:flutter/material.dart';

/// Centralized ACADEX Spacing Tokens (4/8-point Rhythm Scale)
/// Prioritized for Android mobile layouts (360px, 390px, 412px) to prevent vertical & horizontal inflation.
class AcadexSpacing {
  AcadexSpacing._();

  // ── Standard 4/8-point Scale Tokens ──
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ── Convenience Aliases ──
  static const double xxs = space2;
  static const double xs = space4;
  static const double sm = space8;
  static const double md = space12;
  static const double lg = space16;
  static const double xl = space20;
  static const double xxl = space24;
  static const double xxxl = space32;
  static const double section = space48;

  // ── Standard Insets & Padding ──
  /// Mobile horizontal page padding: 14px on small devices, 16px standard
  static const EdgeInsets pagePaddingMobile = EdgeInsets.symmetric(horizontal: space14, vertical: space16);
  static const EdgeInsets pagePaddingTablet = EdgeInsets.all(space20);
  static const EdgeInsets pagePaddingDesktop = EdgeInsets.all(space28);
  static const EdgeInsets pagePadding = EdgeInsets.all(space16);

  /// Card internal padding: 14px default on mobile to maximize content readability
  static const EdgeInsets cardPadding = EdgeInsets.all(space14);
  static const EdgeInsets cardPaddingStandard = EdgeInsets.all(space16);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(space10);
  static const EdgeInsets densePadding = EdgeInsets.all(space10);

  /// Modals & Dialogs
  static const EdgeInsets dialogPadding = EdgeInsets.all(space20);
  static const EdgeInsets modalPadding = EdgeInsets.all(space20);
}

/// Centralized Shape & Corner Radius Tokens
class AcadexRadius {
  AcadexRadius._();

  static const double xs = 4.0;      // Tiny tags, inner badges
  static const double sm = 6.0;      // List items, chips, small controls
  static const double md = 10.0;     // Buttons, text inputs, selectors
  static const double lg = 14.0;     // Cards, containers, panels
  static const double xl = 18.0;     // Bottom sheets, dialogs, modals
  static const double xxl = 24.0;    // Prominent hero sections
  static const double full = 999.0;  // Pills, round action icons

  // BorderRadius getters (CamelCase style)
  static BorderRadius get borderRadiusXs => BorderRadius.circular(xs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(sm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(md);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(lg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(xl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(xxl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(full);

  // Border radius aliases (legacy style)
  static const BorderRadius xsBorder = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlBorder = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius fullBorder = BorderRadius.all(Radius.circular(full));
}

/// Centralized Subtle Shadows (Reduced elevation to eliminate visual noise)
class AcadexShadows {
  AcadexShadows._();

  static List<BoxShadow> lightSm = const [
    BoxShadow(
      color: Color(0x06000000), // 2.5% opacity
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> lightMd = const [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lightLg = const [
    BoxShadow(
      color: Color(0x0F000000), // 6% opacity
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> darkSm = const [
    BoxShadow(
      color: Color(0x40000000), // 25% opacity
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> darkMd = const [
    BoxShadow(
      color: Color(0x59000000), // 35% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
