import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../providers/timetable_lookup_providers.dart';

class AcadexTimetableCalendar extends ConsumerStatefulWidget {
  final AppRole? role;
  final VoidCallback? onCalendarAction;

  const AcadexTimetableCalendar({
    super.key,
    this.role,
    this.onCalendarAction,
  });

  @override
  ConsumerState<AcadexTimetableCalendar> createState() => _AcadexTimetableCalendarState();
}

class _AcadexTimetableCalendarState extends ConsumerState<AcadexTimetableCalendar> {
  late DateTime _currentMonth;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    final selectedDate = ref.read(timetableSelectedDateProvider);
    _currentMonth = DateTime(selectedDate.year, selectedDate.month, 1);
  }

  void _onPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _onNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _onSelectDate(DateTime date) {
    ref.read(timetableSelectedDateProvider.notifier).state = DateTime(date.year, date.month, date.day);
    if (date.month != _currentMonth.month || date.year != _currentMonth.year) {
      setState(() {
        _currentMonth = DateTime(date.year, date.month, 1);
      });
    }
  }

  Future<void> _pickDate() async {
    final selectedDate = ref.read(timetableSelectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AcadexColors.primary,
              onPrimary: Colors.white,
              surface: AcadexColors.surface,
              onSurface: AcadexColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _onSelectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(timetableSelectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStudent = widget.role == AppRole.student;

    final monthFormatter = DateFormat("MMMM ''yy");
    final monthTitle = monthFormatter.format(_currentMonth);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          borderRadius: AcadexRadius.borderRadiusLg,
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
          boxShadow: isDark ? null : AcadexShadows.lightSm,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Header Row: < August '26 > | Legend / Calendar Icon
          Row(
            children: [
              // Previous Month Button (approx 48dp touch target)
              Semantics(
                label: 'Previous Month',
                button: true,
                child: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, size: 20),
                  tooltip: 'Previous Month',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: _onPreviousMonth,
                ),
              ),

              // Month & Year title
              Text(
                monthTitle,
                style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),

              // Next Month Button (approx 48dp touch target)
              Semantics(
                label: 'Next Month',
                button: true,
                child: IconButton(
                  icon: const Icon(LucideIcons.chevronRight, size: 20),
                  tooltip: 'Next Month',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: _onNextMonth,
                ),
              ),

              const Spacer(),

              // Legend (for Student view)
              if (isStudent) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AcadexColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Present',
                      style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)
                          .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AcadexColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Absent',
                      style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)
                          .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],

              // Return to Today / Calendar action button (approx 48dp touch target)
              Semantics(
                label: 'Choose Date',
                button: true,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AcadexColors.primary.withValues(alpha: 0.1),
                      borderRadius: AcadexRadius.borderRadiusSm,
                      border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(LucideIcons.calendar, size: 16, color: AcadexColors.primary),
                  ),
                  tooltip: 'Choose Date',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: widget.onCalendarAction ?? _pickDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Weekday Labels Row (Sun, Mon, Tue, Wed, Thu, Fri, Sat)
          _buildWeekdayLabelsRow(context),

          const SizedBox(height: 6),

          // Days Row or Month Grid (AnimatedSwitcher keeps tree clean)
          AnimatedSwitcher(
            duration: AcadexMotion.resolveDuration(context, AcadexMotion.fast),
            child: KeyedSubtree(
              key: ValueKey(_isExpanded),
              child: _isExpanded
                  ? _buildMonthGrid(context, selectedDate)
                  : _buildWeekStrip(context, selectedDate),
            ),
          ),

          // Expand / Collapse Chevron Toggle
          Center(
            child: Semantics(
              label: _isExpanded ? 'Collapse calendar' : 'Expand calendar',
              button: true,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Icon(
                    _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildWeekdayLabelsRow(BuildContext context) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted;

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekStrip(BuildContext context, DateTime selectedDate) {
    final daysFromSunday = selectedDate.weekday % 7;
    final sunday = selectedDate.subtract(Duration(days: daysFromSunday));
    final weekDays = List.generate(7, (i) => sunday.add(Duration(days: i)));

    return Row(
      children: weekDays.map((date) => Expanded(child: _buildDayCell(context, date, selectedDate))).toList(),
    );
  }

  Widget _buildMonthGrid(BuildContext context, DateTime selectedDate) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysFromSunday = firstDayOfMonth.weekday % 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: daysFromSunday));

    const totalDays = 35; // 5 weeks
    final days = List.generate(totalDays, (i) => startDate.add(Duration(days: i)));

    return Column(
      children: List.generate(5, (weekIndex) {
        final weekDays = days.sublist(weekIndex * 7, (weekIndex + 1) * 7);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: weekDays.map((date) => Expanded(child: _buildDayCell(context, date, selectedDate))).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, DateTime selectedDate) {
    final now = DateTime.now();
    final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isCurrentMonth = date.month == _currentMonth.month;

    final cellColor = isSelected ? AcadexColors.primary : Colors.transparent;
    final textColor = isSelected
        ? Colors.white
        : (!isCurrentMonth
            ? (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).withValues(alpha: 0.4)
            : (isToday ? AcadexColors.primary : (Theme.of(context).colorScheme.onSurface)));

    return Semantics(
      label: '${date.day}, ${isToday ? "Today, " : ""}${isSelected ? "Selected" : ""}',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () => _onSelectDate(date),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Day Pill
              AnimatedContainer(
                duration: AcadexMotion.resolveDuration(context, AcadexMotion.fast),
                curve: AcadexMotion.curveStandard,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cellColor,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: AcadexColors.primary, width: 1.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 2),

              // "Today" Indicator label
              if (isToday)
                Text(
                  'Today',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AcadexColors.primary,
                  ),
                )
              else
                const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
