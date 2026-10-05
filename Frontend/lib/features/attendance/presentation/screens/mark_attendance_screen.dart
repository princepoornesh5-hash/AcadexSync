import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/assigned_class.dart';
import '../providers/attendance_providers.dart';
import '../widgets/attendance_summary_card.dart';
import '../widgets/student_attendance_card.dart';
import '../widgets/save_attendance_button.dart';
import '../widgets/acadex_attendance_guard_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'present', 'late', 'excused', 'absent', 'unmarked'
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool?> _showDiscardConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Unsaved Attendance Changes",
          style: AcadexTypography.heading3(),
        ),
        content: Text(
          "You have unsaved attendance changes. If you leave now, your changes will not be saved.",
          style: AcadexTypography.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Keep Editing"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Discard Changes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackPress() async {
    if (_isDirty) {
      final shouldDiscard = await _showDiscardConfirmationDialog();
      if (shouldDiscard == true && mounted) {
        setState(() => _isDirty = false);
        context.safePop(fallbackRoute: '/attendance');
      }
    } else {
      context.safePop(fallbackRoute: '/attendance');
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return; // Prevent double submit
    final activeClass = ref.read(activeClassProvider);
    if (activeClass == null) return;

    final records = ref.read(markingSessionProvider);
    if (records.isEmpty) {
      AcadexSnackBar.showWarning(
        context,
        "Cannot submit attendance: No students are enrolled in this section.",
      );
      return;
    }

    final notifier = ref.read(markingSessionProvider.notifier);
    if (notifier.remainingCount > 0) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            "Unmarked Students (${notifier.remainingCount})",
            style: AcadexTypography.heading3(),
          ),
          content: Text(
            "There are ${notifier.remainingCount} student(s) without a marked status.\n\nWould you like to mark all remaining students as Absent and save, or continue marking manually?",
            style: AcadexTypography.body(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Continue Marking"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.error),
              onPressed: () {
                notifier.markUnmarked(AttendanceStatus.absent);
                Navigator.of(ctx).pop(true);
              },
              child: const Text("Mark Absent & Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (shouldProceed != true) return;
    }

    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Review & Submit Attendance",
          style: AcadexTypography.heading3(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're about to submit attendance for:",
              style: AcadexTypography.body(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AcadexColors.primaryLight,
                borderRadius: AcadexRadius.borderRadiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Subject: ${activeClass.subjectName}", style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.bold)),
                  Text("Section: ${activeClass.sectionName} • ${activeClass.timeSlot}", style: AcadexTypography.caption()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text("Summary Totals:", style: AcadexTypography.bodyMedium()),
            const SizedBox(height: 4),
            Text("• Total Students: ${records.length}", style: AcadexTypography.bodySmall()),
            Text("• Present: ${notifier.summary[AttendanceStatus.present] ?? 0}", style: AcadexTypography.bodySmall(color: AcadexColors.success)),
            Text("• Absent: ${notifier.summary[AttendanceStatus.absent] ?? 0}", style: AcadexTypography.bodySmall(color: AcadexColors.error)),
            Text("• Late: ${notifier.summary[AttendanceStatus.late] ?? 0}", style: AcadexTypography.bodySmall(color: AcadexColors.warning)),
            Text("• Excused: ${notifier.summary[AttendanceStatus.excused] ?? 0}", style: AcadexTypography.bodySmall(color: const Color(0xFF6366F1))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Confirm & Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (isConfirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final success = await ref.read(saveSessionProvider(activeClass.id).future);
      if (mounted) {
        setState(() {
          _isSaving = false;
          if (success) _isDirty = false;
        });
        if (success) {
          AcadexSnackBar.showSuccess(
            context,
            activeClass.isAttendanceMarked
                ? 'Attendance session updated successfully!'
                : 'Attendance session saved successfully!',
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          AcadexSnackBar.showError(
            context,
            'Unable to save attendance. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to save attendance session',
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
            onPressed: () => context.safePop(fallbackRoute: '/attendance'),
          ),
        ),
        body: Center(
          child: AcadexEmptyState(
            title: "No Class Selected",
            subtitle: "Please select a teaching class from your schedule first.",
            icon: LucideIcons.calendarX,
            actionLabel: "View Schedule",
            onActionTap: () => context.safePop(fallbackRoute: '/attendance'),
          ),
        ),
      );
    }

    // Filter records by local search query and status filter
    final filteredRecords = records.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.rollNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_statusFilter == 'present') return r.status == AttendanceStatus.present;
      if (_statusFilter == 'late') return r.status == AttendanceStatus.late;
      if (_statusFilter == 'excused') return r.status == AttendanceStatus.excused;
      if (_statusFilter == 'absent') return r.status == AttendanceStatus.absent;
      if (_statusFilter == 'unmarked') return r.status == null;
      return true;
    }).toList();

    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = sessionAsync.when(
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
                activeClass.isAttendanceMarked,
                activeClass,
              );
            }

            return _buildMobileTabletLayout(
              context,
              notifier,
              records,
              filteredRecords,
              isDark,
              activeClass.isAttendanceMarked,
              activeClass,
            );
          },
        );
      },
    );

    if (hasEnclosingScaffold) {
      return PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final discard = await _showDiscardConfirmationDialog();
          if (discard == true && mounted) {
            setState(() => _isDirty = false);
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
          body: Column(
            children: [
              Expanded(child: bodyContent),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _showDiscardConfirmationDialog();
        if (discard == true && mounted) {
          setState(() => _isDirty = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
            onPressed: _handleBackPress,
          ),
        title: Text(
          "Mark Attendance",
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
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
      body: bodyContent,
    ),
  );
}

  Widget _buildDesktopLayout(
    BuildContext context,
    MarkingSessionNotifier notifier,
    List<dynamic> records,
    List<dynamic> filteredRecords,
    bool isDark,
    bool isMarked,
    AssignedClass activeClass,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        height: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Attendance Smart Guard, Search & Student Roster
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  AcadexAttendanceGuardCard(
                    activeClass: activeClass,
                    totalStudents: records.length,
                    isMarked: isMarked,
                    onRefreshRoster: () => ref.invalidate(activeStudentListProvider),
                  ),
                  const SizedBox(height: 12),
                  _buildSearchBar(isDark),
                  const SizedBox(height: 10),
                  _buildFilterChips(isDark),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _buildStudentList(records, filteredRecords, notifier, isDark),
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
                      totalStudents: records.length,
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
    );
  }

  Widget _buildMobileTabletLayout(
    BuildContext context,
    MarkingSessionNotifier notifier,
    List<dynamic> records,
    List<dynamic> filteredRecords,
    bool isDark,
    bool isMarked,
    AssignedClass activeClass,
  ) {
    return Column(
      children: [
        // Header Section (Context Guard, Summary, Filters, Actions)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AcadexAttendanceGuardCard(
                activeClass: activeClass,
                totalStudents: records.length,
                isMarked: isMarked,
                onRefreshRoster: () => ref.invalidate(activeStudentListProvider),
              ),
              const SizedBox(height: 8),
              AttendanceSummaryCard(
                summary: notifier.summary,
                remainingCount: notifier.remainingCount,
                totalStudents: records.length,
                isVertical: false,
              ),
              const SizedBox(height: 8),
              _buildSearchBar(isDark),
              const SizedBox(height: 6),
              _buildFilterChips(isDark),
              const SizedBox(height: 6),
              _buildQuickActionButtons(notifier, isDark),
            ],
          ),
        ),

        // Student List (or empty state)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStudentList(records, filteredRecords, notifier, isDark),
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
              totalStudents: records.length,
              isLoading: _isSaving,
              isFullWidth: true,
              onSave: _handleSave,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateWidget(List<dynamic> records) {
    if (records.isEmpty) {
      return Center(
        child: AcadexEmptyState(
          title: "No Enrolled Students",
          subtitle: "No students are currently enrolled in this section.",
          icon: LucideIcons.users,
          actionLabel: "Back to Schedule",
          onActionTap: _handleBackPress,
        ),
      );
    }
    return Center(
      child: AcadexEmptyState(
        title: "No Matching Students",
        subtitle: _searchQuery.isNotEmpty
            ? "No student matches \"$_searchQuery\"."
            : "No students with selected filter \"$_statusFilter\".",
        icon: LucideIcons.userX,
      ),
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

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AcadexChip(
            label: "All",
            isSelected: _statusFilter == 'all',
            onSelected: (_) => setState(() => _statusFilter = 'all'),
          ),
          const SizedBox(width: 6),
          AcadexChip(
            label: "Present",
            isSelected: _statusFilter == 'present',
            onSelected: (_) => setState(() => _statusFilter = 'present'),
          ),
          const SizedBox(width: 6),
          AcadexChip(
            label: "Late",
            isSelected: _statusFilter == 'late',
            onSelected: (_) => setState(() => _statusFilter = 'late'),
          ),
          const SizedBox(width: 6),
          AcadexChip(
            label: "Excused",
            isSelected: _statusFilter == 'excused',
            onSelected: (_) => setState(() => _statusFilter = 'excused'),
          ),
          const SizedBox(width: 6),
          AcadexChip(
            label: "Absent",
            isSelected: _statusFilter == 'absent',
            onSelected: (_) => setState(() => _statusFilter = 'absent'),
          ),
          const SizedBox(width: 6),
          AcadexChip(
            label: "Unmarked",
            isSelected: _statusFilter == 'unmarked',
            onSelected: (_) => setState(() => _statusFilter = 'unmarked'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(MarkingSessionNotifier notifier, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: AcadexButton(
            label: "All Present",
            icon: LucideIcons.checkCheck,
            variant: AcadexButtonVariant.secondary,
            onPressed: () {
              setState(() => _isDirty = true);
              notifier.markAll(AttendanceStatus.present);
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: AcadexButton(
            label: "All Absent",
            icon: LucideIcons.x,
            variant: AcadexButtonVariant.secondary,
            onPressed: () {
              setState(() => _isDirty = true);
              notifier.markAll(AttendanceStatus.absent);
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: AcadexButton(
            label: "Clear All",
            icon: LucideIcons.rotateCcw,
            variant: AcadexButtonVariant.ghost,
            onPressed: () {
              setState(() => _isDirty = true);
              notifier.clearAll();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList(
    List<dynamic> records,
    List<dynamic> filteredRecords,
    MarkingSessionNotifier notifier,
    bool isDark,
  ) {
    if (filteredRecords.isEmpty) {
      return _buildEmptyStateWidget(records);
    }

    return ListView.builder(
      itemCount: filteredRecords.length,
      itemBuilder: (context, index) {
        final record = filteredRecords[index];
        return StudentAttendanceCard(
          record: record,
          onStatusChanged: (status) {
            setState(() => _isDirty = true);
            notifier.markStatus(record.studentId, status);
          },
        );
      },
    );
  }
}
