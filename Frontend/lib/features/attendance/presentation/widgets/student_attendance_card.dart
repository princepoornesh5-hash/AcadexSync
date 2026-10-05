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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: status == null
              ? (isDark ? AcadexColors.darkHairline : AcadexColors.hairline)
              : (status == AttendanceStatus.present
                  ? AcadexColors.success.withValues(alpha: 0.4)
                  : status == AttendanceStatus.late
                      ? AcadexColors.warning.withValues(alpha: 0.4)
                      : status == AttendanceStatus.excused
                          ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                          : AcadexColors.error.withValues(alpha: 0.4)),
          width: status != null ? 1.5 : 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 460;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AcadexAvatar(
                        name: record.studentName,
                        size: 34,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.studentName,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              record.rollNumber,
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ).copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusIndicator(status, isDark),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSegmentedControl(isDark),
                ],
              );
            }

            return Row(
              children: [
                AcadexAvatar(
                  name: record.studentName,
                  size: 36,
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
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        record.rollNumber,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusIndicator(status, isDark),
                const SizedBox(width: 12),
                _buildSegmentedControl(isDark, width: 320),
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
          borderRadius: AcadexRadius.borderRadiusFull,
        ),
        child: Text(
          'UNMARKED',
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
          ).copyWith(fontSize: 9.5, fontWeight: FontWeight.w700),
        ),
      );
    }

    final color = status == AttendanceStatus.present
        ? AcadexColors.success
        : status == AttendanceStatus.late
            ? AcadexColors.warning
            : status == AttendanceStatus.excused
                ? const Color(0xFF6366F1)
                : AcadexColors.error;

    return Semantics(
      label: 'Status: ${status.name}',
      child: Icon(
        status == AttendanceStatus.present
            ? LucideIcons.checkCircle2
            : status == AttendanceStatus.late
                ? LucideIcons.clock
                : status == AttendanceStatus.excused
                    ? LucideIcons.shieldCheck
                    : LucideIcons.xCircle,
        color: color,
        size: 17,
      ),
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
      padding: const EdgeInsets.all(2.5),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              label: 'Present',
              shortLabel: '✓ P',
              icon: LucideIcons.check,
              status: AttendanceStatus.present,
              activeBg: isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight,
              activeBorder: AcadexColors.success,
              activeFg: AcadexColors.success,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _buildSegmentButton(
              label: 'Late',
              shortLabel: '⏱ L',
              icon: LucideIcons.clock,
              status: AttendanceStatus.late,
              activeBg: isDark ? AcadexColors.warningDarkContainer : AcadexColors.warningLight,
              activeBorder: AcadexColors.warning,
              activeFg: AcadexColors.warning,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _buildSegmentButton(
              label: 'Absent',
              shortLabel: '✕ A',
              icon: LucideIcons.x,
              status: AttendanceStatus.absent,
              activeBg: isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight,
              activeBorder: AcadexColors.error,
              activeFg: AcadexColors.error,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _buildSegmentButton(
              label: 'Excused',
              shortLabel: '🛡 E',
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

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Mark ${record.studentName} as $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onStatusChanged(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
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
                size: 12,
                color: isSelected ? activeFg : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(width: 2.5),
              Flexible(
                child: Text(
                  label,
                  style: AcadexTypography.caption(
                    color: isSelected
                        ? activeFg
                        : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
