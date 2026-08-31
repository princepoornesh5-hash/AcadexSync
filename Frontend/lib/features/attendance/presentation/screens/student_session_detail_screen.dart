import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class StudentSessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const StudentSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(studentSessionDetailProvider(sessionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AcadexPageContainer(
      backgroundColor: Colors.transparent,
      maxWidth: AcadexLayout.contentMaxWidth,
      child: sessionAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading session details...'),
        error: (err, _) => AcadexErrorState(
          message: 'Unable to load attendance session: $err',
          onRetry: () => ref.refresh(studentSessionDetailProvider(sessionId)),
        ),
        data: (session) {
          if (session == null) {
            return Center(
              child: AcadexEmptyState(
                title: 'Session Not Found',
                subtitle: 'No verified attendance record was found for session ID "$sessionId".',
                actionLabel: 'Return to Portal',
                onActionTap: () => context.safePop(fallbackRoute: '/attendance'),
              ),
            );
          }

          return _buildDetailContent(context, session, isDark);
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, StudentAttendanceSessionSummary session, bool isDark) {
    final statusColor = _getStatusColor(session.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AcadexPageHeader(
          title: session.subjectName,
          subtitle: 'Official Academic Attendance Record — ${session.subjectCode}',
          actions: [
            AcadexButton(
              label: 'Back to Attendance',
              icon: LucideIcons.arrowLeft,
              variant: AcadexButtonVariant.secondary,
              onPressed: () => context.safePop(fallbackRoute: '/attendance'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Read-Only Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AcadexColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 18, color: AcadexColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verified Institutional Record • Read-Only Access (Faculty Verified)',
                  style: AcadexTypography.bodySmall(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvas : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v${session.version}',
                  style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Primary Attendance Status Card
        Container(
          padding: const EdgeInsets.all(24),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(session.status), size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          session.status.name.toUpperCase(),
                          style: AcadexTypography.bodySmall(color: statusColor).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Recorded on ${session.date.toIso8601String().split('T').first}',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Session Metadata Grid
              Wrap(
                spacing: 24,
                runSpacing: 20,
                children: [
                  _buildMetaItem('Subject Code', session.subjectCode, LucideIcons.bookOpen, isDark),
                  _buildMetaItem('Faculty Instructor', session.facultyName, LucideIcons.graduationCap, isDark),
                  _buildMetaItem('Section', session.sectionName, LucideIcons.users, isDark),
                  _buildMetaItem('Time Slot', session.timeSlot, LucideIcons.clock, isDark),
                  if (session.roomNumber != null)
                    _buildMetaItem('Room / Hall', session.roomNumber!, LucideIcons.mapPin, isDark),
                  if (session.remarks != null && session.remarks!.isNotEmpty)
                    _buildMetaItem('Faculty Remarks', session.remarks!, LucideIcons.messageSquare, isDark),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaItem(String label, String value, IconData icon, bool isDark) {
    return SizedBox(
      width: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
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

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return LucideIcons.checkCircle2;
      case AttendanceStatus.absent:
        return LucideIcons.xCircle;
      case AttendanceStatus.late:
        return LucideIcons.clockAlert;
      case AttendanceStatus.excused:
      case AttendanceStatus.medicalLeave:
      case AttendanceStatus.onDuty:
      case AttendanceStatus.holiday:
        return LucideIcons.fileCheck2;
    }
  }
}
