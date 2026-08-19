import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/attendance_status.dart';
import '../providers/attendance_providers.dart';
import '../widgets/attendance_summary_card.dart';
import '../widgets/student_attendance_card.dart';
import '../widgets/save_attendance_button.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final activeClass = ref.read(activeClassProvider);
    if (activeClass == null) return;

    setState(() => _isSaving = true);
    try {
      final success = await ref.read(saveSessionProvider(activeClass.id).future);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance session saved successfully!',
                    style: AcadexTypography.bodySmall(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: AcadexColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to save attendance. Please try again.',
                style: AcadexTypography.bodySmall(color: Colors.white),
              ),
              backgroundColor: AcadexColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving attendance: $e',
              style: AcadexTypography.bodySmall(color: Colors.white),
            ),
            backgroundColor: AcadexColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClass = ref.watch(activeClassProvider);
    final sessionAsync = ref.watch(activeStudentListProvider);
    final records = ref.watch(markingSessionProvider);
    final notifier = ref.read(markingSessionProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeClass == null) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: AcadexEmptyState(
            title: "No Class Selected",
            subtitle: "Please select a teaching class from your schedule first.",
            icon: LucideIcons.calendarX,
          ),
        ),
      );
    }

    // Filter records by local search query
    final filteredRecords = records.where((r) {
      final matchesSearch = r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.rollNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeClass.subjectName,
              style: AcadexTypography.title(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              "${activeClass.sectionName} • ${activeClass.timeSlot}",
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.refreshCw,
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              size: 18,
            ),
            tooltip: "Refresh Roster",
            onPressed: () {
              ref.invalidate(activeStudentListProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(
          child: AcadexLoadingState(message: "Loading student roster..."),
        ),
        error: (err, stack) => Center(
          child: AcadexErrorState(
            message: "Unable to load student roster: $err",
            onRetry: () => ref.refresh(activeStudentListProvider),
          ),
        ),
        data: (_) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;

              if (isDesktop) {
                return _buildDesktopLayout(
                  context,
                  notifier,
                  records,
                  filteredRecords,
                  isDark,
                );
              }

              return _buildMobileTabletLayout(
                context,
                notifier,
                records,
                filteredRecords,
                isDark,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    MarkingSessionNotifier notifier,
    List<dynamic> records,
    List<dynamic> filteredRecords,
    bool isDark,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Search & Student Roster
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildSearchBar(isDark),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildStudentList(filteredRecords, notifier, isDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              
              // Right: Sticky Side Panel
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AttendanceSummaryCard(
                        summary: notifier.summary,
                        remainingCount: notifier.remainingCount,
                        totalStudents: records.length,
                        isVertical: true,
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActionButtons(notifier, isDark),
                      const SizedBox(height: 20),
                      SaveAttendanceButton(
                        remainingCount: notifier.remainingCount,
                        isLoading: _isSaving,
                        isFullWidth: true,
                        onSave: _handleSave,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabletLayout(
    BuildContext context,
    MarkingSessionNotifier notifier,
    List<dynamic> records,
    List<dynamic> filteredRecords,
    bool isDark,
  ) {
    return Column(
      children: [
        // Top Summary & Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              AttendanceSummaryCard(
                summary: notifier.summary,
                remainingCount: notifier.remainingCount,
                totalStudents: records.length,
                isVertical: false,
              ),
              const SizedBox(height: 12),
              _buildSearchBar(isDark),
              const SizedBox(height: 8),
              _buildQuickActionButtons(notifier, isDark),
            ],
          ),
        ),
        
        // Student List
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStudentList(filteredRecords, notifier, isDark),
          ),
        ),

        // Bottom Sticky Action Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
            border: Border(
              top: BorderSide(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SaveAttendanceButton(
              remainingCount: notifier.remainingCount,
              isLoading: _isSaving,
              isFullWidth: true,
              onSave: _handleSave,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: AcadexTypography.body(
          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
        ),
        decoration: InputDecoration(
          hintText: "Search students by name or roll number...",
          prefixIcon: Icon(
            LucideIcons.search,
            size: 18,
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildQuickActionButtons(MarkingSessionNotifier notifier, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: AcadexButton(
            label: "Mark All Present",
            icon: LucideIcons.checkCheck,
            variant: AcadexButtonVariant.secondary,
            onPressed: () => notifier.markAll(AttendanceStatus.present),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AcadexButton(
            label: "Clear All",
            icon: LucideIcons.rotateCcw,
            variant: AcadexButtonVariant.ghost,
            onPressed: () => notifier.clearAll(),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList(
    List<dynamic> filteredRecords,
    MarkingSessionNotifier notifier,
    bool isDark,
  ) {
    if (filteredRecords.isEmpty) {
      return Center(
        child: AcadexEmptyState(
          title: "No Matching Students",
          subtitle: "No student matches \"$_searchQuery\". Try adjusting your search query.",
          icon: LucideIcons.userX,
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRecords.length,
      itemBuilder: (context, index) {
        final record = filteredRecords[index];
        return StudentAttendanceCard(
          record: record,
          onStatusChanged: (status) {
            notifier.markStatus(record.studentId, status);
          },
        );
      },
    );
  }
}
