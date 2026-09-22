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

class NextClassCard extends ConsumerWidget {
  final TimetableModel? nextClass;
  final bool isLoading;

  const NextClassCard({
    super.key,
    this.nextClass,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isFaculty = user?.role == AppRole.faculty;
    final isStudent = user?.role == AppRole.student;

    if (isLoading) {
      return AcadexCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 14),
              Text(
                'Checking next class...',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (nextClass == null) {
      return AcadexCard(
        backgroundColor: isDark
            ? AcadexColors.darkSurfaceCard
            : AcadexColors.surface,
        borderColor: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AcadexColors.darkSurfaceHover
                      : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: Icon(
                  LucideIcons.calendarCheck,
                  size: 24,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Upcoming Classes',
                      style: AcadexTypography.title(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You are all done with scheduled classes for today.',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final entry = nextClass!;
    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    final subject = subjectMap[entry.subjectId];
    final faculty = facultyMap[entry.facultyId];
    final section = sectionMap[entry.sectionId];

    final subjectName = subject?.name ?? (entry.subjectId.isNotEmpty ? entry.subjectId : 'Scheduled Class');
    final subjectCode = subject?.code ?? '';
    final facultyName = faculty?.name ?? entry.facultyId;
    final sectionName = section?.name ?? entry.sectionId;

    return AcadexCard(
      backgroundColor: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
      borderColor: isDark ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Badges and Time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: AcadexRadius.borderRadiusSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles, size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'NEXT CLASS',
                        style: AcadexTypography.eyebrow(color: Colors.white).copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AcadexBadge(
                  label: '${entry.startTime} – ${entry.endTime}',
                  variant: AcadexBadgeVariant.neutral,
                ),
                const Spacer(),
                if (entry.sessionType != TimetableSessionType.other)
                  AcadexBadge(
                    label: entry.sessionType.displayName,
                    variant: AcadexBadgeVariant.info,
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
            const SizedBox(height: 14),

            // Middle: Subject title and code
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: AcadexTypography.heading2(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subjectCode.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subjectCode,
                          style: AcadexTypography.caption(
                            color: const Color(0xFF6366F1),
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metadata Wrap: Section, Faculty/Room, Building
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (sectionName.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.layoutGrid,
                        size: 14,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Section: $sectionName',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                if (!isFaculty && facultyName.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 14,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        facultyName,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                if (entry.roomNumber.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Room ${entry.roomNumber}${entry.building != null && entry.building!.isNotEmpty ? ' · ${entry.building}' : ''}',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isFaculty)
                  AcadexButton(
                    label: 'Mark Attendance',
                    icon: LucideIcons.userCheck,
                    size: AcadexButtonSize.sm,
                    variant: AcadexButtonVariant.primary,
                    onPressed: () {
                      context.go('/attendance');
                    },
                  )
                else if (isStudent)
                  AcadexButton(
                    label: 'View Attendance',
                    icon: LucideIcons.pieChart,
                    size: AcadexButtonSize.sm,
                    variant: AcadexButtonVariant.secondary,
                    onPressed: () {
                      context.go('/attendance/student');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
