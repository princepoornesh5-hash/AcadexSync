import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AcadexBottomNav extends ConsumerWidget {
  final String activeRoute;
  final ValueChanged<String> onTabSelected;

  const AcadexBottomNav({
    super.key,
    required this.activeRoute,
    required this.onTabSelected,
  });

  String _dashboardRouteForRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin: return '/dashboard/super_admin';
      case AppRole.collegeAdmin: return '/dashboard/college_admin';
      case AppRole.hod: return '/dashboard/hod';
      case AppRole.faculty: return '/dashboard/faculty';
      case AppRole.student: return '/dashboard/student';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    AppRole? role;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }
    
    final dashboardRoute = role != null ? _dashboardRouteForRole(role) : '/login';

    int currentIndex = 0;
    if (activeRoute.startsWith('/attendance')) {
      currentIndex = 1;
    } else if (activeRoute.startsWith('/ai-assistant')) {
      currentIndex = 2;
    } else if (activeRoute.startsWith('/profile')) {
      currentIndex = 3;
    } else if (activeRoute.startsWith('/settings')) {
      currentIndex = 4;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavTab(
              icon: LucideIcons.layoutDashboard,
              label: 'Home',
              isActive: currentIndex == 0,
              onTap: () => onTabSelected(dashboardRoute),
            ),
            _NavTab(
              icon: LucideIcons.calendarCheck,
              label: 'Attendance',
              isActive: currentIndex == 1,
              onTap: () => onTabSelected('/attendance'),
            ),
            _NavTab(
              icon: LucideIcons.bot,
              label: 'AI',
              isActive: currentIndex == 2,
              onTap: () => onTabSelected('/ai-assistant'),
            ),
            _NavTab(
              icon: LucideIcons.userCircle,
              label: 'Profile',
              isActive: currentIndex == 3,
              onTap: () => onTabSelected('/profile'),
            ),
            _NavTab(
              icon: LucideIcons.settings,
              label: 'Settings',
              isActive: currentIndex == 4,
              onTap: () => onTabSelected('/settings'),
            ),
          ],
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
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AcadexTypography.eyebrow(color: isActive ? activeColor : inactiveColor).copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
