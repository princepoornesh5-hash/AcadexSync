import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  void _confirmStatusToggle(BuildContext context, WidgetRef ref, String subjectName, bool isCurrentlyActive) {
    final action = isCurrentlyActive ? 'Deactivate' : 'Activate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Subject?'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to archive/deactivate "$subjectName"? It will become hidden from faculty allocation and student timetables.'
              : 'Are you sure you want to reactivate "$subjectName"?',
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
                await ref.read(subjectsProvider.notifier).toggleStatus(subjectId, !isCurrentlyActive);
                ref.invalidate(subjectByIdProvider(subjectId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Subject $action successful!'),
                      backgroundColor: AcadexColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AcadexColors.error),
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
    final subjectAsync = ref.watch(subjectByIdProvider(subjectId));
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final dateFormat = DateFormat('MMMM d, yyyy');

    final coursesMap = {for (final c in coursesAsync.valueOrNull ?? <Course>[]) c.id: c};
    final semsMap = {for (final s in semestersAsync.valueOrNull ?? <Semester>[]) s.id: s};
    final yearsMap = {for (final y in yearsAsync.valueOrNull ?? <AcademicYear>[]) y.id: y};
    final deptsMap = {for (final d in deptsAsync.valueOrNull ?? <Department>[]) d.id: d};
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = subjectAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert, color: AcadexColors.error, size: 36),
            const SizedBox(height: 12),
            Text('Error loading subject: $err', style: const TextStyle(color: AcadexColors.error)),
            const SizedBox(height: 12),
            AcadexButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(subjectByIdProvider(subjectId)),
            ),
          ],
        ),
      ),
      data: (subject) {
        final semester = semsMap[subject.semesterId];
        final course = coursesMap[subject.courseId] ?? (semester != null ? coursesMap[semester.courseId] : null);
        final academicYear = semester != null ? yearsMap[semester.academicYearId] : null;
        final department = deptsMap[subject.departmentId] ?? (course != null ? deptsMap[course.departmentId] : null);

        return AcadexPageContainer(
          backgroundColor: Colors.transparent,
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, ref, isDark, isMobile, subject),
              const SizedBox(height: 20),

              // ── Academic Hierarchy Card ───────────────────────────────
              _buildHierarchyCard(isDark, course, semester, academicYear, department),
              const SizedBox(height: 20),

              // ── Curriculum Specifications Card ────────────────────────
              _buildSpecsCard(isDark, subject, dateFormat),
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
          onPressed: () => context.safePop(fallbackRoute: '/academics/subjects'),
        ),
        title: Text(
          'Curriculum Subject Overview',
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
    Subject subject,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
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
                child: const Center(
                  child: Icon(LucideIcons.bookOpen, color: AcadexColors.primary, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: AcadexTypography.heading1(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AcadexColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subject.code,
                            style: const TextStyle(
                              color: AcadexColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${subject.credits} Credits",
                            style: TextStyle(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subject.type,
                            style: TextStyle(
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: subject.isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                            borderRadius: AcadexRadius.borderRadiusFull,
                          ),
                          child: Text(
                            subject.isActive ? 'Active' : 'Archived',
                            style: TextStyle(
                              color: subject.isActive ? AcadexColors.success : AcadexColors.error,
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
                label: 'Edit Subject',
                icon: LucideIcons.edit,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/subjects/edit/$subjectId'),
              ),
              AcadexButton(
                label: subject.isActive ? 'Deactivate' : 'Activate',
                icon: subject.isActive ? LucideIcons.powerOff : LucideIcons.power,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _confirmStatusToggle(context, ref, subject.name, subject.isActive),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyCard(
    bool isDark,
    Course? course,
    Semester? semester,
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
                'Academic Curriculum Affiliation',
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
            LucideIcons.calendarClock,
            'Semester / Term',
            semester != null ? "${semester.name} (Term ${semester.number})" : "Linked Semester",
          ),
          if (academicYear != null) ...[
            const Divider(height: 16),
            _infoRow(
              isDark,
              LucideIcons.calendar,
              'Academic Session',
              academicYear.name,
            ),
          ],
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

  Widget _buildSpecsCard(
    bool isDark,
    Subject subject,
    DateFormat dateFormat,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.fileText, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Curriculum Specifications & Metadata',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.hash, 'Subject Code', subject.code),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.award, 'Credits', "${subject.credits} Credits"),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.layers, 'Instruction Type', subject.type),
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.activity,
            'Status',
            subject.isActive ? 'Active Subject' : 'Archived Subject',
          ),
          if (subject.createdAt != null) ...[
            const Divider(height: 16),
            _infoRow(isDark, LucideIcons.clock, 'Created On', dateFormat.format(subject.createdAt!)),
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
