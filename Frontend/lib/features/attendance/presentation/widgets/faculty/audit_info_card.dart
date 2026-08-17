import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/attendance_session.dart';
import 'package:intl/intl.dart';

class AuditInfoCard extends StatelessWidget {
  final AttendanceSession session;

  const AuditInfoCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Audit Trail", style: TextStyle(fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DashboardColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("v${session.version}", style: const TextStyle(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          _buildRow("Created By", session.createdBy ?? "System", session.createdAt),
          const Divider(),
          _buildRow("Last Modified", session.lastModifiedBy ?? "System", session.lastModifiedAt),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String user, DateTime? date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: DashboardColors.textSecondary)),
            Text(user, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
          ],
        ),
        if (date != null)
          Text(
            DateFormat('MMM dd, yyyy • HH:mm').format(date),
            style: const TextStyle(fontSize: 13, color: DashboardColors.textSecondary),
          ),
      ],
    );
  }
}
