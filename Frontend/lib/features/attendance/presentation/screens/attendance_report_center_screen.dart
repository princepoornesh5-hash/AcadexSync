import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../../domain/models/attendance_report_models.dart';
import '../../domain/services/attendance_report_exporter.dart';
import '../providers/attendance_admin_providers.dart';

class AttendanceReportCenterScreen extends ConsumerStatefulWidget {
  const AttendanceReportCenterScreen({super.key});

  @override
  ConsumerState<AttendanceReportCenterScreen> createState() => _AttendanceReportCenterScreenState();
}

class _AttendanceReportCenterScreenState extends ConsumerState<AttendanceReportCenterScreen> {
  int _previewPage = 1;
  static const int _previewPageSize = 10;
  String _tableSearchQuery = '';

  List<AttendanceReportType> _getAllowedReportTypes(AppRole role) {
    switch (role) {
      case AppRole.student:
        return [AttendanceReportType.student];
      case AppRole.faculty:
        return [
          AttendanceReportType.student,
          AttendanceReportType.subject,
          AttendanceReportType.section,
          AttendanceReportType.faculty,
          AttendanceReportType.session,
          AttendanceReportType.lowAttendance,
        ];
      case AppRole.hod:
        return [
          AttendanceReportType.student,
          AttendanceReportType.subject,
          AttendanceReportType.section,
          AttendanceReportType.faculty,
          AttendanceReportType.department,
          AttendanceReportType.session,
          AttendanceReportType.lowAttendance,
        ];
      case AppRole.collegeAdmin:
      case AppRole.superAdmin:
        return AttendanceReportType.values;
    }
  }

