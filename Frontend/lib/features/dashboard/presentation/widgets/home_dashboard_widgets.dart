import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../domain/models/home_dashboard_models.dart';

// ── 1. GREETING & HEADER ─────────────────────────────────────────────────────

class DashboardGreetingHeader extends StatelessWidget {
  final DashboardGreetingModel greeting;

  const DashboardGreetingHeader({
    super.key,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark ? AcadexColors.primary.withValues(alpha: 0.2) : AcadexColors.primary.withValues(alpha: 0.1),
            backgroundImage: greeting.avatarUrl != null && greeting.avatarUrl!.isNotEmpty
                ? NetworkImage(greeting.avatarUrl!)
                : null,
            child: greeting.avatarUrl == null || greeting.avatarUrl!.isEmpty
                ? Text(
                    greeting.displayName.isNotEmpty ? greeting.displayName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AcadexColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting.greetingText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  greeting.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. CONTEXT CARD ─────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content;
    switch (role.toUpperCase()) {
      case 'STUDENT':
        if (!contextModel.isEnrollmentAvailable) {
          content = Row(
            children: [
              Icon(LucideIcons.alertCircle, color: AcadexColors.warning, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your current academic enrollment is not available.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        } else {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.graduationCap, color: AcadexColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contextModel.courseName ?? 'Enrolled Program',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (contextModel.semesterNumber != null)
                    _buildPill(context, 'Semester ${contextModel.semesterNumber}', LucideIcons.bookOpen),
                  if (contextModel.sectionName != null && contextModel.sectionName!.isNotEmpty)
                    _buildPill(context, contextModel.sectionName!, LucideIcons.layoutGrid),
                  if (contextModel.rollNumber != null && contextModel.rollNumber!.isNotEmpty)
                    _buildPill(context, 'Roll: ${contextModel.rollNumber}', LucideIcons.hash),
                ],
              ),
            ],
          );
        }
        break;

      case 'FACULTY':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.briefcase, color: AcadexColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contextModel.departmentName ?? 'Department Faculty',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (contextModel.designation != null)
                  _buildPill(context, contextModel.designation!, LucideIcons.user),
                _buildPill(
                  context,
                  '${contextModel.activeTeachingAssignmentsCount} Assigned Class${contextModel.activeTeachingAssignmentsCount == 1 ? '' : 'es'}',
                  LucideIcons.calendarCheck,
                ),
              ],
            ),
          ],
        );
        break;

      case 'HOD':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.layers, color: AcadexColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contextModel.departmentName ?? 'Department',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildPill(context, 'Head of Department', LucideIcons.shieldCheck),
                if (contextModel.departmentCode != null)
                  _buildPill(context, contextModel.departmentCode!, LucideIcons.code),
              ],
            ),
          ],
        );
        break;

      case 'COLLEGE_ADMIN':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.building, color: AcadexColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contextModel.collegeName ?? 'Institution Operations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPill(context, 'College Administration', LucideIcons.shield),
          ],
        );
        break;

      default:
        content = Row(
          children: [
            Icon(LucideIcons.globe, color: AcadexColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ACADEX Platform Administration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
    }

    return AcadexCard(
      child: content,
    );
  }

  Widget _buildPill(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 5),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: alerts.map((alert) {
          final isWarning = alert.severity == 'WARNING';
          final isCritical = alert.severity == 'CRITICAL';
          final color = isCritical
              ? AcadexColors.error
              : (isWarning ? AcadexColors.warning : AcadexColors.primary);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: alert.route != null ? () => context.push(alert.route!) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCritical
                          ? LucideIcons.alertOctagon
                          : (isWarning ? LucideIcons.alertTriangle : LucideIcons.info),
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            alert.message,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (alert.route != null)
                      Icon(LucideIcons.chevronRight, size: 16, color: color),
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

// ── 4. PENDING ACTIONS SECTION ──────────────────────────────────────────────

class DashboardPendingActionsSection extends StatelessWidget {
  final List<DashboardPendingActionModel> pendingActions;

  const DashboardPendingActionsSection({
    super.key,
    required this.pendingActions,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingActions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Actions Requiring Attention',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${pendingActions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AcadexColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...pendingActions.map((action) => _buildActionCard(context, action)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, DashboardPendingActionModel action) {
    final theme = Theme.of(context);
    final isHigh = action.priority == 'HIGH';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AcadexCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isHigh ? AcadexColors.error.withValues(alpha: 0.1) : AcadexColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isHigh ? LucideIcons.clock : LucideIcons.checkSquare,
                size: 18,
                color: isHigh ? AcadexColors.error : AcadexColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (action.description != null)
                    Text(
                      action.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push(action.route),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action.actionLabel, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.arrowRight, size: 12),
                ],
              ),
            ),
          ],
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Today & Upcoming',
                style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.push('/calendar'),
              child: Text(
                'View Calendar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AcadexColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          AcadexCard(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.calendar, size: 28, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No classes or events scheduled right now.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...upcoming.map((item) => _buildUpcomingTile(context, item)),
      ],
    );
  }

  Widget _buildUpcomingTile(BuildContext context, DashboardUpcomingItemModel item) {
    final theme = Theme.of(context);

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
      padding: const EdgeInsets.only(bottom: 8),
      child: AcadexCard(
        padding: const EdgeInsets.all(12),
        onTap: item.route != null ? () => context.push(item.route!) : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _formatScheduleTime(item.startTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AcadexColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.location != null && item.location!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text('•', style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.location!,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
              Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[400]),
          ],
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

// ── 6. QUICK ACTIONS GRID ───────────────────────────────────────────────────

class DashboardQuickActionsGrid extends StatelessWidget {
  final List<DashboardQuickActionModel> quickActions;

  const DashboardQuickActionsGrid({
    super.key,
    required this.quickActions,
  });

  @override
  Widget build(BuildContext context) {
    if (quickActions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Quick Shortcuts',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive column count: 2 for 360-480px, 4 for desktop
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.3,
              ),
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _buildQuickActionTile(context, action);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionTile(BuildContext context, DashboardQuickActionModel action) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData icon = _resolveIcon(action.icon);

    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: action.isPrimary
                ? AcadexColors.primary.withValues(alpha: 0.5)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2)),
            width: action.isPrimary ? 1.5 : 1.0,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: action.isPrimary
                    ? AcadexColors.primary.withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: action.isPrimary ? AcadexColors.primary : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                action.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: action.isPrimary ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action.badgeCount != null && action.badgeCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AcadexColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${action.badgeCount}',
                  style: const TextStyle(
                    fontSize: 10,
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Recent Activity',
          style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          AcadexCard(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Center(
              child: Text(
                "You're all caught up.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ),
          )
        else
          ...recent.map((item) => _buildRecentTile(context, item)),
      ],
    );
  }

  Widget _buildRecentTile(BuildContext context, DashboardRecentActivityModel item) {
    final theme = Theme.of(context);

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
      padding: const EdgeInsets.only(bottom: 8),
      child: AcadexCard(
        padding: const EdgeInsets.all(12),
        onTap: item.route != null ? () => context.push(item.route!) : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (item.route != null)
              Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
