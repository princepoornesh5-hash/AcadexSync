import 'package:flutter/material.dart';
import '../design_system/acadex_breakpoints.dart';
import '../design_system/acadex_colors.dart';
import 'app_top_bar.dart';

class AppNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class AppScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? topBarActions;
  final List<AppNavDestination>? navDestinations;
  final int selectedNavIndex;
  final ValueChanged<int>? onNavDestinationSelected;
  final Widget? floatingActionButton;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.topBarActions,
    this.navDestinations,
    this.selectedNavIndex = 0,
    this.onNavDestinationSelected,
    this.floatingActionButton,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AcadexBreakpoints.isMobile(context);
    final hasNavigation = navDestinations != null && navDestinations!.isNotEmpty;
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    if (hasEnclosingScaffold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topBarActions != null && topBarActions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: topBarActions!,
              ),
            ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppTopBar(
        title: title,
        subtitle: subtitle,
        actions: topBarActions,
        onNotificationTap: onNotificationTap,
        onProfileTap: onProfileTap,
      ),
      body: Row(
        children: [
          // Desktop / Tablet Navigation Rail
          if (hasNavigation && !isMobile) ...[
            NavigationRail(
              selectedIndex: selectedNavIndex,
              onDestinationSelected: onNavDestinationSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: AcadexColors.surfaceLight,
              indicatorColor: AcadexColors.primary,
              selectedIconTheme: const IconThemeData(color: Colors.white),
              selectedLabelTextStyle: const TextStyle(
                color: AcadexColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AcadexColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              destinations: navDestinations!.map((dest) {
                return NavigationRailDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.selectedIcon),
                  label: Text(dest.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1, color: AcadexColors.borderLight),
          ],
          // Main Body
          Expanded(child: body),
        ],
      ),
      // Mobile Bottom Navigation Bar
      bottomNavigationBar: (hasNavigation && isMobile)
          ? NavigationBar(
              selectedIndex: selectedNavIndex,
              onDestinationSelected: onNavDestinationSelected,
              backgroundColor: AcadexColors.surfaceLight,
              indicatorColor: AcadexColors.primaryLight,
              destinations: navDestinations!.map((dest) {
                return NavigationDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.selectedIcon, color: AcadexColors.primary),
                  label: dest.label,
                );
              }).toList(),
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
