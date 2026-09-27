import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/calendar_event_model.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/create_calendar_event_dialog.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const List<String> _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  void _previousMonth() {
    final current = ref.read(currentMonthProvider);
    final prev = DateTime(current.year, current.month - 1, 1);
    ref.read(currentMonthProvider.notifier).state = prev;
    ref.read(calendarEventsProvider.notifier).loadEvents(prev);
  }

  void _nextMonth() {
    final current = ref.read(currentMonthProvider);
    final next = DateTime(current.year, current.month + 1, 1);
    ref.read(currentMonthProvider.notifier).state = next;
    ref.read(calendarEventsProvider.notifier).loadEvents(next);
  }

  void _jumpToToday() {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    ref.read(currentMonthProvider.notifier).state = month;
    ref.read(selectedCalendarDateProvider.notifier).state = DateTime(now.year, now.month, now.day);
    ref.read(calendarEventsProvider.notifier).loadEvents(month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonth = ref.watch(currentMonthProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    final selectedDayEvents = ref.watch(selectedDayEventsProvider);
    final upcomingEvents = ref.watch(upcomingEventsProvider);
    final activeFilter = ref.watch(calendarFilterProvider);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final role = user?.role ?? AppRole.student;
    final canCreate = role == AppRole.collegeAdmin ||
        role == AppRole.superAdmin ||
        role == AppRole.hod ||
        role == AppRole.faculty;

    final isWide = MediaQuery.of(context).size.width >= 860;

    final calendarCard = Container(
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays
                .map((d) => SizedBox(
                      width: 36,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: d == 'Sun' ? Colors.red.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AcadexColors.hairline),
          const SizedBox(height: 6),

          // Days Grid
          eventsAsync.when(
            data: (events) => _buildMonthDaysGrid(currentMonth, selectedDate, events),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Text('Failed to load events: $err'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(calendarEventsProvider.notifier)
                          .loadEvents(currentMonth, force: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final leftCalendarBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      '${_monthNames[currentMonth.month]} ${currentMonth.year}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 18),
                    onPressed: _previousMonth,
                    tooltip: 'Previous Month',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                    onPressed: _nextMonth,
                    tooltip: 'Next Month',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: _jumpToToday,
              icon: const Icon(LucideIcons.calendarCheck, size: 14),
              label: const Text('Today'),
              style: TextButton.styleFrom(
                foregroundColor: AcadexColors.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', null, activeFilter),
              const SizedBox(width: 6),
              _buildFilterChip('Holidays', 'HOLIDAY', activeFilter),
              const SizedBox(width: 6),
              _buildFilterChip('Exams', 'EXAM', activeFilter),
              const SizedBox(width: 6),
              _buildFilterChip('Deadlines', 'DEADLINE', activeFilter),
              const SizedBox(width: 6),
              _buildFilterChip('Events', 'EVENT', activeFilter),
            ],
          ),
        ),
        const SizedBox(height: 10),

        calendarCard,
      ],
    );

    final rightEventsBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Day Events Section
        Row(
          children: [
            const Icon(LucideIcons.calendarDays, size: 17, color: AcadexColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_weekDays[selectedDate.weekday - 1]}, ${selectedDate.day} ${_monthNames[selectedDate.month]} ${selectedDate.year}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${selectedDayEvents.length} event${selectedDayEvents.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AcadexColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (selectedDayEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AcadexColors.hairline),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.calendarX, size: 24, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text(
                    'No events for this day.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...selectedDayEvents.map((ev) => CalendarEventCard(
                key: ValueKey(ev.id),
                event: ev,
                onRefresh: () => ref
                    .read(calendarEventsProvider.notifier)
                    .loadEvents(currentMonth, force: true),
              )),

        const SizedBox(height: 20),

        // Upcoming Events Section
        Row(
          children: const [
            Icon(LucideIcons.sparkles, size: 17, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text(
              'UPCOMING EVENTS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (upcomingEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AcadexColors.hairline),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendarCheck, size: 18, color: Colors.grey.shade400),
                const SizedBox(width: 10),
                Text(
                  'No upcoming events.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          Builder(
            builder: (context) {
              final Map<DateTime, List<CalendarEventModel>> groupedUpcoming = {};
              for (final ev in upcomingEvents.take(10)) {
                final parsed = DateTime.tryParse(ev.startDate) ?? DateTime.now();
                final dateKey = DateTime(parsed.year, parsed.month, parsed.day);
                groupedUpcoming.putIfAbsent(dateKey, () => []).add(ev);
              }

              final sortedDates = groupedUpcoming.keys.toList()..sort();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final d in sortedDates) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE, MMM d').format(d).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AcadexColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Divider(height: 1, color: AcadexColors.hairline),
                        ],
                      ),
                    ),
                    for (final ev in groupedUpcoming[d]!)
                      CalendarEventCard(
                        key: ValueKey('upcoming_${ev.id}'),
                        event: ev,
                        dateLabel: DateFormat('EEE, MMM d').format(d).toUpperCase(),
                        onRefresh: () => ref
                            .read(calendarEventsProvider.notifier)
                            .loadEvents(currentMonth, force: true),
                      ),
                  ],
                ],
              );
            },
          ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate && !isWide
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CreateCalendarEventDialog(),
                );
              },
              backgroundColor: AcadexColors.primary,
              icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
              label: const Text(
                'Add Event',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(calendarEventsProvider.notifier).loadEvents(currentMonth, force: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canCreate && isWide) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AcadexButton(
                          label: 'Add Event',
                          icon: LucideIcons.plus,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const CreateCalendarEventDialog(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 400, child: leftCalendarBlock),
                        const SizedBox(width: 24),
                        Expanded(child: rightEventsBlock),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leftCalendarBlock,
                        const SizedBox(height: 18),
                        rightEventsBlock,
                        const SizedBox(height: 32),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? currentFilter) {
    final isSelected = currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(calendarFilterProvider.notifier).state = value;
      },
      selectedColor: AcadexColors.primary.withOpacity(0.12),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AcadexColors.primary : const Color(0xFF475569),
      ),
      side: BorderSide(
        color: isSelected ? AcadexColors.primary : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildMonthDaysGrid(
    DateTime month,
    DateTime selectedDate,
    List<CalendarEventModel> events,
  ) {
    // 1st day of month
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // Number of days in month
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Weekday of 1st day (1 = Mon, 7 = Sun)
    final startWeekday = firstDayOfMonth.weekday;

    // Previous month padding days
    final prevMonthDays = DateTime(month.year, month.month, 0).day;
    final leadingDays = startWeekday - 1;

    final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.38,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        int dayNum;
        bool isCurrentMonth = true;
        DateTime cellDate;

        if (index < leadingDays) {
          // Leading days from previous month
          dayNum = prevMonthDays - leadingDays + index + 1;
          isCurrentMonth = false;
          cellDate = DateTime(month.year, month.month - 1, dayNum);
        } else if (index >= leadingDays + daysInMonth) {
          // Trailing days of next month
          dayNum = index - (leadingDays + daysInMonth) + 1;
          isCurrentMonth = false;
          cellDate = DateTime(month.year, month.month + 1, dayNum);
        } else {
          dayNum = index - leadingDays + 1;
          cellDate = DateTime(month.year, month.month, dayNum);
        }

        final cellDateStr =
            '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';

        // Find events on this date
        final dayEvents = events.where((e) {
          return cellDateStr.compareTo(e.startDate) >= 0 &&
              cellDateStr.compareTo(e.endDate) <= 0;
        }).toList();

        final isSelected = cellDate.year == selectedDate.year &&
            cellDate.month == selectedDate.month &&
            cellDate.day == selectedDate.day;

        final isToday = DateTime.now().year == cellDate.year &&
            DateTime.now().month == cellDate.month &&
            DateTime.now().day == cellDate.day;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ref.read(selectedCalendarDateProvider.notifier).state = cellDate;
            if (!isCurrentMonth) {
              final newMonth = DateTime(cellDate.year, cellDate.month, 1);
              ref.read(currentMonthProvider.notifier).state = newMonth;
              ref.read(calendarEventsProvider.notifier).loadEvents(newMonth);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AcadexColors.primary
                  : (isToday ? AcadexColors.primary.withOpacity(0.08) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isCurrentMonth
                            ? const Color(0xFF1E293B)
                            : Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 2),

                // Indicator dots
                if (dayEvents.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: dayEvents.take(3).map((ev) {
                      Color dotColor = const Color(0xFFF59E0B);
                      if (ev.eventType == CalendarEventType.holiday ||
                          ev.eventType == CalendarEventType.publicHoliday ||
                          ev.eventType == CalendarEventType.institutionHoliday) {
                        dotColor = const Color(0xFF10B981);
                      } else if (ev.eventType == CalendarEventType.exam) {
                        dotColor = const Color(0xFF8B5CF6);
                      } else if (ev.eventType == CalendarEventType.deadline) {
                        dotColor = const Color(0xFF3B82F6);
                      }
                      return Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : dotColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
