import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../domain/models/practical_models.dart';
import '../providers/practicals_providers.dart';

class StudentPracticalsScreen extends ConsumerWidget {
  final String? subjectId;

  const StudentPracticalsScreen({
    super.key,
    this.subjectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(studentPracticalHistoryProvider(subjectId));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
        ),
        title: Text(
          'My Practical Labs',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: historyAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading your practical lab history...'),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: "Couldn't load your practical labs.",
            retryLabel: 'Retry',
            onRetry: () => ref.refresh(studentPracticalHistoryProvider(subjectId)),
          ),
        ),
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: AcadexEmptyState(
                icon: LucideIcons.flaskConical,
                title: 'No Practical Records Yet',
                subtitle: 'You do not have any recorded practical lab participations.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildHistoryCard(item, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(StudentPracticalHistoryModel item, bool isDark) {
    Color statusColor;
    Color statusBg;
    switch (item.participationStatus) {
      case PracticalParticipationStatus.completed:
        statusColor = const Color(0xFF15803D);
        statusBg = const Color(0xFFDCFCE7);
        break;
      case PracticalParticipationStatus.inProgress:
        statusColor = AcadexColors.primary;
        statusBg = AcadexColors.primaryTint;
        break;
      case PracticalParticipationStatus.absent:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        break;
      case PracticalParticipationStatus.excused:
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      case PracticalParticipationStatus.notStarted:
        statusColor = AcadexColors.inkSecondary;
        statusBg = isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
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
                  '${item.subjectCode} • ${item.subjectName}',
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.participationStatus.displayName,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Session ${item.sessionNumber}: ${item.topic}',
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(LucideIcons.calendar, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              const SizedBox(width: 4),
              Text(
                item.scheduledDate.toLocal().toString().substring(0, 10),
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              if (item.roomNumber != null) ...[
                const SizedBox(width: 12),
                Icon(LucideIcons.doorClosed, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                const SizedBox(width: 4),
                Text(
                  item.roomNumber!,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),

          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Faculty Note: ${item.notes}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
