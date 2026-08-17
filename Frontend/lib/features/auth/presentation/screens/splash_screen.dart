import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for the splash animation
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    
    final authState = ref.read(authProvider);

    if (authState is AuthAuthenticated) {
      _navigateBasedOnRole(authState.user.role);
    } else if (authState is AuthUnauthenticated || authState is AuthError || authState is AuthProfileError) {
      context.go('/login');
    }
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
  Widget build(BuildContext context) {

    return const Scaffold(
      backgroundColor: AppColors.canvasDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.graduationCap, color: AppColors.primary, size: 80),
            SizedBox(height: 24),
            Text(
              "Acadex",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Empowering Education",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 48),
            Text(
              "v1.0.0",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDarkMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
