import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/calendar_event_model.dart';
import 'calendar_event_detail_sheet.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEventModel event;
  final VoidCallback? onRefresh;
  final String? dateLabel;

  const CalendarEventCard({
    super.key,
    required this.event,
    this.onRefresh,
    this.dateLabel,
  });

  IconData _getIcon() {
    switch (event.eventType) {
      case CalendarEventType.holiday:
      case CalendarEventType.publicHoliday:
      case CalendarEventType.institutionHoliday:
        return LucideIcons.sun;
      case CalendarEventType.exam:
      case CalendarEventType.examination:
        return LucideIcons.fileCheck;
      case CalendarEventType.deadline:
      case CalendarEventType.assignmentDeadline:
        return LucideIcons.clock;
      case CalendarEventType.internalAssessment:
      case CalendarEventType.classTest:
        return LucideIcons.clipboardCheck;
      case CalendarEventType.practical:
      case CalendarEventType.labViva:
        return LucideIcons.flaskConical;
      case CalendarEventType.timetableClass:
        return LucideIcons.bookOpen;
      case CalendarEventType.resultPublication:
        return LucideIcons.award;
      case CalendarEventType.workingDay:
        return LucideIcons.calendarCheck;
      case CalendarEventType.seminar:
      case CalendarEventType.workshop:
        return LucideIcons.presentation;
      case CalendarEventType.academicEvent:
      case CalendarEventType.collegeEvent:
      case CalendarEventType.event:
      case CalendarEventType.other:
        return LucideIcons.calendar;
    }
  }

  Color _getEventColor() {
    switch (event.eventType) {
      case CalendarEventType.holiday:
      case CalendarEventType.publicHoliday:
      case CalendarEventType.institutionHoliday:
        return const Color(0xFF10B981); // Emerald
      case CalendarEventType.exam:
      case CalendarEventType.examination:
        return const Color(0xFF8B5CF6); // Purple
      case CalendarEventType.deadline:
      case CalendarEventType.assignmentDeadline:
        return const Color(0xFF3B82F6); // Blue
      case CalendarEventType.internalAssessment:
      case CalendarEventType.classTest:
        return const Color(0xFFE11D48); // Rose
      case CalendarEventType.practical:
      case CalendarEventType.labViva:
        return const Color(0xFFD97706); // Amber / Orange
      case CalendarEventType.timetableClass:
        return const Color(0xFF0284C7); // Sky blue
      case CalendarEventType.resultPublication:
        return const Color(0xFF7C3AED); // Deep violet
      case CalendarEventType.workingDay:
        return const Color(0xFF059669); // Forest green
      case CalendarEventType.seminar:
      case CalendarEventType.workshop:
        return const Color(0xFF06B6D4); // Cyan
      case CalendarEventType.academicEvent:
      case CalendarEventType.collegeEvent:
      case CalendarEventType.event:
      case CalendarEventType.other:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getEventColor();
    final isCancelled = event.status == CalendarEventStatus.cancelled;
    final isDraft = event.status == CalendarEventStatus.draft;

    String timeLabel = 'All Day';
    if (!event.allDay && event.startTime != null) {
      timeLabel = event.startTime!;
      if (event.endTime != null) {
        timeLabel += ' – ${event.endTime}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCancelled
              ? (isDark ? Colors.red.shade900 : Colors.red.shade200)
              : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (event.sourceType == CalendarSourceType.derived &&
                event.navigationTarget != null &&
                event.navigationTarget!.isNotEmpty) {
              context.push(event.navigationTarget!);
            } else {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CalendarEventDetailSheet(
                  event: event,
                  onChanged: onRefresh,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Main Info Hierarchy: Date -> Title -> Time -> Context / Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Prominent Date Header (when present)
                      if (dateLabel != null) ...[
                        Text(
                          dateLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AcadexColors.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],

                      // 2. Event Title
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isCancelled
                                    ? (isDark ? AcadexColors.darkInkFaint : Colors.grey.shade500)
                                    : (isDark ? AcadexColors.darkInk : const Color(0xFF0F172A)),
                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Cancelled',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            )
                          else if (isDraft)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Draft',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 3. Event Time
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 13,
                            color: isDark ? AcadexColors.darkInkMuted : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AcadexColors.darkInkMuted : const Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 4. Context / Type
                      Row(
                        children: [
                          if (event.academicContext != null && event.academicContext!.isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                event.academicContext!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AcadexColors.darkInkSecondary : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: isDark ? AcadexColors.darkInkFaint : Colors.grey.shade400, fontSize: 10)),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: isDark ? 0.2 : 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event.eventType.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: isDark ? AcadexColors.darkInkFaint : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
