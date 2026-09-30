import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/practical_models.dart';
import '../providers/practicals_providers.dart';

class PracticalSessionsListScreen extends ConsumerStatefulWidget {
  const PracticalSessionsListScreen({super.key});

  @override
  ConsumerState<PracticalSessionsListScreen> createState() => _PracticalSessionsListScreenState();
}

class _PracticalSessionsListScreenState extends ConsumerState<PracticalSessionsListScreen> {
  String? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isStudent = user?.role == AppRole.student;

    final filter = PracticalFilter(status: _selectedStatusFilter);
    final sessionsAsync = ref.watch(practicalSessionsListProvider(filter));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
        ),
        title: Text(
          'Practicals & Labs',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        actions: [
          if (!isStudent)
            IconButton(
              icon: const Icon(LucideIcons.plus, color: AcadexColors.primary),
              tooltip: 'Schedule Practical',
              onPressed: () => context.push('/practicals/new'),
            ),
        ],
      ),
      floatingActionButton: !isStudent
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/practicals/new'),
              backgroundColor: AcadexColors.primary,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              label: const Text(
                'Schedule Lab',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [
          // Filter Chips (All, Planned, Open, Completed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Open', 'OPEN', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Planned', 'PLANNED', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'COMPLETED', isDark),
                ],
              ),
            ),
          ),

          // Session List
          Expanded(
            child: sessionsAsync.when(
              loading: () => const AcadexLoadingState(message: 'Loading practical lab sessions...'),
              error: (err, stack) => Center(
                child: AcadexErrorState(
                  message: "Couldn't load practical lab sessions.",
                  retryLabel: 'Retry',
                  onRetry: () => ref.refresh(practicalSessionsListProvider(filter)),
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(
                    child: AcadexEmptyState(
                      icon: LucideIcons.flaskConical,
                      title: 'No Practical Sessions',
                      subtitle: 'No practical lab sessions match the selected filter.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final sess = sessions[index];
                    return _buildSessionCard(sess, isDark, isStudent);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? statusVal, bool isDark) {
    final isSelected = _selectedStatusFilter == statusVal;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = statusVal),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AcadexColors.primary
              : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(PracticalSessionModel sess, bool isDark, bool isStudent) {
    Color statusColor;
    Color statusBg;
    switch (sess.status) {
      case PracticalSessionStatus.open:
        statusColor = const Color(0xFF15803D);
        statusBg = const Color(0xFFDCFCE7);
        break;
      case PracticalSessionStatus.completed:
        statusColor = AcadexColors.primary;
        statusBg = AcadexColors.primaryTint;
        break;
      case PracticalSessionStatus.cancelled:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        break;
      case PracticalSessionStatus.planned:
        statusColor = AcadexColors.inkSecondary;
        statusBg = isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/practicals/${sess.id}'),
        borderRadius: AcadexRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Subject + Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      sess.subjectName ?? sess.subjectCode ?? 'Practical Subject',
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sess.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Row 2: Topic Title
              Text(
                'Session ${sess.sessionNumber}: ${sess.topic}',
                style: AcadexTypography.heading2(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Row 3: Meta details (Date, Room, Participation Count)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      sess.scheduledDate.toLocal().toString().substring(0, 10),
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                    if (sess.roomNumber != null) ...[
                      const SizedBox(width: 10),
                      Icon(LucideIcons.doorClosed, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        sess.roomNumber!,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                    if (sess.totalEnrolled > 0) ...[
                      const SizedBox(width: 10),
                      Icon(LucideIcons.users, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${sess.completedCount}/${sess.totalEnrolled} completed',
                        style: AcadexTypography.caption(
                          color: sess.completedCount == sess.totalEnrolled
                              ? const Color(0xFF15803D)
                              : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        ),
                      ),
                    ],
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
