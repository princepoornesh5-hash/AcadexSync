import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/navigation/acadex_nav_item.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Compact, role-aware mobile bottom navigation bar conforming to Prompt 11
/// Features 4 primary destinations + 1 'More' entry point with zero horizontal overflow at 360px.
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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AcadexColors.hairline,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A07111F),
            blurRadius: 8,
            offset: Offset(0, -2),
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

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AcadexColors.primary;
    const inactiveColor = AcadexColors.inkMuted;
    final textScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AcadexColors.primaryLight.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AcadexTypography.eyebrow(
                        color: isActive ? activeColor : inactiveColor,
                      ).copyWith(
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 10,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Active indicator bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isActive ? 16 : 0,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
