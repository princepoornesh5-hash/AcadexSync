import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../attendance/domain/models/assigned_class.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';

class DailyTimelineView extends ConsumerWidget {
  final List<TimetableModel> entries;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const DailyTimelineView({
    super.key,
    required this.entries,
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  String _formatTimeLabel(String rawTime) {
    try {
      final parts = rawTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2026, 1, 1, hour, minute);
      return DateFormat('hh a').format(dt).toLowerCase();
    } catch (_) {
      return rawTime;
    }
  }

  String _formatTimeRange(String start, String end) {
    return '$start – $end';
  }

  void _onMarkAttendance(
    BuildContext context,
    WidgetRef ref,
    TimetableModel entry,
    String subjectName,
    String? sectionName,
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
      sectionName: sectionName ?? entry.sectionId,
      semester: entry.semesterId,
      timeSlot: '${entry.startTime} – ${entry.endTime}',
      startTime: entry.startTime,
      endTime: entry.endTime,
      roomNumber: entry.roomNumber,
      building: entry.building,
      date: selectedDate,
    );

    ref.read(activeClassProvider.notifier).state = assignedClass;
    context.push('/attendance/mark');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isFaculty = user?.role == AppRole.faculty;
    final isStudent = user?.role == AppRole.student;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    final selectedDay = ref.watch(timetableSelectedDayProvider);
    final dayFormatter = DateFormat('EEE d');
    final fullDateFormatter = DateFormat('d MMMM yyyy');
    final formattedFullDate = fullDateFormatter.format(selectedDate);
    final dayBadgeText = dayFormatter.format(selectedDate);
    final dayName = selectedDay.displayName;

    // Timeline Header: Date pill on left + formatted date on right
    final timelineHeader = Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          // Left Date Badge (e.g. Sat 29 in ACADEX blue circle)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AcadexColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dayBadgeText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dayName,
                      style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $formattedFullDate',
                      style: AcadexTypography.caption(
                        color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                      ).copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entries.length} ${entries.length == 1 ? "class" : "classes"} scheduled',
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

    // Error State
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 40),
              const SizedBox(height: 12),
              Text(
                'Unable to load timetable schedule',
                style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Loading State
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          timelineHeader,
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    // Empty State
    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          timelineHeader,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
              boxShadow: isDark ? null : AcadexShadows.lightSm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AcadexColors.primaryLight.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.calendarCheck,
                    size: 26,
                    color: AcadexColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No classes scheduled',
                  style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedFullDate,
                  textAlign: TextAlign.center,
                  style: AcadexTypography.caption(
                    color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFaculty
                      ? 'You have no teaching periods or lectures assigned for this day.'
                      : 'No classes are scheduled for your section on this date.',
                  textAlign: TextAlign.center,
                  style: AcadexTypography.caption(
                    color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Sort entries chronologically
    final sortedEntries = List<TimetableModel>.from(entries)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        timelineHeader,
        ...sortedEntries.map((entry) {
          final subject = subjectMap[entry.subjectId];
          final faculty = facultyMap[entry.facultyId];
          final section = sectionMap[entry.sectionId];

          final subjectName = subject?.name ?? entry.subjectId;
          final facultyName = faculty?.name ?? entry.facultyId;
          final sectionName = section?.name ?? (entry.sectionId.isNotEmpty ? entry.sectionId : null);

          final timeLabel = _formatTimeLabel(entry.startTime);
          final timeRangeText = _formatTimeRange(entry.startTime, entry.endTime);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Timeline Column: Time Label + Vertical Guide
                SizedBox(
                  width: 52,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 1.5,
                        height: 50,
                        margin: const EdgeInsets.only(left: 12),
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),

                // Right Timeline Column: Authoritative Class Card
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                      borderRadius: AcadexRadius.borderRadiusLg,
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
                      boxShadow: isDark ? null : AcadexShadows.lightSm,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Title
                        if (entry.isSubstituted) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AcadexColors.warning.withValues(alpha: 0.15),
                              borderRadius: AcadexRadius.borderRadiusSm,
                              border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_horiz_rounded, size: 14, color: AcadexColors.warning),
                                const SizedBox(width: 4),
                                Text(
                                  isFaculty ? 'Substitute Duty' : 'Substitute: $facultyName',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AcadexColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          subjectName,
                          style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Time Range Row with clock icon
                        Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                timeRangeText,
                                style: AcadexTypography.bodySmall(color: Theme.of(context).colorScheme.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),

                        // Metadata Row: Room, Section, and Faculty (if student)
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Room & Location
                            if (entry.roomNumber.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.mapPin,
                                    size: 13,
                                    color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    entry.building != null && entry.building!.isNotEmpty
                                        ? '${entry.building} • ${entry.roomNumber}'
                                        : 'Room ${entry.roomNumber}',
                                    style: AcadexTypography.caption(
                                      color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                                    ).copyWith(fontSize: 12),
                                  ),
                                ],
                              ),

                            // Section
                            if (sectionName != null)
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

                            // Faculty name (visible for Student role)
                            if (isStudent && facultyName.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.user,
                                    size: 13,
                                    color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    facultyName,
                                    style: AcadexTypography.caption(
                                      color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                                    ).copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                          ],
                        ),

                        // Action button for authorized Faculty: [Mark Attendance]
                        if (isFaculty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: () => _onMarkAttendance(context, ref, entry, subjectName, sectionName),
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
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
