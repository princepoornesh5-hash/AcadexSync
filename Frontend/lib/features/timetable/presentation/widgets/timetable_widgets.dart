import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../attendance/domain/models/assigned_class.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';
import 'acadex_timetable_calendar.dart';
import 'daily_timeline_view.dart';

// Helper to determine active/upcoming status
enum TimetableEntryStatus { now, upNext, completed, none }

TimetableEntryStatus getEntryStatus(TimetableModel entry) {
  final now = DateTime.now();
  final currentDay = TimetableDay.values[now.weekday - 1];
  if (entry.dayOfWeek != currentDay) return TimetableEntryStatus.none;

  try {
    final startParts = entry.startTime.split(':');
    final endParts = entry.endTime.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final currentMinutes = now.hour * 60 + now.minute;

    if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
      return TimetableEntryStatus.now;
    } else if (currentMinutes < startMinutes && (startMinutes - currentMinutes) <= 120) {
      return TimetableEntryStatus.upNext;
    } else if (currentMinutes > endMinutes) {
      return TimetableEntryStatus.completed;
    } else {
      return TimetableEntryStatus.none;
    }
  } catch (_) {
    return TimetableEntryStatus.none;
  }
}

Color getSessionTypeColor(TimetableSessionType type) {
  switch (type) {
    case TimetableSessionType.lecture:
      return AcadexColors.accentPurple;
    case TimetableSessionType.lab:
      return AcadexColors.accentTeal;
    case TimetableSessionType.tutorial:
      return AcadexColors.warning;
    case TimetableSessionType.practical:
      return AcadexColors.info;
    case TimetableSessionType.seminar:
      return AcadexColors.accentOrange;
    case TimetableSessionType.other:
      return AcadexColors.inkMuted;
  }
}

IconData getSessionTypeIcon(TimetableSessionType type) {
  switch (type) {
    case TimetableSessionType.lecture:
      return LucideIcons.bookOpen;
    case TimetableSessionType.lab:
      return LucideIcons.flaskConical;
    case TimetableSessionType.tutorial:
      return LucideIcons.users;
    case TimetableSessionType.practical:
      return LucideIcons.wrench;
    case TimetableSessionType.seminar:
      return LucideIcons.presentation;
    case TimetableSessionType.other:
      return LucideIcons.calendar;
  }
}

class TimetableCard extends ConsumerStatefulWidget {
  final TimetableModel entry;
  final bool isCompact;
  final VoidCallback? onTap;

  const TimetableCard({
    super.key,
    required this.entry,
    this.isCompact = false,
    this.onTap,
  });

  @override
  ConsumerState<TimetableCard> createState() => _TimetableCardState();
}

class _TimetableCardState extends ConsumerState<TimetableCard> {
  bool _isHovered = false;

