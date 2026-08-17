import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';

class AcadexAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;

  const AcadexAppBar({
    super.key,
    this.title = 'Acadex',
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

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

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: DashboardColors.surface,
        border: Border(bottom: BorderSide(color: DashboardColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: Row(
          children: [
            // Drawer toggle (hamburger)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(LucideIcons.menu, color: DashboardColors.textSecondary, size: 22),
                tooltip: 'Open menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                splashRadius: 22,
              ),
            ),
            const SizedBox(width: 8),
            // Logo & Title
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: DashboardColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Acadex',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Global Search icon
            IconButton(
              icon: const Icon(LucideIcons.search, color: DashboardColors.textSecondary, size: 22),
              tooltip: 'Search',
              onPressed: () => context.push('/search'),
              splashRadius: 22,
            ),
            const SizedBox(width: 4),
            // Notification icon
            const NotificationBadge(),
            const SizedBox(width: 4),
            // Settings icon
            IconButton(
              icon: const Icon(LucideIcons.settings, color: DashboardColors.textSecondary, size: 22),
              tooltip: 'Settings',
              onPressed: () => context.go('/module/Settings'),
              splashRadius: 22,
            ),
            const SizedBox(width: 8),
            // Avatar with tooltip
            Tooltip(
              message: user?.name ?? 'User',
              child: GestureDetector(
                onTap: () => context.go('/module/Profile'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DashboardColors.primaryLight,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.primary,
                      ),
                    ),
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
