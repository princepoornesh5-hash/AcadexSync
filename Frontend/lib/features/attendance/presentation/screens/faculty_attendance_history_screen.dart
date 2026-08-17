import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../providers/faculty_history_providers.dart';
import '../widgets/faculty/attendance_record_card.dart';

class FacultyAttendanceHistoryScreen extends ConsumerStatefulWidget {
  const FacultyAttendanceHistoryScreen({super.key});

  @override
  ConsumerState<FacultyAttendanceHistoryScreen> createState() => _FacultyAttendanceHistoryScreenState();
}

class _FacultyAttendanceHistoryScreenState extends ConsumerState<FacultyAttendanceHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(filteredFacultyHistoryProvider);
    final statusFilter = ref.watch(historyStatusFilterProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: DashboardColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text("Attendance Records", style: TextStyle(color: DashboardColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Container(
            color: DashboardColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AcadexSearchFilterBar(
                  searchHint: "Search by subject or section...",
                  onSearchChanged: (val) {
                    ref.read(historySearchQueryProvider.notifier).state = val;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip("All", statusFilter == null, () {
                      ref.read(historyStatusFilterProvider.notifier).state = null;
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip("Locked", statusFilter == 'Locked', () {
                      ref.read(historyStatusFilterProvider.notifier).state = 'Locked';
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip("Drafts", statusFilter == 'Draft', () {
                      ref.read(historyStatusFilterProvider.notifier).state = 'Draft';
                    }),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const AcadexEmptyState(
                    title: "No Records Found",
                    subtitle: "Try adjusting your search or filters.",
                    icon: LucideIcons.calendarOff,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return AttendanceRecordCard(
                      session: session,
                      onTap: () {
                        ref.read(activeSessionIdProvider.notifier).state = session.id;
                        context.push('/attendance/faculty/detail');
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DashboardColors.primary : DashboardColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? DashboardColors.primary : DashboardColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : DashboardColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}