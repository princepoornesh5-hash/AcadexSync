import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AttendanceHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const AttendanceHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: DashboardColors.surface,
        border: Border(bottom: BorderSide(color: DashboardColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: DashboardColors.textPrimary),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: DashboardColors.textSecondary)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
