import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';
import '../../../../core/presentation/widgets/animated_particle_sphere.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final int initialStep;
  final String? initialIdentifier;
  final String? initialResetToken;

  const ForgotPasswordScreen({
    super.key,
    this.initialStep = 0,
    this.initialIdentifier,
    this.initialResetToken,
  });

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Request OTP, 1: Verify OTP, 2: Reset Password, 3: Success
  bool _isLoading = false;
  String? _errorMessage;
  String? _resetToken;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Timer? _expiryTimer;
  Timer? _resendTimer;
  int _expirySeconds = 300;
  int _resendCooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (widget.initialIdentifier != null) {
      _identifierController.text = widget.initialIdentifier!;
    }
    if (widget.initialResetToken != null) {
      _resetToken = widget.initialResetToken;
    }
    if (_currentStep == 1) {
      _startTimers();
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimers() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();

    _expirySeconds = 300;
    _resendCooldownSeconds = 60;

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expirySeconds > 0) {
        if (mounted) setState(() => _expirySeconds--);
      } else {
        timer.cancel();
      }
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds > 0) {
        if (mounted) setState(() => _resendCooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _handleRequestOtp() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      await authRepo.sendPasswordResetEmail(_identifierController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 1;
        });
        _startTimers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_step2FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      final token = await authRepo.verifyPasswordResetOtp(
        identifier: _identifierController.text.trim(),
        otpCode: _otpController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetToken = token;
          _currentStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCooldownSeconds > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      await authRepo.sendPasswordResetEmail(_identifierController.text.trim());
      if (mounted) {
        setState(() => _isLoading = false);
        _startTimers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A fresh verification code has been dispatched.'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_step3FormKey.currentState!.validate()) return;

    if (_resetToken == null || _resetToken!.isEmpty) {
      setState(() => _errorMessage = "Missing authorization reset token. Please request a new code.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      await authRepo.resetPassword(
        resetToken: _resetToken!,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 3;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.login,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back navigation
                    if (_currentStep < 3) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(LucideIcons.arrowLeft, size: 16),
                          label: Text(_currentStep == 0 ? 'Back to Sign In' : 'Back'),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                          onPressed: () {
                            if (_currentStep == 0) {
                              context.go('/login');
                            } else {
                              setState(() {
                                _currentStep--;
                                _errorMessage = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    AcadexCard(
                      padding: const EdgeInsets.all(28),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _currentStep == 0
                            ? _buildStep1Identifier(isDark)
                            : _currentStep == 1
                                ? _buildStep2Otp(isDark)
                                : _currentStep == 2
                                    ? _buildStep3NewPassword(isDark)
                                    : _buildStep4Success(isDark),
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

  Widget _buildStepIndicator(int step, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'STEP ${step + 1} OF 3',
                  style: AcadexTypography.eyebrow(color: AcadexColors.primary),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(active: true, completed: step > 0),
                  const SizedBox(width: 6),
                  _buildDot(active: step >= 1, completed: step > 1),
                  const SizedBox(width: 6),
                  _buildDot(active: step >= 2, completed: step > 2),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (step + 1) / 3.0,
              backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              valueColor: const AlwaysStoppedAnimation<Color>(AcadexColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool active, required bool completed}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: completed
            ? AcadexColors.success
            : active
                ? AcadexColors.primary
                : AcadexColors.hairline,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStep1Identifier(bool isDark) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step1_identifier'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(0, isDark),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.keyRound, size: 28, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Forgot your password?",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter your registered email or phone to receive a verification code.",
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!, isDark),
            const SizedBox(height: 16),
          ],

          AcadexTextField(
            controller: _identifierController,
            label: "Email or Phone Number",
            hint: "name@acadex.edu or +1234567890",
            prefixIcon: LucideIcons.user,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Please enter your email or phone number";
              return null;
            },
          ),
          const SizedBox(height: 24),

          AcadexButton(
            label: _isLoading ? "Sending Code..." : "Send Verification Code",
            icon: LucideIcons.send,
            isLoading: _isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _isLoading ? null : _handleRequestOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Otp(bool isDark) {
    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey('step2_otp'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(1, isDark),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.mailCheck, size: 28, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Enter Verification Code",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter the 6-digit code sent to ${_identifierController.text}",
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!, isDark),
            const SizedBox(height: 16),
          ],

          AcadexTextField(
            controller: _otpController,
            label: "Verification Code",
            hint: "123456",
            prefixIcon: LucideIcons.key,
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Please enter the verification code";
              if (v.trim().length < 6) return "Please enter the complete 6-digit code";
              return null;
            },
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
              borderRadius: AcadexRadius.borderRadiusSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: _expirySeconds <= 60 ? AcadexColors.error : AcadexColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  "Code expires in: ${_formatTime(_expirySeconds)}",
                  style: AcadexTypography.caption(
                    color: _expirySeconds <= 60
                        ? AcadexColors.error
                        : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          AcadexButton(
            label: _isLoading ? "Verifying..." : "Verify Code",
            icon: LucideIcons.check,
            isLoading: _isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _isLoading ? null : _handleVerifyOtp,
          ),
          const SizedBox(height: 14),

          Center(
            child: TextButton.icon(
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: Text(
                _resendCooldownSeconds > 0
                    ? "Resend Code in ${_resendCooldownSeconds}s"
                    : "Resend Code",
              ),
              style: TextButton.styleFrom(
                foregroundColor: _resendCooldownSeconds > 0
                    ? (isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint)
                    : AcadexColors.primary,
              ),
              onPressed: (_resendCooldownSeconds > 0 || _isLoading) ? null : _handleResendOtp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3NewPassword(bool isDark) {
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final hasMinLength = password.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final isMatching = password.isNotEmpty && password == confirmPassword;

    return Form(
      key: _step3FormKey,
      child: Column(
        key: const ValueKey('step3_new_password'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(2, isDark),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldCheck, size: 28, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Set New Password",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Create a new password to restore full access to your account.",
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),

          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!, isDark),
            const SizedBox(height: 16),
          ],

          Text(
            'New Password',
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            enabled: !_isLoading,
            obscureText: !_isPasswordVisible,
            onChanged: (v) => setState(() {}),
            style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(
                LucideIcons.lock,
                size: 18,
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return "Please enter a new password";
              if (v.length < 8) return "Password must be at least 8 characters";
              return null;
            },
          ),
          const SizedBox(height: 16),

          Text(
            'Confirm Password',
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_isLoading,
            obscureText: !_isConfirmPasswordVisible,
            onChanged: (v) => setState(() {}),
            style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(
                LucideIcons.lock,
                size: 18,
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return "Please confirm your new password";
              if (v != _newPasswordController.text) return "Passwords do not match";
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Requirements Checklist
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements:',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildRequirementItem('At least 8 characters', hasMinLength, isDark),
                const SizedBox(height: 4),
                _buildRequirementItem('Contains at least one letter', hasLetter, isDark),
                const SizedBox(height: 4),
                _buildRequirementItem('Contains at least one number', hasNumber, isDark),
                const SizedBox(height: 4),
                _buildRequirementItem('Passwords match', isMatching, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),

          AcadexButton(
            label: _isLoading ? "Updating..." : "Reset Password",
            icon: LucideIcons.checkCircle,
            isLoading: _isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _isLoading ? null : _handleResetPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Success(bool isDark) {
    return Column(
      key: const ValueKey('step4_success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AcadexColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCircle2, size: 36, color: AcadexColors.success),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Password Reset Successful",
          textAlign: TextAlign.center,
          style: AcadexTypography.heading1(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your password has been successfully updated. You can now sign in with your new credentials.",
          textAlign: TextAlign.center,
          style: AcadexTypography.bodySmall(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 28),
        AcadexButton(
          label: "Sign In to ACADEX",
          icon: LucideIcons.logIn,
          isFullWidth: true,
          size: AcadexButtonSize.lg,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet, bool isDark) {
    return Row(
      children: [
        Icon(
          isMet ? LucideIcons.check : LucideIcons.circle,
          size: 14,
          color: isMet
              ? AcadexColors.success
              : (isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AcadexTypography.caption(
              color: isMet
                  ? (isDark ? AcadexColors.darkInk : AcadexColors.ink)
                  : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: AcadexColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleAlert, size: 16, color: AcadexColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AcadexTypography.caption(
                color: isDark ? Colors.white : AcadexColors.errorDark,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
