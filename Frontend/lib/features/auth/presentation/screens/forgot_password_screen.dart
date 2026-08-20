import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  int _step = 0; // 0: email, 1: OTP, 2: new password, 3: success
  String? _resetToken;
  String? _errorMessage;

  void _handleRequestOtp() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      await authRepo.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        setState(() { _isLoading = false; _step = 1; });
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

  void _handleVerifyOtp() async {
    if (!_step2FormKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      final resetToken = await authRepo.verifyPasswordResetOtp(
        identifier: _emailController.text.trim(),
        otpCode: _otpController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 2;
          _resetToken = resetToken;
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

  void _handleResetPassword() async {
    if (!_step3FormKey.currentState!.validate()) return;
    if (_resetToken == null) {
      setState(() { _errorMessage = "Missing reset token. Please restart the process."; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      await authRepo.resetPassword(
        resetToken: _resetToken!,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        setState(() { _isLoading = false; _step = 3; });
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
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: _step == 3
            ? null
            : IconButton(
                icon: Icon(
                  LucideIcons.arrowLeft,
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
                onPressed: () {
                  if (_step > 0 && _step < 3) {
                    setState(() { _step = _step - 1; _errorMessage = null; });
                  } else {
                    context.go('/login');
                  }
                },
              ),
        title: Text(
          'Reset Password',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AcadexCard(
              padding: const EdgeInsets.all(32.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStep(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_step) {
      case 0:
        return _buildEmailStep(isDark);
      case 1:
        return _buildOtpStep(isDark);
      case 2:
        return _buildNewPasswordStep(isDark);
      case 3:
        return _buildSuccessStep(isDark);
      default:
        return _buildEmailStep(isDark);
    }
  }

  Widget _buildEmailStep(bool isDark) {
    return Form(
      key: _step1FormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIcon(isDark, LucideIcons.keyRound),
          const SizedBox(height: 20),
          Text(
            "Forgot your password?",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your registered email address or phone number and we'll send you a verification code.",
            textAlign: TextAlign.center,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(),
          ],
          const SizedBox(height: 24),
          AcadexTextField(
            controller: _emailController,
            label: "Email or Phone",
            hint: "user@acadex.edu or +91...",
            prefixIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            validator: (val) {
              if (val == null || val.isEmpty) return "Please enter your email or phone";
              return null;
            },
          ),
          const SizedBox(height: 24),
          AcadexButton(
            label: "Send Verification Code",
            icon: LucideIcons.send,
            isLoading: _isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _isLoading ? null : _handleRequestOtp,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                "Back to Sign In",
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(bool isDark) {
    return Form(
      key: _step2FormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIcon(isDark, LucideIcons.shieldCheck),
          const SizedBox(height: 20),
          Text(
            "Enter Verification Code",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We've sent a verification code to\n${_emailController.text}",
            textAlign: TextAlign.center,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(),
          ],
          const SizedBox(height: 24),
          AcadexTextField(
            controller: _otpController,
            label: "Verification Code",
            hint: "Enter OTP",
            prefixIcon: LucideIcons.hash,
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
            validator: (val) {
              if (val == null || val.isEmpty) return "Please enter the verification code";
              return null;
            },
          ),
          const SizedBox(height: 24),
          AcadexButton(
            label: "Verify Code",
            icon: LucideIcons.checkCircle,
            isLoading: _isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _isLoading ? null : _handleVerifyOtp,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _handleRequestOtp,
              child: Text(
                "Resend Code",
                style: AcadexTypography.bodySmall(
                  color: AcadexColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep(bool isDark) {
    return Form(
      key: _step3FormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIcon(isDark, LucideIcons.lockKeyhole),
          const SizedBox(height: 20),
          Text(
            "Set New Password",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a new secure password for your account.\nMust contain at least one letter and one number.",
            textAlign: TextAlign.center,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(),
          ],
          const SizedBox(height: 24),
          AcadexTextField(
            controller: _newPasswordController,
            label: "New Password",
            hint: "Minimum 8 characters",
            prefixIcon: LucideIcons.lock,
            isPassword: true,
            enabled: !_isLoading,
            validator: (val) {
              if (val == null || val.length < 8) return "Password must be at least 8 characters";
              if (!RegExp(r'[a-zA-Z]').hasMatch(val)) return "Must contain at least one letter";
              if (!RegExp(r'[0-9]').hasMatch(val)) return "Must contain at least one number";
              return null;
            },
          ),
          const SizedBox(height: 16),
          AcadexTextField(
            controller: _confirmPasswordController,
            label: "Confirm Password",
            hint: "Re-enter your password",
            prefixIcon: LucideIcons.lock,
            isPassword: true,
            enabled: !_isLoading,
            validator: (val) {
              if (val != _newPasswordController.text) return "Passwords do not match";
              return null;
            },
          ),
          const SizedBox(height: 24),
          AcadexButton(
            label: "Reset Password",
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

  Widget _buildSuccessStep(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCircle2, size: 32, color: AcadexColors.success),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Password Reset Complete",
          textAlign: TextAlign.center,
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your password has been successfully changed.\nYou can now sign in with your new password.",
          textAlign: TextAlign.center,
          style: AcadexTypography.body(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 28),
        AcadexButton(
          label: "Back to Sign In",
          variant: AcadexButtonVariant.primary,
          icon: LucideIcons.logIn,
          isFullWidth: true,
          size: AcadexButtonSize.lg,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildStepIcon(bool isDark, IconData icon) {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 26, color: AcadexColors.primary),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AcadexColors.error.withValues(alpha: 0.1),
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 18, color: AcadexColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: AcadexTypography.bodySmall(color: AcadexColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
