import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../providers/academic_providers.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  void _confirmStatusToggle(BuildContext context, WidgetRef ref, String courseName, bool isCurrentlyActive) {
    final action = isCurrentlyActive ? 'Deactivate' : 'Activate';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Course?'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to deactivate $courseName? Students and semesters associated with this course may be impacted.'
              : 'Are you sure you want to activate $courseName?',
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
                await ref.read(coursesProvider.notifier).toggleCourseStatus(courseId, !isCurrentlyActive);
                ref.invalidate(courseByIdProvider(courseId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Course $action successful!'),
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
    final courseAsync = ref.watch(courseByIdProvider(courseId));
    final deptMap = ref.watch(departmentMapProvider);
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = courseAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert, color: AcadexColors.error, size: 36),
            const SizedBox(height: 12),
            Text('Error loading course: $err', style: const TextStyle(color: AcadexColors.error)),
            const SizedBox(height: 12),
            AcadexButton(
              label: 'Retry',
              onPressed: () => ref.invalidate(courseByIdProvider(courseId)),
            ),
          ],
        ),
      ),
      data: (course) {
        final dept = deptMap[course.departmentId];
        final deptName = dept?.name ?? (course.departmentId.isNotEmpty ? course.departmentId : 'Unassigned Department');
        final deptCode = dept?.code ?? '';

        return AcadexPageContainer(
          backgroundColor: Colors.transparent,
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header Card ──────────────────────────────────────
              _buildHeroCard(context, ref, isDark, isMobile, course),
              const SizedBox(height: 20),

              // ── Course & Department Cards ─────────────────────────────
              if (isMobile) ...[
                _buildDetailsCard(context, isDark, course),
                const SizedBox(height: 20),
                _buildDepartmentCard(context, isDark, deptName, deptCode, dept?.id),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildDetailsCard(context, isDark, course)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildDepartmentCard(context, isDark, deptName, deptCode, dept?.id)),
                  ],
                ),
              ],
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
          onPressed: () => context.safePop(fallbackRoute: '/academics/courses'),
        ),
        title: Text(
          'Course Overview',
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
    dynamic course,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
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
                child: const Icon(LucideIcons.bookOpen, color: AcadexColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: AcadexTypography.heading1(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                            borderRadius: AcadexRadius.borderRadiusSm,
                          ),
                          child: Text(
                            'CODE: ${course.code}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: course.isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                            borderRadius: AcadexRadius.borderRadiusFull,
                          ),
                          child: Text(
                            course.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: course.isActive ? AcadexColors.success : AcadexColors.error,
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
                label: 'Edit Course',
                icon: LucideIcons.edit,
                variant: AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/courses/edit/$courseId'),
              ),
              AcadexButton(
                label: course.isActive ? 'Deactivate' : 'Activate',
                icon: course.isActive ? LucideIcons.powerOff : LucideIcons.power,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => _confirmStatusToggle(context, ref, course.name, course.isActive),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    bool isDark,
    dynamic course,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 8),
              Text(
                'Degree Program Details',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(isDark, LucideIcons.tag, 'Code', course.code),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.bookOpen, 'Program Name', course.name),
          const Divider(height: 16),
          _infoRow(isDark, LucideIcons.calendar, 'Duration', '${course.duration} ${course.duration == 1 ? "Year" : "Years"}'),
          const Divider(height: 16),
          _infoRow(
            isDark,
            LucideIcons.activity,
            'Status',
            course.isActive ? 'Active (Accepting enrollments & curriculum)' : 'Inactive (Archived)',
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(
    BuildContext context,
    bool isDark,
    String deptName,
    String deptCode,
    String? deptId,
  ) {
    return AcadexCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.layers, size: 16, color: AcadexColors.primary),
              const SizedBox(width: 8),
              Text(
                'Department Affiliation',
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
              borderRadius: AcadexRadius.borderRadiusMd,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deptName,
                        style: AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (deptCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: AcadexRadius.borderRadiusSm,
                        ),
                        child: Text(
                          deptCode,
                          style: const TextStyle(
                            color: AcadexColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (deptId != null && deptId.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(LucideIcons.arrowUpRight, size: 14),
                    label: const Text('View Department Overview', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.push('/academics/departments/$deptId'),
                  ),
              ],
            ),
          ),
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
          width: 95,
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
