import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class _DrawerItem {
  final String label;
  final IconData icon;
  final String? route;
  final bool isModule; // if true, navigate to /module/:label

  const _DrawerItem({
    required this.label,
    required this.icon,
    this.route,
  }) : isModule = false;
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

  const AcadexDrawer({super.key, required this.activeRoute, this.isModal = true});

  static final List<_DrawerItem> _mainItems = [
    const _DrawerItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard),
    const _DrawerItem(label: 'Attendance', icon: LucideIcons.clipboardCheck, route: '/attendance'),
    const _DrawerItem(label: 'AI Assistant', icon: LucideIcons.bot, route: '/ai-assistant'),
  ];

  static final List<_DrawerItem> _bottomItems = [
    const _DrawerItem(label: 'Profile', icon: LucideIcons.userCircle, route: '/profile'),
    const _DrawerItem(label: 'Settings', icon: LucideIcons.settings, route: '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    final initials = user != null
        ? user.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : 'U';

    final dashboardRoute = user != null
        ? _dashboardRouteForRole(user.role)
        : '/login';

    return Drawer(
      backgroundColor: DashboardColors.surface,
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: DashboardColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Acadex',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Profile Row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: DashboardColors.primaryLight,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: DashboardColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DashboardColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'User',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DashboardColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.role.displayName ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: DashboardColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Online indicator
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: DashboardColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: DashboardColors.surface, width: 2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Main Nav Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ..._mainItems.map((item) {
                    final targetRoute = item.isModule
                        ? '/module/${item.label}'
                        : (item.route ?? dashboardRoute);
                    final isActive = activeRoute == targetRoute;
                    return _DrawerTile(
                      item: item,
                      isActive: isActive,
                      onTap: () {
                        if (isModal) {
                          if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                            Navigator.of(context).pop();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        }
                        context.go(targetRoute);
                      },
                    );
                  }),
                  if (user?.role == AppRole.superAdmin || user?.role == AppRole.collegeAdmin)
                    _DrawerTile(
                      item: const _DrawerItem(label: 'Users', icon: LucideIcons.users, route: '/users'),
                      isActive: activeRoute == '/users',
                      onTap: () {
                        if (isModal) {
                          if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                            Navigator.of(context).pop();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        }
                        context.go('/users');
                      },
                    ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ..._bottomItems.map((item) {
                    final targetRoute = item.isModule
                        ? '/module/${item.label}'
                        : (item.route ?? dashboardRoute);
                    return _DrawerTile(
                      item: item,
                      isActive: activeRoute == targetRoute,
                      onTap: () {
                        if (isModal) {
                          if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                            Navigator.of(context).pop();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        }
                        context.go(targetRoute);
                      },
                    );
                  }),
                ],
              ),
            ),
            // Logout
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: const Icon(LucideIcons.logOut, color: DashboardColors.error, size: 20),
                title: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.error,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: DashboardColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(
                        'Logout',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: GoogleFonts.inter(color: DashboardColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: DashboardColors.textSecondary)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DashboardColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final _DrawerItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isActive ? DashboardColors.primaryLight : Colors.transparent,
        leading: Icon(
          item.icon,
          size: 20,
          color: isActive ? DashboardColors.primary : DashboardColors.textSecondary,
        ),
        title: Text(
          item.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? DashboardColors.primary : DashboardColors.textPrimary,
          ),
        ),
        trailing: item.isModule
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DashboardColors.border,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Soon',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textMuted,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
