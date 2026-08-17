import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../widgets/settings_widgets.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text("Language", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SettingsSection(
              title: "Available Languages",
              children: [
                SettingsTile(
                  icon: LucideIcons.checkCircle2,
                  title: "English",
                  iconColor: AppColors.success,
                  trailing: const Icon(LucideIcons.check, color: AppColors.success),
                  onTap: () {},
                ),
                SettingsTile(
                  icon: LucideIcons.globe,
                  title: "Telugu",
                  subtitle: "Coming Soon",
                  iconColor: AppColors.textMuted,
                  onTap: () {},
                ),
                SettingsTile(
                  icon: LucideIcons.globe,
                  title: "Hindi",
                  subtitle: "Coming Soon",
                  iconColor: AppColors.textMuted,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text("Security & Sessions", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsSection(
                  title: "Login & Authentication",
                  children: [
                    SettingsTile(icon: LucideIcons.key, title: "Change Password", onTap: () {}),
                    SettingsTile(icon: LucideIcons.fingerprint, title: "Biometric Login", subtitle: "Coming Soon", onTap: () {}),
                    SettingsTile(icon: LucideIcons.smartphone, title: "Two-Factor Authentication", subtitle: "Coming Soon", onTap: () {}),
                  ],
                ),
                SettingsSection(
                  title: "Active Sessions",
                  children: [
                    SettingsTile(
                      icon: LucideIcons.monitor, 
                      title: "Current Session", 
                      subtitle: "Mac OS • Chrome • Just now",
                      trailing: const Text("Active", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ),
                    SettingsTile(
                      icon: LucideIcons.smartphone, 
                      title: "Mobile App", 
                      subtitle: "iPhone 13 • 2 days ago",
                      trailing: TextButton(onPressed: () {}, child: const Text("Revoke", style: TextStyle(color: AppColors.warning))),
                    ),
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

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text("About", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.graduationCap, size: 64, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text("Acadex", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                Text("Version 1.0.0 (Build 42)", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 32),
                SettingsSection(
                  title: "Legal",
                  children: [
                    SettingsTile(icon: LucideIcons.fileText, title: "Terms & Conditions", onTap: () {}),
                    SettingsTile(icon: LucideIcons.shield, title: "Privacy Policy", onTap: () {}),
                    SettingsTile(icon: LucideIcons.book, title: "Open Source Licenses", onTap: () {}),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text("Help & Support", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SettingsSection(
              title: "Contact & Resources",
              children: [
                SettingsTile(icon: LucideIcons.helpCircle, title: "FAQs", subtitle: "Frequently asked questions", onTap: () {}),
                SettingsTile(icon: LucideIcons.mail, title: "Contact Support", subtitle: "Email our support team", onTap: () {}),
                SettingsTile(icon: LucideIcons.bug, title: "Report a Bug", subtitle: "Help us improve the app", onTap: () {}),
                SettingsTile(icon: LucideIcons.messageSquare, title: "Feedback", subtitle: "Share your thoughts", onTap: () {}),
                SettingsTile(icon: LucideIcons.messageCircle, title: "Live Chat", subtitle: "Coming Soon", onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
