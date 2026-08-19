import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../domain/models/attendance_status.dart';
import '../../../../../core/presentation/widgets/acadex_badge.dart';

class AttendanceBadge extends StatelessWidget {
  final AttendanceStatus status;

  const AttendanceBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AttendanceStatus.present:
        return const AcadexBadge(
          label: 'Present',
          variant: AcadexBadgeVariant.success,
          icon: LucideIcons.checkCircle2,
        );
      case AttendanceStatus.late:
        return const AcadexBadge(
          label: 'Late',
          variant: AcadexBadgeVariant.warning,
          icon: LucideIcons.clock,
        );
      case AttendanceStatus.absent:
        return const AcadexBadge(
          label: 'Absent',
          variant: AcadexBadgeVariant.danger,
          icon: LucideIcons.xCircle,
        );
      case AttendanceStatus.medicalLeave:
        return const AcadexBadge(
          label: 'Medical',
          variant: AcadexBadgeVariant.purple,
          icon: LucideIcons.activity,
        );
      case AttendanceStatus.onDuty:
        return const AcadexBadge(
          label: 'On Duty',
          variant: AcadexBadgeVariant.teal,
          icon: LucideIcons.briefcase,
        );
      case AttendanceStatus.holiday:
        return const AcadexBadge(
          label: 'Holiday',
          variant: AcadexBadgeVariant.info,
          icon: LucideIcons.sun,
        );
    }
  }
}
