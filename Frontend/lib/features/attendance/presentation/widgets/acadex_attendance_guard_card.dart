import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../domain/models/assigned_class.dart';

/// ACADEX Attendance Smart Guard Card
/// Communicates authoritative class context before and during attendance marking:
/// Subject, Program, Semester, Section, Date, Timetable Slot, Faculty, and Session Status.
class AcadexAttendanceGuardCard extends StatelessWidget {
  final AssignedClass activeClass;
  final int totalStudents;
  final bool isMarked;
  final bool isLocked;
  final bool isClosed;
  final Map<String, int>? statusCounts;
  final VoidCallback? onRefreshRoster;

  const AcadexAttendanceGuardCard({
    super.key,
    required this.activeClass,
    required this.totalStudents,
    this.isMarked = false,
    this.isLocked = false,
    this.isClosed = false,
    this.statusCounts,
    this.onRefreshRoster,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(activeClass.date);

    // Build breadcrumb segments
    final breadcrumbs = <String>[];
    if (activeClass.cohort != null && activeClass.cohort!.isNotEmpty) {
      breadcrumbs.add(activeClass.cohort!);
    }
    if (activeClass.semester.isNotEmpty) {
      breadcrumbs.add(
        activeClass.semester.toLowerCase().startsWith('sem')
            ? activeClass.semester
            : 'Sem ${activeClass.semester}',
      );
    }
    if (activeClass.sectionName.isNotEmpty) {
      breadcrumbs.add(
        activeClass.sectionName.toLowerCase().startsWith('sec') ||
                activeClass.sectionName.toLowerCase().startsWith('class')
            ? activeClass.sectionName
            : 'Sec ${activeClass.sectionName}',
      );
    }

    final breadcrumbsText = breadcrumbs.join(' · ');

    return AcadexCard(
      isFlat: true,
      padding: const EdgeInsets.all(14),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Eyebrow + Status Badge
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AcadexColors.primary.withValues(alpha: 0.2)
                              : AcadexColors.primaryLight,
                          borderRadius: AcadexRadius.borderRadiusSm,
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          size: 14,
                          color: AcadexColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ATTENDANCE GUARD',
                        style: AcadexTypography.eyebrow(
                          color: isDark ? AcadexColors.primaryMuted : AcadexColors.primary,
                        ).copyWith(fontSize: 10, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 8),

              // Subject Title
              Text(
                activeClass.subjectName,
                style: AcadexTypography.title(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (breadcrumbsText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  breadcrumbsText,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ).copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Context Details Responsive Wrap
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoRow(LucideIcons.calendar, dateStr, isDark),
                  _buildInfoRow(LucideIcons.clock, activeClass.timeSlot, isDark),
                  _buildInfoRow(
                    LucideIcons.users,
                    '$totalStudents Enrolled',
                    isDark,
                    action: onRefreshRoster != null
                        ? InkWell(
                            onTap: onRefreshRoster,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Icon(LucideIcons.refreshCw, size: 13, color: AcadexColors.primary),
                            ),
                          )
                        : null,
                  ),
                ],
              ),

              // Optional Previous Submission Summary
              if (isMarked && statusCounts != null && statusCounts!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
                    borderRadius: AcadexRadius.borderRadiusSm,
                    border: Border.all(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 13, color: AcadexColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Recorded: ${statusCounts!['present'] ?? 0} Present · ${statusCounts!['absent'] ?? 0} Absent · ${statusCounts!['late'] ?? 0} Late',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
  }

  Widget _buildStatusBadge() {
    if (isClosed) {
      return const AcadexBadge(
        label: 'Session Closed',
        variant: AcadexBadgeVariant.neutral,
      );
    }
    if (isLocked) {
      return const AcadexBadge(
        label: 'Session Locked',
        variant: AcadexBadgeVariant.warning,
      );
    }
    if (isMarked) {
      return const AcadexBadge(
        label: 'Submitted (Editable)',
        variant: AcadexBadgeVariant.info,
      );
    }
    return const AcadexBadge(
      label: 'Ready to Mark',
      variant: AcadexBadgeVariant.success,
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark, {Widget? action}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
            ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 4),
          action,
        ],
      ],
    );
  }
}
