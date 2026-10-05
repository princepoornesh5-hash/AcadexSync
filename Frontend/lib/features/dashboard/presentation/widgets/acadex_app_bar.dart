import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import 'acadex_drawer.dart';

class AcadexAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? extraActions;
  final bool showDrawerButton;
  final bool showBackButton;
  final VoidCallback? onBack;

  final bool showTitle;

  const AcadexAppBar({
    super.key,
    this.title = 'Acadex',
    this.subtitle,
    this.extraActions,
    this.showDrawerButton = true,
    this.showBackButton = false,
    this.onBack,
    this.showTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  ConsumerState<AcadexAppBar> createState() => _AcadexAppBarState();
}

class _AcadexAppBarState extends ConsumerState<AcadexAppBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      context.push('/search');
    } else {
      context.push('/search?q=${Uri.encodeComponent(trimmed)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final isDesktop = AcadexBreakpoints.isDesktop(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    const toolbarHeight = 56.0;
    final headerTextColor = isDark ? AcadexColors.darkInk : const Color(0xFF07111F);
    final headerMutedColor = isDark ? AcadexColors.darkInkMuted : const Color(0xFF64748B);
    final headerIconColor = isDark ? AcadexColors.darkInk : const Color(0xFF07111F);

    final topBarContent = Container(
      height: toolbarHeight + topPadding,
      padding: EdgeInsets.only(
        top: topPadding,
        left: isMobile ? 8 : 16,
        right: isMobile ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? (isDesktop ? const Color(0xFF0F172A) : const Color(0xFF0F172A).withValues(alpha: 0.82))
            : (isDesktop ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF).withValues(alpha: 0.82)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: toolbarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
                // Persistent Desktop Sidebar Toggle Button near top-left
                if (isDesktop) ...[
                  IconButton(
                    icon: Icon(
                      ref.watch(sidebarCollapsedProvider) ? LucideIcons.panelLeftOpen : LucideIcons.panelLeftClose,
                      color: headerIconColor,
                      size: 20,
                    ),
                    tooltip: ref.watch(sidebarCollapsedProvider) ? 'Expand Sidebar' : 'Collapse Sidebar',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    splashRadius: 20,
                    onPressed: () {
                      ref.read(sidebarCollapsedProvider.notifier).state =
                          !ref.read(sidebarCollapsedProvider.notifier).state;
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Left Action: Back Button or Mobile Drawer Menu
                if (widget.showBackButton) ...[
                  IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: headerIconColor,
                      size: 20,
                    ),
                    tooltip: 'Back',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    splashRadius: 20,
                    onPressed: widget.onBack ?? () {
                      context.safePop(fallbackRoute: '/dashboard');
                    },
                  ),
                  const SizedBox(width: 4),
                ] else if (widget.showDrawerButton && !isDesktop) ...[
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: Icon(
                        LucideIcons.menu,
                        color: headerIconColor,
                        size: 20,
                      ),
                      tooltip: 'Open Navigation Menu',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      splashRadius: 20,
                      onPressed: () {
                        final scaffold = Scaffold.maybeOf(ctx);
                        if (scaffold != null && scaffold.hasDrawer) {
                          scaffold.openDrawer();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

            // Contextual Page Title & Subtitle (only when enabled to prevent duplicate title)
            if (widget.showTitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: AcadexTypography.heading2(color: headerTextColor).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle!,
                        style: AcadexTypography.caption(color: headerMutedColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              )
            else
              const Spacer(),

            // Center: Search Bar (Desktop / Tablet)
            if (!isMobile) ...[
              const SizedBox(width: 16),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 120,
                    maxWidth: isDesktop ? 320 : 180,
                    maxHeight: 38,
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _handleSearch,
                    style: TextStyle(
                      color: headerTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        color: headerMutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                          : const Color(0xFFF1F5F9).withValues(alpha: 0.85),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 16,
                        color: headerMutedColor,
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Trailing Actions: Streamlined Mobile vs Rich Desktop/Tablet
            if (isMobile) ...[
              if (widget.extraActions != null && widget.extraActions!.isNotEmpty) ...[
                ...widget.extraActions!,
                const SizedBox(width: 4),
              ],
              NotificationBadge(
                size: 20,
                iconColor: headerIconColor,
              ),
            ] else ...[
              if (widget.extraActions != null) ...widget.extraActions!,
              NotificationBadge(
                size: 20,
                iconColor: headerIconColor,
              ),
              const SizedBox(width: 8),

              // Profile Area with Menu (Desktop/Tablet)
              PopupMenuButton<String>(
              tooltip: 'Account Menu',
              offset: const Offset(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: AcadexRadius.borderRadiusLg,
                side: const BorderSide(
                  color: AcadexColors.hairline,
                ),
              ),
              color: AcadexColors.surface,
              elevation: 4,
              onSelected: (value) async {
                switch (value) {
                  case 'profile':
                    context.push('/profile');
                    break;
                  case 'settings':
                    context.push('/settings');
                    break;
                  case 'change_password':
                    context.push('/change-password');
                    break;
                  case 'logout':
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                // Header Tile with user details
                PopupMenuItem<String>(
                  enabled: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        AcadexAvatar(
                          name: user?.name ?? 'User',
                          size: 38,
                          isOnline: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Authenticated User',
                                style: const TextStyle(
                                  color: Color(0xFF07111F),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? user?.role.displayName ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: const [
                      Icon(LucideIcons.user, size: 16, color: AcadexColors.inkSecondary),
                      SizedBox(width: 12),
                      Text('My Profile', style: TextStyle(color: Color(0xFF07111F), fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: const [
                      Icon(LucideIcons.settings, size: 16, color: AcadexColors.inkSecondary),
                      SizedBox(width: 12),
                      Text('Settings', style: TextStyle(color: Color(0xFF07111F), fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'change_password',
                  child: Row(
                    children: const [
                      Icon(LucideIcons.keyRound, size: 16, color: AcadexColors.inkSecondary),
                      SizedBox(width: 12),
                      Text('Change Password', style: TextStyle(color: Color(0xFF07111F), fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(LucideIcons.logOut, size: 16, color: AcadexColors.error),
                      SizedBox(width: 12),
                      Text('Sign Out', style: TextStyle(color: AcadexColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              child: isDesktop
                  ? Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AcadexAvatar(
                            name: user?.name ?? 'User',
                            size: 34,
                            isOnline: true,
                          ),
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 130),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: TextStyle(
                                    color: headerTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user?.role.displayName ?? '',
                                  style: TextStyle(
                                    color: headerMutedColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            LucideIcons.chevronDown,
                            size: 14,
                            color: headerMutedColor,
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AcadexAvatar(
                          name: user?.name ?? 'User',
                          size: 34,
                          isOnline: true,
                        ),
                      ),
                    ),
            ),
            ],
          ],
        ),
      ),
    );

    if (isDesktop) {
      return topBarContent;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: topBarContent,
      ),
    );
  }
}
