import 'dart:math' as math;
import 'dart:ui';
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

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Grouped, role-aware desktop & mobile navigation drawer with collapsible glass styling
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    final role = user?.role ?? AppRole.student;
    final groupedItems = AcadexNavigationService.getGroupedNavItems(role);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCollapsed = !isModal && ref.watch(sidebarCollapsedProvider);
    final drawerWidth = isModal ? math.min(290.0, screenWidth * 0.82) : (isCollapsed ? 68.0 : 240.0);

    final sidebarContent = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: isModal ? drawerWidth : null,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.75)
                  : const Color(0xFFFFFFFF).withValues(alpha: 0.75),
              border: isModal
                  ? null
                  : Border(
                      right: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.85),
                        width: 1,
                      ),
                    ),
              boxShadow: isModal
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
                        blurRadius: 16,
                        offset: const Offset(2, 0),
                      ),
                    ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Brand & User Identity Area (Compact, Mobile-First)
                  Padding(
                    padding: EdgeInsets.fromLTRB(isCollapsed ? 8 : 16, 12, isCollapsed ? 8 : 16, 8),
                    child: isCollapsed
                        ? Center(
                            child: InkWell(
                              onTap: () {
                                ref.read(sidebarCollapsedProvider.notifier).state = false;
                              },
                              borderRadius: AcadexRadius.borderRadiusMd,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AcadexColors.primary,
                                  borderRadius: AcadexRadius.borderRadiusMd,
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.graduationCap,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Brand Row
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AcadexColors.primary,
                                      borderRadius: AcadexRadius.borderRadiusSm,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.graduationCap,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'ACADEX',
                                      style: AcadexTypography.heading3(
                                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                      ).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isModal)
                                    IconButton(
                                      icon: Icon(
                                        LucideIcons.x,
                                        size: 18,
                                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => Navigator.of(context).pop(),
                                      tooltip: 'Close Menu',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // User Identity Strip
                              InkWell(
                                onTap: () {
                                  if (isModal && Scaffold.of(context).isDrawerOpen) {
                                    Navigator.of(context).pop();
                                  }
                                  context.push('/profile');
                                },
                                borderRadius: AcadexRadius.borderRadiusMd,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                    borderRadius: AcadexRadius.borderRadiusMd,
                                    border: Border.all(
                                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AcadexAvatar(
                                        name: user?.name ?? 'User',
                                        size: 30,
                                        isOnline: true,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              user?.name ?? 'Guest User',
                                              style: AcadexTypography.bodySmall(
                                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                              ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
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
                                      Icon(
                                        LucideIcons.chevronRight,
                                        size: 14,
                                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 4),
                  Divider(
                    height: 1,
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),

                  // Grouped Navigation Items List
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 6 : 10, vertical: 6),
                      children: [
                        for (final entry in groupedItems.entries) ...[
                          if (!isCollapsed)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                              child: Text(
                                entry.key.title,
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 8),
                          for (final item in entry.value)
                            _DrawerTile(
                              label: item.label,
                              icon: item.icon,
                              isActive: item.matchesRoute(activeRoute),
                              badgeCount: item.badgeCount,
                              isCollapsed: isCollapsed,
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

                  Divider(
                    height: 1,
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                  const SizedBox(height: 8),

                  // Bottom Utility Section: Single Predictable Logout
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 6 : 10),
                    child: _DrawerTile(
                      label: 'Logout',
                      icon: LucideIcons.logOut,
                      isActive: false,
                      isCollapsed: isCollapsed,
                      iconColor: AcadexColors.error,
                      textColor: AcadexColors.error,
                      onTap: () async {
                        final confirmed = await AcadexConfirmationDialog.show(
                          context: context,
                          title: 'Logout',
                          message: 'Are you sure you want to sign out of Acadex?',
                          confirmLabel: 'Sign Out',
                          isDestructive: true,
                        );
                        if (confirmed == true) {
                          if (isModal && context.mounted && Scaffold.of(context).isDrawerOpen) {
                            Navigator.of(context).pop();
                          }
                          await ref.read(authProvider.notifier).logout();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      );

    if (isModal) {
      return Drawer(
        backgroundColor: Colors.transparent,
        elevation: 8,
        width: drawerWidth,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: sidebarContent,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      width: drawerWidth,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: drawerWidth,
          maxWidth: drawerWidth,
          child: SizedBox(
            width: drawerWidth,
            child: sidebarContent,
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
  final bool isCollapsed;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.badgeCount,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLogout = iconColor == AcadexColors.error || iconColor == const Color(0xFFDC2626);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Active state: soft primary blue surface and border
    final activeBg = isDark
        ? AcadexColors.primary.withValues(alpha: 0.22)
        : AcadexColors.primaryLight.withValues(alpha: 0.6);
    final activeBorder = isDark
        ? AcadexColors.primary.withValues(alpha: 0.4)
        : AcadexColors.primary.withValues(alpha: 0.25);
    final activeIconColor = isDark ? const Color(0xFF60A5FA) : AcadexColors.primary;
    final activeTextColor = isDark ? const Color(0xFF60A5FA) : AcadexColors.primary;

    // Inactive state: muted neutral colors
    final inactiveIconColor = isLogout
        ? AcadexColors.error
        : (iconColor ?? (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted));
    final inactiveTextColor = isLogout
        ? AcadexColors.error
        : (textColor ?? (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary));

    final content = Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: const BoxConstraints(minHeight: 44.0),
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
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 14, vertical: 9),
            child: isCollapsed
                ? Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isActive ? activeIconColor : inactiveIconColor,
                        ),
                        if (badgeCount != null && badgeCount! > 0)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AcadexColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              child: Text(
                                badgeCount! > 99 ? '99+' : badgeCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      if (isActive) ...[
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
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeCount != null && badgeCount! > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? AcadexColors.primary : AcadexColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeCount! > 99 ? '99+' : badgeCount.toString(),
                            style: TextStyle(
                              color: isActive ? Colors.white : AcadexColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        child: content,
      );
    }
    return content;
  }
}
