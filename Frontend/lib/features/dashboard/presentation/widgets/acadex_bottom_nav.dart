import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AcadexBottomNav extends ConsumerWidget {
  final String activeRoute;
  final ValueChanged<String> onTabSelected;

  const AcadexBottomNav({
    super.key,
    required this.activeRoute,
    required this.onTabSelected,
  });

  String _dashboardRouteForRole(AppRole role) {
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
    final user = authState is AuthAuthenticated ? authState.user : null;
    final dashboardRoute = user != null ? _dashboardRouteForRole(user.role) : '/login';

    int currentIndex = 0;
    if (activeRoute.startsWith('/attendance')) {
      currentIndex = 1;
    } else if (activeRoute.startsWith('/profile')) {
      currentIndex = 2;
    }

    return Container(
      decoration: const BoxDecoration(
        color: DashboardColors.surface,
        border: Border(top: BorderSide(color: DashboardColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavTab(
              icon: LucideIcons.layoutDashboard,
              label: 'Dashboard',
              isActive: currentIndex == 0,
              onTap: () => onTabSelected(dashboardRoute),
            ),
            _NavTab(
              icon: LucideIcons.clipboardCheck,
              label: 'Attendance',
              isActive: currentIndex == 1,
              onTap: () => onTabSelected('/attendance'),
            ),
            _NavTab(
              icon: LucideIcons.userCircle,
              label: 'Profile',
              isActive: currentIndex == 2,
              onTap: () => onTabSelected('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? DashboardColors.primary : DashboardColors.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? DashboardColors.primary : DashboardColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
