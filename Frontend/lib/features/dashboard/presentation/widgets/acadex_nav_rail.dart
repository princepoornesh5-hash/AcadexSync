import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';

class AcadexNavRail extends StatelessWidget {
  final String activeRoute;
  final ValueChanged<String> onDestinationSelected;

  const AcadexNavRail({
    super.key,
    required this.activeRoute,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0;
    if (activeRoute.startsWith('/attendance')) {
      selectedIndex = 1;
    } else if (activeRoute.startsWith('/profile')) {
      selectedIndex = 2;
    } else if (activeRoute.startsWith('/settings')) {
      selectedIndex = 3;
    }

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onDestinationSelected('/dashboard');
            break;
          case 1:
            onDestinationSelected('/attendance');
            break;
          case 2:
            onDestinationSelected('/profile');
            break;
          case 3:
            onDestinationSelected('/settings');
            break;
        }
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: DashboardColors.surface,
      selectedIconTheme: const IconThemeData(color: DashboardColors.primary),
      unselectedIconTheme: const IconThemeData(color: DashboardColors.textMuted),
      selectedLabelTextStyle: GoogleFonts.inter(
        color: DashboardColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: DashboardColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      leading: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 20,
            backgroundColor: DashboardColors.primaryLight,
            child: const Icon(LucideIcons.graduationCap, color: DashboardColors.primary, size: 20),
          ),
          const SizedBox(height: 24),
        ],
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(LucideIcons.layoutDashboard),
          selectedIcon: Icon(LucideIcons.layoutDashboard, color: DashboardColors.primary),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.calendarCheck),
          selectedIcon: Icon(LucideIcons.calendarCheck, color: DashboardColors.primary),
          label: Text('Attendance'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.user),
          selectedIcon: Icon(LucideIcons.user, color: DashboardColors.primary),
          label: Text('Profile'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.settings),
          selectedIcon: Icon(LucideIcons.settings, color: DashboardColors.primary),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
