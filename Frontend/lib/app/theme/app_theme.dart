import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Acadex Color Tokens (Modern Academic & Productivity System)
class AcadexColors {
  // Primary Brand Identity - Vibrant ACADEX Blue
  static const Color primary = Color(0xFF2563EB); // Blue 600 (Primary Action)
  static const Color primaryHover = Color(0xFF1D4ED8); // Blue 700 (Hover/Focus)
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700
  static const Color primaryPressed = Color(0xFF1E40AF); // Blue 800 (Pressed)
  static const Color primaryLight = Color(0xFFDBEAFE); // Blue 100 (Soft Highlight)
  static const Color primarySoft = Color(0xFFDBEAFE); // Blue 100
  static const Color primaryTint = Color(0xFFEFF6FF); // Blue 50 (Subtle Surface)
  static const Color primaryMuted = Color(0xFF60A5FA); // Blue 400

  static const Color secondary = Color(0xFF0F172A); // Deep Slate 900
  static const Color secondaryLight = Color(0xFFF1F5F9); // Slate 100

  // Super Admin Action Blue Hierarchy (Prototype)
  static const Color superAdminDeepAction = Color(0xFF003366); // Deep Action Blue (Primary CTA)
  static const Color superAdminDeepPressed = Color(0xFF00264D); // Deep Pressed Blue
  static const Color superAdminPrimaryAction = Color(0xFF0066CC); // Primary Action Blue (Border/Icon/Text CTA)
  static const Color superAdminSoftAction = Color(0xFFE6F2FF); // Soft Blue (Soft Actions / Badges)
  static const Color superAdminVerySoft = Color(0xFFEFF6FF); // Very Soft Blue (Card Tint)

  // Light Canvas & Surface Layers (Calm & Clean)
  static const Color canvas = Color(0xFFF8FAFC); // Slate 50 neutral canvas
  static const Color canvasLight = Color(0xFFF8FAFC);
  static const Color canvasSoft = Color(0xFFF1F5F9); // Slate 100 soft background
  static const Color surface = Color(0xFFFFFFFF); // Pure White cards
  static const Color surfaceHover = Color(0xFFF8FAFC); // Slate 50
  static const Color hairline = Color(0xFFE2E8F0); // Slate 200 crisp border
  static const Color border = Color(0xFFE2E8F0);
  static const Color hairlineHover = Color(0xFFCBD5E1); // Slate 300

  // Light Typography & Ink (High Contrast WCAG AA / AAA)
  static const Color ink = Color(0xFF0F172A); // Slate 900 primary text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color inkSecondary = Color(0xFF475569); // Slate 600 secondary text
  static const Color textSecondary = Color(0xFF475569);
  static const Color inkMuted = Color(0xFF64748B); // Slate 500 muted text/captions
  static const Color textMuted = Color(0xFF64748B);
  static const Color inkFaint = Color(0xFF94A3B8); // Slate 400 placeholder/disabled

  // Dark Canvas & Surface Layers (Deep Slate Architecture)
  static const Color darkCanvas = Color(0xFF0B0F17); // Deepest Slate Canvas
  static const Color darkCanvasSoft = Color(0xFF111827); // Dark Slate 900
  static const Color darkSurface = Color(0xFF161E2E); // Elevated Dark Card
  static const Color darkSurfaceCard = Color(0xFF1E293B); // Slate 800 Card
  static const Color darkSurfaceHover = Color(0xFF243248); // Slate 750
  static const Color darkHairline = Color(0xFF283548); // Slate 700 Border
  static const Color darkBorder = Color(0xFF283548);
  static const Color darkHairlineHover = Color(0xFF334155); // Slate 600

  // Dark Typography & Ink
  static const Color darkInk = Color(0xFFF8FAFC); // Slate 50 crisp white text
  static const Color darkInkSecondary = Color(0xFFE2E8F0); // Slate 200
  static const Color darkInkMuted = Color(0xFF94A3B8); // Slate 400
  static const Color darkInkFaint = Color(0xFF64748B); // Slate 500

  // Semantic Status Colors (Calm & Accessible)
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

  // Decorative Accent Highlights
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
}

/// Centralized Shape & Radius Tokens
class AcadexRadius {
  static const double xs = 4.0;    // Inputs & Small Badges
  static const double sm = 6.0;    // List items & Chips
  static const double md = 10.0;   // Controls & Buttons
  static const double lg = 14.0;   // Cards & Panels
  static const double xl = 18.0;   // Dialogs & Modals
  static const double xxl = 24.0;  // Large Containers
  static const double full = 9999.0; // Pill Buttons & Badges

