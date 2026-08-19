import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../users/presentation/providers/user_profile_providers.dart';
import '../widgets/settings_widgets.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text("Language", style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        child: SettingsSection(
          title: "Available Languages",
          children: [
            SettingsTile(
              icon: LucideIcons.checkCircle2,
              title: "English",
              iconColor: AcadexColors.success,
              trailing: const Icon(LucideIcons.check, color: AcadexColors.success),
              onTap: () {},
            ),
            SettingsTile(
              icon: LucideIcons.globe,
              title: "Telugu",
              subtitle: "Coming Soon",
              iconColor: AcadexColors.inkMuted,
              onTap: () {},
            ),
            SettingsTile(
              icon: LucideIcons.globe,
              title: "Hindi",
              subtitle: "Coming Soon",
              iconColor: AcadexColors.inkMuted,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _currentObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final profileEditNotifier = ref.read(profileEditProvider.notifier);
    await profileEditNotifier.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );
    final result = ref.read(profileEditProvider);
    if (!mounted) return;
    if (result.status == ProfileEditStatus.saved) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
          backgroundColor: AcadexColors.success,
        ),
      );
    } else if (result.status == ProfileEditStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to change password.'),
          backgroundColor: AcadexColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileEditState = ref.watch(profileEditProvider);
    final email = authState is AuthAuthenticated ? authState.user.email : '—';
    final isSaving = profileEditState.status == ProfileEditStatus.saving;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text("Security & Sessions", style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Identity (read-only)
            SettingsSection(
              title: "Account Identity",
              children: [
                SettingsTile(
                  icon: LucideIcons.mail,
                  title: "Email Address",
                  subtitle: email,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AcadexColors.inkMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Read-only', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Change Password Form
            SettingsSection(
              title: "Change Password",
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _currentObscure,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(LucideIcons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_currentObscure ? LucideIcons.eyeOff : LucideIcons.eye),
                              onPressed: () => setState(() => _currentObscure = !_currentObscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Current password is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _newObscure,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(LucideIcons.keyRound),
                            suffixIcon: IconButton(
                              icon: Icon(_newObscure ? LucideIcons.eyeOff : LucideIcons.eye),
                              onPressed: () => setState(() => _newObscure = !_newObscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'New password is required';
                            if (v.length < 8) return 'Password must be at least 8 characters';
                            if (v == _currentPasswordController.text) return 'New password must differ from current password';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _confirmObscure,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: const Icon(LucideIcons.keyRound),
                            suffixIcon: IconButton(
                              icon: Icon(_confirmObscure ? LucideIcons.eyeOff : LucideIcons.eye),
                              onPressed: () => setState(() => _confirmObscure = !_confirmObscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please confirm your new password';
                            if (v != _newPasswordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSaving ? null : _changePassword,
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Update Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Logout all sessions
            SettingsSection(
              title: "Session",
              children: [
                SettingsTile(
                  icon: LucideIcons.logOut,
                  iconColor: AcadexColors.warning,
                  title: "Sign Out",
                  subtitle: "Ends your current session on this device",
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
          ],
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
        title: Text("About", style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.graduationCap, size: 64, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Text("Acadex", style: AcadexTypography.heading2(color: Theme.of(context).colorScheme.onSurface)),
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
        title: Text("Help & Support", style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
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
    );
  }
}
