import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/attendance_session.dart';

class AuditInfoCard extends StatelessWidget {
  final AttendanceSession session;

  const AuditInfoCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "AUDIT TRAIL",
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.25) : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusFull,
                ),
                child: Text(
                  "v${session.version}",
                  style: AcadexTypography.caption(
                    color: isDark ? Colors.white : AcadexColors.primary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRow("Created By", session.createdBy ?? "System", session.createdAt, isDark),
          Divider(height: 18, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          _buildRow("Last Modified", session.lastModifiedBy ?? "System", session.lastModifiedAt, isDark),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String user, DateTime? date, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (date != null)
          Text(
            DateFormat('MMM dd, yyyy • HH:mm').format(date),
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
      ],
    );
  }
}
