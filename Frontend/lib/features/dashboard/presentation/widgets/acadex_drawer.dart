import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/navigation/acadex_nav_item.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_dialogs.dart';

/// Grouped, role-aware desktop & mobile navigation drawer (Prompt 11)
/// Groups destinations into WORKSPACE, ACADEMICS, OPERATIONS, INSIGHTS, SYSTEM
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
    final groupedItems = AcadexNavigationService.getGroupedNavItems(role);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = isModal ? math.min(290.0, screenWidth * 0.82) : 260.0;

    return Drawer(
      backgroundColor: Colors.white,
      elevation: isModal ? 8 : 0,
      width: drawerWidth.clamp(260.0, 300.0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: isModal
              ? null
              : const Border(
                  right: BorderSide(
                    color: AcadexColors.hairline,
                    width: 1,
                  ),
                ),
        ),
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
                        color: AcadexColors.primary,
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                      child: const Icon(
                        LucideIcons.graduationCap,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acadex',
                            style: AcadexTypography.heading3(
                              color: AcadexColors.ink,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Campus Platform',
                            style: AcadexTypography.caption(
                              color: AcadexColors.inkMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // User Identity Area (Clean subtle surface)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AcadexColors.canvasSoft,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: AcadexColors.hairline,
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
                                color: AcadexColors.ink,
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

              const SizedBox(height: 8),
              const Divider(
                height: 1,
                color: AcadexColors.hairline,
              ),

              // Grouped Navigation Items List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  children: [
                    for (final entry in groupedItems.entries) ...[
                      // Group Section Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                        child: Text(
                          entry.key.title,
                          style: AcadexTypography.caption(
                            color: AcadexColors.inkMuted,
                          ).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      // Group Navigation Items
                      for (final item in entry.value)
                        _DrawerTile(
                          label: item.label,
                          icon: item.icon,
                          isActive: item.matchesRoute(activeRoute),
                          badgeCount: item.badgeCount,
                          onTap: () {
                            if (isModal && Scaffold.of(context).isDrawerOpen) {
                              Navigator.of(context).pop();
                            }
                            context.go(item.route);
                          },
                        ),
                    ],
                  ],
                ),
              ),

              const Divider(
                height: 1,
                color: AcadexColors.hairline,
              ),
              const SizedBox(height: 8),

              // Bottom Utility Section: Single Predictable Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _DrawerTile(
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
  final int? badgeCount;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isLogout = iconColor == AcadexColors.error || iconColor == const Color(0xFFDC2626);

    // Active state: soft primary blue surface and border
    final activeBg = AcadexColors.primaryLight.withValues(alpha: 0.6);
    final activeBorder = AcadexColors.primary.withValues(alpha: 0.25);
    final activeIconColor = AcadexColors.primary;
    final activeTextColor = AcadexColors.primary;

    // Inactive state: muted neutral colors
    final inactiveIconColor = isLogout
        ? AcadexColors.error
        : (iconColor ?? AcadexColors.inkMuted);
    final inactiveTextColor = isLogout
        ? AcadexColors.error
        : (textColor ?? AcadexColors.inkSecondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      constraints: const BoxConstraints(minHeight: 40.0),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: isActive ? Border.all(color: activeBorder, width: 1.0) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusMd,
        child: InkWell(
          onTap: onTap,
          hoverColor: AcadexColors.surfaceHover,
          splashColor: AcadexColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: AcadexRadius.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                if (isActive) ...[
                  // 3px vertical blue indicator on the left
                  Container(
                    width: 3.0,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AcadexColors.primary,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  icon,
                  size: 19,
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
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AcadexColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
