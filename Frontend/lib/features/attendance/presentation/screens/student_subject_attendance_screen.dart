import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/student_attendance_models.dart';
import '../providers/student_portal_providers.dart';
import 'student_attendance_portal_screen.dart';

/// Dedicated Student Subject Attendance screen with chronological history drilldown
class StudentSubjectAttendanceScreen extends ConsumerWidget {
  final String? subjectId;

  const StudentSubjectAttendanceScreen({
    super.key,
    this.subjectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subjectId == null || subjectId!.isEmpty) {
      return const StudentAttendancePortalScreen(initialTab: 1);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(studentSubjectHistoryProvider(subjectId!));
    final subjectsAsync = ref.watch(studentDetailedSubjectsProvider);

    return AcadexPageContainer(
      backgroundColor: Colors.transparent,
      maxWidth: AcadexLayout.contentMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            AcadexPageHeader(
              title: 'Subject Attendance History',
              subtitle: 'Chronological verified attendance sessions for $subjectId',
              actions: [
                AcadexButton(
                  label: 'Back to Subjects',
                  icon: LucideIcons.arrowLeft,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => context.safePop(fallbackRoute: '/attendance'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject Summary Header Card if available
            subjectsAsync.maybeWhen(
              data: (subjects) {
                final sub = subjects.where((s) => s.subjectId == subjectId).firstOrNull;
                if (sub == null) return const SizedBox.shrink();

                final statusColor = sub.isBelowThreshold
                    ? AcadexColors.error
                    : (sub.attendancePercentage < 85 ? AcadexColors.warning : AcadexColors.success);

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.subjectName,
                                  style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sub.subjectCode} • ${sub.facultyName}',
                                  style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${sub.attendancePercentage.toStringAsFixed(1)}%',
                              style: AcadexTypography.body(color: statusColor).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _buildStatBadge('Total Classes', '${sub.totalClasses}', LucideIcons.calendar, isDark),
                          _buildStatBadge('Present', '${sub.presentCount}', LucideIcons.checkCircle2, isDark, color: AcadexColors.success),
                          _buildStatBadge('Absent', '${sub.absentCount}', LucideIcons.xCircle, isDark, color: AcadexColors.error),
                          _buildStatBadge('Late', '${sub.lateCount}', LucideIcons.clockAlert, isDark, color: AcadexColors.warning),
                          _buildStatBadge('Excused', '${sub.excusedCount}', LucideIcons.fileCheck2, isDark, color: AcadexColors.primary),
                        ],
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Chronological Session History
            Expanded(
              child: historyAsync.when(
                loading: () => const AcadexLoadingState(message: 'Loading chronological attendance history...'),
                error: (err, _) => AcadexErrorState(
                  message: 'Unable to load subject history: $err',
                  onRetry: () => ref.refresh(studentSubjectHistoryProvider(subjectId!)),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const AcadexEmptyState(
                      title: 'No Session Records Found',
                      subtitle: 'No attendance sessions have been logged for this subject yet.',
                    );
                  }

                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _buildHistorySessionTile(context, session, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, bool isDark, {Color? color}) {
    final effectiveColor = color ?? (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySessionTile(BuildContext context, StudentAttendanceSessionSummary session, bool isDark) {
    final statusColor = _getStatusColor(session.status);

    return InkWell(
      onTap: () => context.push('/attendance/student/sessions/${session.sessionId}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                session.status.name.toUpperCase(),
                style: AcadexTypography.caption(color: statusColor).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.subjectName,
                    style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.date.toIso8601String().split('T').first} • ${session.timeSlot} • ${session.facultyName}${session.roomNumber != null ? " • Room: ${session.roomNumber}" : ""}',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AcadexColors.success;
      case AttendanceStatus.absent:
        return AcadexColors.error;
      case AttendanceStatus.late:
        return AcadexColors.warning;
      case AttendanceStatus.excused:
      case AttendanceStatus.medicalLeave:
      case AttendanceStatus.onDuty:
      case AttendanceStatus.holiday:
        return AcadexColors.primary;
    }
  }
}
