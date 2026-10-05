import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_motion.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/time_board/acadex_live_time_board.dart';
import '../../domain/models/home_dashboard_models.dart';

// ── 1. GREETING & HEADER (COMPACT & MOBILE-FIRST) ───────────────────────────

class DashboardGreetingHeader extends StatelessWidget {
  final DashboardGreetingModel greeting;

  const DashboardGreetingHeader({
    super.key,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = 'Today, ${now.day} ${months[now.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                  border: Border.all(
                    color: AcadexColors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: greeting.avatarUrl != null && greeting.avatarUrl!.isNotEmpty
                      ? Image.network(
                          greeting.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildInitials(),
                        )
                      : _buildInitials(),
                ),
              ),
              const SizedBox(width: 12),

              // User Name & Role & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting.displayName,
                      style: AcadexTypography.heading2(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        AcadexBadge(
                          label: greeting.role.replaceAll('_', ' '),
                          variant: AcadexBadgeVariant.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '•  $dateStr',
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ).copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Live IST HH:MM Time Board + ACADEX Assistant Minute Animation
              AcadexLiveTimeBoard(
                userName: greeting.displayName,
                isCompact: isNarrow,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInitials() {
    final initial = greeting.displayName.isNotEmpty ? greeting.displayName[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AcadexColors.primary,
        ),
      ),
    );
  }
}

// ── 2. CONTEXT CARD (COMPACT STRIP) ─────────────────────────────────────────

class DashboardContextCard extends StatelessWidget {
  final String role;
  final DashboardContextModel contextModel;

