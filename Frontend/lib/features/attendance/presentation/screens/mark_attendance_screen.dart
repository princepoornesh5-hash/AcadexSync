import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../domain/models/attendance_status.dart';
import '../providers/attendance_providers.dart';
import '../widgets/attendance_summary_card.dart';
import '../widgets/student_attendance_card.dart';
import '../widgets/save_attendance_button.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activeClass = ref.watch(activeClassProvider);
    final sessionAsync = ref.watch(activeStudentListProvider);
    final records = ref.watch(markingSessionProvider);
    final notifier = ref.read(markingSessionProvider.notifier);

    if (activeClass == null) {
      return const Scaffold(
        body: Center(child: Text("No active class selected")),
      );
    }

    // Filter records
    final filteredRecords = records.where((r) {
      final matchesSearch = r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            r.rollNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: DashboardColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activeClass.subjectName, style: const TextStyle(color: DashboardColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${activeClass.sectionName} • ${activeClass.timeSlot}", style: const TextStyle(color: DashboardColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: DashboardColors.primary),
            tooltip: "Refresh List",
            onPressed: () {
              ref.invalidate(activeStudentListProvider);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: DashboardColors.textPrimary),
            onSelected: (val) {
              if (val == 'mark_all_present') {
                notifier.markAll(AttendanceStatus.present);
              } else if (val == 'clear_all') {
                notifier.clearAll();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_present',
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle2, color: DashboardColors.success),
                    SizedBox(width: 8),
                    Text("Mark All Present"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(LucideIcons.rotateCcw, color: DashboardColors.warning),
                    SizedBox(width: 8),
                    Text("Clear All"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: DashboardColors.primary)),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (initialList) {
          if (initialList.isEmpty) {
            return const Center(child: Text("No students found in this section."));
          }

          return Column(
            children: [
              // Summary and Search
              Container(
                color: DashboardColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    AttendanceSummaryCard(
                      summary: notifier.summary,
                      remainingCount: notifier.remainingCount,
                      totalStudents: records.length,
                    ),
                    const SizedBox(height: 16),
                    AcadexSearchFilterBar(
                      searchHint: "Search by Name or Roll Number...",
                      onSearchChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ],
                ),
              ),
              
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StudentAttendanceCard(
                        record: record,
                        onStatusChanged: (status) {
                          notifier.markStatus(record.studentId, status);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DashboardColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SaveAttendanceButton(
            remainingCount: notifier.remainingCount,
            onSave: () async {
              // Wait for save dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Save Attendance"),
                  content: const Text("Are you sure you want to save this attendance record?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.primary, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Save"),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                // In a real app we would call saveSessionProvider or repository.saveSession
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Attendance saved successfully!"), backgroundColor: DashboardColors.success),
                );
                context.pop();
              }
            },
          ),
        ),
      ),
    );
  }
}
