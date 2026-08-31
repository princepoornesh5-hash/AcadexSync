import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
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

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      await authRepo.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
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
    final newPassword = _newPasswordController.text;
    final strength = _calculatePasswordStrength(newPassword);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Change Password",
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: AcadexPageContainer(
          maxWidth: AcadexLayout.formMaxWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: _isSuccess
                ? _buildSuccessCard(isDark)
                : _buildChangePasswordCard(isDark, newPassword, strength),
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordCard(bool isDark, String newPassword, double strength) {
    return AcadexCard(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AcadexColors.primaryHover.withValues(alpha: 0.2)
                        : AcadexColors.primaryLight,
                    borderRadius: AcadexRadius.borderRadiusMd,
                  ),
                  child: const Icon(LucideIcons.keyRound, size: 22, color: AcadexColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Update Credentials",
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      Text(
                        "Ensure your new password contains letters, numbers, and symbols.",
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              const SizedBox(height: 18),
            ],

            // Current Password
            Text(
              'Current Password',
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _currentPasswordController,
              enabled: !_isLoading,
              obscureText: !_isCurrentPasswordVisible,
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
                    _isCurrentPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  onPressed: () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Please enter your current password";
                return null;
              },
            ),
            const SizedBox(height: 18),

            // New Password
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
              obscureText: !_isNewPasswordVisible,
              onChanged: (v) => setState(() {}),
              style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Icon(
                  LucideIcons.key,
                  size: 18,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isNewPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Please enter a new password";
                if (v.length < 8) return "New password must be at least 8 characters";
                if (v == _currentPasswordController.text) return "New password must differ from current password";
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Strength bar
            if (newPassword.isNotEmpty) ...[
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
                  _buildRequirementItem('At least 8 characters', newPassword.length >= 8, isDark),
                  const SizedBox(height: 4),
                  _buildRequirementItem('Letters & numbers', RegExp(r'[a-zA-Z]').hasMatch(newPassword) && RegExp(r'[0-9]').hasMatch(newPassword), isDark),
                  const SizedBox(height: 4),
                  _buildRequirementItem('Special character (!@#\$%^&*)', RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword), isDark),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Confirm New Password
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
            const SizedBox(height: 28),

            // Submit Button
            AcadexButton(
              label: _isLoading ? "Updating..." : "Update Password",
              icon: LucideIcons.checkCircle,
              isLoading: _isLoading,
              isFullWidth: true,
              size: AcadexButtonSize.lg,
              onPressed: _isLoading ? null : _handleChangePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(bool isDark) {
    return AcadexCard(
      padding: const EdgeInsets.all(28),
      child: Column(
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
            "Password Changed Successfully",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your password has been updated. Use your new password for all subsequent sign-ins.",
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),
          AcadexButton(
            label: "Done",
            icon: LucideIcons.check,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: () => context.pop(),
          ),
        ],
      ),
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
