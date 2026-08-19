import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';

import '../../../../core/presentation/widgets/animated_particle_sphere.dart';

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
      backgroundColor: Color(0xFF020617),
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.splash,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.graduationCap, color: Color(0xFF818CF8), size: 80),
              SizedBox(height: 24),
              Text(
                "Acadex",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Empowering Education",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF94A3B8),
                ),
              ),
              SizedBox(height: 48),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Color(0xFF818CF8),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 48),
              Text(
                "v1.0.0",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
