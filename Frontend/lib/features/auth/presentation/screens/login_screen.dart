import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/animated_particle_sphere.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _selectedRole;

  AppRole _mapStringToRole(String roleString) {
    switch (roleString) {
      case "Super Admin": return AppRole.superAdmin;
      case "College Admin": return AppRole.collegeAdmin;
      case "HOD": return AppRole.hod;
      case "Faculty": return AppRole.faculty;
      case "Student": return AppRole.student;
      default: return AppRole.student;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _identifierController.text.trim(),
      _passwordController.text,
    );
  }

  void _navigateBasedOnRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin: context.go('/dashboard/super_admin'); break;
      case AppRole.collegeAdmin: context.go('/dashboard/college_admin'); break;
      case AppRole.hod: context.go('/dashboard/hod'); break;
      case AppRole.faculty: context.go('/dashboard/faculty'); break;
      case AppRole.student: context.go('/dashboard/student'); break;
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _navigateBasedOnRole(next.user.role);
      } else if (next is AuthError) {
        final isPendingActivation = next.message.toLowerCase().contains('pending activation') ||
            next.message.toLowerCase().contains('activate your account');
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: isPendingActivation ? AcadexColors.warning : AcadexColors.error,
            duration: isPendingActivation ? const Duration(seconds: 8) : const Duration(seconds: 4),
            action: isPendingActivation
                ? SnackBarAction(
                    label: 'Activate Now',
                    textColor: Colors.white,
                    onPressed: () => context.go('/activate'),
                  )
                : null,
          ),
        );
      } else if (next is AuthProfileError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AcadexColors.warning,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Logout',
              textColor: Colors.white,
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
        );
      }
    });

    final isLoading = authState is AuthLoading || authState is AuthProfileLoading;
    final loadingMessage = authState is AuthProfileLoading ? "Loading Profile..." : "Sign In";

    final width = MediaQuery.of(context).size.width;
    final isSplitView = width >= 900;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.login,
        sphereAlignment: isSplitView ? const Alignment(-0.35, 0.0) : Alignment.center,
        child: SafeArea(
          child: isSplitView
              ? Row(
                  children: [
                    // Left Branded Hero Section
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0F172A).withValues(alpha: 0.40),
                              const Color(0xFF1E1B4B).withValues(alpha: 0.25),
                            ],
                          ),
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                        ),
                      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Brand Header
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: AcadexRadius.borderRadiusMd,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Acadex',
                                style: AcadexTypography.heading1(color: Colors.white),
                              ),
                            ],
                          ),

                          // Hero Value Prop
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AcadexBadge(
                                label: 'CAMPUS OPERATING SYSTEM',
                                variant: AcadexBadgeVariant.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'The modern platform for academic excellence.',
                                style: AcadexTypography.display2(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Streamline attendance, timetable scheduling, faculty workflows, notes distribution, and student analytics across your entire institution.',
                                style: AcadexTypography.body(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Feature Highlights
                              _FeaturePill(
                                icon: LucideIcons.clipboardCheck,
                                title: 'One-Tap Attendance Marking',
                                subtitle: 'Instant session logging and student verification',
                              ),
                              const SizedBox(height: 14),
                              _FeaturePill(
                                icon: LucideIcons.calendar,
                                title: 'Smart Academic Timetable',
                                subtitle: 'Automated conflict detection and room schedules',
                              ),
                              const SizedBox(height: 14),
                              _FeaturePill(
                                icon: LucideIcons.bot,
                                title: 'AI-Powered Campus Assistant',
                                subtitle: 'Instant answers for curriculum and scheduling queries',
                              ),
                            ],
                          ),

                          // Footer Note
                          Text(
                            '© 2026 Acadex Platform. Secure Multi-Tenant Architecture.',
                            style: AcadexTypography.caption(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Form Area
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _buildLoginForm(context, isDark, isLoading, loadingMessage),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mobile Header
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AcadexColors.primary,
                            borderRadius: AcadexRadius.borderRadiusMd,
                          ),
                          child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Acadex',
                          style: AcadexTypography.heading1(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to your campus account',
                          style: AcadexTypography.bodySmall(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildLoginForm(context, isDark, isLoading, loadingMessage),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    bool isDark,
    bool isLoading,
    String loadingMessage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcadexCard(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome Back',
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your credentials to access your dashboard.',
                  style: AcadexTypography.bodySmall(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 24),

                // Identifier (Email or Phone)
                AcadexTextField(
                  controller: _identifierController,
                  label: 'Email or Phone Number',
                  hint: 'user@acadex.edu or +1234567890',
                  prefixIcon: LucideIcons.user,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Please enter your email or phone number";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    InkWell(
                      onTap: isLoading ? null : () => context.go('/forgot-password'),
                      child: Text(
                        'Forgot password?',
                        style: AcadexTypography.caption(
                          color: AcadexColors.primary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AcadexTextField(
                  controller: _passwordController,
                  hint: '••••••••',
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  enabled: !isLoading,
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Please enter your password";
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                AcadexButton(
                  label: loadingMessage,
                  icon: LucideIcons.logIn,
                  isLoading: isLoading,
                  isFullWidth: true,
                  size: AcadexButtonSize.lg,
                  onPressed: isLoading ? null : _handleLogin,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Account Activation Link
        Center(
          child: TextButton(
            onPressed: () => context.go('/activate'),
            child: Text(
              'New student or faculty? Activate Account',
              style: AcadexTypography.bodySmall(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
          ),
        ),

        // Development Test Mode (Debug Only)
        if (kDebugMode) ...[
          const SizedBox(height: 24),
          AcadexCard(
            backgroundColor: isDark
                ? AcadexColors.warningDarkContainer.withValues(alpha: 0.3)
                : AcadexColors.warningLight,
            borderColor: isDark ? AcadexColors.warningDark : AcadexColors.warning.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.code2, size: 16, color: AcadexColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'DEVELOPMENT TEST SANDBOX',
                      style: AcadexTypography.eyebrow(color: AcadexColors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AcadexDropdown<String>(
                  value: _selectedRole,
                  hint: 'Select Test Role',
                  prefixIcon: LucideIcons.userCheck,
                  items: const [
                    DropdownMenuItem(value: "Super Admin", child: Text("Super Admin")),
                    DropdownMenuItem(value: "College Admin", child: Text("College Admin")),
                    DropdownMenuItem(value: "HOD", child: Text("HOD")),
                    DropdownMenuItem(value: "Faculty", child: Text("Faculty")),
                    DropdownMenuItem(value: "Student", child: Text("Student")),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedRole = val;
                      switch (val) {
                        case "Super Admin":
                          _identifierController.text = "admin@acadex.com";
                          _passwordController.text = "acadex123";
                          break;
                        case "College Admin":
                          _identifierController.text = "college@acadex.com";
                          _passwordController.text = "acadex123";
                          break;
                        case "HOD":
                          _identifierController.text = "hod@acadex.com";
                          _passwordController.text = "acadex123";
                          break;
                        case "Faculty":
                          _identifierController.text = "faculty@acadex.com";
                          _passwordController.text = "acadex123";
                          break;
                        case "Student":
                          _identifierController.text = "student@acadex.com";
                          _passwordController.text = "acadex123";
                          break;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                AcadexButton(
                  label: _selectedRole == null ? "Sign In as Role..." : "Sign In as $_selectedRole",
                  variant: AcadexButtonVariant.secondary,
                  icon: LucideIcons.play,
                  onPressed: (isLoading || _selectedRole == null)
                      ? null
                      : () {
                          ref.read(authProvider.notifier).loginAsDevelopmentRole(
                            _mapStringToRole(_selectedRole!),
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeaturePill({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: AcadexRadius.borderRadiusMd,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AcadexTypography.body(color: Colors.white).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AcadexTypography.caption(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
