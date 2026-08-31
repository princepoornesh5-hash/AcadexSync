import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/animated_particle_sphere.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String resetToken;
  final String? identifier;
  final VoidCallback? onSuccess;

  const ResetPasswordScreen({
    super.key,
    required this.resetToken,
    this.identifier,
    this.onSuccess,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[a-zA-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    return strength;
  }

  String _getPasswordStrengthLabel(double strength) {
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Good';
    return 'Strong';
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength <= 0.25) return AcadexColors.error;
    if (strength <= 0.5) return AcadexColors.warning;
    if (strength <= 0.75) return AcadexColors.accentOrange;
    return AcadexColors.success;
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      await authRepo.resetPassword(
        resetToken: widget.resetToken,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
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
    final password = _newPasswordController.text;
    final strength = _calculatePasswordStrength(password);

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
                    if (!_isSuccess) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(LucideIcons.arrowLeft, size: 16),
                          label: const Text('Back to Sign In'),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                          onPressed: () => context.go('/login'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    AcadexCard(
                      padding: const EdgeInsets.all(28),
                      child: _isSuccess
                          ? _buildSuccessCard(isDark)
                          : _buildResetForm(isDark, password, strength),
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

  Widget _buildResetForm(bool isDark, String password, double strength) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AcadexColors.primaryHover.withValues(alpha: 0.2)
                    : AcadexColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.lockKeyhole, size: 28, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Reset Your Password",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Create a new strong password for your campus account.",
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: AcadexColors.error),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.circleAlert, size: 16, color: AcadexColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AcadexTypography.caption(
                        color: isDark ? Colors.white : AcadexColors.errorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // New Password Field
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
          const SizedBox(height: 10),

          // Strength meter
          if (password.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Password Strength:',
                  style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                ),
                Text(
                  _getPasswordStrengthLabel(strength),
                  style: AcadexTypography.caption(
                    color: _getPasswordStrengthColor(strength),
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                valueColor: AlwaysStoppedAnimation<Color>(_getPasswordStrengthColor(strength)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Requirements checklist
          Container(
            padding: const EdgeInsets.all(12),
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
                _buildRequirementItem('At least 8 characters', password.length >= 8, isDark),
                const SizedBox(height: 4),
                _buildRequirementItem('Letters & numbers', RegExp(r'[a-zA-Z]').hasMatch(password) && RegExp(r'[0-9]').hasMatch(password), isDark),
                const SizedBox(height: 4),
                _buildRequirementItem('Special character (!@#\$%^&*)', RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password), isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          Text(
            'Confirm New Password',
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_isLoading,
            obscureText: !_isConfirmPasswordVisible,
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
          const SizedBox(height: 24),

          AcadexButton(
            label: _isLoading ? "Updating..." : "Update Password",
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

  Widget _buildSuccessCard(bool isDark) {
    return Column(
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
          "Password Reset Successfully",
          textAlign: TextAlign.center,
          style: AcadexTypography.heading1(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your password has been updated. You can now sign in with your new credentials.",
          textAlign: TextAlign.center,
          style: AcadexTypography.bodySmall(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 28),
        AcadexButton(
          label: "Proceed to Sign In",
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
        Text(
          text,
          style: AcadexTypography.caption(
            color: isMet
                ? (isDark ? AcadexColors.darkInk : AcadexColors.ink)
                : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          ),
        ),
      ],
    );
  }
}
