import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/activation_providers.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  
  final _rollNumberController = TextEditingController();
  final _codeController = TextEditingController();
  
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _rollNumberController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitStep1() {
    if (!_step1FormKey.currentState!.validate()) return;
    ref.read(activationNotifierProvider.notifier).validateCode(
      _rollNumberController.text.trim(),
      _codeController.text.trim(),
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
    if (strength <= 0.25) return Colors.red;
    if (strength <= 0.5) return Colors.orange;
    if (strength <= 0.75) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activationNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final primaryColor = const Color(0xFF6366F1);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    ref.listen<ActivationState>(activationNotifierProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
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
            Text(
              "Activate your Acadex account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your details to begin the activation process.",
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 32),
            Text("Student ID", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: subTextColor)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rollNumberController,
              decoration: const InputDecoration(
                hintText: "e.g., CS2025001",
                prefixIcon: Icon(LucideIcons.idCard, size: 18),
              ),
              validator: (val) => val == null || val.isEmpty ? "Please enter your Student ID" : null,
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 20),
            Text("Activation Code", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: subTextColor)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: "Enter your 8-character code",
                prefixIcon: Icon(LucideIcons.keyRound, size: 18),
              ),
              validator: (val) => val == null || val.isEmpty ? "Please enter your activation code" : null,
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.isLoading ? null : _submitStep1,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: state.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Continue"),
            ),
          ],
        ),
      );
    }

    Widget buildStep2() {
      final student = state.validatedStudent!;
      return Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Create your password",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              "Secure your account to complete activation.",
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.userCheck, size: 20, color: primaryColor),
                      const SizedBox(width: 8),
                      Text("Verified Identity", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(student.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text("ID: ${student.rollNumber}", style: TextStyle(fontSize: 14, color: subTextColor)),
                  Text(student.email, style: TextStyle(fontSize: 14, color: subTextColor)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("New Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: subTextColor)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Enter a strong password",
                prefixIcon: const Icon(LucideIcons.lock, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.length < 8) return "Password must be at least 8 characters";
                return null;
              },
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _calculatePasswordStrength(_passwordController.text),
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                color: _getPasswordStrengthColor(_calculatePasswordStrength(_passwordController.text)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 20),
            Text("Confirm Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: subTextColor)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: "Repeat your new password",
                prefixIcon: const Icon(LucideIcons.lock, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (val) {
                if (val != _passwordController.text) return "Passwords do not match";
                return null;
              },
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.isLoading ? null : _submitStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: state.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Activate Account"),
            ),
          ],
        ),
      );
    }

    Widget buildStep3() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCircle, size: 64, color: Colors.green),
          ),
          const SizedBox(height: 32),
          Text(
            "Account Activated!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          Text(
            "Your Acadex account is now ready.\nYou can now log in using your email and new password.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: subTextColor, height: 1.5),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Continue to Login"),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: state.step == 2 ? null : IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textColor),
          onPressed: () {
            if (state.step == 1) {
              ref.read(activationNotifierProvider.notifier).reset();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: cardColor,
              elevation: isDark ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark 
                    ? const BorderSide(color: Color(0xFF334155), width: 1)
                    : const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
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
      ),
    );
  }
}
