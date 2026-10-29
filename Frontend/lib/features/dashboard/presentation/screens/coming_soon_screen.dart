import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_back_button.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';

/// Reusable Coming Soon screen for unavailable or future ACADEXSYNC modules.
///
/// Features:
/// - Follows ACADEX design system, typography, and dark/light mode palette
/// - Prominent 'Coming Soon' heading and module name
/// - Customizable description with fallback
/// - Contextual Lucide icon per module
/// - Consistent top-left back navigation via [AcadexBackButton]
class ComingSoonScreen extends StatelessWidget {
  final String moduleName;
  final String? description;
  final IconData? icon;
  final String? fallbackRoute;

  const ComingSoonScreen({
    super.key,
    required this.moduleName,
    this.description,
    this.icon,
    this.fallbackRoute,
  });

  static IconData iconForModule(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('certificate')) return LucideIcons.award;
    if (lower.contains('achievement')) return LucideIcons.trophy;
    if (lower.contains('timetable')) return LucideIcons.calendarClock;
    if (lower.contains('attendance')) return LucideIcons.clipboardCheck;
    if (lower.contains('note')) return LucideIcons.fileText;
    if (lower.contains('profile')) return LucideIcons.userCircle;
    if (lower.contains('setting')) return LucideIcons.settings;
    if (lower.contains('notification') || lower.contains('announcement')) {
      return LucideIcons.bell;
    }
    if (lower.contains('analytic') || lower.contains('report')) {
      return LucideIcons.barChart3;
    }
    if (lower.contains('assessment') || lower.contains('exam')) {
      return LucideIcons.graduationCap;
    }
    if (lower.contains('assignment')) return LucideIcons.fileSpreadsheet;
    if (lower.contains('practical') || lower.contains('lab')) {
      return LucideIcons.flaskConical;
    }
    if (lower.contains('library')) return LucideIcons.bookMarked;
    if (lower.contains('fee') || lower.contains('payment')) {
      return LucideIcons.creditCard;
    }
    if (lower.contains('hostel') || lower.contains('transport')) {
      return LucideIcons.bus;
    }
    return LucideIcons.sparkles;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final secondaryTextColor = isDark
        ? AcadexColors.darkInkMuted
        : AcadexColors.inkMuted;

    final effectiveMessage =
        description ??
        "We're working on this module. It will be available in a future update.";
    final effectiveIcon = icon ?? iconForModule(moduleName);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AcadexBackButton(fallbackRoute: fallbackRoute ?? '/dashboard'),
        title: Text(
          moduleName,
          style: AcadexTypography.title(color: primaryTextColor),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Module Icon Container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AcadexColors.primary.withValues(alpha: 0.15)
                        : AcadexColors.primaryLight,
                    borderRadius: AcadexRadius.borderRadiusXl,
                    border: Border.all(
                      color: isDark
                          ? AcadexColors.primary.withValues(alpha: 0.3)
                          : AcadexColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    effectiveIcon,
                    color: isDark
                        ? AcadexColors.primaryMuted
                        : AcadexColors.primary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),

                // Coming Soon Status Badge
                const AcadexBadge(
                  label: 'COMING SOON',
                  variant: AcadexBadgeVariant.warning,
                  icon: LucideIcons.clock,
                ),
                const SizedBox(height: 16),

                // Heading: Coming Soon
                Text(
                  'Coming Soon',
                  textAlign: TextAlign.center,
                  style: AcadexTypography.heading1(color: primaryTextColor),
                ),
                const SizedBox(height: 6),

                // Selected Module Name
                Text(
                  moduleName,
                  textAlign: TextAlign.center,
                  style: AcadexTypography.heading2(
                    color: AcadexColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
                ),
                const SizedBox(height: 14),

                // Short Informational Message
                Text(
                  effectiveMessage,
                  textAlign: TextAlign.center,
                  style: AcadexTypography.body(color: secondaryTextColor),
                ),
                const SizedBox(height: 32),

                // Return / Go Back Button
                AcadexButton(
                  label: 'Go Back',
                  icon: LucideIcons.arrowLeft,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => context.safePop(
                    fallbackRoute: fallbackRoute ?? '/dashboard',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
