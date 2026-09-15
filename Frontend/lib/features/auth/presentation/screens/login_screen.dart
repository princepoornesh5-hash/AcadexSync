import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/animated_particle_sphere.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  String? _selectedDevRole;
  bool _showDevDrawer = false;

  AppRole _mapStringToRole(String roleString) {
    switch (roleString) {
      case "Super Admin": return AppRole.superAdmin;
      case "College Admin": return AppRole.collegeAdmin;
      case "HOD": return AppRole.hod;
      case "Faculty": return AppRole.faculty;
      case "Student": return AppRole.student;
      default: return AppRole.student;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
      _identifierController.text.trim(),
      _passwordController.text,
    );
  }

  void _navigateBasedOnRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin: context.go('/dashboard/super_admin'); break;
      case AppRole.collegeAdmin: context.go('/dashboard/college_admin'); break;
      case AppRole.hod: context.go('/dashboard/hod'); break;
      case AppRole.faculty: context.go('/dashboard/faculty'); break;
      case AppRole.student: context.go('/dashboard/student'); break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[LOGIN_VISIBLE]');
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _navigateBasedOnRole(next.user.role);
      } else if (next is AuthError) {
        final isPending = next.message.toLowerCase().contains('pending activation') ||
            next.message.toLowerCase().contains('activate your account') ||
            next.message.toLowerCase().contains('pending_activation');

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isPending ? LucideIcons.alertTriangle : LucideIcons.circleAlert,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(next.message)),
              ],
            ),
            backgroundColor: isPending ? AcadexColors.warningDark : AcadexColors.error,
            duration: isPending ? const Duration(seconds: 8) : const Duration(seconds: 4),
            action: isPending
                ? SnackBarAction(
                    label: 'Activate Now',
                    textColor: Colors.white,
                    onPressed: () => context.go('/activate'),
                  )
                : null,
          ),
        );
      }
    });

    final isLoading = authState is AuthLoading || authState is AuthProfileLoading;
    final loadingLabel = authState is AuthProfileLoading ? "Verifying Session..." : "Signing in...";

    final isDesktop = AcadexBreakpoints.isDesktop(context);
    final isTablet = AcadexBreakpoints.isTablet(context);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AnimatedParticleSphereBackground(
        variant: ParticleSphereVariant.login,
        sphereAlignment: isDesktop ? const Alignment(-0.35, 0.0) : Alignment.center,
        intensityMultiplier: 0.88,
        child: SafeArea(
          child: isDesktop
              ? Row(
                  children: [
                    // Left Hero Showcase Section (Solid & Confident Blue Visual Field)
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0F172A), // Slate 900 — Solid foundation
                              Color(0xFF1E1B4B), // Deep Indigo 950 — Solid foundation
                            ],
                          ),
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFF334155), // Crisp Slate 700 boundary
                              width: 1,
                            ),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight - 96 > 0 ? constraints.maxHeight - 96 : 0),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 1. ACADEX Brand Header
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [AcadexColors.primary, Color(0xFF6366F1)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: AcadexRadius.borderRadiusMd,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AcadexColors.primary.withValues(alpha: 0.35),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          'Acadex',
                                          style: AcadexTypography.heading1(color: Colors.white),
                                        ),
                                      ],
                                    ),

                                    // 2 & 3. Hero Value Proposition & Supporting Description
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 28),
                                        const AcadexBadge(
                                          label: 'CAMPUS OPERATING SYSTEM',
                                          variant: AcadexBadgeVariant.primary,
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'The complete platform for academic institutions.',
                                          style: AcadexTypography.display2(color: Colors.white).copyWith(
                                            letterSpacing: -0.8,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Unified attendance tracking, intelligent timetable scheduling, faculty management, notes distribution, and institutional analytics.',
                                          style: AcadexTypography.body(
                                            color: Colors.white.withValues(alpha: 0.85),
                                          ).copyWith(height: 1.5),
                                        ),
                                        const SizedBox(height: 24),

                                        // 4 & 5. Compact Feature Highlights
                                        const _FeaturePill(
                                          icon: LucideIcons.clipboardCheck,
                                          title: 'Verified Attendance',
                                          subtitle: 'Role-scoped session logging and instant verification',
                                        ),
                                        const SizedBox(height: 8),
                                        const _FeaturePill(
                                          icon: LucideIcons.calendar,
                                          title: 'Authoritative Timetables',
                                          subtitle: 'Conflict-free schedules for sections, faculty, and rooms',
                                        ),
                                        const SizedBox(height: 8),
                                        const _FeaturePill(
                                          icon: LucideIcons.bookOpen,
                                          title: 'Curriculum & Notes Hub',
                                          subtitle: 'Direct syllabus materials distribution and offline access',
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),

                                    // Footer Note
                                    Text(
                                      '© 2026 Acadex Platform. Secure Multi-Tenant Architecture.',
                                      style: AcadexTypography.caption(
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Form Area (Anchored & Cohesive Card)
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _buildFormCard(context, isDark, isLoading, loadingLabel),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 48.0 : 16.0,
                      vertical: 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mobile / Tablet Header
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AcadexColors.primary, Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: AcadexRadius.borderRadiusMd,
                              boxShadow: [
                                BoxShadow(
                                  color: AcadexColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Acadex',
                            style: AcadexTypography.heading1(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Campus Management Platform',
                            style: AcadexTypography.bodySmall(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFormCard(context, isDark, isLoading, loadingLabel),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    bool isDark,
    bool isLoading,
    String loadingLabel,
  ) {
    final isMobile = AcadexBreakpoints.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Solid White / Dark Surface Card with Refined Elevation
        AcadexCard(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 28,
            vertical: isMobile ? 24 : 30,
          ),
          backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
          borderColor: isDark ? AcadexColors.darkHairline : const Color(0xFFE2E8F0),
          borderRadius: AcadexRadius.borderRadiusLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 6. Login Heading (Dominates the card)
                Text(
                  'Welcome Back',
                  style: AcadexTypography.heading2(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(letterSpacing: -0.4),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your credentials to access your dashboard.',
                  style: AcadexTypography.bodySmall(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Form Labels & 8. Input Controls: Identifier Field
                Text(
                  'Email or Phone Number',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _identifierController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. user@acadex.edu, 26CSE042, or phone',
                    prefixIcon: Icon(
                      LucideIcons.user,
                      size: 18,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter your email or phone number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Password',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ).copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: isLoading ? null : () => context.go('/forgot-password'),
                      child: Text(
                        'Forgot password?',
                        style: AcadexTypography.caption(
                          color: AcadexColors.primary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  obscureText: !_isPasswordVisible,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
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
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Please enter your password";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Primary Button
                AcadexButton(
                  label: isLoading ? loadingLabel : 'Sign In',
                  icon: LucideIcons.logIn,
                  isLoading: isLoading,
                  isFullWidth: true,
                  size: AcadexButtonSize.lg,
                  onPressed: isLoading ? null : _handleLogin,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 5. Strengthened "Activate Account" Secondary CTA
        Center(
          child: TextButton(
            onPressed: () => context.go('/activate'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(0, 44),
            ),
            child: Text.rich(
              TextSpan(
                text: 'New student or faculty? ',
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                ),
                children: [
                  TextSpan(
                    text: 'Activate Account',
                    style: AcadexTypography.bodySmall(
                      color: AcadexColors.primary,
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AcadexColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // 11. Development Role Quick-Login (Clearly secondary, collapsed by default)
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _showDevDrawer,
              onExpansionChanged: (exp) => setState(() => _showDevDrawer = exp),
              tilePadding: EdgeInsets.zero,
              title: Row(
                children: [
                  const Icon(LucideIcons.code2, size: 13, color: AcadexColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'DEVELOPMENT ROLE QUICK-LOGIN',
                      style: AcadexTypography.eyebrow(color: AcadexColors.warning).copyWith(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              children: [
                AcadexCard(
                  backgroundColor: isDark
                      ? AcadexColors.warningDarkContainer.withValues(alpha: 0.20)
                      : AcadexColors.warningLight.withValues(alpha: 0.60),
                  borderColor: isDark ? AcadexColors.warningDark : AcadexColors.warning.withValues(alpha: 0.25),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AcadexDropdown<String>(
                        value: _selectedDevRole,
                        hint: 'Select Test Role',
                        prefixIcon: LucideIcons.userCheck,
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
                            _selectedDevRole = val;
                            switch (val) {
                              case "Super Admin":
                                _identifierController.text = "admin@acadex.com";
                                _passwordController.text = "acadex123";
                                break;
                              case "College Admin":
                                _identifierController.text = "college@acadex.com";
                                _passwordController.text = "acadex123";
                                break;
                              case "HOD":
                                _identifierController.text = "hod@acadex.com";
                                _passwordController.text = "acadex123";
                                break;
                              case "Faculty":
                                _identifierController.text = "faculty@acadex.com";
                                _passwordController.text = "acadex123";
                                break;
                              case "Student":
                                _identifierController.text = "student@acadex.com";
                                _passwordController.text = "acadex123";
                                break;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      AcadexButton(
                        label: _selectedDevRole == null ? "Sign In as Role..." : "Sign In as $_selectedDevRole",
                        variant: AcadexButtonVariant.secondary,
                        icon: LucideIcons.play,
                        size: AcadexButtonSize.sm,
                        onPressed: (isLoading || _selectedDevRole == null)
                            ? null
                            : () {
                                ref.read(authProvider.notifier).loginAsDevelopmentRole(
                                  _mapStringToRole(_selectedDevRole!),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact supporting feature pill row with tight spacing and clean alignment.
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeaturePill({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.65),
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.60),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: AcadexRadius.borderRadiusSm,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AcadexTypography.body(color: Colors.white).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AcadexTypography.caption(
                    color: Colors.white.withValues(alpha: 0.72),
                  ).copyWith(
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