  void _exportCsv(AttendanceReportResult report) {
    AttendanceReportExporter.generateReportCsv(report);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.fileSpreadsheet, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'CSV Generated successfully (${report.totalRecords} records exported).',
                style: AcadexTypography.bodySmall(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AcadexColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportPdf(AttendanceReportResult report) {
    AttendanceReportExporter.generateStructuredPdfReport(reportResult: report);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.fileText, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Official PDF Document compiled successfully.',
                style: AcadexTypography.bodySmall(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AcadexColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final role = user?.role ?? AppRole.student;

    final allowedTypes = _getAllowedReportTypes(role);
    final currentFilter = ref.watch(attendanceReportFilterProvider);

    // Ensure selected report type is allowed for current role
    final effectiveType = allowedTypes.contains(currentFilter.reportType)
        ? currentFilter.reportType
        : allowedTypes.first;

    final effectiveFilter = currentFilter.copyWith(reportType: effectiveType);
    final reportAsync = ref.watch(attendanceReportDataProvider(effectiveFilter));

    final isGradientRole = role == AppRole.superAdmin ||
        role == AppRole.collegeAdmin ||
        role == AppRole.hod ||
        role == AppRole.faculty ||
        role == AppRole.student;

    return Scaffold(
      backgroundColor: isGradientRole ? Colors.transparent : (isDark ? AcadexColors.darkCanvas : AcadexColors.canvas),
      appBar: AppBar(
        title: Text(
          'Attendance Report Center',
          style: AcadexTypography.heading3(color: isGradientRole ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink)),
        ),
        backgroundColor: isGradientRole ? Colors.transparent : (isDark ? AcadexColors.darkSurface : AcadexColors.surface),
        elevation: 0,
        iconTheme: IconThemeData(color: isGradientRole ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink)),
        actions: [
          reportAsync.maybeWhen(
            data: (report) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _exportCsv(report),
                    icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                    label: const Text('Export CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _exportPdf(report),
                    icon: const Icon(LucideIcons.fileText, size: 16, color: Colors.white),
                    label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selector
            Text(
              'Select Report Type',
              style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allowedTypes.map((type) {
                  final isSelected = type == effectiveType;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _previewPage = 1;
                            _tableSearchQuery = '';
                          });
                          ref.read(attendanceReportFilterProvider.notifier).state =
                              effectiveFilter.copyWith(reportType: type);
                        }
                      },
                      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                      labelStyle: AcadexTypography.bodySmall(
                        color: isSelected
                            ? AcadexColors.primary
                            : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Date Range & Quick Preset Filters
            _buildFilterBar(context, effectiveFilter, isDark),
            const SizedBox(height: 24),

            // Report Preview Area
            reportAsync.when(
              loading: () => const AcadexLoadingState(message: 'Generating attendance report...'),
              error: (err, _) => AcadexErrorState(
                message: 'Failed to generate report: $err',
                onRetry: () => ref.refresh(attendanceReportDataProvider(effectiveFilter)),
              ),
              data: (report) => _buildReportPreview(context, report, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, AttendanceReportFilter filter, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.slidersHorizontal, size: 16, color: AcadexColors.primary),
              const SizedBox(width: 8),
              Text(
                'Report Filters & Scope',
                style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
              ),
              const Spacer(),
              if (filter.dateRange != null)
                TextButton.icon(
                  onPressed: () {
                    ref.read(attendanceReportFilterProvider.notifier).state =
                        filter.copyWith(dateRange: null);
                  },
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: const Text('Clear Date Filter'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(LucideIcons.calendarDays, size: 14),
                label: Text(AttendanceReportExporter.formatDateRange(filter.dateRange)),
                onPressed: () => _showDateRangePicker(context, filter),
              ),
              ActionChip(
                avatar: const Icon(LucideIcons.calendar, size: 14),
                label: const Text('Last 30 Days'),
                onPressed: () {
                  final now = DateTime.now();
                  final range = AttendanceDateRange.custom(
                    startDate: now.subtract(const Duration(days: 30)),
                    endDate: now,
                  );
                  ref.read(attendanceReportFilterProvider.notifier).state =
                      filter.copyWith(dateRange: range);
                },
              ),
              ActionChip(
                avatar: const Icon(LucideIcons.calendarCheck, size: 14),
                label: const Text('This Term (90 Days)'),
                onPressed: () {
                  final now = DateTime.now();
                  final range = AttendanceDateRange.custom(
                    startDate: now.subtract(const Duration(days: 90)),
                    endDate: now,
                  );
                  ref.read(attendanceReportFilterProvider.notifier).state =
                      filter.copyWith(dateRange: range);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context, AttendanceReportFilter filter) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: filter.dateRange != null
          ? DateTimeRange(start: filter.dateRange!.startDate, end: filter.dateRange!.endDate)
          : null,
    );

    if (picked != null) {
      final range = AttendanceDateRange.custom(
        startDate: picked.start,
        endDate: picked.end,
      );
      ref.read(attendanceReportFilterProvider.notifier).state = filter.copyWith(dateRange: range);
    }
  }

  Widget _buildReportPreview(BuildContext context, AttendanceReportResult report, bool isDark) {
    if (report.rows.isEmpty) {
      return const AcadexEmptyState(
        icon: LucideIcons.fileQuestion,
        title: 'No Report Data',
        subtitle: 'No attendance records match the selected scope and criteria.',
      );
    }

    // Filter rows by table search query
    final filteredRows = _tableSearchQuery.trim().isEmpty
        ? report.rows
        : report.rows.where((row) {
            final q = _tableSearchQuery.toLowerCase();
            return row.any((cell) => cell.toString().toLowerCase().contains(q));
          }).toList();

    // Paginate rows
    final totalRows = filteredRows.length;
    final totalPages = (totalRows / _previewPageSize).ceil().clamp(1, 9999);
    final currentPage = _previewPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _previewPageSize;
    final endIndex = (startIndex + _previewPageSize).clamp(0, totalRows);
    final pagedRows = filteredRows.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Header & Scope
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: AcadexTypography.heading3(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.scopeDescription,
                      style: AcadexTypography.bodySmall(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${report.totalRecords} Total Records',
                  style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Statistics Grid
          if (report.summaryStatistics.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                children: report.summaryStatistics.entries.map((e) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.value.toString(),
                        style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Search inside table
          TextField(
            decoration: InputDecoration(
              hintText: 'Search within table...',
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              setState(() {
                _tableSearchQuery = val;
                _previewPage = 1;
              });
            },
          ),
          const SizedBox(height: 16),

          // Scrollable Preview Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
              ),
              columns: report.headers.map((h) {
                return DataColumn(
                  label: Text(
                    h,
                    style: AcadexTypography.bodySmall(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
              rows: pagedRows.map((row) {
                return DataRow(
                  cells: row.map((cell) {
                    final str = cell.toString();
                    final isCritical = str.contains('CRITICAL') || str.contains('NON-COMPLIANT');
                    final isSuccess = str.contains('GOOD') || str.contains('HEALTHY') || str.contains('VERIFIED');

                    Color? textColor;
                    if (isCritical) textColor = AcadexColors.error;
                    if (isSuccess) textColor = AcadexColors.success;

                    return DataCell(
                      Text(
                        str,
                        style: AcadexTypography.bodySmall(
                          color: textColor ?? (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                        ).copyWith(fontWeight: isCritical ? FontWeight.w700 : FontWeight.w400),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Pagination Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${startIndex + 1}–$endIndex of $totalRows rows',
                style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 18),
                    onPressed: currentPage > 1
                        ? () => setState(() => _previewPage = currentPage - 1)
                        : null,
                  ),
                  Text(
                    'Page $currentPage of $totalPages',
                    style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                    onPressed: currentPage < totalPages
                        ? () => setState(() => _previewPage = currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
