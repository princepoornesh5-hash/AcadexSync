import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/activation_providers.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';

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
      _collegeCodeController.text.trim(),
      _instituteIdController.text.trim(),
      _activationCodeController.text.trim(),
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
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    return strength;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AcadexColors.error,
          ),
        );
        ref.read(activationNotifierProvider.notifier).clearError();
      }
    });

    Widget buildStep1() {
      return Form(
        key: _step1FormKey,
        child: Column(
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
                child: const Icon(LucideIcons.userCheck, size: 26, color: AcadexColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Activate Account",
              textAlign: TextAlign.center,
              style: AcadexTypography.heading2(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Enter your college code, institutional ID, and the activation code provided by your administrator.",
              textAlign: TextAlign.center,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 28),
            AcadexTextField(
              controller: _collegeCodeController,
              label: "College Code",
              hint: "e.g., ACME-UNIV",
              prefixIcon: LucideIcons.building2,
              enabled: !state.isLoading,
              validator: (val) => val == null || val.isEmpty ? "Please enter the college code" : null,
            ),
            const SizedBox(height: 16),
            AcadexTextField(
              controller: _instituteIdController,
              label: "Student or Employee ID",
              hint: "e.g., CS2025001 or EMP101",
              prefixIcon: LucideIcons.idCard,
              enabled: !state.isLoading,
              validator: (val) => val == null || val.isEmpty ? "Please enter your ID" : null,
            ),
            const SizedBox(height: 16),
            AcadexTextField(
              controller: _activationCodeController,
              label: "Activation Code",
              hint: "Enter activation code",
              prefixIcon: LucideIcons.keyRound,
              enabled: !state.isLoading,
              validator: (val) => val == null || val.isEmpty ? "Please enter your activation code" : null,
            ),
            const SizedBox(height: 28),
            AcadexButton(
              label: "Continue",
              icon: LucideIcons.arrowRight,
              isLoading: state.isLoading,
              isFullWidth: true,
              size: AcadexButtonSize.lg,
              onPressed: state.isLoading ? null : _submitStep1,
            ),
          ],
        ),
      );
    }

    Widget buildStep2() {
      final strength = _calculatePasswordStrength(_passwordController.text);

      return Form(
        key: _step2FormKey,
        child: Column(
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
                child: const Icon(LucideIcons.lock, size: 26, color: AcadexColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Create Password",
              textAlign: TextAlign.center,
              style: AcadexTypography.heading2(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Set a secure password for your new Acadex account.\nPassword must contain at least one letter and one number.",
              textAlign: TextAlign.center,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 24),

            AcadexTextField(
              controller: _passwordController,
              label: "New Password",
              hint: "Minimum 8 characters",
              prefixIcon: LucideIcons.lock,
              isPassword: true,
              onChanged: (_) => setState(() {}),
              enabled: !state.isLoading,
              validator: (val) {
                if (val == null || val.length < 8) return "Password must be at least 8 characters";
                if (!RegExp(r'[a-zA-Z]').hasMatch(val)) return "Password must contain at least one letter";
                if (!RegExp(r'[0-9]').hasMatch(val)) return "Password must contain at least one number";
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Password strength bar
            ClipRRect(
              borderRadius: AcadexRadius.borderRadiusFull,
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                valueColor: AlwaysStoppedAnimation<Color>(_getPasswordStrengthColor(strength)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 16),

            AcadexTextField(
              controller: _confirmPasswordController,
              label: "Confirm Password",
              hint: "Re-enter your password",
              prefixIcon: LucideIcons.lock,
              isPassword: true,
              enabled: !state.isLoading,
              validator: (val) {
                if (val != _passwordController.text) return "Passwords do not match";
                return null;
              },
            ),
            const SizedBox(height: 24),

            AcadexButton(
              label: "Activate Account",
              icon: LucideIcons.checkCircle,
              isLoading: state.isLoading,
              isFullWidth: true,
              size: AcadexButtonSize.lg,
              onPressed: state.isLoading ? null : _submitStep2,
            ),
          ],
        ),
      );
    }

    Widget buildStep3() {
      return Column(
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
              child: const Icon(LucideIcons.checkCircle2, size: 36, color: AcadexColors.success),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Account Activated!",
            textAlign: TextAlign.center,
            style: AcadexTypography.heading1(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your Acadex account is now fully active.\nYou can now sign in using your credentials.",
            textAlign: TextAlign.center,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 36),
          AcadexButton(
            label: "Continue to Sign In",
            icon: LucideIcons.logIn,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: () => context.go('/login'),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: state.step == 2
            ? null
            : IconButton(
                icon: Icon(
                  LucideIcons.arrowLeft,
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
                onPressed: () {
                  if (state.step == 1) {
                    ref.read(activationNotifierProvider.notifier).reset();
                  } else {
                    context.go('/login');
                  }
                },
              ),
        title: Text(
          'Account Activation',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: AcadexCard(
              padding: const EdgeInsets.all(32.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: state.step == 0
                    ? buildStep1()
                    : state.step == 1
                        ? buildStep2()
                        : buildStep3(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
