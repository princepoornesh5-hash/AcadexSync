import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/practical_models.dart';

class PracticalParticipationCard extends StatelessWidget {
  final PracticalParticipationModel participation;
  final bool isSessionOpen;
  final ValueChanged<PracticalParticipationStatus>? onStatusChanged;
  final VoidCallback? onEditNotes;

  const PracticalParticipationCard({
    super.key,
    required this.participation,
    required this.isSessionOpen,
    this.onStatusChanged,
    this.onEditNotes,
  });

  Color _getStatusColor() {
    switch (participation.status) {
      case PracticalParticipationStatus.completed:
        return const Color(0xFF15803D);
      case PracticalParticipationStatus.inProgress:
        return AcadexColors.primary;
      case PracticalParticipationStatus.absent:
        return const Color(0xFFDC2626);
      case PracticalParticipationStatus.excused:
        return const Color(0xFFD97706);
      case PracticalParticipationStatus.notStarted:
        return AcadexColors.inkSecondary;
    }
  }

  Color _getStatusBg() {
    switch (participation.status) {
      case PracticalParticipationStatus.completed:
        return const Color(0xFFDCFCE7);
      case PracticalParticipationStatus.inProgress:
        return AcadexColors.primaryTint;
      case PracticalParticipationStatus.absent:
        return const Color(0xFFFEE2E2);
      case PracticalParticipationStatus.excused:
        return const Color(0xFFFEF3C7);
      case PracticalParticipationStatus.notStarted:
        return AcadexColors.canvasSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Student Name + Roll Number
          Row(
            children: [
              Expanded(
                child: Text(
                  participation.studentName,
                  style: AcadexTypography.title(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (participation.rollNumber != null) ...[
                const SizedBox(width: 6),
                Text(
                  '(${participation.rollNumber})',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Row 2: Status pill + Action controls (scaled down to fit 360px)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: _getStatusBg(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    participation.status.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
                if (participation.notes != null && participation.notes!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(LucideIcons.fileText, size: 12, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  const SizedBox(width: 3),
                  Text(
                    participation.notes!,
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ],
                if (isSessionOpen && onStatusChanged != null) ...[
                  const SizedBox(width: 12),
                  // Quick Actions
                  _buildQuickAction(
                    label: 'In Progress',
                    color: AcadexColors.primary,
                    isSelected: participation.status == PracticalParticipationStatus.inProgress,
                    onTap: () => onStatusChanged!(PracticalParticipationStatus.inProgress),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildQuickAction(
                    label: 'Completed',
                    color: const Color(0xFF15803D),
                    isSelected: participation.status == PracticalParticipationStatus.completed,
                    onTap: () => onStatusChanged!(PracticalParticipationStatus.completed),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildQuickAction(
                    label: 'Absent',
                    color: const Color(0xFFDC2626),
                    isSelected: participation.status == PracticalParticipationStatus.absent,
                    onTap: () => onStatusChanged!(PracticalParticipationStatus.absent),
                    isDark: isDark,
                  ),
                ],
                if (onEditNotes != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onEditNotes,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        LucideIcons.edit2,
                        size: 13,
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? color : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
          ),
        ),
      ),
    );
  }
}
