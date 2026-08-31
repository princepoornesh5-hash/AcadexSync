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
    AppRole role = AppRole.student;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final dashboardRoute = _dashboardRouteForRole(role);

    List<({IconData icon, String label, String route})> navItems;
    switch (role) {
      case AppRole.superAdmin:
        navItems = [
          (icon: LucideIcons.layoutDashboard, label: 'Dashboard', route: dashboardRoute),
          (icon: LucideIcons.building, label: 'Colleges', route: '/academics/colleges'),
          (icon: LucideIcons.users, label: 'Users', route: '/users'),
          (icon: LucideIcons.barChart3, label: 'Analytics', route: '/analytics'),
          (icon: LucideIcons.bell, label: 'Notifications', route: '/notifications'),
          (icon: LucideIcons.bot, label: 'AI Assistant', route: '/ai-assistant'),
          (icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
          (icon: LucideIcons.user, label: 'Profile', route: '/profile'),
        ];
        break;
      case AppRole.collegeAdmin:
        navItems = [
          (icon: LucideIcons.layoutDashboard, label: 'Dashboard', route: dashboardRoute),
          (icon: LucideIcons.layers, label: 'Academics', route: '/academics'),
          (icon: LucideIcons.userCheck, label: 'Faculty', route: '/academics/faculty'),
          (icon: LucideIcons.graduationCap, label: 'Students', route: '/academics/students'),
          (icon: LucideIcons.calendarDays, label: 'Timetable', route: '/timetable/manage'),
          (icon: LucideIcons.clipboardCheck, label: 'Attendance', route: '/attendance'),
          (icon: LucideIcons.fileText, label: 'Notes', route: '/notes'),
          (icon: LucideIcons.barChart3, label: 'Analytics', route: '/analytics'),
          (icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
        ];
        break;
      case AppRole.hod:
        navItems = [
          (icon: LucideIcons.layoutDashboard, label: 'Dashboard', route: dashboardRoute),
          (icon: LucideIcons.building2, label: 'Department', route: '/academics/departments'),
          (icon: LucideIcons.userCheck, label: 'Faculty', route: '/academics/faculty'),
          (icon: LucideIcons.graduationCap, label: 'Students', route: '/academics/students'),
          (icon: LucideIcons.calendarDays, label: 'Timetable', route: '/timetable/manage'),
          (icon: LucideIcons.clipboardCheck, label: 'Attendance', route: '/attendance'),
          (icon: LucideIcons.fileText, label: 'Notes', route: '/notes'),
          (icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
        ];
        break;
      case AppRole.faculty:
        navItems = [
          (icon: LucideIcons.layoutDashboard, label: 'Dashboard', route: dashboardRoute),
          (icon: LucideIcons.bookOpen, label: 'Classes', route: '/my-assignments'),
          (icon: LucideIcons.clipboardCheck, label: 'Attendance', route: '/attendance'),
          (icon: LucideIcons.calendarDays, label: 'Timetable', route: '/timetable'),
          (icon: LucideIcons.fileText, label: 'Notes', route: '/notes'),
          (icon: LucideIcons.user, label: 'Profile', route: '/profile'),
          (icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
        ];
        break;
      case AppRole.student:
        navItems = [
          (icon: LucideIcons.layoutDashboard, label: 'Dashboard', route: dashboardRoute),
          (icon: LucideIcons.calendarDays, label: 'Timetable', route: '/timetable'),
          (icon: LucideIcons.clipboardCheck, label: 'Attendance', route: '/attendance'),
          (icon: LucideIcons.bookOpen, label: 'Subjects', route: '/academics/subjects'),
          (icon: LucideIcons.fileText, label: 'Notes', route: '/notes'),
          (icon: LucideIcons.user, label: 'Profile', route: '/profile'),
          (icon: LucideIcons.settings, label: 'Settings', route: '/settings'),
        ];
        break;
    }

    int selectedIndex = 0;
    for (int i = 0; i < navItems.length; i++) {
      if (activeRoute == navItems[i].route ||
          (navItems[i].route != dashboardRoute && activeRoute.startsWith(navItems[i].route))) {
        selectedIndex = i;
        break;
      }
    }

    final isGradientRole = role == AppRole.superAdmin ||
        role == AppRole.collegeAdmin ||
        role == AppRole.hod ||
        role == AppRole.faculty ||
        role == AppRole.student;
    final selectedColor = isGradientRole ? const Color(0xFF003366) : Theme.of(context).primaryColor;
    final unselectedColor = isGradientRole ? const Color(0xFF07111F) : (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted);
    final logoBg = isGradientRole ? const Color(0xFF003366) : Theme.of(context).primaryColor.withValues(alpha: 0.1);
    final logoColor = isGradientRole ? Colors.white : Theme.of(context).primaryColor;

    final destinations = navItems.map((item) {
      return NavigationRailDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.icon, color: selectedColor),
        label: Text(item.label),
      );
    }).toList();

    final rail = NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index >= 0 && index < navItems.length) {
          onDestinationSelected(navItems[index].route);
        }
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.transparent,
      indicatorColor: isGradientRole ? Colors.transparent : null,
      selectedIconTheme: IconThemeData(color: selectedColor),
      unselectedIconTheme: IconThemeData(color: unselectedColor),
      selectedLabelTextStyle: AcadexTypography.eyebrow(
        color: selectedColor,
      ).copyWith(fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: AcadexTypography.eyebrow(
        color: unselectedColor,
      ).copyWith(fontWeight: FontWeight.w500),
      leading: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: logoBg,
              borderRadius: AcadexRadius.borderRadiusSm,
            ),
            child: Icon(LucideIcons.graduationCap, color: logoColor, size: 24),
          ),
          const SizedBox(height: 24),
        ],
      ),
      destinations: destinations,
    );

    final scrollableRail = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: rail),
          ),
        );
      },
    );

    if (isGradientRole) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xC7FFFFFF), // Subtle translucent white contrast overlay
          border: Border(
            right: BorderSide(
              color: Color(0x14000000), // rgba(0,0,0,0.08)
              width: 1,
            ),
          ),
        ),
        child: scrollableRail,
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: scrollableRail,
    );
  }
}
