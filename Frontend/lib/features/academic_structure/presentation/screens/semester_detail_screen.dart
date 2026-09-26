import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class SemesterDetailScreen extends ConsumerWidget {
  final String semesterId;

  const SemesterDetailScreen({super.key, required this.semesterId});

  void _confirmCurrentToggle(BuildContext context, WidgetRef ref, String semesterName, bool isCurrentlyCurrent) {
    final action = isCurrentlyCurrent ? 'Unset Current Term' : 'Set as Current Ongoing Term';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action?'),
        content: Text(
          isCurrentlyCurrent
              ? 'Mark "$semesterName" as no longer the currently ongoing term?'
              : 'Mark "$semesterName" as the active ongoing term for teaching and scheduling?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(semestersProvider.notifier).toggleCurrent(semesterId, !isCurrentlyCurrent);
                ref.invalidate(semesterByIdProvider(semesterId));
                if (context.mounted) {
                  AcadexSnackBar.showSuccess(context, 'Semester current status updated successfully.');
                }
              } catch (e) {
                if (context.mounted) {
                  AcadexSnackBar.showError(context, e);
                }
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _confirmStatusToggle(BuildContext context, WidgetRef ref, String semesterName, bool isCurrentlyActive) {
    final action = isCurrentlyActive ? 'Deactivate' : 'Activate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Semester?'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to archive/deactivate "$semesterName"? Active sections or timetable entries under this semester may become hidden.'
              : 'Are you sure you want to reactivate "$semesterName"?',
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
                await ref.read(semestersProvider.notifier).toggleStatus(semesterId, !isCurrentlyActive);
                ref.invalidate(semesterByIdProvider(semesterId));
                if (context.mounted) {
                  AcadexSnackBar.showSuccess(context, 'Semester $action successful!');
                }
              } catch (e) {
                if (context.mounted) {
                  AcadexSnackBar.showError(context, e);
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
    final semesterAsync = ref.watch(semesterByIdProvider(semesterId));
    final coursesAsync = ref.watch(coursesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final dateFormat = DateFormat('MMMM d, yyyy');

    final coursesMap = {for (final c in coursesAsync.valueOrNull ?? <Course>[]) c.id: c};
    final yearsMap = {for (final y in yearsAsync.valueOrNull ?? <AcademicYear>[]) y.id: y};
    final deptsMap = {for (final d in deptsAsync.valueOrNull ?? <Department>[]) d.id: d};
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = semesterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: AcadexErrorState.fromError(
          error: err,
          title: 'Unable to load semester',
          onRetry: () => ref.invalidate(semesterByIdProvider(semesterId)),
          actionLabel: 'Go Back',
          onAction: () => context.safePop(fallbackRoute: '/academics/semesters'),
        ),
      ),
      data: (semester) {
        final course = coursesMap[semester.courseId];
        final academicYear = yearsMap[semester.academicYearId];
        final department = deptsMap[semester.departmentId] ?? (course != null ? deptsMap[course.departmentId] : null);

        return AcadexPageContainer(
          backgroundColor: Colors.white,
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, ref, isDark, isMobile, semester),
              const SizedBox(height: 20),

              // ── Curriculum & Parent Affiliations ──────────────────────
              _buildCurriculumCard(isDark, course, academicYear, department),
              const SizedBox(height: 20),

              // ── Schedule & Details ────────────────────────────────────
              _buildScheduleCard(isDark, semester, dateFormat),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/academics/semesters'),
        ),
        title: Text(
          'Semester Term Overview',
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
    dynamic semester,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: semester.isCurrent
              ? AcadexColors.primary
              : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          width: semester.isCurrent ? 1.5 : 1,
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
                child: Center(
                  child: Text(
                    "T${semester.number}",
                    style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semester.name,
                      style: AcadexTypography.heading1(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (semester.isCurrent) ...[
                          const AcadexBadge(label: 'CURRENT TERM', variant: AcadexBadgeVariant.primary),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: semester.isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                            borderRadius: AcadexRadius.borderRadiusFull,
                          ),
                          child: Text(
                            semester.isActive ? 'Active' : 'Archived',
                            style: TextStyle(
                              color: semester.isActive ? AcadexColors.success : AcadexColors.error,
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
                label: 'Edit Semester',
                icon: LucideIcons.edit,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/semesters/edit/$semesterId'),
              ),
              AcadexButton(
                label: semester.isCurrent ? 'Unset Current Term' : 'Set as Current Term',
                icon: LucideIcons.checkCircle,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _confirmCurrentToggle(context, ref, semester.name, semester.isCurrent),
              ),
              AcadexButton(
                label: semester.isActive ? 'Deactivate' : 'Activate',
                icon: semester.isActive ? LucideIcons.powerOff : LucideIcons.power,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _confirmStatusToggle(context, ref, semester.name, semester.isActive),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumCard(
    bool isDark,
    Course? course,
    AcademicYear? academicYear,
    Department? department,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.graduationCap, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Curriculum & Hierarchy Affiliation',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(
            isDark,
            LucideIcons.bookOpen,
            'Degree Program',
            course != null ? "${course.name} (${course.code})" : "Linked Degree Program",
          ),
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.calendar,
            'Academic Session',
            academicYear != null ? academicYear.name : "Linked Session",
          ),
          if (department != null) ...[
            const Divider(height: 16),
            _infoRow(
              isDark,
              LucideIcons.building2,
              'Department',
              "${department.name} (${department.code})",
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
    bool isDark,
    dynamic semester,
    DateFormat dateFormat,
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
                'Term Schedule & Metadata',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.hash, 'Sequence Term #', "Term ${semester.number}"),
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.calendarDays,
            'Start Date',
            semester.startDate != null ? dateFormat.format(semester.startDate!) : "Not configured",
          ),
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.calendarCheck,
            'End Date',
            semester.endDate != null ? dateFormat.format(semester.endDate!) : "Not configured",
          ),
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.activity,
            'Term State',
            semester.isCurrent ? 'Current Active Term' : 'Non-Current Term',
          ),
          if (semester.createdAt != null) ...[
            const Divider(height: 16),
            _infoRow(isDark, LucideIcons.fileText, 'Created On', dateFormat.format(semester.createdAt!)),
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
          width: 120,
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
