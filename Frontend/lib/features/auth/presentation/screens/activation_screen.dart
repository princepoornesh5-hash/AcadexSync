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
import '../../domain/models/activation_model.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();
  final _step5FormKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _codeController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _formatActivationCode(String value) {
    // Keep raw uppercase characters and dashes
    final formatted = value.toUpperCase();
    if (formatted != value) {
      _codeController.value = _codeController.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _submitCode() {
    if (!_step1FormKey.currentState!.validate()) return;
    ref.read(activationNotifierProvider.notifier).validateActivationCode(_codeController.text);
  }

  void _submitOtp() {
    if (!_step4FormKey.currentState!.validate()) return;
    ref.read(activationNotifierProvider.notifier).verifyOtp(_otpController.text);
  }

  void _submitPassword() {
    final notifier = ref.read(activationNotifierProvider.notifier);
    final state = ref.read(activationNotifierProvider);

    if (state.isExistingUser) {
      notifier.completeActivation();
      return;
    }

    if (!_step5FormKey.currentState!.validate()) return;
    notifier.completeActivation(
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activationNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<ActivationState>(activationNotifierProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
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
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.login,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 20.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back to login button
                    if (state.currentStep != ActivationStep.success)
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

                    // Main Card Container
                    AcadexCard(
                      padding: EdgeInsets.all(isMobile ? 20 : 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.currentStep != ActivationStep.success)
                            _buildProgressIndicator(state.currentStep, isDark),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildCurrentStep(state, isDark),
                          ),
                        ],
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

  Widget _buildProgressIndicator(ActivationStep currentStep, bool isDark) {
    const totalSteps = 5;
    final stepIndex = currentStep.index.clamp(0, 4);

    String stepLabel;
    switch (currentStep) {
      case ActivationStep.enterCode:
        stepLabel = 'Activation Code';
        break;
      case ActivationStep.confirmIdentity:
        stepLabel = 'Confirm Identity';
        break;
      case ActivationStep.selectContact:
        stepLabel = 'Contact Channel';
        break;
      case ActivationStep.verifyOtp:
        stepLabel = 'Verification';
        break;
      case ActivationStep.setPassword:
        stepLabel = 'Security Setup';
        break;
      case ActivationStep.success:
        stepLabel = 'Completed';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${stepIndex + 1} OF $totalSteps',
                style: AcadexTypography.caption(
                  color: AcadexColors.primary,
                ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stepLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (stepIndex + 1) / totalSteps,
              backgroundColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(AcadexColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ActivationState state, bool isDark) {
    switch (state.currentStep) {
      case ActivationStep.enterCode:
        return _buildStep1Code(state, isDark);
      case ActivationStep.confirmIdentity:
        return _buildStep2Identity(state, isDark);
      case ActivationStep.selectContact:
        return _buildStep3Contact(state, isDark);
      case ActivationStep.verifyOtp:
        return _buildStep4Otp(state, isDark);
      case ActivationStep.setPassword:
        return _buildStep5Password(state, isDark);
      case ActivationStep.success:
        return _buildStep6Success(state, isDark);
    }
  }

  // -------------------------------------------------------------------------
  // STEP 1: Enter Activation Code
  // -------------------------------------------------------------------------
  Widget _buildStep1Code(ActivationState state, bool isDark) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step_1_code'),
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
              child: const Icon(LucideIcons.keyRound, size: 28, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Activate Your Account',
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the activation code provided by your institution to begin setting up your account.',
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),

          if (state.error != null) ...[
            _buildErrorBox(state.error!, isDark),
            const SizedBox(height: 16),
          ],

          AcadexTextField(
            controller: _codeController,
            label: 'Activation Code',
            hint: 'e.g. SVGP-A1B2-C3D4',
            prefixIcon: LucideIcons.keyRound,
            autofocus: true,
            enabled: !state.isLoading,
            onChanged: _formatActivationCode,
            onSubmitted: (_) => _submitCode(),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your activation code';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          AcadexButton(
            label: state.isLoading ? 'Validating...' : 'Continue',
            icon: LucideIcons.arrowRight,
            isLoading: state.isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: state.isLoading ? null : _submitCode,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // STEP 2: Confirm Identity ("Is this you?")
  // -------------------------------------------------------------------------
  Widget _buildStep2Identity(ActivationState state, bool isDark) {
    final result = state.validationResult;
    final notifier = ref.read(activationNotifierProvider.notifier);

    return Column(
      key: const ValueKey('step_2_identity'),
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
            child: const Icon(LucideIcons.userCheck, size: 28, color: AcadexColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Confirm Your Identity',
          textAlign: TextAlign.center,
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify that these details match your academic profile.',
          textAlign: TextAlign.center,
          style: AcadexTypography.bodySmall(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 20),

        if (state.error != null) ...[
          _buildErrorBox(state.error!, isDark),
          const SizedBox(height: 16),
        ],

        // Identity Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
            borderRadius: BorderRadius.circular(12),
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
                  Expanded(
                    child: Text(
                      result?.displayName ?? 'Academic User',
                      style: AcadexTypography.heading3(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                  ),
                  if (result?.role != null)
                    AcadexBadge(
                      label: result!.role,
                      variant: AcadexBadgeVariant.primary,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.building, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result?.institutionName ?? '',
                      style: AcadexTypography.bodySmall(
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (result != null && result.contactOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Registered Contact Channels:',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 6),
                for (final opt in result.contactOptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          opt.method == 'email' ? LucideIcons.mail : LucideIcons.phone,
                          size: 14,
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt.maskedValue,
                          style: AcadexTypography.bodySmall(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Is this you?',
          textAlign: TextAlign.center,
          style: AcadexTypography.body(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        AcadexButton(
          label: 'Yes, Continue',
          icon: LucideIcons.check,
          isFullWidth: true,
          size: AcadexButtonSize.lg,
          onPressed: () => notifier.confirmIdentity(true),
        ),
        const SizedBox(height: 10),

        AcadexButton(
          label: "This Isn't Me",
          icon: LucideIcons.x,
          variant: AcadexButtonVariant.secondary,
          isFullWidth: true,
          onPressed: () => notifier.confirmIdentity(false),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // STEP 3: Select Registered Contact Method
  // -------------------------------------------------------------------------
  Widget _buildStep3Contact(ActivationState state, bool isDark) {
    final notifier = ref.read(activationNotifierProvider.notifier);
    final options = state.validationResult?.contactOptions ?? [];

    return Column(
      key: const ValueKey('step_3_contact'),
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
            child: const Icon(LucideIcons.send, size: 28, color: AcadexColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Select Contact Method',
          textAlign: TextAlign.center,
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We will send a one-time verification code (OTP) to your selected registered contact.',
          textAlign: TextAlign.center,
          style: AcadexTypography.bodySmall(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 20),

        if (state.error != null) ...[
          _buildErrorBox(state.error!, isDark),
          const SizedBox(height: 16),
        ],

        for (final opt in options)
          _buildContactOptionCard(
            option: opt,
            isSelected: state.selectedContactMethod == opt.method,
            isDark: isDark,
            onTap: () => notifier.selectContactMethod(opt.method),
          ),
        const SizedBox(height: 24),

        AcadexButton(
          label: state.isLoading ? 'Sending Code...' : 'Send Verification Code',
          icon: LucideIcons.send,
          isLoading: state.isLoading,
          isFullWidth: true,
          size: AcadexButtonSize.lg,
          onPressed: state.isLoading || state.selectedContactMethod == null
              ? null
              : () => notifier.sendOtp(),
        ),
        const SizedBox(height: 10),

        AcadexButton(
          label: 'Back',
          variant: AcadexButtonVariant.ghost,
          isFullWidth: true,
          onPressed: () => notifier.goToStep(ActivationStep.confirmIdentity),
        ),
      ],
    );
  }

  Widget _buildContactOptionCard({
    required ContactOption option,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isEmail = option.method == 'email';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AcadexColors.primaryHover.withValues(alpha: 0.15) : AcadexColors.primaryLight)
                : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEmail ? LucideIcons.mail : LucideIcons.phone,
                size: 20,
                color: isSelected ? AcadexColors.primary : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmail ? 'Registered Email' : 'Registered Phone',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.maskedValue,
                      style: AcadexTypography.body(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: option.method,
                groupValue: isSelected ? option.method : null,
                activeColor: AcadexColors.primary,
                onChanged: (_) => onTap(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // STEP 4: Verify OTP
  // -------------------------------------------------------------------------
  Widget _buildStep4Otp(ActivationState state, bool isDark) {
    final notifier = ref.read(activationNotifierProvider.notifier);
    final destination = state.sendOtpResult?.maskedDestination ?? 'your contact';

    return Form(
      key: _step4FormKey,
      child: Column(
        key: const ValueKey('step_4_otp'),
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
              child: const Icon(LucideIcons.shieldCheck, size: 28, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter Verification Code',
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AcadexTypography.bodySmall(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to '),
                TextSpan(
                  text: destination,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (state.error != null) ...[
            _buildErrorBox(state.error!, isDark),
            const SizedBox(height: 16),
          ],

          AcadexTextField(
            controller: _otpController,
            label: '6-Digit Security Code',
            hint: '123456',
            prefixIcon: LucideIcons.key,
            keyboardType: TextInputType.number,
            autofocus: true,
            enabled: !state.isLoading,
            onSubmitted: (_) => _submitOtp(),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter the 6-digit verification code';
              }
              if (val.trim().length != 6) {
                return 'Code must be exactly 6 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Expiry and timer countdown
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: state.otpExpiryRemaining <= 60 ? AcadexColors.error : AcadexColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  state.otpExpiryRemaining > 0
                      ? 'Code expires in: ${_formatTime(state.otpExpiryRemaining)}'
                      : 'Code has expired. Please request a new code.',
                  style: AcadexTypography.caption(
                    color: state.otpExpiryRemaining <= 60
                        ? AcadexColors.error
                        : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          AcadexButton(
            label: state.isLoading ? 'Verifying...' : 'Verify Code',
            icon: LucideIcons.check,
            isLoading: state.isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: state.isLoading ? null : _submitOtp,
          ),
          const SizedBox(height: 12),

          // Resend button governed by cooldown
          Center(
            child: state.resendCooldownRemaining > 0
                ? Text(
                    'Resend code in ${state.resendCooldownRemaining}s',
                    style: AcadexTypography.bodySmall(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  )
                : TextButton.icon(
                    icon: const Icon(LucideIcons.rotateCw, size: 14),
                    label: const Text('Resend Code'),
                    style: TextButton.styleFrom(
                      foregroundColor: AcadexColors.primary,
                    ),
                    onPressed: state.isLoading ? null : () => notifier.resendOtp(),
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // STEP 5: Set & Confirm Password (or Activate for Existing User)
  // -------------------------------------------------------------------------
  Widget _buildStep5Password(ActivationState state, bool isDark) {
    if (state.isExistingUser) {
      return _buildExistingUserActivation(state, isDark);
    }
    return _buildNewUserPasswordSetup(state, isDark);
  }

  Widget _buildExistingUserActivation(ActivationState state, bool isDark) {
    return Column(
      key: const ValueKey('step_5_existing_user'),
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
            child: const Icon(LucideIcons.building2, size: 28, color: AcadexColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Activate Workspace Access',
          textAlign: TextAlign.center,
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your ACADEX account was verified. Your existing login credentials will be used to access this college workspace.',
          textAlign: TextAlign.center,
          style: AcadexTypography.bodySmall(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 20),

        if (state.error != null) ...[
          _buildErrorBox(state.error!, isDark),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target Workspace:',
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.validationResult?.institutionName ?? 'College Workspace',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Assigned Role: ${state.validationResult?.role ?? "MEMBER"}',
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        AcadexButton(
          label: state.isLoading ? 'Activating...' : 'Activate Workspace Access',
          icon: LucideIcons.building2,
          isLoading: state.isLoading,
          isFullWidth: true,
          size: AcadexButtonSize.lg,
          onPressed: state.isLoading ? null : _submitPassword,
        ),
      ],
    );
  }

  Widget _buildNewUserPasswordSetup(ActivationState state, bool isDark) {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final isNotEmpty = pass.isNotEmpty && confirm.isNotEmpty;
    final isMatch = isNotEmpty && pass == confirm;
    final hasMinLength = pass.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(pass);
    final hasDigit = RegExp(r'[0-9]').hasMatch(pass);
    final meetsPolicy = hasMinLength && hasLetter && hasDigit;

    // Critical Requirement: Show "Passwords matched" ONLY when both nonempty, matching, and satisfying policy
    final showMatchedSuccess = isMatch && meetsPolicy;

    return Form(
      key: _step5FormKey,
      child: Column(
        key: const ValueKey('step_5_password'),
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
              child: const Icon(LucideIcons.lockKeyhole, size: 28, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create Your Password',
            textAlign: TextAlign.center,
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a secure password for your ACADEX account to complete activation.',
            textAlign: TextAlign.center,
            style: AcadexTypography.bodySmall(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),

          if (state.error != null) ...[
            _buildErrorBox(state.error!, isDark),
            const SizedBox(height: 16),
          ],

          // Password Field
          AcadexTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: 'At least 8 characters',
            prefixIcon: LucideIcons.lock,
            isPassword: !_isPasswordVisible,
            enabled: !state.isLoading,
            onChanged: (_) => setState(() {}),
            suffix: IconButton(
              icon: Icon(
                _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 18,
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter a password';
              if (val.length < 8) return 'Password must be at least 8 characters';
              if (!RegExp(r'[a-zA-Z]').hasMatch(val) || !RegExp(r'[0-9]').hasMatch(val)) {
                return 'Password must contain at least one letter and one number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          AcadexTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: LucideIcons.lock,
            isPassword: !_isConfirmPasswordVisible,
            enabled: !state.isLoading,
            onChanged: (_) => setState(() {}),
            suffix: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 18,
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please confirm your password';
              if (val != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password Match Status
          if (showMatchedSuccess)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.success.withValues(alpha: 0.15) : AcadexColors.successLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AcadexColors.success),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, size: 16, color: AcadexColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Passwords matched',
                    style: AcadexTypography.caption(
                      color: isDark ? Colors.white : AcadexColors.successDark,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else if (isNotEmpty && !isMatch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AcadexColors.error),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.circleAlert, size: 16, color: AcadexColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Passwords do not match',
                    style: AcadexTypography.caption(
                      color: isDark ? Colors.white : AcadexColors.errorDark,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // Password Policy Checklist
          _buildPolicyChecklist(
            hasMinLength: hasMinLength,
            hasLetterAndNumber: hasLetter && hasDigit,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          AcadexButton(
            label: state.isLoading ? 'Activating Account...' : 'Activate Account',
            icon: LucideIcons.checkCircle,
            isLoading: state.isLoading,
            isFullWidth: true,
            size: AcadexButtonSize.lg,
            onPressed: state.isLoading ? null : _submitPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyChecklist({
    required bool hasMinLength,
    required bool hasLetterAndNumber,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPolicyRow('At least 8 characters long', hasMinLength, isDark),
        const SizedBox(height: 4),
        _buildPolicyRow('Contains at least one letter and one number', hasLetterAndNumber, isDark),
      ],
    );
  }

  Widget _buildPolicyRow(String text, bool isMet, bool isDark) {
    return Row(
      children: [
        Icon(
          isMet ? LucideIcons.check : LucideIcons.circle,
          size: 14,
          color: isMet ? AcadexColors.success : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
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

  // -------------------------------------------------------------------------
  // STEP 6 & 7: Success & Redirect to Login
  // -------------------------------------------------------------------------
  Widget _buildStep6Success(ActivationState state, bool isDark) {
    final message = state.completionResult?.message ??
        'Your account has been activated successfully. You can now sign in with your credentials.';

    return Column(
      key: const ValueKey('step_6_success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.success.withValues(alpha: 0.2) : AcadexColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCheck, size: 36, color: AcadexColors.success),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Account Activated!',
          textAlign: TextAlign.center,
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AcadexTypography.body(
            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 32),

        AcadexButton(
          label: 'Proceed to Sign In',
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

  Widget _buildErrorBox(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
        borderRadius: BorderRadius.circular(8),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
