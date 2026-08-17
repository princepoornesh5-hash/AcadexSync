import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/super_admin_insight.dart';

class SuperAdminInsightCard extends StatelessWidget {
  final SuperAdminInsight insight;

  const SuperAdminInsightCard({super.key, required this.insight});

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
                color: insight.isPositive ? DashboardColors.success.withValues(alpha: 0.1) : DashboardColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                insight.isPositive ? Icons.analytics : Icons.radar,
                color: insight.isPositive ? DashboardColors.success : DashboardColors.primary,
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
