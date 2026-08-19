import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';

class AcadexAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;
  final bool showDrawerButton;

  const AcadexAppBar({
    super.key,
    this.title = 'Acadex',
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
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  splashRadius: 20,
                ),
              ),
            if (showDrawerButton) const SizedBox(width: 8),

            // Logo & Brand
            GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AcadexColors.primary,
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

            const Spacer(),

            // Extra actions if any
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

            // Notifications
            const NotificationBadge(),
            const SizedBox(width: 2),

            // Theme Toggle Button (Light / Dark)
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
            const SizedBox(width: 2),

            // Settings Icon
            IconButton(
              icon: Icon(
                LucideIcons.settings,
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                size: 19,
              ),
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              splashRadius: 20,
            ),
            const SizedBox(width: 10),

            // User Avatar & Profile Quick Link
            GestureDetector(
              onTap: () => context.push('/profile'),
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