  void _showDetailDialog(BuildContext context, WidgetRef ref) {
    final subjectMap = ref.read(timetableSubjectMapProvider);
    final facultyMap = ref.read(timetableFacultyMapProvider);
    final sectionMap = ref.read(timetableSectionMapProvider);

    final subject = subjectMap[widget.entry.subjectId];
    final faculty = facultyMap[widget.entry.facultyId];
    final section = sectionMap[widget.entry.sectionId];

    final subjectName = subject?.name ?? widget.entry.subjectId;
    final subjectCode = subject?.code ?? '';
    final facultyName = faculty?.name ?? widget.entry.facultyId;
    final facultyEmail = faculty?.email ?? '';
    final sectionName = section?.name ?? (widget.entry.sectionId.isNotEmpty ? widget.entry.sectionId : '—');
    final sessionColor = getSessionTypeColor(widget.entry.sessionType);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusXl),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sessionColor.withValues(alpha: 0.12),
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
              child: Icon(getSessionTypeIcon(widget.entry.sessionType), size: 20, color: sessionColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subjectName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (subjectCode.isNotEmpty)
                    Text(subjectCode, style: TextStyle(fontSize: 12, color: sessionColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(ctx, LucideIcons.calendar, 'Day', widget.entry.dayOfWeek.displayName),
            const SizedBox(height: 8),
            _buildDetailRow(ctx, LucideIcons.clock, 'Time', '${widget.entry.startTime} – ${widget.entry.endTime}'),
            const SizedBox(height: 8),
            _buildDetailRow(ctx, LucideIcons.tag, 'Session Type', widget.entry.sessionType.displayName),
            const SizedBox(height: 8),
            _buildDetailRow(ctx, LucideIcons.user, 'Faculty', facultyName + (facultyEmail.isNotEmpty ? ' ($facultyEmail)' : '')),
            const SizedBox(height: 8),
            _buildDetailRow(ctx, LucideIcons.layoutGrid, 'Section', sectionName),
            if (widget.entry.roomNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(ctx, LucideIcons.mapPin, 'Location', 'Room ${widget.entry.roomNumber}${widget.entry.building != null ? ' · ${widget.entry.building}' : ''}'),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isCompact = widget.isCompact;

    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    final subject = subjectMap[entry.subjectId];
    final faculty = facultyMap[entry.facultyId];
    final section = sectionMap[entry.sectionId];

    final subjectName = subject?.name ?? entry.subjectId;
    final subjectCode = subject?.code ?? '';
    final facultyName = faculty?.name ?? entry.facultyId;
    final sectionName = section?.name ?? (entry.sectionId.isNotEmpty ? entry.sectionId : null);

    final sessionColor = getSessionTypeColor(entry.sessionType);
    final status = getEntryStatus(entry);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isFaculty = user?.role == AppRole.faculty;

    final isLive = status == TimetableEntryStatus.now;
    final isUpNext = status == TimetableEntryStatus.upNext;

    final baseBorderColor = isLive
        ? sessionColor
        : (isUpNext
            ? AcadexColors.info.withValues(alpha: 0.7)
            : (_isHovered ? sessionColor.withValues(alpha: 0.5) : Theme.of(context).dividerColor.withValues(alpha: 0.6)));

    final baseShadow = isLive
        ? (_isHovered
            ? (isDark ? AcadexShadows.darkMd : AcadexShadows.lightMd)
            : (isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm))
        : (_isHovered ? (isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm) : null);

    final animDuration = AcadexMotion.resolveDuration(context, AcadexMotion.micro);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: AcadexMotion.resolveDuration(context, AcadexMotion.fast),
      curve: AcadexMotion.curveStandard,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 4),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: animDuration,
          curve: AcadexMotion.curveStandard,
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
          decoration: BoxDecoration(
            color: isDark
                ? (isLive
                    ? sessionColor.withValues(alpha: _isHovered ? 0.16 : 0.12)
                    : (_isHovered ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.95) : Theme.of(context).colorScheme.surface))
                : (isLive
                    ? sessionColor.withValues(alpha: _isHovered ? 0.09 : 0.06)
                    : (_isHovered ? Colors.white : Theme.of(context).colorScheme.surface)),
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: baseBorderColor,
              width: (isLive || isUpNext || _isHovered) ? 1.5 : 1,
            ),
            boxShadow: baseShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap ?? () => _showDetailDialog(context, ref),
              borderRadius: AcadexRadius.borderRadiusLg,
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Time Range & Semantic Badges
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Time Range
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.clock, size: 13, color: sessionColor),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.startTime} – ${entry.endTime}',
                              style: AcadexTypography.bodySmall(color: Theme.of(context).colorScheme.onSurface).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isCompact ? 12 : 13,
                              ),
                            ),
                          ],
                        ),
                        
                        // Status & Session Type Badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLive) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AcadexColors.error.withValues(alpha: 0.15),
                                  borderRadius: AcadexRadius.borderRadiusXs,
                                  border: Border.all(color: AcadexColors.error.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: AcadexColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'NOW',
                                      style: AcadexTypography.eyebrow(color: AcadexColors.error).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                            ] else if (isUpNext) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AcadexColors.info.withValues(alpha: 0.15),
                                  borderRadius: AcadexRadius.borderRadiusXs,
                                  border: Border.all(color: AcadexColors.info.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'UP NEXT',
                                  style: AcadexTypography.eyebrow(color: AcadexColors.info).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: sessionColor.withValues(alpha: 0.12),
                                borderRadius: AcadexRadius.borderRadiusXs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(getSessionTypeIcon(entry.sessionType), size: 10, color: sessionColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    entry.sessionType.displayName,
                                    style: AcadexTypography.eyebrow(color: sessionColor).copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Middle: Subject Title & Code
                    Text(
                      subjectName,
                      style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface).copyWith(
                        fontSize: isCompact ? 13 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subjectCode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subjectCode,
                        style: AcadexTypography.caption(color: sessionColor).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Bottom row: Faculty, Room, Section
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Faculty
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isCompact ? 180 : 300),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.user, size: 13, color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  facultyName,
                                  style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Room & Building
                        if (entry.roomNumber.isNotEmpty)
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: isCompact ? 180 : 300),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.mapPin, size: 13, color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Room ${entry.roomNumber}${entry.building != null && entry.building!.isNotEmpty ? ' · ${entry.building}' : ''}',
                                    style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
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
                              'Sec: $sectionName',
                              style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).copyWith(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    if (isFaculty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () {
                            final selectedDate = ref.read(timetableSelectedDateProvider);
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
                          },
                          borderRadius: AcadexRadius.borderRadiusSm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.1),
                              borderRadius: AcadexRadius.borderRadiusSm,
                              border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.clipboardCheck, size: 13, color: AcadexColors.primary),
                                const SizedBox(width: 5),
                                Text(
                                  'Mark Attendance',
                                  style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Management Card with explicit non-overlapping trailing action buttons
class TimetableManagementCard extends ConsumerStatefulWidget {
  final TimetableModel entry;
  final VoidCallback onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onSubstitute;
  final VoidCallback onDelete;

  const TimetableManagementCard({
    super.key,
    required this.entry,
    required this.onEdit,
    this.onDuplicate,
    this.onSubstitute,
    required this.onDelete,
  });

  @override
  ConsumerState<TimetableManagementCard> createState() => _TimetableManagementCardState();
}

class _TimetableManagementCardState extends ConsumerState<TimetableManagementCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    final subject = subjectMap[entry.subjectId];
    final faculty = facultyMap[entry.facultyId];
    final section = sectionMap[entry.sectionId];

    final subjectName = subject?.name ?? entry.subjectId;
    final subjectCode = subject?.code ?? '';
    final facultyName = faculty?.name ?? entry.facultyId;
    final sectionName = section?.name ?? (entry.sectionId.isNotEmpty ? entry.sectionId : '—');

    final sessionColor = getSessionTypeColor(entry.sessionType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final animDuration = AcadexMotion.resolveDuration(context, AcadexMotion.micro);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: AcadexMotion.resolveDuration(context, AcadexMotion.fast),
      curve: AcadexMotion.curveStandard,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 4),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: animDuration,
          curve: AcadexMotion.curveStandard,
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.95) : Theme.of(context).colorScheme.surface)
                : (_isHovered ? Colors.white : Theme.of(context).colorScheme.surface),
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: _isHovered ? sessionColor.withValues(alpha: 0.4) : Theme.of(context).dividerColor,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? (isDark ? AcadexShadows.darkMd : AcadexShadows.lightMd)
                : (isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Day and Time pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: sessionColor.withValues(alpha: 0.1),
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: sessionColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.dayOfWeek.displayName.substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: sessionColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.startTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      entry.endTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Center: Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subjectName,
                            style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sessionColor.withValues(alpha: 0.1),
                            borderRadius: AcadexRadius.borderRadiusXs,
                          ),
                          child: Text(
                            entry.sessionType.displayName,
                            style: AcadexTypography.eyebrow(color: sessionColor).copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    if (subjectCode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subjectCode,
                        style: AcadexTypography.caption(color: sessionColor).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.user, size: 13, color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                            const SizedBox(width: 4),
                            Text(
                              facultyName,
                              style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.layoutGrid, size: 13, color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Sec: $sectionName',
                              style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                            ),
                          ],
                        ),
                        if (entry.roomNumber.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.mapPin, size: 13, color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Room ${entry.roomNumber}${entry.building != null && entry.building!.isNotEmpty ? ' · ${entry.building}' : ''}',
                                style: AcadexTypography.caption(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Dedicated Trailing Action Buttons (non-overlapping)
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onSubstitute != null)
                    IconButton(
                      icon: Icon(Icons.swap_horiz_rounded, size: 20, color: Theme.of(context).primaryColor),
                      tooltip: 'Assign Substitute',
                      onPressed: widget.onSubstitute,
                    ),
                  IconButton(
                    icon: Icon(LucideIcons.edit2, size: 18, color: Theme.of(context).primaryColor),
                    tooltip: 'Edit Schedule',
                    onPressed: widget.onEdit,
                  ),
                  if (widget.onDuplicate != null)
                    IconButton(
                      icon: Icon(LucideIcons.copy, size: 18, color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                      tooltip: 'Duplicate Schedule',
                      onPressed: widget.onDuplicate,
                    ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.error),
                    tooltip: 'Delete Schedule',
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Week View Matrix with Fixed Time Axis and Horizontally Scrollable Day Columns
class WeeklyTimetableGrid extends StatelessWidget {
  final Map<TimetableDay, List<TimetableModel>> weeklyData;

  const WeeklyTimetableGrid({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final days = TimetableDay.values;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: days.map((day) {
              final entries = weeklyData[day] ?? [];
              final now = DateTime.now();
              final isToday = day == TimetableDay.values[now.weekday - 1];

              return AnimatedContainer(
                duration: AcadexMotion.resolveDuration(context, AcadexMotion.micro),
                curve: AcadexMotion.curveStandard,
                width: 240,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isToday ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface)
                      : (isToday ? Theme.of(context).primaryColor.withValues(alpha: 0.03) : Theme.of(context).colorScheme.surface),
                  borderRadius: AcadexRadius.borderRadiusXl,
                  border: Border.all(
                    color: isToday ? Theme.of(context).primaryColor.withValues(alpha: 0.4) : Theme.of(context).dividerColor,
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Column Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.12)
                            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    day.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isToday ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: AcadexRadius.borderRadiusXs,
                                    ),
                                    child: const Text(
                                      'TODAY',
                                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                              borderRadius: AcadexRadius.borderRadiusSm,
                            ),
                            child: Text(
                              '${entries.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Column Content
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: entries.isEmpty
                          ? SizedBox(
                              height: 180,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.calendarCheck,
                                      size: 32,
                                      color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No Classes',
                                      style: TextStyle(
                                        color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: entries.map((entry) => TimetableCard(entry: entry, isCompact: true)).toList(),
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// Day View Schedule with Smooth Transitions
class TimetableDayView extends ConsumerWidget {
  final Map<TimetableDay, List<TimetableModel>> weeklyData;

  const TimetableDayView({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(timetableSelectedDayProvider);
    final selectedDate = ref.watch(timetableSelectedDateProvider);
    final entries = weeklyData[selectedDay] ?? [];
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AcadexTimetableCalendar(role: user?.role),
          const SizedBox(height: 16),
          DailyTimelineView(
            entries: entries,
            selectedDate: selectedDate,
          ),
        ],
      ),
    );
  }
}

// List View Chronological Schedule Grouped by Day
class TimetableListView extends StatelessWidget {
  final Map<TimetableDay, List<TimetableModel>> weeklyData;

  const TimetableListView({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final activeDays = TimetableDay.values.where((day) => (weeklyData[day] ?? []).isNotEmpty).toList();

    if (activeDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.calendarX,
              size: 56,
              color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled for the week',
              style: AcadexTypography.heading3(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activeDays.length,
      itemBuilder: (context, index) {
        final day = activeDays[index];
        final entries = weeklyData[day] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Group Header
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Row(
                children: [
                  Text(
                    day.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: Text(
                      '${entries.length} ${entries.length == 1 ? 'class' : 'classes'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Entries for this day
            ...entries.map((entry) => TimetableCard(entry: entry)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

// Today Schedule Widget for Dashboard Integration
class TodayScheduleWidget extends StatelessWidget {
  final List<TimetableModel> todayEntries;

  const TodayScheduleWidget({super.key, required this.todayEntries});

  @override
  Widget build(BuildContext context) {
    if (todayEntries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: AcadexColors.surface,
          borderRadius: AcadexRadius.borderRadiusLg,
          border: Border.all(color: AcadexColors.hairline),
          boxShadow: AcadexShadows.lightSm,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AcadexColors.primaryLight.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.calendarCheck,
                  size: 22,
                  color: AcadexColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No classes scheduled for today',
                style: AcadexTypography.title().copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'There are no active timetable sessions or lectures planned for today.',
                textAlign: TextAlign.center,
                style: AcadexTypography.caption(),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: todayEntries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => TimetableCard(entry: todayEntries[index], isCompact: true),
    );
  }
}
