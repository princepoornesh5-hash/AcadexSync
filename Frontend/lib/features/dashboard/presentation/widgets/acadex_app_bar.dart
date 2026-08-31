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
import '../../../../core/presentation/widgets/acadex_badge.dart';

class AcadexAppBar extends ConsumerWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    final isMobile = AcadexBreakpoints.isMobile(context);
    final isDesktop = AcadexBreakpoints.isDesktop(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final isGradientRole = user?.role == AppRole.superAdmin ||
        user?.role == AppRole.collegeAdmin ||
        user?.role == AppRole.hod ||
        user?.role == AppRole.faculty ||
        user?.role == AppRole.student;

    final headerTextColor = isGradientRole ? Colors.white : AcadexColors.ink;
    final headerMutedColor = isGradientRole ? const Color(0xFFCCE6FF) : AcadexColors.inkMuted;
    final headerIconColor = isGradientRole ? Colors.white : AcadexColors.ink;

    final toolbarHeight = isMobile ? 64.0 : 60.0;

    return Container(
      height: toolbarHeight + topPadding,
      padding: EdgeInsets.only(
        top: topPadding,
        left: isMobile ? 8 : 16,
        right: isMobile ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: isGradientRole ? Colors.transparent : AcadexColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isGradientRole
                ? Colors.white.withValues(alpha: 0.12)
                : AcadexColors.hairline,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: toolbarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back Button (High priority for secondary screens)
            if (showBackButton) ...[
              IconButton(
                icon: Icon(
                  LucideIcons.arrowLeft,
                  color: headerIconColor,
                  size: isMobile ? 24 : 20,
                ),
                tooltip: 'Back',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                splashRadius: 24,
                onPressed: onBack ?? () {
                  context.safePop(fallbackRoute: '/dashboard');
                },
              ),
              const SizedBox(width: 4),
            ] else if (showDrawerButton) ...[
              Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    LucideIcons.menu,
                    color: headerIconColor,
                    size: isMobile ? 24 : 22,
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

            // Logo & Brand (when at root dashboard) or Page Title (when in secondary screen)
            if (isMobile) ...[
              if (title == 'Acadex') ...[
                Expanded(
                  child: InkWell(
                    onTap: () => context.go('/dashboard'),
                    borderRadius: AcadexRadius.borderRadiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isGradientRole ? const Color(0xFF0080FF) : AcadexColors.primary,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.graduationCap, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Acadex',
                                  style: TextStyle(
                                    color: headerTextColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Campus Management',
                                  style: TextStyle(
                                    color: headerMutedColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    height: 1.15,
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
                ),
              ] else ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: headerTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: headerMutedColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Expanded(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AcadexTypography.title(color: headerTextColor).copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            style: AcadexTypography.caption(color: headerMutedColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    if (user != null && isDesktop) ...[
                      const SizedBox(width: 14),
                      AcadexBadge(
                        label: user.role.displayName.toUpperCase(),
                        variant: isGradientRole ? AcadexBadgeVariant.primary : AcadexBadgeVariant.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Extra actions if provided (desktop/tablet)
            if (extraActions != null && !isMobile) ...extraActions!,

            // Search Icon (desktop/tablet only to keep mobile header lean)
            if (!isMobile) ...[
              IconButton(
                icon: Icon(
                  LucideIcons.search,
                  color: isGradientRole ? Colors.white70 : AcadexColors.inkSecondary,
                  size: 19,
                ),
                tooltip: 'Search',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => context.push('/search'),
                splashRadius: 22,
              ),
              const SizedBox(width: 2),
            ],

            // Live Notifications Badge (min 48x48 touch target)
            NotificationBadge(
              size: isMobile ? 24 : 20,
              iconColor: isGradientRole ? Colors.white : AcadexColors.inkSecondary,
            ),
            const SizedBox(width: 4),

            // Authenticated User Profile Menu
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
                                style: AcadexTypography.body(
                                  color: AcadexColors.ink,
                                ).copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? user?.role.displayName ?? '',
                                style: AcadexTypography.caption(
                                  color: AcadexColors.inkMuted,
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
                    children: [
                      const Icon(LucideIcons.user, size: 16, color: AcadexColors.inkSecondary),
                      const SizedBox(width: 12),
                      Text('My Profile', style: AcadexTypography.body(color: AcadexColors.ink)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.settings, size: 16, color: AcadexColors.inkSecondary),
                      const SizedBox(width: 12),
                      Text('Settings', style: AcadexTypography.body(color: AcadexColors.ink)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'change_password',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.keyRound, size: 16, color: AcadexColors.inkSecondary),
                      const SizedBox(width: 12),
                      Text('Change Password', style: AcadexTypography.body(color: AcadexColors.ink)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.logOut, size: 16, color: AcadexColors.error),
                      const SizedBox(width: 12),
                      Text('Sign Out', style: AcadexTypography.body(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: AcadexAvatar(
                    name: user?.name ?? 'User',
                    size: isMobile ? 36 : 34,
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
