import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
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
    // Microtask check in case auth restoration completed synchronously before mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState(ref.read(authProvider));
    });
  }

  void _checkAuthState(AuthState state) {
    if (!mounted) return;
    if (state is AuthAuthenticated) {
      _navigateBasedOnRole(state.user.role);
    } else if (state is AuthUnauthenticated || state is AuthError || state is AuthProfileError) {
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
    ref.listen<AuthState>(authProvider, (previous, next) {
      _checkAuthState(next);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : const Color(0xFF0F172A),
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.splash,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Brand Cap Container
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AcadexColors.primary, Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AcadexRadius.borderRadiusXl,
                  boxShadow: [
                    BoxShadow(
                      color: AcadexColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 28),
              const Text(
                "Acadex",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Campus Operating System",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AcadexColors.primaryMuted,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                "v1.0.0 • Secure Institutional Architecture",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
