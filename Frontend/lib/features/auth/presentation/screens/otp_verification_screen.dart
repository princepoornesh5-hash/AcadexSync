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

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String identifier;
  final ValueChanged<String>? onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    this.onVerified,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Timer? _expiryTimer;
  Timer? _resendTimer;
  int _expirySeconds = 300; // 5 minutes
  int _resendCooldownSeconds = 60; // 60 seconds

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();
    _otpController.dispose();
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

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      final resetToken = await authRepo.verifyPasswordResetOtp(
        identifier: widget.identifier.trim(),
        otpCode: _otpController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.onVerified != null) {
          widget.onVerified!(resetToken);
        } else {
          context.go(
            '/reset-password?identifier=${Uri.encodeComponent(widget.identifier)}&resetToken=${Uri.encodeComponent(resetToken)}',
          );
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

  Future<void> _handleResendOtp() async {
    if (_resendCooldownSeconds > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(apiAuthRepositoryProvider);
      await authRepo.sendPasswordResetEmail(widget.identifier.trim());
      if (mounted) {
        setState(() => _isLoading = false);
        _startTimers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new 6-digit verification code has been dispatched.'),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(LucideIcons.arrowLeft, size: 16),
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ),
                        onPressed: () => context.go('/forgot-password'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AcadexCard(
                      padding: const EdgeInsets.all(28),
                      child: Form(
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
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AcadexTypography.bodySmall(
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                                children: [
                                  const TextSpan(text: "We sent a 6-digit code to "),
                                  TextSpan(
                                    text: widget.identifier,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                    ),
                                  ),
                                ],
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

                            // OTP Field
                            AcadexTextField(
                              controller: _otpController,
                              label: "6-Digit Security Code",
                              hint: "123456",
                              prefixIcon: LucideIcons.key,
                              keyboardType: TextInputType.number,
                              enabled: !_isLoading,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return "Please enter the 6-digit code";
                                if (val.trim().length < 6) return "Code must be 6 digits";
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Expiry Timer Indicator
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
                            const SizedBox(height: 16),

                            // Resend Code Button
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
                                onPressed: (_resendCooldownSeconds > 0 || _isLoading)
                                    ? null
                                    : _handleResendOtp,
                              ),
                            ),
                          ],
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
    );
  }
}
