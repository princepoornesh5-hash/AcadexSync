import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/college_insight.dart';

class CollegeInsightCard extends StatelessWidget {
  final CollegeInsight insight;

  const CollegeInsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DashboardColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: DashboardColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: insight.isPositive ? DashboardColors.success.withValues(alpha: 0.1) : DashboardColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                insight.isPositive ? Icons.lightbulb : Icons.info_outline,
                color: insight.isPositive ? DashboardColors.success : DashboardColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.subtitle,
                    style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
