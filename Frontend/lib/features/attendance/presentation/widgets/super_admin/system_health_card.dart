import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/super_admin_system_health.dart';

class SystemHealthCard extends StatelessWidget {
  final SuperAdminSystemHealth health;

  const SystemHealthCard({super.key, required this.health});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monitor_heart, color: DashboardColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  "System Health",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow("Server Status", health.serverStatus, DashboardColors.success),
            const Divider(color: DashboardColors.border, height: 24),
            _buildStatusRow("Sync Status", health.syncStatus, DashboardColors.success),
            const Divider(color: DashboardColors.border, height: 24),
            _buildStatusRow("API Latency", health.apiLatency, DashboardColors.primary),
            const Divider(color: DashboardColors.border, height: 24),
            _buildStatusRow("Active Users", health.activeUsers.toString(), DashboardColors.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: DashboardColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
