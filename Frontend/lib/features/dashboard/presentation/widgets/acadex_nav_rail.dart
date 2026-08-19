import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AcadexNavRail extends ConsumerWidget {
  final String activeRoute;
  final ValueChanged<String> onDestinationSelected;

  const AcadexNavRail({
    super.key,
    required this.activeRoute,
    required this.onDestinationSelected,
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

    int selectedIndex = 0;
    if (activeRoute.startsWith('/attendance')) {
      selectedIndex = 1;
    } else if (activeRoute.startsWith('/ai-assistant')) {
      selectedIndex = 2;
    } else if (activeRoute.startsWith('/users') && (role == AppRole.superAdmin || role == AppRole.collegeAdmin)) {
      selectedIndex = 3;
    } else if (activeRoute.startsWith('/profile')) {
      selectedIndex = (role == AppRole.superAdmin || role == AppRole.collegeAdmin) ? 4 : 3;
    } else if (activeRoute.startsWith('/settings')) {
      selectedIndex = (role == AppRole.superAdmin || role == AppRole.collegeAdmin) ? 5 : 4;
    }

    final hasUsersTab = role == AppRole.superAdmin || role == AppRole.collegeAdmin;

    final destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: Icon(LucideIcons.layoutDashboard),
        selectedIcon: Icon(LucideIcons.layoutDashboard, color: Theme.of(context).primaryColor),
        label: const Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: const Icon(LucideIcons.calendarCheck),
        selectedIcon: Icon(LucideIcons.calendarCheck, color: Theme.of(context).primaryColor),
        label: const Text('Attendance'),
      ),
      NavigationRailDestination(
        icon: const Icon(LucideIcons.bot),
        selectedIcon: Icon(LucideIcons.bot, color: Theme.of(context).primaryColor),
        label: const Text('AI'),
      ),
      if (hasUsersTab)
        NavigationRailDestination(
          icon: const Icon(LucideIcons.users),
          selectedIcon: Icon(LucideIcons.users, color: Theme.of(context).primaryColor),
          label: const Text('Users'),
        ),
      NavigationRailDestination(
        icon: const Icon(LucideIcons.user),
        selectedIcon: Icon(LucideIcons.user, color: Theme.of(context).primaryColor),
        label: const Text('Profile'),
      ),
      NavigationRailDestination(
        icon: const Icon(LucideIcons.settings),
        selectedIcon: Icon(LucideIcons.settings, color: Theme.of(context).primaryColor),
        label: const Text('Settings'),
      ),
    ];

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == 0) {
          onDestinationSelected(dashboardRoute);
        } else if (index == 1) {
          onDestinationSelected('/attendance');
        } else if (index == 2) {
          onDestinationSelected('/ai-assistant');
        } else if (index == 3 && hasUsersTab) {
          onDestinationSelected('/users');
        } else if ((index == 3 && !hasUsersTab) || (index == 4 && hasUsersTab)) {
          onDestinationSelected('/profile');
        } else if ((index == 4 && !hasUsersTab) || (index == 5 && hasUsersTab)) {
          onDestinationSelected('/settings');
        }
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedIconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      unselectedIconTheme: IconThemeData(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
      selectedLabelTextStyle: AcadexTypography.eyebrow(color: Theme.of(context).primaryColor),
      unselectedLabelTextStyle: AcadexTypography.eyebrow(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).copyWith(fontWeight: FontWeight.w500),
      leading: Column(
        children: [
          SizedBox(height: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: AcadexRadius.borderRadiusSm,
            ),
            child: Icon(LucideIcons.graduationCap, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(height: 24),
        ],
      ),
      destinations: destinations,
    );
  }
}
