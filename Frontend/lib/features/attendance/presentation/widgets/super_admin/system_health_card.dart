import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/super_admin_system_health.dart';

class SystemHealthCard extends StatelessWidget {
  final SuperAdminSystemHealth health;

  const SystemHealthCard({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusXl,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.activity,
                  color: AcadexColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  "System Health & Telemetry",
                  style: AcadexTypography.title(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatusRow("Server Status", health.serverStatus, AcadexColors.success, isDark),
            Divider(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline, height: 24),
            _buildStatusRow("Sync Engine", health.syncStatus, AcadexColors.success, isDark),
            Divider(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline, height: 24),
            _buildStatusRow("API Latency", health.apiLatency, AcadexColors.primary, isDark),
            Divider(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline, height: 24),
            _buildStatusRow("Active Sessions", health.activeUsers.toString(), isDark ? AcadexColors.darkInk : AcadexColors.ink, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AcadexTypography.bodySmall(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        Text(
          value,
          style: AcadexTypography.body(
            color: valueColor,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
