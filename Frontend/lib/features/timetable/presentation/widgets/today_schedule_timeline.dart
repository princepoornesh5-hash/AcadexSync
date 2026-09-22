import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';
import 'timetable_widgets.dart';

class TodayScheduleTimeline extends ConsumerWidget {
  final List<TimetableModel> classes;
  final bool isLoading;

  const TodayScheduleTimeline({
    super.key,
    required this.classes,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isFaculty = user?.role == AppRole.faculty;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (classes.isEmpty) {
      return AcadexCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                LucideIcons.calendarOff,
                size: 36,
                color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
              ),
              const SizedBox(height: 12),
              Text(
                'No classes scheduled for today',
                style: AcadexTypography.title(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Enjoy your free day or prepare for upcoming classes.',
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<TimetableModel>.from(classes)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    return Column(
      children: sorted.map((entry) {
        final status = getEntryStatus(entry);
        final isNow = status == TimetableEntryStatus.now;
        final isUpNext = status == TimetableEntryStatus.upNext;
        final isCompleted = status == TimetableEntryStatus.completed;

        final subject = subjectMap[entry.subjectId];
        final faculty = facultyMap[entry.facultyId];
        final section = sectionMap[entry.sectionId];

        final subjectName = subject?.name ?? (entry.subjectId.isNotEmpty ? entry.subjectId : 'Class');
        final subjectCode = subject?.code ?? '';
        final facultyName = faculty?.name ?? entry.facultyId;
        final sectionName = section?.name ?? entry.sectionId;

        final sessionColor = getSessionTypeColor(entry.sessionType);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: AcadexCard(
            backgroundColor: isNow
                ? (isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF))
                : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface),
            borderColor: isNow
                ? (isDark ? const Color(0xFF4338CA) : const Color(0xFF818CF8))
                : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time block
                  Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isNow
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.15)
                          : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft),
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(
                        color: isNow
                            ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                            : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.startTime,
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          entry.endTime,
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isNow) ...[
                              AcadexBadge(
                                label: 'NOW',
                                variant: AcadexBadgeVariant.danger,
                              ),
                              const SizedBox(width: 6),
                            ] else if (isUpNext) ...[
                              AcadexBadge(
                                label: 'UP NEXT',
                                variant: AcadexBadgeVariant.info,
                              ),
                              const SizedBox(width: 6),
                            ] else if (isCompleted) ...[
                              AcadexBadge(
                                label: 'COMPLETED',
                                variant: AcadexBadgeVariant.neutral,
                              ),
                              const SizedBox(width: 6),
                            ],
                            AcadexBadge(
                              label: entry.sessionType.displayName,
                              variant: AcadexBadgeVariant.neutral,
                            ),
                            if (entry.isSubstituted) ...[
                              const SizedBox(width: 6),
                              AcadexBadge(
                                label: isFaculty ? 'Substitute Duty' : 'Substitute Teacher',
                                variant: AcadexBadgeVariant.warning,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subjectName,
                          style: AcadexTypography.title(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subjectCode.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subjectCode,
                            style: AcadexTypography.caption(
                              color: sessionColor,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (sectionName.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.layoutGrid, size: 12, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sec: $sectionName',
                                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                  ),
                                ],
                              ),
                            if (!isFaculty && facultyName.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.user, size: 12, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    facultyName,
                                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                  ),
                                ],
                              ),
                            if (entry.roomNumber.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.mapPin, size: 12, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Room ${entry.roomNumber}${entry.building != null ? ' · ${entry.building}' : ''}',
                                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action for Faculty: Mark Attendance
                  if (isFaculty && (isNow || isUpNext))
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: AcadexButton(
                        label: 'Attendance',
                        icon: LucideIcons.userCheck,
                        size: AcadexButtonSize.sm,
                        variant: isNow ? AcadexButtonVariant.primary : AcadexButtonVariant.secondary,
                        onPressed: () {
                          context.go('/attendance');
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
