import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../features/auth/domain/models/auth_state.dart';
import '../../../features/auth/domain/models/role_enum.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/acadex_button.dart';
import '../widgets/acadex_page_container.dart';

/// Screen displayed when an authenticated user attempts to access a route or resource
/// outside their assigned role or administrative scope.
class AcadexAccessRestrictedScreen extends ConsumerWidget {
  final String? message;

  const AcadexAccessRestrictedScreen({
    super.key,
    this.message,
  });

  static String getHomeRouteForRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return '/dashboard/super_admin';
      case AppRole.collegeAdmin:
        return '/dashboard/college_admin';
      case AppRole.hod:
        return '/dashboard/hod';
      case AppRole.faculty:
        return '/dashboard/faculty';
      case AppRole.student:
        return '/dashboard/student';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppRole? role;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final homeRoute = role != null ? getHomeRouteForRole(role) : '/login';

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 540,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusXl,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
                boxShadow: isDark ? AcadexShadows.darkMd : AcadexShadows.lightMd,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFECACA), width: 1),
                    ),
                    child: const Icon(
                      LucideIcons.shieldAlert,
                      size: 34,
                      color: AcadexColors.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AcadexColors.error.withValues(alpha: 0.1),
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: const Text(
                      '403 — ACCESS RESTRICTED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AcadexColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Restricted',
                    style: AcadexTypography.heading2(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message ??
                        'You don\'t have permission to access or manage this section. If you believe this is an error, please contact your college administrator.',
                    style: AcadexTypography.body(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(homeRoute);
                            }
                          },
                          icon: const Icon(LucideIcons.arrowLeft, size: 16),
                          label: const Text('Go Back'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            side: BorderSide(
                              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: AcadexRadius.borderRadiusMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AcadexButton(
                          label: 'Go to Dashboard',
                          icon: LucideIcons.layoutDashboard,
                          size: AcadexButtonSize.md,
                          onPressed: () => context.go(homeRoute),
                          isFullWidth: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
