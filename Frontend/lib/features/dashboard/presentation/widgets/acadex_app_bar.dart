import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';

class AcadexAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? extraActions;
  final bool showDrawerButton;

  const AcadexAppBar({
    super.key,
    this.title = 'Acadex',
    this.subtitle,
    this.extraActions,
    this.showDrawerButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    final isMobile = AcadexBreakpoints.isMobile(context);
    final isDesktop = AcadexBreakpoints.isDesktop(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        child: Row(
          children: [
            if (showDrawerButton)
              Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    LucideIcons.menu,
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                    size: 20,
                  ),
                  tooltip: 'Open Navigation Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  splashRadius: 20,
                ),
              ),
            if (showDrawerButton) const SizedBox(width: 8),

            // Logo & Brand (for Mobile/Top) or Page Title with breadcrumb
            if (isMobile) ...[
              GestureDetector(
                onTap: () => context.go('/dashboard'),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AcadexColors.primary, Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                      child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Acadex',
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AcadexTypography.title(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                ],
              ),
              if (user != null && isDesktop) ...[
                const SizedBox(width: 16),
                AcadexBadge(
                  label: user.role.displayName.toUpperCase(),
                  variant: AcadexBadgeVariant.primary,
                ),
              ],
            ],

            const Spacer(),

            // Extra actions if provided
            if (extraActions != null) ...extraActions!,

            // Search Icon
            IconButton(
              icon: Icon(
                LucideIcons.search,
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                size: 19,
              ),
              tooltip: 'Search (Cmd+K)',
              onPressed: () => context.push('/search'),
              splashRadius: 20,
            ),
            const SizedBox(width: 2),

            // Live Notifications Badge
            const NotificationBadge(),
            const SizedBox(width: 2),

            // Theme Mode Toggle Button
            IconButton(
              icon: Icon(
                isDark ? LucideIcons.sun : LucideIcons.moon,
                color: isDark ? const Color(0xFFFBBF24) : AcadexColors.primary,
                size: 19,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () {
                final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                settingsAsync.whenData((settings) {
                  ref.read(appSettingsProvider.notifier).updateSettings(
                        settings.copyWith(themeMode: newMode),
                      );
                });
              },
              splashRadius: 20,
            ),
            const SizedBox(width: 8),

            // Authenticated User Profile Menu
            PopupMenuButton<String>(
              tooltip: 'Account Menu',
              offset: const Offset(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: AcadexRadius.borderRadiusLg,
                side: BorderSide(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
              ),
              color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
              elevation: 6,
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
                                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                ).copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? user?.role.displayName ?? '',
                                style: AcadexTypography.caption(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
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
                      Icon(LucideIcons.user, size: 16, color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                      const SizedBox(width: 12),
                      Text('My Profile', style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(LucideIcons.settings, size: 16, color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                      const SizedBox(width: 12),
                      Text('Settings', style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(LucideIcons.keyRound, size: 16, color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                      const SizedBox(width: 12),
                      Text('Change Password', style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
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
              child: AcadexAvatar(
                name: user?.name ?? 'User',
                size: 34,
                isOnline: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
