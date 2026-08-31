import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_status.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';

class StudentAttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const StudentAttendanceCard({
    super.key,
    required this.record,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = record.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: status == null
              ? (isDark ? AcadexColors.darkHairline : AcadexColors.hairline)
              : (status == AttendanceStatus.present
                  ? AcadexColors.success.withValues(alpha: 0.3)
                  : status == AttendanceStatus.late
                      ? AcadexColors.warning.withValues(alpha: 0.3)
                      : AcadexColors.error.withValues(alpha: 0.3)),
          width: status != null ? 1.5 : 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AcadexAvatar(
                        name: record.studentName,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.studentName,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              record.rollNumber,
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusIndicator(status, isDark),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSegmentedControl(isDark),
                ],
              );
            }

            return Row(
              children: [
                AcadexAvatar(
                  name: record.studentName,
                  size: 40,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.studentName,
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.rollNumber,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildSegmentedControl(isDark, width: 330),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(AttendanceStatus? status, bool isDark) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
          borderRadius: AcadexRadius.borderRadiusFull,
        ),
        child: Text(
          'UNMARKED',
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
          ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
    }

    final color = status == AttendanceStatus.present
        ? AcadexColors.success
        : status == AttendanceStatus.late
            ? AcadexColors.warning
            : AcadexColors.error;

    return Icon(
      status == AttendanceStatus.present
          ? LucideIcons.checkCircle2
          : status == AttendanceStatus.late
              ? LucideIcons.clock
              : LucideIcons.xCircle,
      color: color,
      size: 18,
    );
  }

  Widget _buildSegmentedControl(bool isDark, {double? width}) {
    final control = Container(
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              label: 'Present',
              shortLabel: 'P',
              icon: LucideIcons.check,
              status: AttendanceStatus.present,
              activeBg: isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight,
              activeBorder: AcadexColors.success,
              activeFg: AcadexColors.success,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegmentButton(
              label: 'Late',
              shortLabel: 'L',
              icon: LucideIcons.clock,
              status: AttendanceStatus.late,
              activeBg: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
              activeBorder: AcadexColors.warning,
              activeFg: AcadexColors.warning,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegmentButton(
              label: 'Absent',
              shortLabel: 'A',
              icon: LucideIcons.x,
              status: AttendanceStatus.absent,
              activeBg: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
              activeBorder: AcadexColors.error,
              activeFg: AcadexColors.error,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegmentButton(
              label: 'Excused',
              shortLabel: 'E',
              icon: LucideIcons.shieldCheck,
              status: AttendanceStatus.excused,
              activeBg: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
              activeBorder: const Color(0xFF6366F1),
              activeFg: const Color(0xFF6366F1),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: control);
    }
    return control;
  }

  Widget _buildSegmentButton({
    required String label,
    required String shortLabel,
    required IconData icon,
    required AttendanceStatus status,
    required Color activeBg,
    required Color activeBorder,
    required Color activeFg,
    required bool isDark,
  }) {
    final isSelected = record.status == status;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onStatusChanged(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: AcadexRadius.borderRadiusSm,
          border: Border.all(
            color: isSelected ? activeBorder : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? activeFg : AcadexColors.inkMuted,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: AcadexTypography.caption(
                  color: isSelected ? activeFg : AcadexColors.inkSecondary,
                ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
