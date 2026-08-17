import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  final bool _rememberMe = false;
  String? _selectedRole;

  AppRole _mapStringToRole(String roleString) {
    switch (roleString) {
      case "Super Admin":
        return AppRole.superAdmin;
      case "College Admin":
        return AppRole.collegeAdmin;
      case "HOD":
        return AppRole.hod;
      case "Faculty":
        return AppRole.faculty;
      case "Student":
        return AppRole.student;
      default:
        return AppRole.student;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  void _navigateBasedOnRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        context.go('/dashboard/super_admin');
        break;
      case AppRole.collegeAdmin:
        context.go('/dashboard/college_admin');
        break;
      case AppRole.hod:
        context.go('/dashboard/hod');
        break;
      case AppRole.faculty:
        context.go('/dashboard/faculty');
        break;
      case AppRole.student:
        context.go('/dashboard/student');
        break;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme references matching existing system
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final primaryColor = const Color(0xFF6366F1); // Brand Indigo
    
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _navigateBasedOnRole(next.user.role);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next is AuthProfileError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Logout',
              textColor: Colors.white,
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
        );
      }
    });

    final isLoading = authState is AuthLoading || authState is AuthProfileLoading;
    final loadingMessage = authState is AuthProfileLoading ? "Loading Profile..." : "Sign In";

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 850;

    Widget buildBrandPanel() {
      return Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.graduationCap, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Acadex",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            
            // Abstract technology/academic visual
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subtle minimalist grid visual representation
                      Icon(LucideIcons.network, size: 120, color: primaryColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 32),
                      const Text(
                        "Campus management, simplified.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "One connected platform for students, faculty and administrators.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer branding
            const Text(
              "© 2026 Acadex Platform. All rights reserved.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      );
    }

    Widget buildLoginForm() {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mobile-only logo
                      if (isMobile) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(LucideIcons.graduationCap, color: primaryColor, size: 24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Acadex",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        "Welcome back",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Sign in to continue to Acadex.",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      Text(
                        "Email address",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          prefixIcon: const Icon(LucideIcons.mail, size: 18),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Please enter your email";
                          if (!val.contains('@')) return "Invalid email address";
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Password",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading ? null : () => context.go('/forgot-password'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Forgot password?", style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Enter your password",
                          prefixIcon: const Icon(LucideIcons.lock, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Please enter your password";
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(loadingMessage),
                      ),
                      const SizedBox(height: 24),

                      // Account Activation Action
                      Center(
                        child: TextButton(
                          onPressed: () {
                            context.go('/activate');
                          },
                          child: Text(
                            "New to Acadex? Activate your account",
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      // Development Test Mode (Debug Only)
                      if (kDebugMode) ...[
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFF334155)),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "DEVELOPMENT MODE",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Preview role-based dashboards using test identities.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedRole,
                                decoration: const InputDecoration(
                                  labelText: "Test Role",
                                  prefixIcon: Icon(LucideIcons.user, size: 16),
                                ),
                                dropdownColor: cardColor,
                                items: const [
                                  DropdownMenuItem(value: "Super Admin", child: Text("Super Admin")),
                                  DropdownMenuItem(value: "College Admin", child: Text("College Admin")),
                                  DropdownMenuItem(value: "HOD", child: Text("HOD")),
                                  DropdownMenuItem(value: "Faculty", child: Text("Faculty")),
                                  DropdownMenuItem(value: "Student", child: Text("Student")),
                                ],
                                onChanged: (val) {
                                  if (val == null) return;
                                  setState(() {
                                    _selectedRole = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: (isLoading || _selectedRole == null)
                                    ? null
                                    : () {
                                        ref.read(authProvider.notifier).loginAsDevelopmentRole(
                                          _mapStringToRole(_selectedRole!),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _selectedRole == null 
                                      ? "Sign In as..." 
                                      : "Sign In as $_selectedRole",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile)
              Expanded(
                flex: 1,
                child: buildBrandPanel(),
              ),
            Expanded(
              flex: 1,
              child: buildLoginForm(),
            ),
          ],
        ),
      ),
    );
  }
}
