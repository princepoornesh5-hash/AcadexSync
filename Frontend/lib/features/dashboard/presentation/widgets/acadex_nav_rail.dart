import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/navigation/acadex_nav_item.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Role-aware tablet NavigationRail using centralized AcadexNavigationService (Prompt 11)
class AcadexNavRail extends ConsumerWidget {
  final String activeRoute;
  final ValueChanged<String> onDestinationSelected;

  const AcadexNavRail({
    super.key,
    required this.activeRoute,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    AppRole role = AppRole.student;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final navItems = AcadexNavigationService.getPrimaryNavItems(role);

    int selectedIndex = 0;
    for (int i = 0; i < navItems.length; i++) {
      if (navItems[i].matchesRoute(activeRoute)) {
        selectedIndex = i;
        break;
      }
    }

    final selectedColor = AcadexColors.primary;
    final unselectedColor = AcadexColors.inkMuted;
    const logoBg = AcadexColors.primary;
    const logoColor = Colors.white;

    final destinations = navItems.map((item) {
      return NavigationRailDestination(
        icon: Icon(item.icon, size: 20),
        selectedIcon: Icon(item.icon, color: selectedColor, size: 20),
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
      backgroundColor: Colors.white,
      indicatorColor: AcadexColors.primaryLight,
      selectedIconTheme: IconThemeData(color: selectedColor),
      unselectedIconTheme: IconThemeData(color: unselectedColor),
      selectedLabelTextStyle: AcadexTypography.eyebrow(
        color: selectedColor,
      ).copyWith(fontWeight: FontWeight.w700, fontSize: 10),
      unselectedLabelTextStyle: AcadexTypography.eyebrow(
        color: unselectedColor,
      ).copyWith(fontWeight: FontWeight.w500, fontSize: 10),
      leading: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: logoBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(LucideIcons.graduationCap, color: logoColor, size: 22),
          ),
        ),
      ),
      destinations: destinations,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: AcadexColors.hairline,
            width: 1.0,
          ),
        ),
      ),
      child: rail,
    );
  }
}
