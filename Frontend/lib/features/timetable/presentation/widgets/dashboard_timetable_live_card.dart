import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../attendance/domain/models/assigned_class.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';
import '../providers/timetable_providers.dart';
import 'timetable_entry_detail_sheet.dart';
import 'timetable_widgets.dart';

class DashboardTimetableLiveCard extends ConsumerWidget {
  final AppRole role;

  const DashboardTimetableLiveCard({
    super.key,
    required this.role,
  });

  void _onMarkAttendance(
    BuildContext context,
    WidgetRef ref,
    TimetableModel entry,
    String subjectName,
    String sectionName,
  ) {
    final assignedClass = AssignedClass(
      id: entry.id,
      timetableId: entry.timetableId,
      timetableEntryId: entry.id,
      facultyId: entry.facultyId,
      facultyAssignmentId: entry.facultyAssignmentId,
      subjectId: entry.subjectId,
      subjectName: subjectName,
      sectionId: entry.sectionId,
      sectionName: sectionName,
      semester: entry.semesterId,
      timeSlot: '${entry.startTime} – ${entry.endTime}',
      startTime: entry.startTime,
      endTime: entry.endTime,
      roomNumber: entry.roomNumber,
      building: entry.building,
      date: DateTime.now(),
    );

    ref.read(activeClassProvider.notifier).state = assignedClass;
    context.push('/attendance/mark');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final workingDayAsync = ref.watch(workingDayResolutionProvider(dateStr));

    final isHoliday = workingDayAsync.valueOrNull?.isHoliday == true;
    final holidayReason = workingDayAsync.valueOrNull?.reason;

    if (isHoliday) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AcadexColors.warning.withValues(alpha: 0.1),
          borderRadius: AcadexRadius.borderRadiusLg,
          border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AcadexColors.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.calendarOff, size: 20, color: AcadexColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACADEMIC HOLIDAY',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AcadexColors.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    holidayReason != null && holidayReason.isNotEmpty
                        ? holidayReason
                        : 'Institutional Holiday',
                    style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'No regular classes scheduled today.',
                    style: AcadexTypography.caption(
                      color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentClassAsync = ref.watch(currentClassProvider);
    final nextClassAsync = ref.watch(nextClassProvider);

    final currentClass = currentClassAsync.valueOrNull;
    final nextClass = nextClassAsync.valueOrNull;

    if (currentClass == null && nextClass == null) {
      return const SizedBox.shrink();
    }

    final activeEntry = currentClass ?? nextClass!;
    final isLive = currentClass != null;

    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    final subject = subjectMap[activeEntry.subjectId];
    final faculty = facultyMap[activeEntry.facultyId];
    final section = sectionMap[activeEntry.sectionId];

    final subjectName = AcadexEntityFormatters.formatSubjectLabel(
      activeEntry.subjectName ?? subject?.name,
      code: activeEntry.subjectCode ?? subject?.code,
      rawId: activeEntry.subjectId,
    );
    final facultyName = AcadexEntityFormatters.formatFacultyLabel(
      activeEntry.facultyName ?? faculty?.name,
      rawId: activeEntry.facultyId,
    );
    final sectionName = AcadexEntityFormatters.formatSectionLabel(
      activeEntry.sectionName ?? section?.name,
      rawId: activeEntry.sectionId,
      prefix: false,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionColor = getSessionTypeColor(activeEntry.sessionType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isLive ? AcadexColors.error.withValues(alpha: 0.5) : AcadexColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: isDark ? null : AcadexShadows.lightSm,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tag row: [LIVE NOW] or [UP NEXT]
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive
                      ? AcadexColors.error.withValues(alpha: 0.15)
                      : AcadexColors.primary.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusSm,
                  border: Border.all(
                    color: isLive
                        ? AcadexColors.error.withValues(alpha: 0.3)
                        : AcadexColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AcadexColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      isLive ? 'CURRENT CLASS' : 'UP NEXT TODAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isLive ? AcadexColors.error : AcadexColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sessionColor.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusXs,
                ),
                child: Text(
                  activeEntry.sessionType.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: sessionColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${activeEntry.startTime} – ${activeEntry.endTime}',
                style: AcadexTypography.caption(
                  color: Theme.of(context).colorScheme.onSurface,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Subject Name
          Text(
            subjectName,
            style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Subtitle / Location / Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  borderRadius: AcadexRadius.borderRadiusXs,
                ),
                child: Text(
                  'Section $sectionName',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                  ),
                ),
              ),
              if (activeEntry.roomNumber.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.mapPin,
                  size: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    activeEntry.building != null && activeEntry.building!.isNotEmpty
                        ? '${activeEntry.building} · Room ${activeEntry.roomNumber}'
                        : 'Room ${activeEntry.roomNumber}',
                    style: AcadexTypography.caption(
                      color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                    ).copyWith(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (role == AppRole.student && facultyName.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.user,
                  size: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    facultyName,
                    style: AcadexTypography.caption(
                      color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                    ).copyWith(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Contextual Actions
          Row(
            children: [
              if (role == AppRole.faculty) ...[
                ElevatedButton.icon(
                  onPressed: () => _onMarkAttendance(context, ref, activeEntry, subjectName, sectionName),
                  icon: const Icon(LucideIcons.clipboardCheck, size: 15),
                  label: const Text('Mark Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => TimetableEntryDetailSheet.show(context, activeEntry),
                icon: const Icon(LucideIcons.info, size: 14),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
