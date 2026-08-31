import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_dialogs.dart';
import '../../../../core/presentation/widgets/super_admin_gradient_background.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

List<_NavItem> _getNavItemsForRole(AppRole role, String dashboardRoute) {
  switch (role) {
    case AppRole.superAdmin:
      return [
        _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: dashboardRoute),
        const _NavItem(label: 'Colleges', icon: LucideIcons.building, route: '/academics/colleges'),
        const _NavItem(label: 'Platform Users', icon: LucideIcons.users, route: '/users'),
        const _NavItem(label: 'Global Analytics', icon: LucideIcons.barChart3, route: '/analytics'),
        const _NavItem(label: 'Notifications', icon: LucideIcons.bell, route: '/notifications'),
        const _NavItem(label: 'AI Assistant', icon: LucideIcons.bot, route: '/ai-assistant'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, route: '/settings'),
        const _NavItem(label: 'Profile', icon: LucideIcons.user, route: '/profile'),
      ];

    case AppRole.collegeAdmin:
      return [
        _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: dashboardRoute),
        const _NavItem(label: 'Academic Structure', icon: LucideIcons.layers, route: '/academics'),
        const _NavItem(label: 'Faculty & HODs', icon: LucideIcons.userCheck, route: '/academics/faculty'),
        const _NavItem(label: 'Students', icon: LucideIcons.graduationCap, route: '/academics/students'),
        const _NavItem(label: 'Timetable', icon: LucideIcons.calendarDays, route: '/timetable/manage'),
        const _NavItem(label: 'Attendance', icon: LucideIcons.clipboardCheck, route: '/attendance'),
        const _NavItem(label: 'Lesson Notes', icon: LucideIcons.fileText, route: '/notes'),
        const _NavItem(label: 'College Analytics', icon: LucideIcons.barChart3, route: '/analytics'),
        const _NavItem(label: 'Notifications', icon: LucideIcons.bell, route: '/notifications'),
        const _NavItem(label: 'AI Assistant', icon: LucideIcons.bot, route: '/ai-assistant'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, route: '/settings'),
        const _NavItem(label: 'Profile', icon: LucideIcons.user, route: '/profile'),
      ];

    case AppRole.hod:
      return [
        _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: dashboardRoute),
        const _NavItem(label: 'Academic Structure', icon: LucideIcons.layers, route: '/academics'),
        const _NavItem(label: 'Department Faculty', icon: LucideIcons.userCheck, route: '/academics/faculty'),
        const _NavItem(label: 'Faculty Assignments', icon: LucideIcons.briefcase, route: '/faculty-assignments'),
        const _NavItem(label: 'Department Students', icon: LucideIcons.graduationCap, route: '/academics/students'),
        const _NavItem(label: 'Timetable', icon: LucideIcons.calendarDays, route: '/timetable/manage'),
        const _NavItem(label: 'Department Attendance', icon: LucideIcons.clipboardCheck, route: '/attendance'),
        const _NavItem(label: 'Lesson Notes', icon: LucideIcons.fileText, route: '/notes'),
        const _NavItem(label: 'Department Analytics', icon: LucideIcons.barChart3, route: '/analytics'),
        const _NavItem(label: 'Notifications', icon: LucideIcons.bell, route: '/notifications'),
        const _NavItem(label: 'AI Assistant', icon: LucideIcons.bot, route: '/ai-assistant'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, route: '/settings'),
        const _NavItem(label: 'Profile', icon: LucideIcons.user, route: '/profile'),
      ];

    case AppRole.faculty:
      return [
        _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: dashboardRoute),
        const _NavItem(label: 'My Assignments', icon: LucideIcons.bookOpen, route: '/my-assignments'),
        const _NavItem(label: 'Mark Attendance', icon: LucideIcons.clipboardCheck, route: '/attendance'),
        const _NavItem(label: 'My Timetable', icon: LucideIcons.calendarDays, route: '/timetable'),
        const _NavItem(label: 'Teaching Notes', icon: LucideIcons.fileText, route: '/notes'),
        const _NavItem(label: 'Notifications', icon: LucideIcons.bell, route: '/notifications'),
        const _NavItem(label: 'AI Assistant', icon: LucideIcons.bot, route: '/ai-assistant'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, route: '/settings'),
        const _NavItem(label: 'Profile', icon: LucideIcons.user, route: '/profile'),
      ];

    case AppRole.student:
      return [
        _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: dashboardRoute),
        const _NavItem(label: 'My Timetable', icon: LucideIcons.calendarDays, route: '/timetable'),
        const _NavItem(label: 'My Attendance', icon: LucideIcons.clipboardCheck, route: '/attendance'),
        const _NavItem(label: 'Study Notes', icon: LucideIcons.fileText, route: '/notes'),
        const _NavItem(label: 'Notifications', icon: LucideIcons.bell, route: '/notifications'),
        const _NavItem(label: 'AI Assistant', icon: LucideIcons.bot, route: '/ai-assistant'),
        const _NavItem(label: 'Settings', icon: LucideIcons.settings, route: '/settings'),
        const _NavItem(label: 'Profile', icon: LucideIcons.user, route: '/profile'),
      ];
  }
}

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

