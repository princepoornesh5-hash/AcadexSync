import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/presentation/widgets/acadex_badge.dart';

class AttendanceLockChip extends StatelessWidget {
  final bool isLocked;

  const AttendanceLockChip({super.key, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return const AcadexBadge(
        label: 'Locked',
        variant: AcadexBadgeVariant.neutral,
        icon: LucideIcons.lock,
      );
    }
    return const AcadexBadge(
      label: 'Draft',
      variant: AcadexBadgeVariant.warning,
      icon: LucideIcons.fileEdit,
    );
  }
}
