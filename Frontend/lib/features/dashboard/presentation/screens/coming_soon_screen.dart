import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';

class ComingSoonScreen extends StatelessWidget {
  final String moduleName;

  const ComingSoonScreen({super.key, required this.moduleName});

  IconData _iconForModule(String name) {
    switch (name.toLowerCase()) {
      case 'attendance':
        return LucideIcons.clipboardCheck;
      case 'timetable':
        return LucideIcons.calendarDays;
      case 'notes':
        return LucideIcons.fileText;
      case 'profile':
        return LucideIcons.userCircle;
      case 'settings':
        return LucideIcons.settings;
      case 'notifications':
        return LucideIcons.bell;
      default:
        return LucideIcons.layoutDashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
        ),
        title: Text(
          moduleName,
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.25) : AcadexColors.primaryLight,
                    borderRadius: AcadexRadius.borderRadiusXl,
                  ),
                  child: Icon(
                    _iconForModule(moduleName),
                    color: isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  moduleName,
                  style: AcadexTypography.heading1(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const AcadexBadge(
                  label: 'COMING SOON',
                  variant: AcadexBadgeVariant.warning,
                  icon: LucideIcons.clock,
                ),
                const SizedBox(height: 16),
                Text(
                  'This module is currently being finalized for the upcoming Acadex semester release.',
                  textAlign: TextAlign.center,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 32),
                AcadexButton(
                  label: 'Return to Dashboard',
                  icon: LucideIcons.arrowLeft,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => context.go('/dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
