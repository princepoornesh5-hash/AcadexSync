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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSuccess = false;

  void _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).resetPassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AcadexColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.go('/login'),
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
              child: _isSuccess ? _buildSuccessState(isDark) : _buildFormState(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.keyRound, size: 26, color: AcadexColors.primary),
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
          const SizedBox(height: 8),
          Text(
            "Enter your registered email address and we'll send you instructions to reset your password.",
            textAlign: TextAlign.center,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),
          AcadexTextField(
            controller: _emailController,
            label: "Email Address",
            hint: "user@acadex.edu",
            prefixIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            validator: (val) {
              if (val == null || val.isEmpty) return "Please enter your email";
              if (!val.contains('@')) return "Please enter a valid email";
              return null;
            },
          ),
          const SizedBox(height: 24),
          AcadexButton(
            label: "Send Reset Link",
            icon: LucideIcons.send,
            isLoading: _isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _isLoading ? null : _handleReset,
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

  Widget _buildSuccessState(bool isDark) {
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
            child: const Icon(LucideIcons.mailCheck, size: 32, color: AcadexColors.success),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Check your email",
          textAlign: TextAlign.center,
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We have sent a password reset link to\n${_emailController.text}",
          textAlign: TextAlign.center,
          style: AcadexTypography.body(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 28),
        AcadexButton(
          label: "Back to Sign In",
          variant: AcadexButtonVariant.secondary,
          icon: LucideIcons.arrowLeft,
          isFullWidth: true,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
