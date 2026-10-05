import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../providers/assessment_providers.dart';

class StudentInternalMarksScreen extends ConsumerWidget {
  final String? semesterId;

  const StudentInternalMarksScreen({
    super.key,
    this.semesterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final marksAsync = ref.watch(studentMarksProvider(semesterId));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
        ),
        title: Text(
          'My Internal Marks',
          style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Marks',
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(studentMarksProvider(semesterId)),
          ),
        ],
      ),
      body: AcadexPageContainer(
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Published internal assessment breakdown across your enrolled subjects.',
                style: AcadexTypography.bodySmall(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
            ),

            marksAsync.when(
              loading: () => const AcadexLoadingState(message: 'Loading your internal assessment marks...'),
              error: (err, _) => Center(
                child: AcadexErrorState(
                  message: "Couldn't load your internal marks.",
                  retryLabel: 'Retry',
                  onRetry: () => ref.refresh(studentMarksProvider(semesterId)),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 24),
                    child: Center(
                      child: AcadexEmptyState(
                        title: 'No Marks Published Yet',
                        subtitle: 'Your course instructors have not finalized or published internal marks for this term yet.',
                        icon: LucideIcons.award,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final subName = item.subject['name']?.toString() ?? 'Subject';
                    final subCode = item.subject['code']?.toString() ?? '';
                    final secName = item.section?['name']?.toString();

                    double totalMax = 0;
                    for (final c in item.components) {
                      totalMax += c.maxMarks;
                    }

                    return AcadexCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Subject Code & Section
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (subCode.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AcadexColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(AcadexRadius.xs),
                                      ),
                                      child: Text(
                                        subCode,
                                        style: const TextStyle(
                                          color: AcadexColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (secName != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Section $secName',
                                      style: AcadexTypography.caption(
                                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // Total score badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AcadexColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AcadexRadius.sm),
                                ),
                                child: Text(
                                  '${item.totalMarks % 1 == 0 ? item.totalMarks.toInt() : item.totalMarks} / ${totalMax.toInt()}',
                                  style: const TextStyle(
                                    color: AcadexColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Subject Title
                          Text(
                            subName,
                            style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // Component breakdown chips
                          Text(
                            'Component Breakdown',
                            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: item.components.map((comp) {
                              final mark = item.marks[comp.key];
                              final markText = mark != null
                                  ? (mark % 1 == 0 ? mark.toInt().toString() : mark.toString())
                                  : '—';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                                  borderRadius: BorderRadius.circular(AcadexRadius.sm),
                                  border: Border.all(
                                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      comp.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$markText / ${comp.maxMarks.toInt()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AcadexColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Instructor Remarks: ${item.remarks!}',
                              style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
