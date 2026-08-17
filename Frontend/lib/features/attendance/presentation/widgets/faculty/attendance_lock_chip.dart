import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';

class AttendanceLockChip extends StatelessWidget {
  final bool isLocked;

  const AttendanceLockChip({
    super.key,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLocked ? DashboardColors.success : DashboardColors.warning;
    final label = isLocked ? "Locked" : "Draft";
    final icon = isLocked ? Icons.lock : Icons.edit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
