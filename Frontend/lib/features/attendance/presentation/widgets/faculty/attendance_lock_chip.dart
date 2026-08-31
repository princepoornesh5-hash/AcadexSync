import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/presentation/widgets/acadex_badge.dart';

class AttendanceLockChip extends StatelessWidget {
  final bool isLocked;
  final String? status;

  const AttendanceLockChip({super.key, required this.isLocked, this.status});

  @override
  Widget build(BuildContext context) {
    final st = status?.toLowerCase();
    if (st == 'cancelled') {
      return const AcadexBadge(
        label: 'Cancelled',
        variant: AcadexBadgeVariant.danger,
        icon: LucideIcons.ban,
      );
    }
    if (st == 'closed') {
      return const AcadexBadge(
        label: 'Closed',
        variant: AcadexBadgeVariant.success,
        icon: LucideIcons.checkCircle,
      );
    }
    if (isLocked || st == 'locked') {
      return const AcadexBadge(
        label: 'Locked',
        variant: AcadexBadgeVariant.neutral,
        icon: LucideIcons.lock,
      );
    }
    return const AcadexBadge(
      label: 'Open',
      variant: AcadexBadgeVariant.primary,
      icon: LucideIcons.fileEdit,
    );
  }
}
