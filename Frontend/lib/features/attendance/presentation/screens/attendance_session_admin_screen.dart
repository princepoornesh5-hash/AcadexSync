import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_report_models.dart';
import '../../domain/models/attendance_session.dart';
import '../providers/attendance_admin_providers.dart';

class AttendanceSessionAdminScreen extends ConsumerStatefulWidget {
  const AttendanceSessionAdminScreen({super.key});

  @override
  ConsumerState<AttendanceSessionAdminScreen> createState() => _AttendanceSessionAdminScreenState();
}

class _AttendanceSessionAdminScreenState extends ConsumerState<AttendanceSessionAdminScreen> {
  String _searchQuery = '';
  int _page = 1;
  static const int _pageSize = 10;
  String _sortBy = 'date'; // 'date', 'attendance', 'students'
  bool _sortAscending = false;

  void _showAuditDialog(BuildContext context, AttendanceSession session, List<AttendanceAuditEntry> allAudits) {
    final sessionAudits = allAudits.where((a) => a.sessionId == session.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.history, size: 20, color: AcadexColors.primary),
            const SizedBox(width: 8),
            Text('Session Audit Trail — v${session.version}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subject: ${session.subjectName.isNotEmpty ? session.subjectName : session.subjectId} (${session.sectionName})'),
              Text('Created: ${session.createdAt?.toIso8601String().split("T").first ?? "-"} by ${session.createdBy ?? "Faculty"}'),
              Text('Last Modified: ${session.lastModifiedAt?.toIso8601String().split("T").first ?? "-"} by ${session.lastModifiedBy ?? "-"}'),
              const Divider(height: 24),
              Text('Version Delta History:', style: AcadexTypography.title()),
              const SizedBox(height: 8),
              if (sessionAudits.isEmpty)
                const Text('No record corrections recorded for this session. (Initial v1 state).')
              else
                ...sessionAudits.map((a) => ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.filePenLine, size: 16),
                  title: Text('v${a.fromVersion} → v${a.toVersion} by ${a.modifiedBy}'),
                  subtitle: Text('${a.details} (${a.modifiedAt.toIso8601String().split("T").first})'),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final deptId = user?.departmentId;

    final reconciliationAsync = ref.watch(
      attendanceReconciliationProvider((departmentId: deptId, sectionId: null, dateRange: null)),
    );
    final consistencyAsync = ref.watch(
      attendanceConsistencyProvider((departmentId: deptId, dateRange: null)),
    );
    final auditAsync = ref.watch(
      attendanceAuditHistoryProvider((departmentId: deptId, dateRange: null)),
    );
    final sessionsAsync = ref.watch(
      attendanceAdminSessionsProvider((
        query: _searchQuery,
        sectionId: null,
        facultyId: null,
        page: _page,
        pageSize: _pageSize,
      )),
    );

    final isGradientRole = user?.role == AppRole.superAdmin ||
        user?.role == AppRole.collegeAdmin ||
        user?.role == AppRole.hod ||
        user?.role == AppRole.faculty ||
        user?.role == AppRole.student;

    return Scaffold(
      backgroundColor: isGradientRole ? Colors.transparent : (isDark ? AcadexColors.darkCanvas : AcadexColors.canvas),
      appBar: AppBar(
        title: Text(
          'Attendance Administration & Audit',
          style: AcadexTypography.heading3(color: isGradientRole ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink)),
        ),
        backgroundColor: isGradientRole ? Colors.transparent : (isDark ? AcadexColors.darkSurface : AcadexColors.surface),
        elevation: 0,
        iconTheme: IconThemeData(color: isGradientRole ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reconciliation Summary Cards
            reconciliationAsync.when(
              loading: () => const AcadexLoadingState(message: 'Reconciling timetable schedules...'),
              error: (err, _) => AcadexErrorState(
                message: 'Reconciliation error: $err',
                onRetry: () => ref.refresh(
                  attendanceReconciliationProvider((departmentId: deptId, sectionId: null, dateRange: null)),
                ),
              ),
              data: (reconciliation) => _buildReconciliationOverview(context, reconciliation, isDark),
            ),
            const SizedBox(height: 24),

            // Data Consistency Issues Panel
            consistencyAsync.maybeWhen(
              data: (issues) => _buildConsistencyAlerts(context, issues, isDark),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Session List with Search, Sort, and Audit Trail
            _buildSessionTable(context, sessionsAsync, auditAsync, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildReconciliationOverview(BuildContext context, AttendanceReconciliationResult reconciliation, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.calendarClock, size: 18, color: AcadexColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Timetable Attendance Reconciliation',
                    style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: reconciliation.isFullyReconciled
                      ? AcadexColors.success.withValues(alpha: 0.1)
                      : AcadexColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${reconciliation.compliancePercentage.toStringAsFixed(1)}% Operational Compliance',
                  style: AcadexTypography.caption(
                    color: reconciliation.isFullyReconciled ? AcadexColors.success : AcadexColors.warning,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildMetricTile('Expected Classes', '${reconciliation.expectedSessions}', LucideIcons.calendarCheck, AcadexColors.primary, isDark),
              _buildMetricTile('Recorded Sessions', '${reconciliation.recordedSessions}', LucideIcons.checkCircle2, AcadexColors.success, isDark),
              _buildMetricTile('Missing Sessions', '${reconciliation.missingSessions}', LucideIcons.alertTriangle, reconciliation.missingSessions > 0 ? AcadexColors.error : AcadexColors.inkMuted, isDark),
            ],
          ),
          if (reconciliation.missingDetails.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Unmarked Scheduled Classes (${reconciliation.missingDetails.length}):',
              style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
            ),
            const SizedBox(height: 8),
            ...reconciliation.missingDetails.take(5).map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: AcadexColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${m.subjectName} (${m.sectionId}) — Scheduled: ${m.timeSlot} on ${m.scheduledDate.toIso8601String().split("T").first}',
                      style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
              Text(
                value,
                style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyAlerts(BuildContext context, List<AttendanceConsistencyIssue> issues, bool isDark) {
    if (issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AcadexColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AcadexColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: AcadexColors.success, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Data Integrity Verified: No anomalous or corrupted attendance sessions detected.',
                style: AcadexTypography.bodySmall(color: AcadexColors.success),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcadexColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldAlert, color: AcadexColors.error, size: 18),
              const SizedBox(width: 8),
              Text(
                'Data Consistency Warnings (${issues.length})',
                style: AcadexTypography.title(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...issues.map((i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: i.severity == 'critical' ? AcadexColors.error : AcadexColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    i.severity.toUpperCase(),
                    style: AcadexTypography.caption(color: Colors.white).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${i.issueType.displayName}: ${i.description}',
                    style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSessionTable(
    BuildContext context,
    AsyncValue<List<AttendanceSession>> sessionsAsync,
    AsyncValue<List<AttendanceAuditEntry>> auditAsync,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'Attendance Sessions Log',
                style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
              const Spacer(),
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search sessions...',
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onChanged: (val) => setState(() {
                    _searchQuery = val;
                    _page = 1;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          sessionsAsync.when(
            loading: () => const AcadexLoadingState(message: 'Loading attendance sessions...'),
            error: (err, _) => AcadexErrorState(message: 'Failed to load sessions: $err'),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const AcadexEmptyState(
                  icon: LucideIcons.calendarX,
                  title: 'No Sessions Found',
                  subtitle: 'No attendance sessions match the current criteria.',
                );
              }

              // Apply sorting
              final sortedSessions = List<AttendanceSession>.from(sessions)..sort((a, b) {
                int cmp;
                switch (_sortBy) {
                  case 'attendance':
                    cmp = a.attendancePercentage.compareTo(b.attendancePercentage);
                    break;
                  case 'students':
                    cmp = a.totalStudents.compareTo(b.totalStudents);
                    break;
                  case 'date':
                  default:
                    cmp = a.date.compareTo(b.date);
                    break;
                }
                return _sortAscending ? cmp : -cmp;
              });

              final allAudits = auditAsync.valueOrNull ?? [];

              return Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(
                        isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                      ),
                      columns: [
                        DataColumn(
                          label: const Text('Date'),
                          onSort: (idx, asc) => setState(() {
                            _sortBy = 'date';
                            _sortAscending = asc;
                          }),
                        ),
                        const DataColumn(label: Text('Time Slot')),
                        const DataColumn(label: Text('Subject')),
                        const DataColumn(label: Text('Section')),
                        DataColumn(
                          label: const Text('Students'),
                          onSort: (idx, asc) => setState(() {
                            _sortBy = 'students';
                            _sortAscending = asc;
                          }),
                        ),
                        DataColumn(
                          label: const Text('Attendance %'),
                          onSort: (idx, asc) => setState(() {
                            _sortBy = 'attendance';
                            _sortAscending = asc;
                          }),
                        ),
                        const DataColumn(label: Text('Status')),
                        const DataColumn(label: Text('Version')),
                        const DataColumn(label: Text('Audit Trail')),
                      ],
                      rows: sortedSessions.map((s) {
                        return DataRow(
                          cells: [
                            DataCell(Text(s.date.toIso8601String().split('T').first)),
                            DataCell(Text(s.timeSlot)),
                            DataCell(Text(s.subjectName.isNotEmpty ? s.subjectName : s.subjectId)),
                            DataCell(Text(s.sectionName.isNotEmpty ? s.sectionName : s.sectionId)),
                            DataCell(Text('${s.totalStudents}')),
                            DataCell(
                              Text(
                                '${s.attendancePercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: s.attendancePercentage < 70
                                      ? AcadexColors.error
                                      : (s.attendancePercentage < 75 ? AcadexColors.warning : AcadexColors.success),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: s.isSubmitted ? AcadexColors.success.withValues(alpha: 0.1) : AcadexColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.isSubmitted ? 'Submitted' : 'Draft',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: s.isSubmitted ? AcadexColors.success : AcadexColors.warning,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text('v${s.version}')),
                            DataCell(
                              IconButton(
                                icon: const Icon(LucideIcons.history, size: 16),
                                tooltip: 'View Audit Trail',
                                onPressed: () => _showAuditDialog(context, s, allAudits),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft),
                        onPressed: _page > 1 ? () => setState(() => _page--) : null,
                      ),
                      Text('Page $_page', style: AcadexTypography.caption()),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight),
                        onPressed: sessions.length == _pageSize ? () => setState(() => _page++) : null,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
