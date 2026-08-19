import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_dialogs.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  final List<AppRole>? allowedRoles;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
    this.allowedRoles,
  });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    final role = user?.role ?? AppRole.student;
    final dashboardRoute = user != null ? _dashboardRouteForRole(role) : '/login';

    final navItems = [
      _NavItem(
        label: 'Dashboard',
        icon: LucideIcons.layoutDashboard,
        route: dashboardRoute,
      ),
      const _NavItem(
        label: 'Colleges',
        icon: LucideIcons.building,
        route: '/academics/colleges',
        allowedRoles: [AppRole.superAdmin],
      ),
      const _NavItem(
        label: 'Academic Structure',
        icon: LucideIcons.layers,
        route: '/academic-structure/departments',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod],
      ),
      const _NavItem(
        label: 'Faculty & Staff',
        icon: LucideIcons.users,
        route: '/academics/faculty',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod],
      ),
      const _NavItem(
        label: 'Faculty Assignments',
        icon: LucideIcons.userCheck,
        route: '/faculty-assignments',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod, AppRole.superAdmin],
      ),
      const _NavItem(
        label: 'Faculty Workload',
        icon: LucideIcons.activity,
        route: '/faculty-workload',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod],
      ),
      const _NavItem(
        label: 'My Assignments',
        icon: LucideIcons.bookOpen,
        route: '/my-assignments',
        allowedRoles: [AppRole.faculty],
      ),
      const _NavItem(
        label: 'Students',
        icon: LucideIcons.graduationCap,
        route: '/academics/students',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod],
      ),
      const _NavItem(
        label: 'User Management',
        icon: LucideIcons.users,
        route: '/users',
        allowedRoles: [AppRole.superAdmin, AppRole.collegeAdmin],
      ),
      const _NavItem(
        label: 'Attendance',
        icon: LucideIcons.clipboardCheck,
        route: '/attendance',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student],
      ),
      const _NavItem(
        label: 'Timetable',
        icon: LucideIcons.calendar,
        route: '/timetable',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student],
      ),
      const _NavItem(
        label: 'Notes & Resources',
        icon: LucideIcons.fileText,
        route: '/notes',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student],
      ),
      const _NavItem(
        label: 'Official Certificates',
        icon: LucideIcons.fileCheck2,
        route: '/official-certificates',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student],
      ),
      const _NavItem(
        label: 'Achievements',
        icon: LucideIcons.trophy,
        route: '/achievements',
        allowedRoles: [AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student],
      ),
      const _NavItem(
        label: 'Analytics',
        icon: LucideIcons.barChart3,
        route: '/analytics',
        allowedRoles: [AppRole.superAdmin, AppRole.collegeAdmin, AppRole.hod],
      ),
      const _NavItem(
        label: 'Notifications',
        icon: LucideIcons.bell,
        route: '/notifications',
      ),
      const _NavItem(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        route: '/ai-assistant',
      ),
    ];

    final filteredItems = navItems.where((item) {
      if (item.allowedRoles == null) return true;
      return item.allowedRoles!.contains(role);
    }).toList();

    return Drawer(
      backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
      elevation: isModal ? 16 : 0,
      width: 270,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          border: isModal
              ? null
              : Border(
                  right: BorderSide(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    width: 1,
                  ),
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Brand Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AcadexColors.primary,
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                      child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acadex',
                          style: AcadexTypography.heading3(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                        Text(
                          'Campus Platform',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // User Profile Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                    borderRadius: AcadexRadius.borderRadiusLg,
                    border: Border.all(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AcadexAvatar(
                        name: user?.name ?? 'User',
                        size: 38,
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
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
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
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
              const SizedBox(height: 8),

              // Main Nav Items List
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
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
              const SizedBox(height: 8),

              // Bottom Section: Theme Switcher, Profile, Settings & Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
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
                    _DrawerTile(
                      label: isDark ? 'Light Theme' : 'Dark Theme',
                      icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                      isActive: false,
                      iconColor: isDark ? const Color(0xFFFBBF24) : AcadexColors.primary,
                      onTap: () {
                        final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                        settingsAsync.whenData((settings) {
                          ref.read(appSettingsProvider.notifier).updateSettings(
                                settings.copyWith(themeMode: newMode),
                              );
                        });
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerTile(
                      label: 'Logout',
                      icon: LucideIcons.logOut,
                      isActive: false,
                      iconColor: AcadexColors.error,
                      textColor: AcadexColors.error,
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
    );
  }
}

class _DrawerTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = isDark
        ? AcadexColors.primaryHover.withValues(alpha: 0.25)
        : AcadexColors.primaryLight;
    final activeBorder = isDark
        ? AcadexColors.primaryMuted.withValues(alpha: 0.5)
        : AcadexColors.primary.withValues(alpha: 0.3);

    final activeIconColor = isDark ? AcadexColors.primaryMuted : AcadexColors.primary;
    final activeTextColor = isDark ? Colors.white : AcadexColors.primary;

    final inactiveIconColor = iconColor ?? (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted);
    final inactiveTextColor = textColor ?? (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: isActive ? Border.all(color: activeBorder, width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AcadexRadius.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? activeIconColor : inactiveIconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AcadexTypography.bodySmall(
                      color: isActive ? activeTextColor : inactiveTextColor,
                    ).copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
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
