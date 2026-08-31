import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/attendance_analytics_models.dart';
import '../../domain/services/attendance_report_exporter.dart';
import '../providers/attendance_analytics_providers.dart';
import '../widgets/analytics/analytics_date_range_selector.dart';
import '../widgets/analytics/attendance_overview_card.dart';
import '../widgets/analytics/low_attendance_action_panel.dart';
import 'student_attendance_detail_screen.dart';

enum SectionSortOption {
  attendanceDesc,
  attendanceAsc,
  nameAsc,
  rollAsc,
}

class SectionAttendanceDetailScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final AttendanceDateRange? initialDateRange;

  const SectionAttendanceDetailScreen({
    super.key,
    required this.sectionId,
    this.initialDateRange,
  });

  @override
  ConsumerState<SectionAttendanceDetailScreen> createState() =>
      _SectionAttendanceDetailScreenState();
}

class _SectionAttendanceDetailScreenState
    extends ConsumerState<SectionAttendanceDetailScreen> {
  late AttendanceDateRange _selectedRange;
  String _searchQuery = '';
  SectionSortOption _sortOption = SectionSortOption.attendanceDesc;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialDateRange ?? AttendanceDateRange.thisMonth();
  }

  void _exportCsv(SectionAttendanceAnalytics section) {
    final csv = AttendanceReportExporter.generateSectionAttendanceCsv(
      section: section,
      dateRange: _selectedRange,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported section roster report for ${section.sectionName.isNotEmpty ? section.sectionName : widget.sectionId} (${csv.length} bytes)'),
        backgroundColor: AcadexColors.success,
      ),
    );
  }

  List<StudentAttendanceAnalytics> _filterAndSortStudents(
      List<StudentAttendanceAnalytics> students) {
    var result = students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = s.studentName.toLowerCase();
      final roll = s.rollNumber.toLowerCase();
      return name.contains(q) || roll.contains(q);
    }).toList();

    switch (_sortOption) {
      case SectionSortOption.attendanceDesc:
        result.sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));
        break;
      case SectionSortOption.attendanceAsc:
        result.sort((a, b) => a.attendancePercentage.compareTo(b.attendancePercentage));
        break;
      case SectionSortOption.nameAsc:
        result.sort((a, b) => a.studentName.compareTo(b.studentName));
        break;
      case SectionSortOption.rollAsc:
        result.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    final analyticsAsync = ref.watch(
      sectionAttendanceAnalyticsProvider(
        SectionAnalyticsQuery(
          sectionId: widget.sectionId,
          dateRange: _selectedRange,
        ),
      ),
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AcadexPageHeader(
                title: 'Section Attendance Analytics',
                subtitle: 'Class roster ranking, student drill-down, and compliance monitoring.',
                onBack: () => context.safePop(fallbackRoute: '/attendance/analytics'),
                actions: [
                  AnalyticsDateRangeSelector(
                    selectedRange: _selectedRange,
                    onRangeChanged: (newRange) {
                      setState(() {
                        _selectedRange = newRange;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              analyticsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => AcadexCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load section analytics',
                              style: AcadexTypography.heading2(color: AcadexColors.error),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              err.toString(),
                              style: AcadexTypography.caption(color: AcadexColors.inkMuted),
                            ),
                            const SizedBox(height: 16),
                            AcadexButton(
                              label: 'Retry',
                              icon: LucideIcons.refreshCw,
                              onPressed: () => ref.refresh(
                                sectionAttendanceAnalyticsProvider(
                                  SectionAnalyticsQuery(
                                    sectionId: widget.sectionId,
                                    dateRange: _selectedRange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (data) {
                      final displayName = data.sectionName.isNotEmpty
                          ? data.sectionName
                          : 'Section ${widget.sectionId}';
                      final filteredStudents = _filterAndSortStudents(data.studentAnalytics);
                      final lowStudents = data.studentAnalytics
                          .where((s) => AttendanceAnalyticsConstants.isLowAttendance(s.attendancePercentage))
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section Identity & CSV Action Card
                          AcadexCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AcadexColors.primary.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(LucideIcons.layoutGrid, color: AcadexColors.primary, size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: AcadexTypography.heading2(
                                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${data.totalStudents} enrolled • ${data.totalSessions} sessions',
                                              style: AcadexTypography.caption(
                                                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AcadexButton(
                                  label: 'Export CSV',
                                  icon: LucideIcons.download,
                                  variant: AcadexButtonVariant.secondary,
                                  size: AcadexButtonSize.sm,
                                  onPressed: () => _exportCsv(data),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Section Overview Card
                          AttendanceOverviewCard(
                            title: 'Section Performance Overview',
                            subtitle: 'Overall attendance rate for $displayName',
                            percentage: data.attendancePercentage,
                            presentCount: data.presentCount,
                            absentCount: data.absentCount,
                            lateCount: data.lateCount,
                            excusedCount: data.excusedCount,
                            unmarkedCount: data.unmarkedCount,
                            totalSessions: data.totalSessions,
                            totalStudents: data.totalStudents,
                            isLowAttendance: AttendanceAnalyticsConstants.isLowAttendance(data.attendancePercentage),
                          ),

                          // Action Panel for Low Attendance Students
                          if (lowStudents.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            LowAttendanceActionPanel(
                              title: 'Section Shortage Action Center',
                              students: lowStudents,
                              onStudentSelected: (student) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentAttendanceDetailScreen(
                                      studentId: student.studentId,
                                      initialDateRange: _selectedRange,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Student Roster Leaderboard & Filters Card
                          AcadexCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.users, size: 18, color: AcadexColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Student Attendance Roster',
                                        style: AcadexTypography.heading2(
                                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                        ),
                                      ),
                                    ),
                                    AcadexBadge(
                                      label: '${filteredStudents.length} Students',
                                      variant: AcadexBadgeVariant.info,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                if (isMobile) ...[
                                  TextField(
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search student name / roll...',
                                      prefixIcon: const Icon(LucideIcons.search, size: 16),
                                      isDense: true,
                                      filled: true,
                                      fillColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                      border: OutlineInputBorder(
                                        borderRadius: AcadexRadius.borderRadiusSm,
                                        borderSide: BorderSide(
                                          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonHideUnderline(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                        borderRadius: AcadexRadius.borderRadiusSm,
                                        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                                      ),
                                      child: DropdownButton<SectionSortOption>(
                                        value: _sortOption,
                                        isExpanded: true,
                                        icon: const Icon(LucideIcons.arrowUpDown, size: 14),
                                        onChanged: (opt) {
                                          if (opt != null) {
                                            setState(() {
                                              _sortOption = opt;
                                            });
                                          }
                                        },
                                        items: const [
                                          DropdownMenuItem(
                                            value: SectionSortOption.attendanceDesc,
                                            child: Text('Highest % First'),
                                          ),
                                          DropdownMenuItem(
                                            value: SectionSortOption.attendanceAsc,
                                            child: Text('Lowest % First'),
                                          ),
                                          DropdownMenuItem(
                                            value: SectionSortOption.nameAsc,
                                            child: Text('Name (A-Z)'),
                                          ),
                                          DropdownMenuItem(
                                            value: SectionSortOption.rollAsc,
                                            child: Text('Roll Number'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          onChanged: (val) {
                                            setState(() {
                                              _searchQuery = val;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Search by student name or roll number...',
                                            prefixIcon: const Icon(LucideIcons.search, size: 16),
                                            isDense: true,
                                            filled: true,
                                            fillColor: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                            border: OutlineInputBorder(
                                              borderRadius: AcadexRadius.borderRadiusSm,
                                              borderSide: BorderSide(
                                                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      DropdownButtonHideUnderline(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft,
                                            borderRadius: AcadexRadius.borderRadiusSm,
                                            border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                                          ),
                                          child: DropdownButton<SectionSortOption>(
                                            value: _sortOption,
                                            icon: const Icon(LucideIcons.arrowUpDown, size: 14),
                                            onChanged: (opt) {
                                              if (opt != null) {
                                                setState(() {
                                                  _sortOption = opt;
                                                });
                                              }
                                            },
                                            items: const [
                                              DropdownMenuItem(
                                                value: SectionSortOption.attendanceDesc,
                                                child: Text('Highest % First'),
                                              ),
                                              DropdownMenuItem(
                                                value: SectionSortOption.attendanceAsc,
                                                child: Text('Lowest % First'),
                                              ),
                                              DropdownMenuItem(
                                                value: SectionSortOption.nameAsc,
                                                child: Text('Name (A-Z)'),
                                              ),
                                              DropdownMenuItem(
                                                value: SectionSortOption.rollAsc,
                                                child: Text('Roll Number'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 16),

                                if (filteredStudents.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Center(
                                      child: Text(
                                        'No matching students found in this section.',
                                        style: AcadexTypography.caption(
                                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      for (int index = 0; index < filteredStudents.length; index++) ...[
                                        if (index > 0) const Divider(height: 12),
                                        Builder(
                                          builder: (context) {
                                            final student = filteredStudents[index];
                                            final sName = student.studentName.isNotEmpty
                                                ? student.studentName
                                                : student.studentId;
                                            final roll = student.rollNumber.isNotEmpty
                                                ? student.rollNumber
                                                : 'Roll: --';

                                            return InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => StudentAttendanceDetailScreen(
                                                      studentId: student.studentId,
                                                      initialDateRange: _selectedRange,
                                                    ),
                                                  ),
                                                );
                                              },
                                              borderRadius: AcadexRadius.borderRadiusSm,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: student.isLowAttendance
                                                            ? AcadexColors.error.withValues(alpha: 0.15)
                                                            : AcadexColors.primary.withValues(alpha: 0.1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${index + 1}',
                                                          style: AcadexTypography.caption(
                                                            color: student.isLowAttendance
                                                                ? AcadexColors.error
                                                                : AcadexColors.primary,
                                                          ).copyWith(fontWeight: FontWeight.w700),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            sName,
                                                            style: AcadexTypography.body(
                                                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                                                            ).copyWith(fontWeight: FontWeight.w600),
                                                          ),
                                                          Text(
                                                            '$roll • ${student.presentCount}/${student.totalSessions} present',
                                                            style: AcadexTypography.caption(
                                                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          '${student.attendancePercentage.toStringAsFixed(1)}%',
                                                          style: AcadexTypography.body(
                                                            color: student.isLowAttendance
                                                                ? AcadexColors.error
                                                                : (student.attendancePercentage >= 85.0 ? AcadexColors.success : AcadexColors.warning),
                                                          ).copyWith(fontWeight: FontWeight.w700),
                                                        ),
                                                        if (student.isLowAttendance)
                                                          const AcadexBadge(
                                                            label: 'Shortage',
                                                            variant: AcadexBadgeVariant.danger,
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Icon(
                                                      LucideIcons.chevronRight,
                                                      size: 16,
                                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
