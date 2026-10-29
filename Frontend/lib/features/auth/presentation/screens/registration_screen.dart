import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_logo.dart';
import '../../../../core/presentation/widgets/animated_particle_sphere.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';
import '../providers/auth_provider.dart';
import '../widgets/terms_acceptance_checkbox.dart';

enum RegistrationStep {
  enterDetails, // Step 1: Full name and email address
  verifyOtp, // Step 2: 6-digit email OTP verification
  setPassword, // Step 3: Password & confirm password
}

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  RegistrationStep _currentStep = RegistrationStep.enterDetails;

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;
  bool _acceptedTerms = false;
  String? _registrationToken;
  String? _stepError;

  Timer? _cooldownTimer;
  int _cooldownSecondsRemaining = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSecondsRemaining = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownSecondsRemaining = 0);
      } else {
        setState(() => _cooldownSecondsRemaining--);
      }
    });
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

  Future<void> _handleRequestOtp() async {
    setState(() => _stepError = null);
    if (!_step1FormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      await ref.read(authProvider.notifier).requestRegistrationOtp(email);
      if (!mounted) return;
      _startCooldown(60);
      setState(() {
        _isSubmitting = false;
        _currentStep = RegistrationStep.verifyOtp;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _stepError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_cooldownSecondsRemaining > 0 || _isSubmitting) return;
    setState(() => _stepError = null);
    final email = _emailController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      await ref.read(authProvider.notifier).requestRegistrationOtp(email);
      if (!mounted) return;
      _startCooldown(60);
      setState(() => _isSubmitting = false);
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
        _isSubmitting = false;
        _stepError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() => _stepError = null);
    if (!_step2FormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      final token = await ref
          .read(authProvider.notifier)
          .verifyRegistrationOtp(email: email, otp: otp);
      if (!mounted) return;
      setState(() {
        _registrationToken = token;
        _isSubmitting = false;
        _currentStep = RegistrationStep.setPassword;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _stepError = 'Invalid or expired verification code. Please try again.';
      });
    }
  }

  Future<void> _handleCompleteRegistration() async {
    setState(() => _stepError = null);
    if (!_step3FormKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() {
        _stepError =
            'Please review and accept the Terms & Conditions and Privacy Policy to proceed.';
      });
      return;
    }
    if (_registrationToken == null) {
      setState(() {
        _stepError = 'Verification expired. Please restart the process.';
        _currentStep = RegistrationStep.enterDetails;
      });
      return;
    }

    setState(() => _isSubmitting = true);
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    try {
      await ref
          .read(authProvider.notifier)
          .completeRegistration(
            registrationToken: _registrationToken!,
            password: password,
            confirmPassword: confirmPassword,
            name: name.isNotEmpty ? name : null,
            termsAccepted: true,
            termsVersion: '2026.1-draft',
          );
      // Auth state listener handles navigation
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _stepError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = AcadexBreakpoints.isDesktop(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _navigateBasedOnRole(next.user.role);
      } else if (next is AuthError) {
        setState(() {
          _isSubmitting = false;
          _stepError = next.message;
        });
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.login,
        sphereAlignment: isDesktop
            ? const Alignment(-0.35, 0.0)
            : Alignment.center,
        intensityMultiplier: 0.88,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 32.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo & Title
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AcadexLogo(size: 44),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACADEXSYNC',
                                style: AcadexTypography.heading2(
                                  color: isDark
                                      ? AcadexColors.darkInk
                                      : AcadexColors.ink,
                                ).copyWith(letterSpacing: -0.5),
                              ),
                              Row(
                                children: [
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
                                    'CAMPUS REGISTRATION',
                                    style: AcadexTypography.eyebrow(
                                      color: isDark
                                          ? AcadexColors.darkInkMuted
                                          : AcadexColors.inkMuted,
                                    ).copyWith(fontSize: 9.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Form Card
                    AcadexCard(
                      padding: EdgeInsets.all(isMobile ? 20 : 28),
                      backgroundColor: isDark
                          ? AcadexColors.darkSurface
                          : Colors.white,
                      borderColor: isDark
                          ? AcadexColors.darkHairline
                          : const Color(0xFFE2E8F0),
                      borderRadius: AcadexRadius.borderRadiusLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStepIndicator(isDark),
                          const SizedBox(height: 20),
                          if (_stepError != null) ...[
                            _buildErrorBanner(_stepError!, isDark),
                            const SizedBox(height: 16),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildCurrentStepContent(isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back to Sign In Link
                    TextButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go('/login'),
                      icon: const Icon(LucideIcons.arrowLeft, size: 16),
                      label: Text(
                        'Already have an account? Sign In',
                        style: AcadexTypography.bodySmall(
                          color: AcadexColors.primary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildStepIndicator(bool isDark) {
    final stepNum = _currentStep.index + 1;
    const totalSteps = 3;

    String stepTitle;
    switch (_currentStep) {
      case RegistrationStep.enterDetails:
        stepTitle = 'Your Information';
        break;
      case RegistrationStep.verifyOtp:
        stepTitle = 'Email Verification';
        break;
      case RegistrationStep.setPassword:
        stepTitle = 'Security Setup';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'STEP $stepNum OF $totalSteps',
                    style: AcadexTypography.caption(
                      color: AcadexColors.primary,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AcadexColors.accentYellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                stepTitle,
                overflow: TextOverflow.ellipsis,
                style: AcadexTypography.caption(
                  color: isDark
                      ? AcadexColors.darkInkSecondary
                      : AcadexColors.inkSecondary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stepNum / totalSteps,
            backgroundColor: isDark
                ? AcadexColors.darkCanvasSoft
                : AcadexColors.canvasSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AcadexColors.primary,
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AcadexColors.errorLight.withValues(alpha: isDark ? 0.2 : 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AcadexColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 18,
            color: AcadexColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AcadexTypography.caption(
                color: isDark
                    ? const Color(0xFFFCA5A5)
                    : AcadexColors.errorDark,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case RegistrationStep.enterDetails:
        return _buildStep1Details(isDark);
      case RegistrationStep.verifyOtp:
        return _buildStep2Otp(isDark);
      case RegistrationStep.setPassword:
        return _buildStep3Password(isDark);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Full Name & Email
  // ---------------------------------------------------------------------------
  Widget _buildStep1Details(bool isDark) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('reg_step_1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Account',
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(letterSpacing: -0.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your full name and email address to receive a verification code.',
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Full Name
          Text(
            'Full Name',
            style: AcadexTypography.caption(
              color: isDark
                  ? AcadexColors.darkInkSecondary
                  : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('reg_name_field'),
            controller: _nameController,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Alex Morgan',
              prefixIcon: Icon(
                LucideIcons.user,
                size: 18,
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email Address
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
            key: const Key('reg_email_field'),
            controller: _emailController,
            enabled: !_isSubmitting,
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
          ),
          const SizedBox(height: 24),

          AcadexButton(
            key: const Key('reg_request_otp_button'),
            label: _isSubmitting ? 'Sending Code...' : 'Send Verification Code',
            icon: LucideIcons.send,
            isLoading: _isSubmitting,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _isSubmitting ? null : _handleRequestOtp,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Email OTP Verification
  // ---------------------------------------------------------------------------
  Widget _buildStep2Otp(bool isDark) {
    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey('reg_step_2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _stepError = null;
                          _currentStep = RegistrationStep.enterDetails;
                        });
                      },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verify Your Email',
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(letterSpacing: -0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit verification code to ${_emailController.text.trim()}.',
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Verification Code',
            style: AcadexTypography.caption(
              color: isDark
                  ? AcadexColors.darkInkSecondary
                  : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('reg_otp_field'),
            controller: _otpController,
            enabled: !_isSubmitting,
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
                LucideIcons.shieldCheck,
                size: 18,
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().length != 6) {
                return 'Enter the complete 6-digit code';
              }
              if (!RegExp(r'^\d{6}$').hasMatch(val.trim())) {
                return 'Code must contain only digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Cooldown and Resend Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _cooldownSecondsRemaining > 0
                      ? 'Resend available in ${_cooldownSecondsRemaining}s'
                      : 'Didn\'t receive code?',
                  style: AcadexTypography.caption(
                    color: isDark
                        ? AcadexColors.darkInkMuted
                        : AcadexColors.inkMuted,
                  ),
                ),
              ),
              TextButton(
                key: const Key('reg_resend_otp_button'),
                onPressed: (_cooldownSecondsRemaining > 0 || _isSubmitting)
                    ? null
                    : _handleResendOtp,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  'Resend Code',
                  style: AcadexTypography.caption(
                    color: _cooldownSecondsRemaining > 0
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

          AcadexButton(
            key: const Key('reg_verify_otp_button'),
            label: _isSubmitting ? 'Verifying...' : 'Verify Code',
            icon: LucideIcons.checkCheck,
            isLoading: _isSubmitting,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _isSubmitting ? null : _handleVerifyOtp,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Password & Confirm Password
  // ---------------------------------------------------------------------------
  Widget _buildStep3Password(bool isDark) {
    return Form(
      key: _step3FormKey,
      child: Column(
        key: const ValueKey('reg_step_3'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _stepError = null;
                          _currentStep = RegistrationStep.verifyOtp;
                        });
                      },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Secure Your Account',
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(letterSpacing: -0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Create a password with at least 8 characters to complete registration.',
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Password Field
          Text(
            'Password',
            style: AcadexTypography.caption(
              color: isDark
                  ? AcadexColors.darkInkSecondary
                  : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('reg_password_field'),
            controller: _passwordController,
            enabled: !_isSubmitting,
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
                return 'Please enter a password';
              }
              if (val.length < 8) {
                return 'Password must be at least 8 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          Text(
            'Confirm Password',
            style: AcadexTypography.caption(
              color: isDark
                  ? AcadexColors.darkInkSecondary
                  : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('reg_confirm_password_field'),
            controller: _confirmPasswordController,
            enabled: !_isSubmitting,
            obscureText: !_isConfirmPasswordVisible,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(
                LucideIcons.lockKeyhole,
                size: 18,
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? LucideIcons.eyeOff
                      : LucideIcons.eye,
                  size: 18,
                  color: isDark
                      ? AcadexColors.darkInkMuted
                      : AcadexColors.inkMuted,
                ),
                onPressed: () {
                  setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  );
                },
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please confirm your password';
              }
              if (val != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TermsAcceptanceCheckbox(
            value: _acceptedTerms,
            enabled: !_isSubmitting,
            onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
          ),
          const SizedBox(height: 20),

          AcadexButton(
            key: const Key('reg_complete_button'),
            label: _isSubmitting
                ? 'Creating Account...'
                : 'Complete Registration',
            icon: LucideIcons.userPlus,
            isLoading: _isSubmitting,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: (_isSubmitting || !_acceptedTerms)
                ? null
                : _handleCompleteRegistration,
          ),
        ],
      ),
    );
  }
}
