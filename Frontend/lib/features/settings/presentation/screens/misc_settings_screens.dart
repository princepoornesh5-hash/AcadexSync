import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../users/presentation/providers/user_profile_providers.dart';
import '../widgets/settings_widgets.dart';
import 'package:flutter/services.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcadexPageContainer(
      maxWidth: AcadexLayout.formMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcadexPageHeader(
            title: 'Language',
            subtitle: 'Choose your preferred interface language',
            onBack: () => context.safePop(fallbackRoute: '/settings'),
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: "Available Languages",
            children: [
              SettingsTile(
                icon: LucideIcons.checkCircle2,
                title: "English",
                iconColor: AcadexColors.success,
                trailing: const Icon(LucideIcons.check, color: AcadexColors.success),
                onTap: () => AcadexSnackBar.showInfo(context, 'English is your active interface language.'),
              ),
              SettingsTile(
                icon: LucideIcons.globe,
                title: "Telugu",
                subtitle: "Coming Soon",
                iconColor: AcadexColors.inkMuted,
                onTap: () => AcadexSnackBar.showInfo(context, 'Telugu language pack is scheduled for an upcoming release.'),
              ),
              SettingsTile(
                icon: LucideIcons.globe,
                title: "Hindi",
                subtitle: "Coming Soon",
                iconColor: AcadexColors.inkMuted,
                onTap: () => AcadexSnackBar.showInfo(context, 'Hindi language pack is scheduled for an upcoming release.'),
              ),
            ],
          ),
        ],
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
      AcadexSnackBar.showSuccess(context, 'Password changed successfully.');
    } else if (result.status == ProfileEditStatus.error) {
      AcadexSnackBar.showError(
        context,
        result.error ?? 'Failed to change password.',
        fallbackMessage: 'Failed to change password.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileEditState = ref.watch(profileEditProvider);
    final email = authState is AuthAuthenticated ? authState.user.email : '—';
    final isSaving = profileEditState.status == ProfileEditStatus.saving;

    return AcadexPageContainer(
      maxWidth: AcadexLayout.formMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcadexPageHeader(
            title: 'Security & Sessions',
            subtitle: 'Manage password, identity, and active device sessions',
            onBack: () => context.safePop(fallbackRoute: '/settings'),
          ),
          const SizedBox(height: 16),
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
                      AcadexTextField(
                        controller: _currentPasswordController,
                        label: 'Current Password',
                        prefixIcon: LucideIcons.lock,
                        isPassword: true,
                        enabled: !isSaving,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Current password is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AcadexTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        prefixIcon: LucideIcons.keyRound,
                        isPassword: true,
                        enabled: !isSaving,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'New password is required';
                          if (v.length < 8) return 'Password must be at least 8 characters';
                          if (v == _currentPasswordController.text) return 'New password must differ from current password';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AcadexTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        prefixIcon: LucideIcons.keyRound,
                        isPassword: true,
                        enabled: !isSaving,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your new password';
                          if (v != _newPasswordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      AcadexButton(
                        label: 'Update Password',
                        icon: LucideIcons.checkCircle,
                        isLoading: isSaving,
                        isFullWidth: true,
                        size: AcadexButtonSize.lg,
                        onPressed: isSaving ? null : _changePassword,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logout sessions
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
              SettingsTile(
                icon: LucideIcons.shieldAlert,
                iconColor: AcadexColors.error,
                title: "Sign Out All Devices",
                subtitle: "Revokes all active sessions on other phones and computers",
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Revoke All Sessions?"),
                      content: const Text(
                        "This will immediately sign you out from all browsers, mobile devices, and sessions.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Sign Out All"),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await ref.read(authProvider.notifier).logoutAll();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcadexPageContainer(
      maxWidth: AcadexLayout.formMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AcadexPageHeader(
            title: 'About Acadex',
            subtitle: 'Version, build specifications, and legal notices',
            onBack: () => context.safePop(fallbackRoute: '/settings'),
          ),
          const SizedBox(height: 24),
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
            title: "Legal & Licenses",
            children: [
              SettingsTile(
                icon: LucideIcons.fileText,
                title: "Terms & Conditions",
                subtitle: "Institutional terms and acceptable use policy",
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Terms & Conditions'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'Acadex Campus Management System is licensed for accredited institutional operations. '
                        'All academic data, student records, and attendance logs are governed by institutional policy '
                        'and applicable data privacy standards.',
                      ),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                  ),
                ),
              ),
              SettingsTile(
                icon: LucideIcons.shield,
                title: "Privacy Policy",
                subtitle: "Student and staff data protection principles",
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Privacy Policy'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'Acadex enforces strict multi-tenant isolation and role-based access control. '
                        'Personal data, profile images, and academic evaluations are restricted to authorized campus staff '
                        'and never shared across tenant boundaries.',
                      ),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                  ),
                ),
              ),
              SettingsTile(
                icon: LucideIcons.book,
                title: "Open Source Licenses",
                subtitle: "Third-party software libraries and dependencies",
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Acadex',
                  applicationVersion: '1.0.0 (Build 42)',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AcadexPageContainer(
      maxWidth: AcadexLayout.formMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcadexPageHeader(
            title: 'Help & Support',
            subtitle: 'Contact resources, FAQs, and incident reporting',
            onBack: () => context.safePop(fallbackRoute: '/settings'),
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: "Contact & Resources",
            children: [
              SettingsTile(
                icon: LucideIcons.helpCircle,
                title: "FAQs",
                subtitle: "Frequently asked questions",
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Frequently Asked Questions'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Q: How do I request class substitution?\nA: Faculty can initiate substitution requests through the Timetable Schedule view.\n', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Q: How do I export attendance registers?\nA: Department HODs and College Admins can download monthly attendance reports from the Attendance section.\n', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Q: Who do I contact for role upgrades?\nA: Please contact your designated College Administrator or Campus Super Admin.', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                  ),
                ),
              ),
              SettingsTile(
                icon: LucideIcons.mail,
                title: "Contact Support",
                subtitle: "support@acadex.edu",
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'support@acadex.edu'));
                  AcadexSnackBar.showSuccess(context, 'Support email (support@acadex.edu) copied to clipboard');
                },
              ),
              SettingsTile(
                icon: LucideIcons.bug,
                title: "Report an Issue",
                subtitle: "Submit bug report or error logs to the IT desk",
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'helpdesk@acadex.edu'));
                  AcadexSnackBar.showInfo(context, 'IT Helpdesk email copied to clipboard. Please forward your issue details.');
                },
              ),
              SettingsTile(
                icon: LucideIcons.messageSquare,
                title: "Campus Feedback",
                subtitle: "Share feedback with the administration",
                onTap: () => AcadexSnackBar.showInfo(context, 'Feedback portal opens during the end-of-semester evaluation period.'),
              ),
              SettingsTile(
                icon: LucideIcons.messageCircle,
                title: "Live Chat",
                subtitle: "Available for authorized staff during office hours",
                onTap: () => AcadexSnackBar.showInfo(context, 'Live chat desk is currently offline. Operating hours: Mon-Fri 9AM-5PM IST.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