  static BorderRadius get borderRadiusXs => BorderRadius.circular(xs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(sm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(md);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(lg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(xl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(xxl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(full);
}

/// Centralized Spacing Tokens (8px Rhythm Scale)
class AcadexSpacing {
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Standard EdgeInsets utilities
  static const EdgeInsets pagePaddingMobile = EdgeInsets.all(space16);
  static const EdgeInsets pagePaddingTablet = EdgeInsets.all(space24);
  static const EdgeInsets pagePaddingDesktop = EdgeInsets.all(space32);
  static const EdgeInsets cardPadding = EdgeInsets.all(space20);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(space16);
  static const EdgeInsets dialogPadding = EdgeInsets.all(space24);
}

/// Responsive Layout Breakpoints
class AcadexBreakpoints {
  static const double mobileSmallMax = 374.0;
  static const double mobileMax = 599.0;
  static const double tabletMax = 1023.0;
  static const double desktopMin = 1024.0;
  static const double desktopMax = 1440.0;

  static bool isSmallMobile(BuildContext context) => MediaQuery.of(context).size.width <= mobileSmallMax;
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width <= mobileMax;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMax && width <= tabletMax;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= desktopMin;
}

/// Centralized Subtle Shadows
class AcadexShadows {
  static List<BoxShadow> lightSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> lightMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lightLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> darkSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> darkMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

/// Centralized Typography System (Inter Font Hierarchy)
class AcadexTypography {
  static TextStyle display1({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.15,
        color: color,
      );

  static TextStyle display2({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.2,
        color: color,
      );

  static TextStyle heading1({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.25,
        color: color,
      );

  static TextStyle heading2({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
        color: color,
      );

  static TextStyle heading3({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: color,
      );

  static TextStyle title({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle body({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium({Color color = AcadexColors.ink}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySmall({Color color = AcadexColors.inkSecondary}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
        color: color,
      );

  static TextStyle button({Color color = Colors.white}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle caption({Color color = AcadexColors.inkMuted}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.4,
        color: color,
      );

  static TextStyle eyebrow({Color color = AcadexColors.inkMuted}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: color,
      );

  static TextStyle code({Color color = AcadexColors.ink}) => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // Convenience getters
  static TextStyle get h1 => heading1();
  static TextStyle get h2 => heading2();
  static TextStyle get h3 => heading3();
  static TextStyle get bodyText => body();
  static TextStyle get captionText => caption();
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

      // Card System (Clean 14px radius, 1px subtle border, soft elevation)
      cardTheme: CardThemeData(
        color: AcadexColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusLg,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
      ),

      // AppBar Theme (Clean, border-bottom)
      appBarTheme: AppBarTheme(
        backgroundColor: AcadexColors.surface,
        foregroundColor: AcadexColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AcadexColors.ink,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AcadexColors.inkSecondary, size: 20),
      ),

      // Button System
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcadexColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusMd,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusSm,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AcadexColors.surface,
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
        labelStyle: GoogleFonts.inter(color: AcadexColors.inkMuted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AcadexColors.inkFaint, fontSize: 14),
      ),

      dividerTheme: const DividerThemeData(
        color: AcadexColors.hairline,
        thickness: 1,
        space: 0,
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
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AcadexColors.surface,
        elevation: 4,
        constraints: const BoxConstraints(maxWidth: 480),
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusXl,
          side: const BorderSide(color: AcadexColors.hairline, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
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
        elevation: 8,
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
          letterSpacing: 0.5,
          color: AcadexColors.inkSecondary,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AcadexColors.ink,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 24,
      ),

      textTheme: baseTextTheme.apply(
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
        onErrorContainer: Colors.white,
        outline: AcadexColors.darkHairline,
        outlineVariant: AcadexColors.darkHairlineHover,
      ),

      // Card System (Deep Slate, crisp border)
      cardTheme: CardThemeData(
        color: AcadexColors.darkSurfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusLg,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AcadexColors.darkSurface,
        foregroundColor: AcadexColors.darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AcadexColors.darkSurfaceCard,
          foregroundColor: AcadexColors.darkInk,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AcadexColors.primaryMuted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: AcadexRadius.borderRadiusSm,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
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
        labelStyle: GoogleFonts.inter(color: AcadexColors.darkInkMuted, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AcadexColors.darkInkFaint, fontSize: 14),
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
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AcadexColors.darkSurface,
        elevation: 4,
        constraints: const BoxConstraints(maxWidth: 480),
        shape: RoundedRectangleBorder(
          borderRadius: AcadexRadius.borderRadiusXl,
          side: const BorderSide(color: AcadexColors.darkHairline, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AcadexColors.darkInk,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AcadexColors.darkInkSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AcadexColors.darkSurface,
        elevation: 8,
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

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AcadexColors.darkSurfaceCard),
        headingTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AcadexColors.darkInkSecondary,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AcadexColors.darkInk,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 24,
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
  // Standardized Durations
  static const Duration instant = Duration.zero;
  static const Duration micro = Duration(milliseconds: 120);     // Hover, press, tiny icon tweaks
  static const Duration fast = Duration(milliseconds: 180);      // Chip toggles, card entrances, fade-ins
  static const Duration normal = Duration(milliseconds: 240);    // View switching, filter results, accordions
  static const Duration page = Duration(milliseconds: 280);      // Page transitions, modal sheets

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

