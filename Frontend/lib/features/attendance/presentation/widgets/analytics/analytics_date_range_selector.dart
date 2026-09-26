import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../domain/models/attendance_analytics_models.dart';

class AnalyticsDateRangeSelector extends StatelessWidget {
  final AttendanceDateRange selectedRange;
  final ValueChanged<AttendanceDateRange> onRangeChanged;

  const AnalyticsDateRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2, 1, 1);
    final lastDate = DateTime(now.year + 1, 12, 31);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(
        start: selectedRange.startDate,
        end: selectedRange.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AcadexColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onRangeChanged(
        AttendanceDateRange.custom(
          startDate: picked.start,
          endDate: picked.end,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentButton(
              context,
              label: 'Today',
              icon: LucideIcons.calendar,
              isSelected: selectedRange.preset == AttendanceDateRangePreset.today,
              onTap: () => onRangeChanged(AttendanceDateRange.today()),
            ),
            const SizedBox(width: 4),
            _buildSegmentButton(
              context,
              label: 'This Week',
              icon: LucideIcons.calendarDays,
              isSelected: selectedRange.preset == AttendanceDateRangePreset.thisWeek,
              onTap: () => onRangeChanged(AttendanceDateRange.thisWeek()),
            ),
            const SizedBox(width: 4),
            _buildSegmentButton(
              context,
              label: 'This Month',
              icon: LucideIcons.calendarRange,
              isSelected: selectedRange.preset == AttendanceDateRangePreset.thisMonth,
              onTap: () => onRangeChanged(AttendanceDateRange.thisMonth()),
            ),
            const SizedBox(width: 4),
            _buildSegmentButton(
              context,
              label: selectedRange.preset == AttendanceDateRangePreset.custom
                  ? '${selectedRange.startDate.day}/${selectedRange.startDate.month} - ${selectedRange.endDate.day}/${selectedRange.endDate.month}'
                  : 'Custom',
              icon: LucideIcons.calendarCheck2,
              isSelected: selectedRange.preset == AttendanceDateRangePreset.custom,
              onTap: () => _pickCustomRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AcadexRadius.borderRadiusSm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AcadexColors.primary
                : Colors.transparent,
            borderRadius: AcadexRadius.borderRadiusSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AcadexTypography.caption(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
