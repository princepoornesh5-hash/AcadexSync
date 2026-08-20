import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/models/assigned_class.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';

class AssignedClassCard extends StatelessWidget {
  final AssignedClass assignedClass;
  final VoidCallback onTap;

  const AssignedClassCard({
    super.key,
    required this.assignedClass,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final times = assignedClass.timeSlot.split(' - ');
    final startTime = times.isNotEmpty ? times[0] : '';
    final endTime = times.length > 1 ? times[1] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AcadexRadius.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AcadexRadius.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Time Slot Column
                Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AcadexColors.primaryHover.withValues(alpha: 0.2)
                        : AcadexColors.primaryLight,
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: isDark ? AcadexColors.primaryHover.withValues(alpha: 0.4) : AcadexColors.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        color: isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
                        size: 16,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        startTime,
                        style: AcadexTypography.caption(
                          color: isDark ? Colors.white : AcadexColors.primary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (endTime.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          endTime,
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Class Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              assignedClass.subjectName,
                              style: AcadexTypography.title(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 13,
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            assignedClass.sectionName,
                            style: AcadexTypography.bodySmall(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                          if (assignedClass.semester.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                              ),
                            ),
                            Text(
                              assignedClass.semester,
                              style: AcadexTypography.bodySmall(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (assignedClass.isAttendanceMarked)
                            const AcadexBadge(
                              label: 'Marked',
                              variant: AcadexBadgeVariant.success,
                              icon: LucideIcons.checkCircle2,
                            )
                          else
                            const AcadexBadge(
                              label: 'Pending',
                              variant: AcadexBadgeVariant.warning,
                              icon: LucideIcons.clock,
                            ),
                          if (assignedClass.roomNumber != null && assignedClass.roomNumber!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            AcadexBadge(
                              label: assignedClass.building != null && assignedClass.building!.isNotEmpty
                                  ? '${assignedClass.roomNumber} (${assignedClass.building})'
                                  : 'Room ${assignedClass.roomNumber}',
                              variant: AcadexBadgeVariant.neutral,
                              icon: LucideIcons.mapPin,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
