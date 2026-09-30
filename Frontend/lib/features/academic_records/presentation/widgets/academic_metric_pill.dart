import 'package:flutter/material.dart';

class AcademicMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final num? percentage;
  final VoidCallback? onTap;

  const AcademicMetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.percentage,
    this.onTap,
  });

  Color _resolveColor(BuildContext context) {
    if (percentage == null) {
      return Theme.of(context).colorScheme.primary;
    }
    if (percentage! >= 75) {
      return const Color(0xFF10B981); // Emerald
    } else if (percentage! >= 60) {
      return const Color(0xFFF59E0B); // Amber
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _resolveColor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              '$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
