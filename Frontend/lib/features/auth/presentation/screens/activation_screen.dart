import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/activation_providers.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/animated_particle_sphere.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _collegeCodeController = TextEditingController();
  final _instituteIdController = TextEditingController();
  final _activationCodeController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _collegeCodeController.dispose();
    _instituteIdController.dispose();
    _activationCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitStep1() {
    if (!_step1FormKey.currentState!.validate()) return;
    ref.read(activationNotifierProvider.notifier).proceedToPasswordStep(
      _collegeCodeController.text.trim().toUpperCase(),
      _instituteIdController.text.trim().toUpperCase(),
      _activationCodeController.text.trim().toUpperCase(),
    );
  }

  void _submitStep2() {
    if (!_step2FormKey.currentState!.validate()) return;
    ref.read(activationNotifierProvider.notifier).completeActivation(
      _passwordController.text,
    );
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activationNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<ActivationState>(activationNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circleAlert, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(next.error!)),
              ],
            ),
            backgroundColor: AcadexColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.login,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back to login bar
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(LucideIcons.arrowLeft, size: 16),
                        label: const Text('Back to Sign In'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ),
                        onPressed: () {
                          ref.read(activationNotifierProvider.notifier).reset();
                          context.go('/login');
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Main Container Card
                    AcadexCard(
                      padding: const EdgeInsets.all(28),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: state.step == 0
                            ? _buildStep1(isDark, state)
                            : state.step == 1
                                ? _buildStep2(isDark, state)
                                : _buildStep3Success(isDark, state),
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

  Widget _buildStepIndicator(int currentStep, bool isDark) {
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
                  currentStep == 0 ? 'STEP 1 OF 2' : 'STEP 2 OF 2',
                  style: AcadexTypography.eyebrow(color: AcadexColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  _buildProgressDot(active: true, completed: currentStep > 0),
                  const SizedBox(width: 6),
                  _buildProgressDot(active: currentStep >= 1, completed: currentStep > 1),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentStep == 0 ? 0.5 : 1.0,
              backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              valueColor: const AlwaysStoppedAnimation<Color>(AcadexColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot({required bool active, required bool completed}) {
    return Container(
      width: 10,
      height: 10,
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

  Widget _buildStep1(bool isDark, ActivationState state) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(0, isDark),

          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.userCheck, size: 26, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            "Account Activation",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter the institutional details provided by your college administrator to activate your access.",
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Error Banner if present
          if (state.error != null) ...[
            _buildErrorBanner(state.error!, isDark),
            const SizedBox(height: 16),
          ],

          // College Code Input
          AcadexTextField(
            controller: _collegeCodeController,
            label: "College Code",
            hint: "e.g. GIT or ENG-COLLEGE",
            prefixIcon: LucideIcons.building,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Please enter your college code";
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Institute ID Input
          AcadexTextField(
            controller: _instituteIdController,
            label: "Student or Employee ID",
            hint: "e.g. CS2026001 or EMP102",
            prefixIcon: LucideIcons.idCard,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Please enter your ID";
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Single-Use Activation Code Input
          AcadexTextField(
            controller: _activationCodeController,
            label: "Activation Code",
            hint: "e.g. ACT-849201",
            prefixIcon: LucideIcons.keyRound,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Please enter your activation code";
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Continue Button
          AcadexButton(
            label: "Continue",
            icon: LucideIcons.arrowRight,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: _submitStep1,
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () {
                ref.read(activationNotifierProvider.notifier).reset();
                context.go('/login');
              },
              child: Text(
                'Already activated? Sign In',
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

  Widget _buildStep2(bool isDark, ActivationState state) {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(1, isDark),

          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldCheck, size: 26, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            "Create Password",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Set a secure password for your ${state.instituteId ?? 'account'} profile.",
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Error Banner if present
          if (state.error != null) ...[
            _buildErrorBanner(state.error!, isDark),
            const SizedBox(height: 16),
          ],

          // New Password Input
          Text(
            'New Password',
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            enabled: !state.isLoading,
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
              if (v == null || v.isEmpty) return "Please enter a password";
              if (v.length < 8) return "Password must be at least 8 characters";
              return null;
            },
          ),
          const SizedBox(height: 10),

          // Password Strength Bar
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

          // Password Requirements Checklist
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

          // Confirm Password Input
          Text(
            'Confirm Password',
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !state.isLoading,
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
              if (v == null || v.isEmpty) return "Please confirm your password";
              if (v != _passwordController.text) return "Passwords do not match";
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Action
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AcadexButton(
                  label: "Back",
                  variant: AcadexButtonVariant.secondary,
                  icon: LucideIcons.arrowLeft,
                  onPressed: state.isLoading
                      ? null
                      : () {
                          ref.read(activationNotifierProvider.notifier).reset();
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: AcadexButton(
                  label: state.isLoading ? "Activating..." : "Activate Account",
                  icon: LucideIcons.checkCircle,
                  isLoading: state.isLoading,
                  size: AcadexButtonSize.lg,
                  onPressed: state.isLoading ? null : _submitStep2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Success(bool isDark, ActivationState state) {
    final user = state.validatedUser;
    final name = user?['name']?.toString() ?? 'User';
    final email = user?['email']?.toString() ?? '';
    final role = user?['role']?.toString() ?? 'Student';

    return Column(
      key: const ValueKey('step3_success'),
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
          "Account Activated!",
          textAlign: TextAlign.center,
          style: AcadexTypography.heading1(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your institutional account is now fully active. You can now sign in using your credentials.",
          textAlign: TextAlign.center,
          style: AcadexTypography.bodySmall(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 24),

        // User Identity Preview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: AcadexTypography.body(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  AcadexBadge(
                    label: role.toUpperCase(),
                    variant: AcadexBadgeVariant.success,
                  ),
                ],
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.idCard, size: 14, color: AcadexColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'ID: ${state.instituteId ?? "—"}',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Sign In Button
        AcadexButton(
          label: "Continue to Sign In",
          icon: LucideIcons.logIn,
          isFullWidth: true,
          size: AcadexButtonSize.lg,
          onPressed: () {
            ref.read(activationNotifierProvider.notifier).reset();
            context.go('/login');
          },
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
