import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/navigation/acadex_nav_item.dart';
import '../../../../core/presentation/widgets/acadex_motion.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

/// Compact, role-aware mobile bottom navigation bar conforming to Prompt 1 & Prompt 2.
/// Features 4 primary destinations + 1 'More' entry point with zero horizontal overflow at 360px.
/// Uses refined Android Material 3 pill active states, AcadexPressable micro-interactions,
/// and the unified ACADEX Blue semantic palette.
class AcadexBottomNav extends ConsumerWidget {
  final String activeRoute;
  final ValueChanged<String> onTabSelected;

  const AcadexBottomNav({
    super.key,
    required this.activeRoute,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    AppRole role = AppRole.student;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final primaryItems = AcadexNavigationService.getPrimaryNavItems(role);

    // Check if any primary item is active
    bool isAnyPrimaryActive = false;
    for (final item in primaryItems) {
      if (item.matchesRoute(activeRoute)) {
        isAnyPrimaryActive = true;
        break;
      }
    }
    final isMoreActive = !isAnyPrimaryActive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x0807111F),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              ...primaryItems.map((item) {
                final isActive = item.matchesRoute(activeRoute);
                return _NavTab(
                  icon: item.icon,
                  label: item.label,
                  isActive: isActive,
                  onTap: () => onTabSelected(item.route),
                );
              }),
              _NavTab(
                icon: LucideIcons.ellipsis,
                label: 'More',
                isActive: isMoreActive,
                badgeCount: unreadNotifs,
                onTap: () {
                  final scaffoldState = Scaffold.maybeOf(context);
                  if (scaffoldState != null && scaffoldState.hasDrawer) {
                    scaffoldState.openDrawer();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFF60A5FA) : AcadexColors.primary;
    final inactiveColor = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
    final activePillColor = isDark
        ? AcadexColors.primary.withValues(alpha: 0.22)
        : AcadexColors.primaryLight;
    final textScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);

    return Expanded(
      child: AcadexPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          color: Colors.transparent,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active pill with icon and badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isActive ? activePillColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: isActive ? activeColor : inactiveColor,
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -2,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AcadexColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AcadexTypography.caption(
                    color: isActive ? activeColor : inactiveColor,
                  ).copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10.5,
                    letterSpacing: 0.1,
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
