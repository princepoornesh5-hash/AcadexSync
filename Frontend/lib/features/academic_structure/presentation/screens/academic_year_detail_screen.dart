import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../providers/academic_providers.dart';

class AcademicYearDetailScreen extends ConsumerWidget {
  final String academicYearId;

  const AcademicYearDetailScreen({super.key, required this.academicYearId});

  void _confirmSetCurrent(BuildContext context, WidgetRef ref, String yearName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set as Current Academic Year?"),
        content: Text(
          'Set "$yearName" as the ongoing academic year for your institution?\n\nAny other active current year will be automatically unset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(academicYearsProvider.notifier).setAsCurrent(academicYearId);
                ref.invalidate(academicYearByIdProvider(academicYearId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$yearName is now set as the current academic year.'),
                      backgroundColor: AcadexColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AcadexColors.error),
                  );
                }
              }
            },
            child: const Text("Set as Current"),
          ),
        ],
      ),
    );
  }

  void _confirmStatusToggle(BuildContext context, WidgetRef ref, String yearName, bool isCurrentlyActive) {
    final action = isCurrentlyActive ? 'Deactivate' : 'Activate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Academic Year?'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to archive/deactivate $yearName? Associated semesters and registrations may be restricted while inactive.'
              : 'Are you sure you want to reactivate $yearName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive ? AcadexColors.error : AcadexColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(academicYearsProvider.notifier).toggleStatus(academicYearId, !isCurrentlyActive);
                ref.invalidate(academicYearByIdProvider(academicYearId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Academic Year $action successful!'),
                      backgroundColor: AcadexColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: AcadexColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final yearAsync = ref.watch(academicYearByIdProvider(academicYearId));
    final dateFormat = DateFormat('MMMM d, yyyy');
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = yearAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert, color: AcadexColors.error, size: 36),
            const SizedBox(height: 12),
            Text('Error loading academic year: $err', style: const TextStyle(color: AcadexColors.error)),
            const SizedBox(height: 12),
            AcadexButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(academicYearByIdProvider(academicYearId)),
            ),
          ],
        ),
      ),
      data: (year) {
        final totalDays = year.endDate.difference(year.startDate).inDays;
        final totalMonths = (totalDays / 30.44).round();

        return AcadexPageContainer(
          backgroundColor: Colors.transparent,
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, ref, isDark, isMobile, year),
              const SizedBox(height: 20),

              // ── Session Timeline & Details ────────────────────────────
              _buildTimelineCard(isDark, year, dateFormat, totalDays, totalMonths),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );

    if (hasEnclosingScaffold) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/academic_years'),
        ),
        title: Text(
          'Academic Session Overview',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isMobile,
    dynamic year,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: year.isCurrent
              ? AcadexColors.primary
              : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          width: year.isCurrent ? 1.5 : 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: const Icon(LucideIcons.calendar, color: AcadexColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      year.name,
                      style: AcadexTypography.heading1(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (year.isCurrent) ...[
                          const AcadexBadge(label: 'CURRENT SESSION', variant: AcadexBadgeVariant.primary),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: year.isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                            borderRadius: AcadexRadius.borderRadiusFull,
                          ),
                          child: Text(
                            year.isActive ? 'Active' : 'Archived',
                            style: TextStyle(
                              color: year.isActive ? AcadexColors.success : AcadexColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AcadexButton(
                label: 'Edit Session',
                icon: LucideIcons.edit,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/academic_years/edit/$academicYearId'),
              ),
              if (!year.isCurrent)
                AcadexButton(
                  label: 'Set as Current Year',
                  icon: LucideIcons.checkCircle,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => _confirmSetCurrent(context, ref, year.name),
                ),
              AcadexButton(
                label: year.isActive ? 'Deactivate' : 'Activate',
                icon: year.isActive ? LucideIcons.powerOff : LucideIcons.power,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _confirmStatusToggle(context, ref, year.name, year.isActive),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    bool isDark,
    dynamic year,
    DateFormat dateFormat,
    int totalDays,
    int totalMonths,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clock, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Session Schedule & Timeline',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.calendar, 'Session Name', year.name),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.calendarDays, 'Start Date', dateFormat.format(year.startDate)),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.calendarCheck, 'End Date', dateFormat.format(year.endDate)),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.hourglass, 'Span', '$totalMonths months (~$totalDays days)'),
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.activity,
            'Current State',
            year.isCurrent ? 'Active Ongoing Academic Session' : 'Inactive / Non-Current Session',
          ),
          if (year.createdAt != null) ...[
            const Divider(height: 16),
            _infoRow(isDark, LucideIcons.fileText, 'Created On', dateFormat.format(year.createdAt!)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AcadexTypography.caption(
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ).copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
