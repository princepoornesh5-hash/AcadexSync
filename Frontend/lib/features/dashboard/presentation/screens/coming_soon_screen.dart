import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final String moduleName;

  const ComingSoonScreen({super.key, required this.moduleName});

  IconData _iconForModule(String name) {
    switch (name.toLowerCase()) {
      case 'attendance':
        return LucideIcons.clipboardCheck;
      case 'timetable':
        return LucideIcons.calendarDays;
      case 'notes':
        return LucideIcons.fileText;

      case 'profile':
        return LucideIcons.userCircle;
      case 'settings':
        return LucideIcons.settings;
      case 'notifications':
        return LucideIcons.bell;
      case 'modules':
        return LucideIcons.grid3x3;
      default:
        return LucideIcons.layoutDashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
          ),
          title: Text(moduleName),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: DashboardColors.primaryLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    _iconForModule(moduleName),
                    color: DashboardColors.primary,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  moduleName,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: DashboardColors.warningLight,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'This module is under development and will be available in a future update.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: DashboardColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                OutlinedButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
