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

class AcadexAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? extraActions;
  final bool showDrawerButton;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AcadexAppBar({
    super.key,
    this.title = 'Acadex',
    this.subtitle,
    this.extraActions,
    this.showDrawerButton = true,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

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

    final isMobile = AcadexBreakpoints.isMobile(context);
    final isDesktop = AcadexBreakpoints.isDesktop(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    const toolbarHeight = 64.0;
    const headerTextColor = Color(0xFF07111F);
    const headerMutedColor = Color(0xFF64748B);
    const headerIconColor = Color(0xFF07111F);

    return Container(
      height: toolbarHeight + topPadding,
      padding: EdgeInsets.only(
        top: topPadding,
        left: isMobile ? 8 : 20,
        right: isMobile ? 8 : 20,
      ),
      decoration: const BoxDecoration(
        color: AcadexColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AcadexColors.hairline,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: toolbarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Action: Back Button or Drawer Menu
            if (widget.showBackButton) ...[
              IconButton(
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: headerIconColor,
                  size: 22,
                ),
                tooltip: 'Back',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                splashRadius: 24,
                onPressed: widget.onBack ?? () {
                  context.safePop(fallbackRoute: '/dashboard');
                },
              ),
              const SizedBox(width: 4),
            ] else if (widget.showDrawerButton) ...[
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(
                    LucideIcons.menu,
                    color: headerIconColor,
                    size: 22,
                  ),
                  tooltip: 'Open Navigation Menu',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  splashRadius: 24,
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

            // Contextual Page Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: headerTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        color: headerMutedColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Center: Search Bar (Desktop / Tablet)
            if (!isMobile) ...[
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 180,
                  maxWidth: isDesktop ? 340 : 220,
                  maxHeight: 38,
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _handleSearch,
                  style: const TextStyle(
                    color: headerTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(
                      color: headerMutedColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 16,
                      color: headerMutedColor,
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AcadexColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Extra Actions if any
            if (widget.extraActions != null && !isMobile) ...widget.extraActions!,

            // Mobile Compact Search Icon Button
            if (isMobile) ...[
              IconButton(
                icon: const Icon(
                  LucideIcons.search,
                  color: headerMutedColor,
                  size: 22,
                ),
                tooltip: 'Search',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => context.push('/search'),
                splashRadius: 24,
              ),
            ],

            // Notifications Badge (min 48x48 touch target)
            NotificationBadge(
              size: isMobile ? 22 : 20,
              iconColor: const Color(0xFF475569),
            ),
            const SizedBox(width: 4),

            // Profile Area with Menu
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: const TextStyle(
                                  color: Color(0xFF07111F),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.role.displayName ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.chevronDown,
                            size: 14,
                            color: Color(0xFF64748B),
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
        ),
      ),
    );
  }
}