class AcadexDrawer extends ConsumerWidget {
  final String activeRoute;
  final bool isModal;

  const AcadexDrawer({
    super.key,
    required this.activeRoute,
    this.isModal = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    final role = user?.role ?? AppRole.student;
    final isGradientRole = role == AppRole.superAdmin ||
        role == AppRole.collegeAdmin ||
        role == AppRole.hod ||
        role == AppRole.faculty ||
        role == AppRole.student;
    final dashboardRoute = user != null ? _dashboardRouteForRole(role) : '/login';

    final filteredItems = _getNavItemsForRole(role, dashboardRoute);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = isModal ? math.min(290.0, screenWidth * 0.82) : 260.0;

    return Drawer(
      backgroundColor: isGradientRole ? Colors.transparent : AcadexColors.surface,
      elevation: isModal ? 16 : 0,
      width: drawerWidth.clamp(260.0, 300.0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          color: isGradientRole
              ? (isModal ? null : const Color(0xC7FFFFFF)) // Subtle translucent contrast overlay (78% white)
              : AcadexColors.surface,
          gradient: (isGradientRole && isModal) ? AcadexSuperAdminGradient.gradient : null,
          border: isModal
              ? null
              : Border(
                  right: BorderSide(
                    color: isGradientRole
                        ? const Color(0x14000000) // rgba(0,0,0,0.08)
                        : AcadexColors.hairline,
                    width: 1,
                  ),
                ),
        ),
        child: Container(
          // For modal drawer on mobile, apply the translucent white contrast layer over the gradient
          color: (isGradientRole && isModal) ? const Color(0xC7FFFFFF) : null,
          child: SafeArea(
            child: Column(
              children: [
                // Top Brand Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isGradientRole
                              ? const Color(0xFF003366)
                              : AcadexColors.primary,
                          borderRadius: AcadexRadius.borderRadiusMd,
                        ),
                        child: const Icon(
                          LucideIcons.graduationCap,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acadex',
                            style: AcadexTypography.heading3(
                              color: isGradientRole
                                  ? const Color(0xFF07111F)
                                  : AcadexColors.ink,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            'Campus Platform',
                            style: AcadexTypography.caption(
                              color: isGradientRole
                                  ? const Color(0xFF475569)
                                  : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // User Identity Area (Flat subtle surface)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isGradientRole
                          ? const Color(0x0A07111F) // Flat subtle translucent surface
                          : AcadexColors.canvasSoft,
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(
                        color: isGradientRole
                            ? const Color(0x14000000)
                            : AcadexColors.hairline,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        AcadexAvatar(
                          name: user?.name ?? 'User',
                          size: 34,
                          isOnline: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Guest User',
                                style: AcadexTypography.bodySmall(
                                  color: isGradientRole
                                      ? const Color(0xFF07111F)
                                      : AcadexColors.ink,
                                ).copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              AcadexBadge(
                                label: role.displayName,
                                variant: AcadexBadgeVariant.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isGradientRole
                      ? const Color(0x14000000) // rgba(0,0,0,0.08)
                      : AcadexColors.hairline,
                ),
                const SizedBox(height: 8),

                // Primary Navigation Items List (Floating Typography Style)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isDashboardItem = item.label == 'Dashboard';
                      final isActive = isDashboardItem
                          ? (activeRoute.startsWith('/dashboard') || activeRoute == '/')
                          : activeRoute.startsWith(item.route);

                      return _DrawerTile(
                        label: item.label,
                        icon: item.icon,
                        isActive: isActive,
                        onTap: () {
                          if (isModal && Scaffold.of(context).isDrawerOpen) {
                            Navigator.of(context).pop();
                          }
                          context.go(item.route);
                        },
                      );
                    },
                  ),
                ),

                Divider(
                  height: 1,
                  color: isGradientRole
                      ? const Color(0x14000000)
                      : AcadexColors.hairline,
                ),
                const SizedBox(height: 8),

                // Bottom Utility Section: Logout (Clean footer)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      if (!isGradientRole) ...[
                        _DrawerTile(
                          label: 'Profile',
                          icon: LucideIcons.user,
                          isActive: activeRoute.startsWith('/profile'),
                          onTap: () {
                            if (isModal && Scaffold.of(context).isDrawerOpen) {
                              Navigator.of(context).pop();
                            }
                            context.go('/profile');
                          },
                        ),
                        _DrawerTile(
                          label: 'Settings',
                          icon: LucideIcons.settings,
                          isActive: activeRoute.startsWith('/settings'),
                          onTap: () {
                            if (isModal && Scaffold.of(context).isDrawerOpen) {
                              Navigator.of(context).pop();
                            }
                            context.go('/settings');
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
                      _DrawerTile(
                        label: 'Logout',
                        icon: LucideIcons.logOut,
                        isActive: false,
                        iconColor: const Color(0xFFDC2626),
                        textColor: const Color(0xFFDC2626),
                        onTap: () async {
                          if (isModal && Scaffold.of(context).isDrawerOpen) {
                            Navigator.of(context).pop();
                          }
                          final confirmed = await AcadexConfirmationDialog.show(
                            context: context,
                            title: 'Logout',
                            message: 'Are you sure you want to sign out of Acadex?',
                            confirmLabel: 'Sign Out',
                            isDestructive: true,
                          );
                          if (confirmed == true && context.mounted) {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends ConsumerWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.iconColor,
    this.textColor,
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

    final isLogout = iconColor == const Color(0xFFDC2626) || iconColor == AcadexColors.error;

    // Active state
    final activeBg = isGradientRole
        ? Colors.transparent // NO filled box, NO pill, clean floating typography
        : AcadexColors.primaryLight;
    final activeBorder = isGradientRole
        ? null // NO filled box border
        : AcadexColors.primary.withValues(alpha: 0.3);

    final activeIconColor = isGradientRole
        ? const Color(0xFF003366) // Deep Action Blue
        : AcadexColors.primary;
    final activeTextColor = isGradientRole
        ? const Color(0xFF003366)
        : AcadexColors.primary;

    // Inactive state
    final inactiveIconColor = isLogout
        ? const Color(0xFFDC2626)
        : (iconColor ?? (isGradientRole ? const Color(0xFF07111F) : AcadexColors.inkMuted));

    final inactiveTextColor = isLogout
        ? const Color(0xFFDC2626)
        : (textColor ?? (isGradientRole ? const Color(0xFF07111F) : AcadexColors.inkSecondary));

    final hoverColor = isGradientRole
        ? const Color(0x1F07111F) // rgba(255,255,255,0.12) equivalent on light overlay
        : AcadexColors.surfaceHover;
    final splashColor = isGradientRole
        ? const Color(0x2E07111F) // rgba(255,255,255,0.18)
        : AcadexColors.primaryLight.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      constraints: const BoxConstraints(minHeight: 46.0),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: isActive && activeBorder != null ? Border.all(color: activeBorder, width: 1.2) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          hoverColor: hoverColor,
          splashColor: splashColor,
          borderRadius: AcadexRadius.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (isActive && isGradientRole) ...[
                  // 3px vertical blue indicator on the left (Split Accent Style)
                  Container(
                    width: 3.0,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0080FF), // Primary active split accent blue
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeIconColor : inactiveIconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AcadexTypography.bodySmall(
                      color: isActive ? activeTextColor : inactiveTextColor,
                    ).copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive && !isGradientRole)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeIconColor,
                      shape: BoxShape.circle,
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
