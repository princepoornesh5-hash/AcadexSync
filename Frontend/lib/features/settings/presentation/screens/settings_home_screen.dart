import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/settings_widgets.dart';

class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text("Manage your preferences and application settings.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 32),
                
                SettingsSection(
                  title: "Profile",
                  children: [
                    SettingsTile(icon: LucideIcons.user, title: "Profile Information", subtitle: "View and edit your personal details", onTap: () => context.push('/settings/profile')),
                    SettingsTile(icon: LucideIcons.key, title: "Change Password", onTap: () => context.push('/settings/security')),
                  ],
                ),

                SettingsSection(
                  title: "Preferences",
                  children: [
                    SettingsTile(icon: LucideIcons.palette, title: "Appearance", subtitle: "Theme and display options", onTap: () => context.push('/settings/appearance')),
                    SettingsTile(icon: LucideIcons.bell, title: "Notifications", subtitle: "Manage alerts and updates", onTap: () => context.push('/settings/notifications')),
                    SettingsTile(icon: LucideIcons.globe, title: "Language", subtitle: "English", onTap: () => context.push('/settings/language')),
                  ],
                ),

                SettingsSection(
                  title: "Account & Security",
                  children: [
                    SettingsTile(icon: LucideIcons.shield, title: "Security & Sessions", onTap: () => context.push('/settings/security')),
                    SettingsTile(
                      icon: LucideIcons.logOut, 
                      title: "Sign Out", 
                      iconColor: AppColors.warning, 
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                      }
                    ), 
                  ],
                ),

                SettingsSection(
                  title: "Support",
                  children: [
                    SettingsTile(icon: LucideIcons.helpCircle, title: "Help & FAQ", onTap: () => context.push('/settings/support')),
                    SettingsTile(icon: LucideIcons.info, title: "About Acadex", onTap: () => context.push('/settings/about')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
