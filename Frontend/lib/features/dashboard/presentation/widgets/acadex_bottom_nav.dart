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
      case AppRole.superAdmin:
        return '/dashboard/super_admin';
      case AppRole.collegeAdmin:
        return '/dashboard/college_admin';
      case AppRole.hod:
        return '/dashboard/hod';
      case AppRole.faculty:
        return '/dashboard/faculty';
      case AppRole.student:
        return '/dashboard/student';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    AppRole role = AppRole.student;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final dashboardRoute = _dashboardRouteForRole(role);

    List<_NavDestination> destinations;
    switch (role) {
      case AppRole.superAdmin:
        destinations = [
          _NavDestination(icon: LucideIcons.layoutDashboard, label: 'Home', route: dashboardRoute),
          _NavDestination(icon: LucideIcons.building, label: 'Colleges', route: '/academics/colleges'),
          _NavDestination(icon: LucideIcons.users, label: 'Users', route: '/users'),
          _NavDestination(icon: LucideIcons.barChart3, label: 'Analytics', route: '/analytics'),
          _NavDestination(icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
        ];
        break;
      case AppRole.collegeAdmin:
        destinations = [
          _NavDestination(icon: LucideIcons.layoutDashboard, label: 'Home', route: dashboardRoute),
          _NavDestination(icon: LucideIcons.layers, label: 'Academics', route: '/academics'),
          _NavDestination(icon: LucideIcons.userCheck, label: 'Faculty', route: '/academics/faculty'),
          _NavDestination(icon: LucideIcons.clipboardCheck, label: 'Attendance', route: '/attendance'),
          _NavDestination(icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
        ];
        break;
      case AppRole.hod:
        destinations = [
          _NavDestination(icon: LucideIcons.layoutDashboard, label: 'Home', route: dashboardRoute),
          _NavDestination(icon: LucideIcons.users, label: 'Faculty', route: '/academics/faculty'),
          _NavDestination(icon: LucideIcons.clipboardCheck, label: 'Attendance', route: '/attendance'),
          _NavDestination(icon: LucideIcons.calendarDays, label: 'Timetable', route: '/timetable/manage'),
          _NavDestination(icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
        ];
        break;
      case AppRole.faculty:
        destinations = [
          _NavDestination(icon: LucideIcons.layoutDashboard, label: 'Home', route: dashboardRoute),
          _NavDestination(icon: LucideIcons.bookOpen, label: 'Classes', route: '/my-assignments'),
          _NavDestination(icon: LucideIcons.clipboardCheck, label: 'Attendance', route: '/attendance'),
          _NavDestination(icon: LucideIcons.calendarDays, label: 'Timetable', route: '/timetable'),
          _NavDestination(icon: LucideIcons.fileText, label: 'Notes', route: '/notes'),
        ];
        break;
      case AppRole.student:
        destinations = [
          _NavDestination(icon: LucideIcons.layoutDashboard, label: 'Home', route: dashboardRoute),
          _NavDestination(icon: LucideIcons.calendarDays, label: 'Timetable', route: '/timetable'),
          _NavDestination(icon: LucideIcons.clipboardCheck, label: 'Attendance', route: '/attendance'),
          _NavDestination(icon: LucideIcons.fileText, label: 'Notes', route: '/notes'),
          _NavDestination(icon: LucideIcons.user, label: 'Profile', route: '/profile'),
        ];
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AcadexColors.surface,
        border: Border(
          top: BorderSide(
            color: AcadexColors.hairline,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: destinations.map((dest) {
              final isActive = activeRoute == dest.route ||
                  (dest.route != dashboardRoute && activeRoute.startsWith(dest.route));
              return _NavTab(
                icon: dest.icon,
                label: dest.label,
                isActive: isActive,
                onTap: () => onTabSelected(dest.route),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  final String route;

  const _NavDestination({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _NavTab extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isGradientRole = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.superAdmin ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.faculty ||
            authState.user.role == AppRole.student);

    final activeColor = isGradientRole ? AcadexColors.superAdminDeepAction : AcadexColors.primary;
    final inactiveColor = isGradientRole ? AcadexColors.inkSecondary : AcadexColors.inkMuted;
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
