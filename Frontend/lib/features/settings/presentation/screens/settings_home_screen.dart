import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/settings_widgets.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_dialogs.dart';

class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AcadexPageHeader(
              title: "Settings",
              subtitle: "Manage your preferences, security, and institutional application configurations.",
            ),
            const SizedBox(height: 12),
            
            SettingsSection(
              title: "User Profile",
              children: [
                SettingsTile(
                  icon: LucideIcons.user,
                  title: "Profile Information",
                  subtitle: "View and edit your personal details",
                  onTap: () => context.push('/profile'),
                ),
                SettingsTile(
                  icon: LucideIcons.key,
                  title: "Change Password",
                  subtitle: "Update your login credentials",
                  onTap: () => context.push('/settings/security'),
                ),
              ],
            ),

            SettingsSection(
              title: "Appearance & Preferences",
              children: [
                SettingsTile(
                  icon: LucideIcons.palette,
                  title: "Appearance",
                  subtitle: "Interface theme and typography display options",
                  onTap: () => context.push('/settings/appearance'),
                ),
                SettingsTile(
                  icon: LucideIcons.bell,
                  title: "Notifications",
                  subtitle: "Manage alerts, sound, and email notifications",
                  onTap: () => context.push('/settings/notifications'),
                ),
                SettingsTile(
                  icon: LucideIcons.globe,
                  title: "Language",
                  subtitle: "English (US)",
                  onTap: () => context.push('/settings/language'),
                ),
              ],
            ),

            SettingsSection(
              title: "Account & Security",
              children: [
                SettingsTile(
                  icon: LucideIcons.shield,
                  title: "Security & Sessions",
                  subtitle: "Manage active sessions and two-factor authentication",
                  onTap: () => context.push('/settings/security'),
                ),
                SettingsTile(
                  icon: LucideIcons.logOut,
                  title: "Sign Out",
                  iconColor: AcadexColors.error,
                  onTap: () async {
                    final confirmed = await AcadexConfirmationDialog.show(
                      context: context,
                      title: 'Sign Out',
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
