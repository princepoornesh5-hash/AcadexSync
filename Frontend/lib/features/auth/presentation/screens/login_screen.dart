import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';
import '../../../../core/presentation/widgets/animated_particle_sphere.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';
import '../providers/auth_provider.dart';

enum LoginStep {
  welcome, // Screen 1: Welcome / sign in with email address input & Continue
  passwordLogin, // Screen 2: Existing account login with password
  otpLogin, // Screen 2: Existing account login with dedicated email OTP code entry
}

class LoginScreen extends ConsumerStatefulWidget {
  final LoginStep initialStep;
  final String? initialEmail;

  const LoginScreen({
    super.key,
    this.initialStep = LoginStep.welcome,
    this.initialEmail,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late LoginStep _currentStep;

  final _welcomeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isRequestingOtp = false;
  String? _selectedDevRole;
  bool _showDevDrawer = false;
  String? _otpError;

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _identifierController.text = widget.initialEmail!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[LOGIN_VISIBLE]');
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownRemaining = 0);
      } else {
        setState(() => _cooldownRemaining--);
      }
    });
  }

  AppRole _mapStringToRole(String roleString) {
    switch (roleString) {
      case "Super Admin":
        return AppRole.superAdmin;
      case "College Admin":
        return AppRole.collegeAdmin;
      case "HOD":
        return AppRole.hod;
      case "Faculty":
        return AppRole.faculty;
      case "Student":
        return AppRole.student;
      default:
        return AppRole.student;
    }
  }

  void _navigateBasedOnRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        context.go('/dashboard/super_admin');
        break;
      case AppRole.collegeAdmin:
        context.go('/dashboard/college_admin');
        break;
      case AppRole.hod:
        context.go('/dashboard/hod');
        break;
      case AppRole.faculty:
        context.go('/dashboard/faculty');
        break;
      case AppRole.student:
        context.go('/dashboard/student');
        break;
    }
  }

  /// Screen 1 -> Screen 2 transition:
  /// Validates format without querying backend, never revealing if registered.
  void _handleContinue() {
    if (!_welcomeFormKey.currentState!.validate()) return;
    setState(() {
      _otpError = null;
      _currentStep = LoginStep.passwordLogin;
    });
  }

  Future<void> _handlePasswordLogin() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final email = _identifierController.text.trim();
    final password = _passwordController.text;

    await ref.read(authProvider.notifier).login(email, password);
  }

  Future<void> _switchToOtpLogin() async {
    final email = _identifierController.text.trim();
    if (email.isEmpty) {
      setState(() => _currentStep = LoginStep.welcome);
      return;
    }

    setState(() {
      _isRequestingOtp = true;
      _otpError = null;
      _currentStep = LoginStep.otpLogin;
    });

    try {
      await ref.read(authProvider.notifier).requestLoginOtp(email);
      if (!mounted) return;
      _startCooldown(60);
      setState(() => _isRequestingOtp = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRequestingOtp = false;
        _otpError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_cooldownRemaining > 0 || _isRequestingOtp) return;
    final email = _identifierController.text.trim();
    setState(() {
      _isRequestingOtp = true;
      _otpError = null;
    });

    try {
      await ref.read(authProvider.notifier).requestLoginOtp(email);
      if (!mounted) return;
      _startCooldown(60);
      setState(() => _isRequestingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A fresh verification code was sent to your email.'),
          backgroundColor: AcadexColors.info,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRequestingOtp = false;
        _otpError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleOtpLogin() async {
    if (!_otpFormKey.currentState!.validate()) return;
    final email = _identifierController.text.trim();
    final otp = _otpController.text.trim();

    setState(() => _otpError = null);
    try {
      await ref.read(authProvider.notifier).loginWithOtp(email, otp);
      // Auth state listener handles navigation
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpError =
            'Invalid or expired verification code. Please check and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _navigateBasedOnRole(next.user.role);
      } else if (next is AuthError) {
        final isPending =
            next.message.toLowerCase().contains('pending activation') ||
            next.message.toLowerCase().contains('activate your account') ||
            next.message.toLowerCase().contains('pending_activation');

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isPending
                      ? LucideIcons.alertTriangle
                      : LucideIcons.circleAlert,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(next.message)),
              ],
            ),
            backgroundColor: isPending
                ? AcadexColors.warningDark
                : AcadexColors.error,
            duration: isPending
                ? const Duration(seconds: 8)
                : const Duration(seconds: 4),
            action: isPending
                ? SnackBarAction(
                    label: 'Activate Now',
                    textColor: Colors.white,
                    onPressed: () => context.go('/activate'),
                  )
                : null,
          ),
        );
      }
    });

    final isLoading =
        authState is AuthLoading ||
        authState is AuthProfileLoading ||
        _isRequestingOtp;
    final loadingLabel = authState is AuthProfileLoading
        ? "Verifying Session..."
        : (_isRequestingOtp ? "Sending Code..." : "Signing in...");

    final isDesktop = AcadexBreakpoints.isDesktop(context);
    final isTablet = AcadexBreakpoints.isTablet(context);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.login,
        sphereAlignment: isDesktop
            ? const Alignment(-0.35, 0.0)
            : Alignment.center,
        intensityMultiplier: 0.88,
        child: SafeArea(
          child: isDesktop
              ? Row(
                  children: [
                    // Left Hero Showcase Section
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                          ),
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFF334155),
                              width: 1,
                            ),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 56,
                              vertical: 48,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 96 > 0
                                    ? constraints.maxHeight - 96
                                    : 0,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Brand Header
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AcadexColors.primary,
                                                Color(0xFF6366F1),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                AcadexRadius.borderRadiusMd,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AcadexColors.primary
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 14,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            LucideIcons.graduationCap,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          'ACADEXSYNC',
                                          style: AcadexTypography.heading1(
                                            color: Colors.white,
                                          ).copyWith(letterSpacing: -0.5),
                                        ),
                                      ],
                                    ),

                                    // Hero Highlights
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 32),
                                        Row(
                                          children: [
                                            const AcadexBadge(
                                              label: 'CAMPUS PLATFORM',
                                              variant:
                                                  AcadexBadgeVariant.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: AcadexColors.accentPink,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'SECURE ACCESS',
                                              style: AcadexTypography.eyebrow(
                                                color:
                                                    AcadexColors.accentYellow,
                                              ).copyWith(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'The unified academic operating system.',
                                          style:
                                              AcadexTypography.display2(
                                                color: Colors.white,
                                              ).copyWith(
                                                letterSpacing: -0.8,
                                                height: 1.2,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Verified attendance, intelligent scheduling, faculty records, curriculum distribution, and institutional analytics.',
                                          style: AcadexTypography.body(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                          ).copyWith(height: 1.5),
                                        ),
                                        const SizedBox(height: 28),

                                        const _FeaturePill(
                                          icon: LucideIcons.shieldCheck,
                                          title: 'Verified Authentication',
                                          subtitle:
                                              'Cryptographic email OTP & role-scoped tenant isolation',
                                        ),
                                        const SizedBox(height: 10),
                                        const _FeaturePill(
                                          icon: LucideIcons.calendar,
                                          title: 'Authoritative Timetables',
                                          subtitle:
                                              'Conflict-free multi-section and faculty schedules',
                                        ),
                                        const SizedBox(height: 10),
                                        const _FeaturePill(
                                          icon: LucideIcons.sparkles,
                                          title: 'Smart Academic Cloud',
                                          subtitle:
                                              'Seamless collaboration for students, faculty & leadership',
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),

                                    Text(
                                      '© 2026 ACADEXSYNC Platform. Multi-Tenant Campus System.',
                                      style: AcadexTypography.caption(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Form Area
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 32,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _buildFormContent(
                              context,
                              isDark,
                              isLoading,
                              loadingLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 48.0 : 16.0,
                      vertical: 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mobile Header
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AcadexColors.primary,
                                  Color(0xFF6366F1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: AcadexRadius.borderRadiusMd,
                              boxShadow: [
                                BoxShadow(
                                  color: AcadexColors.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.graduationCap,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ACADEXSYNC',
                            style: AcadexTypography.heading1(
                              color: isDark
                                  ? AcadexColors.darkInk
                                  : AcadexColors.ink,
                            ).copyWith(letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AcadexColors.accentPink,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Campus Operating System',
                                style: AcadexTypography.bodySmall(
                                  color: isDark
                                      ? AcadexColors.darkInkMuted
                                      : AcadexColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildFormContent(
                            context,
                            isDark,
                            isLoading,
                            loadingLabel,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context,
    bool isDark,
    bool isLoading,
    String loadingLabel,
  ) {
    final isMobile = AcadexBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AcadexCard(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 28,
            vertical: isMobile ? 24 : 30,
          ),
          backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
          borderColor: isDark
              ? AcadexColors.darkHairline
              : const Color(0xFFE2E8F0),
          borderRadius: AcadexRadius.borderRadiusLg,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildStepView(context, isDark, isLoading, loadingLabel),
          ),
        ),

        // Development Role Quick-Login Drawer in Debug Mode
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          _buildDevDrawer(context, isDark, isLoading),
        ],
      ],
    );
  }

  Widget _buildStepView(
    BuildContext context,
    bool isDark,
    bool isLoading,
    String loadingLabel,
  ) {
    switch (_currentStep) {
      case LoginStep.welcome:
        return _buildWelcomeStep(context, isDark, isLoading);
      case LoginStep.passwordLogin:
        return _buildPasswordStep(context, isDark, isLoading, loadingLabel);
      case LoginStep.otpLogin:
        return _buildOtpStep(context, isDark, isLoading);
    }
  }

  // ---------------------------------------------------------------------------
  // SCREEN 1: Welcome / Sign In
  // ---------------------------------------------------------------------------
  Widget _buildWelcomeStep(BuildContext context, bool isDark, bool isLoading) {
    return Form(
      key: _welcomeFormKey,
      child: Column(
        key: const ValueKey('step_welcome'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign In',
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(letterSpacing: -0.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to access your institutional dashboard.',
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Email input field
          Text(
            'Email Address',
            style: AcadexTypography.caption(
              color: isDark
                  ? AcadexColors.darkInkSecondary
                  : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('welcome_email_field'),
            controller: _identifierController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            decoration: InputDecoration(
              hintText: 'name@institution.edu or personal email',
              prefixIcon: Icon(
                LucideIcons.mail,
                size: 18,
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your email address';
              }
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(val.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleContinue(),
          ),
          const SizedBox(height: 24),

          // Continue button
          AcadexButton(
            key: const Key('welcome_continue_button'),
            label: 'Continue',
            icon: LucideIcons.arrowRight,
            isLoading: isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: isLoading ? null : _handleContinue,
          ),
          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : const Color(0xFFE2E8F0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: AcadexTypography.caption(
                    color: isDark
                        ? AcadexColors.darkInkFaint
                        : AcadexColors.inkFaint,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Create an account link
          OutlinedButton.icon(
            key: const Key('link_create_account'),
            onPressed: isLoading ? null : () => context.go('/register'),
            icon: const Icon(LucideIcons.userPlus, size: 16),
            label: const Text('Create an Account'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AcadexColors.primary,
              side: BorderSide(
                color: AcadexColors.primary.withValues(alpha: 0.4),
              ),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Activate institutional account link
          TextButton.icon(
            key: const Key('link_activate_account'),
            onPressed: isLoading ? null : () => context.go('/activate'),
            icon: const Icon(
              LucideIcons.shieldCheck,
              size: 16,
              color: AcadexColors.accentPink,
            ),
            label: Text.rich(
              TextSpan(
                text: 'Have an invitation code? ',
                style: AcadexTypography.caption(
                  color: isDark
                      ? AcadexColors.darkInkSecondary
                      : AcadexColors.inkSecondary,
                ),
                children: [
                  TextSpan(
                    text: 'Activate Account',
                    style: AcadexTypography.caption(color: AcadexColors.primary)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 2A: Password Login
  // ---------------------------------------------------------------------------
  Widget _buildPasswordStep(
    BuildContext context,
    bool isDark,
    bool isLoading,
    String loadingLabel,
  ) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey('step_password'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected email chip with change button
          _buildEmailHeaderChip(isDark),
          const SizedBox(height: 20),

          Text(
            'Welcome Back',
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(letterSpacing: -0.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your password to sign in.',
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Password field & Forgot password link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password',
                style: AcadexTypography.caption(
                  color: isDark
                      ? AcadexColors.darkInkSecondary
                      : AcadexColors.inkSecondary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              InkWell(
                key: const Key('forgot_password_button'),
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
          TextFormField(
            key: const Key('login_password_field'),
            controller: _passwordController,
            enabled: !isLoading,
            obscureText: !_isPasswordVisible,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(
                LucideIcons.lock,
                size: 18,
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: isDark
                      ? AcadexColors.darkInkMuted
                      : AcadexColors.inkMuted,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handlePasswordLogin(),
          ),
          const SizedBox(height: 24),

          // Sign In button
          AcadexButton(
            key: const Key('password_sign_in_button'),
            label: isLoading ? loadingLabel : 'Sign In',
            icon: LucideIcons.logIn,
            isLoading: isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: isLoading ? null : _handlePasswordLogin,
          ),
          const SizedBox(height: 16),

          // Login with OTP option
          OutlinedButton.icon(
            key: const Key('switch_to_otp_button'),
            onPressed: isLoading ? null : _switchToOtpLogin,
            icon: const Icon(LucideIcons.sparkles, size: 16),
            label: const Text('Sign In with Email Code (OTP)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AcadexColors.primary,
              side: BorderSide(
                color: AcadexColors.primary.withValues(alpha: 0.35),
              ),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 2B: Login with Email OTP (Dedicated Code-Entry View)
  // ---------------------------------------------------------------------------
  Widget _buildOtpStep(BuildContext context, bool isDark, bool isLoading) {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey('step_otp'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEmailHeaderChip(isDark),
          const SizedBox(height: 20),

          Text(
            'Verification Code',
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(letterSpacing: -0.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-digit code sent to ${_identifierController.text.trim()}.',
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),

          if (_otpError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AcadexColors.errorLight.withValues(
                  alpha: isDark ? 0.2 : 0.8,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AcadexColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.circleAlert,
                    size: 16,
                    color: AcadexColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _otpError!,
                      style: AcadexTypography.caption(
                        color: isDark
                            ? const Color(0xFFFCA5A5)
                            : AcadexColors.errorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 6-digit code entry field
          Text(
            'Enter 6-digit Code',
            style: AcadexTypography.caption(
              color: isDark
                  ? AcadexColors.darkInkSecondary
                  : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('otp_code_field'),
            controller: _otpController,
            enabled: !isLoading,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '123456',
              counterText: '',
              prefixIcon: Icon(
                LucideIcons.keyRound,
                size: 18,
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().length != 6) {
                return 'Please enter all 6 digits of the code';
              }
              if (!RegExp(r'^\d{6}$').hasMatch(val.trim())) {
                return 'Code must contain digits only';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleOtpLogin(),
          ),
          const SizedBox(height: 16),

          // Cooldown and resend button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _cooldownRemaining > 0
                    ? 'Resend in ${_cooldownRemaining}s'
                    : 'Didn\'t get a code?',
                style: AcadexTypography.caption(
                  color: isDark
                      ? AcadexColors.darkInkMuted
                      : AcadexColors.inkMuted,
                ),
              ),
              TextButton(
                key: const Key('resend_otp_button'),
                onPressed: (_cooldownRemaining > 0 || isLoading)
                    ? null
                    : _handleResendOtp,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  'Resend Code',
                  style: AcadexTypography.caption(
                    color: _cooldownRemaining > 0
                        ? (isDark
                              ? AcadexColors.darkInkFaint
                              : AcadexColors.inkFaint)
                        : AcadexColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Verify & Sign In
          AcadexButton(
            key: const Key('otp_sign_in_button'),
            label: isLoading ? 'Verifying...' : 'Verify & Sign In',
            icon: LucideIcons.shieldCheck,
            isLoading: isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: isLoading ? null : _handleOtpLogin,
          ),
          const SizedBox(height: 16),

          // Switch back to password
          Center(
            child: TextButton.icon(
              key: const Key('switch_to_password_button'),
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() {
                        _otpError = null;
                        _currentStep = LoginStep.passwordLogin;
                      });
                    },
              icon: const Icon(LucideIcons.lock, size: 15),
              label: Text(
                'Use Password Instead',
                style: AcadexTypography.caption(
                  color: AcadexColors.primary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact chip showing entered email with a Change button
  Widget _buildEmailHeaderChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.mail, size: 16, color: AcadexColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _identifierController.text.trim(),
              style: AcadexTypography.bodySmall(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            key: const Key('change_email_button'),
            onTap: () {
              setState(() {
                _otpError = null;
                _currentStep = LoginStep.welcome;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Change',
                style: AcadexTypography.caption(
                  color: AcadexColors.primary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Development Role Quick-Login (Collapsed in kDebugMode)
  // ---------------------------------------------------------------------------
  Widget _buildDevDrawer(BuildContext context, bool isDark, bool isLoading) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _showDevDrawer,
        onExpansionChanged: (exp) => setState(() => _showDevDrawer = exp),
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            const Icon(
              LucideIcons.code2,
              size: 13,
              color: AcadexColors.warning,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'DEVELOPMENT ROLE QUICK-LOGIN',
                style: AcadexTypography.eyebrow(
                  color: AcadexColors.warning,
                ).copyWith(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        children: [
          AcadexCard(
            backgroundColor: isDark
                ? AcadexColors.warningDarkContainer.withValues(alpha: 0.20)
                : AcadexColors.warningLight.withValues(alpha: 0.60),
            borderColor: isDark
                ? AcadexColors.warningDark
                : AcadexColors.warning.withValues(alpha: 0.25),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Server: ${ApiClient.defaultBaseUrl}',
                    style: AcadexTypography.caption(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ).copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AcadexDropdown<String>(
                  value: _selectedDevRole,
                  hint: 'Select Test Role',
                  prefixIcon: LucideIcons.userCheck,
                  items: const [
                    DropdownMenuItem(
                      value: "Super Admin",
                      child: Text("Super Admin"),
                    ),
                    DropdownMenuItem(
                      value: "College Admin",
                      child: Text("College Admin"),
                    ),
                    DropdownMenuItem(value: "HOD", child: Text("HOD")),
                    DropdownMenuItem(value: "Faculty", child: Text("Faculty")),
                    DropdownMenuItem(value: "Student", child: Text("Student")),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedDevRole = val;
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
                const SizedBox(height: 8),
                AcadexButton(
                  label: _selectedDevRole == null
                      ? "Sign In as Role..."
                      : "Sign In as $_selectedDevRole",
                  variant: AcadexButtonVariant.secondary,
                  icon: LucideIcons.play,
                  size: AcadexButtonSize.sm,
                  onPressed: (isLoading || _selectedDevRole == null)
                      ? null
                      : () {
                          ref
                              .read(authProvider.notifier)
                              .loginAsDevelopmentRole(
                                _mapStringToRole(_selectedDevRole!),
                              );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact supporting feature pill row with tight spacing and clean alignment.
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.65),
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.60),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: AcadexRadius.borderRadiusSm,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AcadexTypography.body(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AcadexTypography.caption(
                    color: Colors.white.withValues(alpha: 0.72),
                  ).copyWith(fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