  const DashboardContextCard({
    super.key,
    required this.role,
    required this.contextModel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;
    switch (role.toUpperCase()) {
      case 'STUDENT':
        if (!contextModel.isEnrollmentAvailable) {
          content = Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: AcadexColors.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Academic enrollment not assigned yet.',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ),
            ],
          );
        } else {
          content = Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: const Icon(LucideIcons.graduationCap, color: AcadexColors.primary, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contextModel.courseName ?? 'Enrolled Program',
                      style: AcadexTypography.bodySmall(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (contextModel.semesterNumber != null)
                          _buildChip(context, 'Sem ${contextModel.semesterNumber}', isDark),
                        if (contextModel.sectionName != null && contextModel.sectionName!.isNotEmpty)
                          _buildChip(context, 'Sec ${contextModel.sectionName!}', isDark),
                        if (contextModel.rollNumber != null && contextModel.rollNumber!.isNotEmpty)
                          _buildChip(context, 'Roll: ${contextModel.rollNumber}', isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        break;

      case 'FACULTY':
        content = Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: const Icon(LucideIcons.briefcase, color: AcadexColors.primary, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contextModel.departmentName ?? 'Department Faculty',
                    style: AcadexTypography.bodySmall(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (contextModel.designation != null)
                        _buildChip(context, contextModel.designation!, isDark),
                      _buildChip(
                        context,
                        '${contextModel.activeTeachingAssignmentsCount} Class${contextModel.activeTeachingAssignmentsCount == 1 ? '' : 'es'}',
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
        break;

      case 'HOD':
        content = Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: const Icon(LucideIcons.layers, color: AcadexColors.primary, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contextModel.departmentName ?? 'Department',
                    style: AcadexTypography.bodySmall(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildChip(context, 'Head of Department', isDark),
                      if (contextModel.departmentCode != null)
                        _buildChip(context, contextModel.departmentCode!, isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
        break;

      case 'COLLEGE_ADMIN':
        content = Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: const Icon(LucideIcons.building, color: AcadexColors.primary, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contextModel.collegeName ?? 'Institution Operations',
                    style: AcadexTypography.bodySmall(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  _buildChip(context, 'College Administration', isDark),
                ],
              ),
            ),
          ],
        );
        break;

      default:
        content = Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primaryLight,
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: const Icon(LucideIcons.globe, color: AcadexColors.primary, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ACADEX Platform Administration',
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    }

    return AcadexCard(
      isFlat: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: content,
    );
  }

  Widget _buildChip(BuildContext context, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: AcadexRadius.borderRadiusSm,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: AcadexTypography.caption(
          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
        ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── 3. ALERTS SECTION ───────────────────────────────────────────────────────

class DashboardAlertsSection extends StatelessWidget {
  final List<DashboardAlertModel> alerts;

  const DashboardAlertsSection({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: alerts.map((alert) {
          final isWarning = alert.severity == 'WARNING';
          final isCritical = alert.severity == 'CRITICAL';
          final color = isCritical
              ? AcadexColors.error
              : (isWarning ? AcadexColors.warning : AcadexColors.primary);
          final bgColor = isCritical
              ? AcadexColors.errorLight
              : (isWarning ? AcadexColors.warningLight : AcadexColors.primaryLight);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AcadexPressable(
              onTap: alert.route != null ? () => context.push(alert.route!) : null,
              pressedScale: 0.985,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCritical
                          ? LucideIcons.alertOctagon
                          : (isWarning ? LucideIcons.alertTriangle : LucideIcons.info),
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            alert.message,
                            style: AcadexTypography.caption(color: AcadexColors.inkSecondary)
                                .copyWith(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (alert.route != null)
                      Icon(LucideIcons.chevronRight, size: 14, color: color),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 4. PENDING ACTIONS SECTION (STREAMLINED LIST) ───────────────────────────

class DashboardPendingActionsSection extends StatelessWidget {
  final List<DashboardPendingActionModel> pendingActions;

  const DashboardPendingActionsSection({
    super.key,
    required this.pendingActions,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingActions.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Actions Requiring Attention',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
              decoration: BoxDecoration(
                color: AcadexColors.errorLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AcadexColors.error.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Text(
                '${pendingActions.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AcadexColors.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...pendingActions.map((action) => _buildActionCard(context, action, isDark)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, DashboardPendingActionModel action, bool isDark) {
    final isHigh = action.priority == 'HIGH';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AcadexPressable(
        onTap: () => context.push(action.route),
        pressedScale: 0.985,
        child: AcadexCard(
          isFlat: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isHigh ? AcadexColors.errorLight : AcadexColors.primaryLight,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Icon(
                  isHigh ? LucideIcons.clock : LucideIcons.checkSquare,
                  size: 16,
                  color: isHigh ? AcadexColors.error : AcadexColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: AcadexTypography.bodySmall(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (action.description != null)
                      Text(
                        action.description!,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ).copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.actionLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AcadexColors.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(LucideIcons.arrowRight, size: 12, color: AcadexColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 5. UPCOMING EVENTS SECTION ──────────────────────────────────────────────

class DashboardUpcomingSection extends StatelessWidget {
  final List<DashboardUpcomingItemModel> upcoming;

  const DashboardUpcomingSection({
    super.key,
    required this.upcoming,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Today & Upcoming',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.push('/calendar'),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View Calendar',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AcadexColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (upcoming.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 15,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No classes scheduled today',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...upcoming.map((item) => _buildUpcomingTile(context, item, isDark)),
      ],
    );
  }

  Widget _buildUpcomingTile(BuildContext context, DashboardUpcomingItemModel item, bool isDark) {
    IconData icon;
    Color iconColor;
    switch (item.type) {
      case 'CLASS':
        icon = LucideIcons.graduationCap;
        iconColor = AcadexColors.primary;
        break;
      case 'PRACTICAL':
        icon = LucideIcons.flaskConical;
        iconColor = Colors.teal;
        break;
      case 'ASSESSMENT':
        icon = LucideIcons.penTool;
        iconColor = Colors.deepOrange;
        break;
      case 'HOLIDAY':
        icon = LucideIcons.sun;
        iconColor = Colors.amber[700]!;
        break;
      default:
        icon = LucideIcons.calendarDays;
        iconColor = Colors.purple;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AcadexPressable(
        onTap: item.route != null ? () => context.push(item.route!) : null,
        pressedScale: 0.985,
        child: AcadexCard(
          isFlat: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AcadexTypography.bodySmall(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatScheduleTime(item.startTime),
                            style: const TextStyle(
                              color: AcadexColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.location != null && item.location!.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text('•', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              item.location!,
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              ).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (item.route != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScheduleTime(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    }
    return raw;
  }
}

// ── 6. QUICK ACTIONS GRID (TACTILE & COMPACT) ───────────────────────────────

class DashboardQuickActionsGrid extends StatelessWidget {
  final List<DashboardQuickActionModel> quickActions;
  final String? title;

  const DashboardQuickActionsGrid({
    super.key,
    required this.quickActions,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (quickActions.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          title ?? 'Quick Operations',
          style: AcadexTypography.heading3(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _buildQuickActionTile(context, action, isDark);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionTile(BuildContext context, DashboardQuickActionModel action, bool isDark) {
    final icon = _resolveIcon(action.icon);

    return AcadexPressable(
      onTap: () => context.push(action.route),
      pressedScale: 0.965,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
          borderRadius: AcadexRadius.borderRadiusMd,
          border: Border.all(
            color: action.isPrimary
                ? AcadexColors.primary.withValues(alpha: 0.4)
                : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            width: action.isPrimary ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x0607111F),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: action.isPrimary
                    ? AcadexColors.primary.withValues(alpha: 0.12)
                    : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: Icon(
                icon,
                size: 15,
                color: action.isPrimary
                    ? AcadexColors.primary
                    : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                action.label,
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(
                  fontWeight: action.isPrimary ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action.badgeCount != null && action.badgeCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AcadexColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${action.badgeCount}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'checkSquare':
        return LucideIcons.checkSquare;
      case 'fileSpreadsheet':
        return LucideIcons.fileSpreadsheet;
      case 'flaskConical':
        return LucideIcons.flaskConical;
      case 'penTool':
        return LucideIcons.penTool;
      case 'award':
        return LucideIcons.award;
      case 'calendar':
        return LucideIcons.calendar;
      case 'calendarDays':
        return LucideIcons.calendarDays;
      case 'inbox':
        return LucideIcons.inbox;
      case 'bell':
        return LucideIcons.bell;
      case 'graduationCap':
        return LucideIcons.graduationCap;
      case 'users':
        return LucideIcons.users;
      case 'layers':
        return LucideIcons.layers;
      case 'building':
        return LucideIcons.building;
      case 'userCheck':
        return LucideIcons.userCheck;
      case 'fileText':
        return LucideIcons.fileText;
      case 'settings':
        return LucideIcons.settings;
      case 'megaphone':
        return LucideIcons.megaphone;
      default:
        return LucideIcons.folder;
    }
  }
}

// ── 7. RECENT ACTIVITY SECTION ──────────────────────────────────────────────

class DashboardRecentActivitySection extends StatelessWidget {
  final List<DashboardRecentActivityModel> recent;

  const DashboardRecentActivitySection({
    super.key,
    required this.recent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          'Recent Activity',
          style: AcadexTypography.heading3(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.activity,
                  size: 15,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You're all caught up. No recent updates right now.",
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...recent.map((item) => _buildRecentTile(context, item, isDark)),
      ],
    );
  }

  Widget _buildRecentTile(BuildContext context, DashboardRecentActivityModel item, bool isDark) {
    IconData icon;
    Color iconColor;
    switch (item.type) {
      case 'ANNOUNCEMENT':
        icon = LucideIcons.megaphone;
        iconColor = Colors.blue;
        break;
      case 'SUBMISSION':
        icon = LucideIcons.uploadCloud;
        iconColor = Colors.teal;
        break;
      case 'RESULT':
        icon = LucideIcons.award;
        iconColor = Colors.amber[700]!;
        break;
      case 'REQUEST':
        icon = LucideIcons.inbox;
        iconColor = Colors.purple;
        break;
      case 'ASSESSMENT':
        icon = LucideIcons.penTool;
        iconColor = Colors.deepOrange;
        break;
      default:
        icon = LucideIcons.activity;
        iconColor = AcadexColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AcadexPressable(
        onTap: item.route != null ? () => context.push(item.route!) : null,
        pressedScale: 0.985,
        child: AcadexCard(
          isFlat: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AcadexTypography.bodySmall(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ).copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (item.route != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 13,
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
